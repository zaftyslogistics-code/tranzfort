import { createClient } from '@supabase/supabase-js'

const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('APP_ORIGIN') ?? 'https://tranzfort.com',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type SingleNotificationRequest = {
  target_user_id: string
  title: string
  body: string
  data?: Record<string, string | number | boolean | null>
}

type BatchNotificationRequest = {
  notifications: Array<{
    target_user_id: string
    title: string
    body: string
    data?: Record<string, string | number | boolean | null>
  }>
}

type PushNotificationRequest = SingleNotificationRequest | BatchNotificationRequest

// Rate limiting: max 100 notifications per request, max 500 tokens per FCM batch
const MAX_NOTIFICATIONS_PER_REQUEST = 100
const MAX_FCM_BATCH_SIZE = 500
const MAX_REQUESTS_PER_MINUTE = 60

// Simple in-memory rate limiter (resets on function cold start)
const requestCounts = new Map<string, { count: number; resetTime: number }>()

function checkRateLimit(clientId: string): boolean {
  const now = Date.now()
  const windowStart = now - 60000 // 1 minute window

  const record = requestCounts.get(clientId)
  if (!record || record.resetTime < windowStart) {
    requestCounts.set(clientId, { count: 1, resetTime: now })
    return true
  }

  if (record.count >= MAX_REQUESTS_PER_MINUTE) {
    return false
  }

  record.count++
  return true
}

type ServiceAccountCredentials = {
  client_email: string
  private_key: string
  project_id: string
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const fcmServiceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON') ?? ''

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Supabase environment is not configured' }, 500)
  }

  if (!fcmServiceAccountJson) {
    return jsonResponse({ error: 'FCM_SERVICE_ACCOUNT_JSON is not configured' }, 500)
  }

  let serviceAccount: ServiceAccountCredentials
  try {
    serviceAccount = JSON.parse(fcmServiceAccountJson)
  } catch {
    return jsonResponse({ error: 'FCM_SERVICE_ACCOUNT_JSON is not valid JSON' }, 500)
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key || !serviceAccount.project_id) {
    return jsonResponse({ error: 'FCM_SERVICE_ACCOUNT_JSON missing required fields' }, 500)
  }

  // Rate limiting check
  const clientId = request.headers.get('x-client-info') ?? 'anonymous'
  if (!checkRateLimit(clientId)) {
    return jsonResponse({ error: 'Rate limit exceeded. Max 60 requests per minute.' }, 429)
  }

  let payload: PushNotificationRequest
  try {
    payload = await request.json()
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400)
  }

  // Normalize to batch format
  const notifications: Array<{ target_user_id: string; title: string; body: string; data?: Record<string, string | number | boolean | null> }> =
    'notifications' in payload ? payload.notifications : [payload as SingleNotificationRequest]

  if (notifications.length === 0) {
    return jsonResponse({ error: 'At least one notification is required' }, 400)
  }

  if (notifications.length > MAX_NOTIFICATIONS_PER_REQUEST) {
    return jsonResponse(
      { error: `Max ${MAX_NOTIFICATIONS_PER_REQUEST} notifications per request` },
      400,
    )
  }

  // Validate all notifications
  for (const notification of notifications) {
    if (!notification.target_user_id?.trim() || !notification.title?.trim() || !notification.body?.trim()) {
      return jsonResponse(
        { error: 'Each notification requires target_user_id, title, and body' },
        400,
      )
    }
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  })

  // Fetch all push tokens in a single query
  const userIds = notifications.map((n) => n.target_user_id.trim())
  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .select('id, push_token')
    .in('id', userIds)

  if (profilesError) {
    return jsonResponse({ error: profilesError.message }, 500)
  }

  // Build token -> notification mapping
  const tokenMap = new Map<string, typeof notifications[0]>()
  const skippedUsers: string[] = []

  for (const notification of notifications) {
    const profile = profiles?.find((p) => p.id === notification.target_user_id.trim())
    const pushToken = profile?.push_token?.toString().trim() ?? ''

    if (!pushToken) {
      skippedUsers.push(notification.target_user_id)
      continue
    }

    // If same user appears multiple times, last one wins
    tokenMap.set(pushToken, notification)
  }

  if (tokenMap.size === 0) {
    return jsonResponse({
      delivered: false,
      reason: 'No valid push tokens found',
      skipped_users: skippedUsers,
    }, 200)
  }

  let accessToken: string
  try {
    accessToken = await getAccessToken(serviceAccount)
  } catch (err) {
    return jsonResponse({ error: 'Failed to obtain FCM access token', details: String(err) }, 500)
  }

  // Send notifications in batches (FCM supports up to 500 tokens per batch)
  const tokens = Array.from(tokenMap.keys())
  const results: Array<{ token: string; success: boolean; error?: string }> = []

  for (let i = 0; i < tokens.length; i += MAX_FCM_BATCH_SIZE) {
    const batchTokens = tokens.slice(i, i + MAX_FCM_BATCH_SIZE)
    const batchResults = await sendFcmBatch(
      serviceAccount.project_id,
      accessToken,
      batchTokens,
      tokenMap,
    )
    results.push(...batchResults)
  }

  const successCount = results.filter((r) => r.success).length
  const failureCount = results.length - successCount

  return jsonResponse({
    delivered: successCount > 0,
    success_count: successCount,
    failure_count: failureCount,
    skipped_users: skippedUsers,
    results: results,
  }, 200)
})

async function getAccessToken(sa: ServiceAccountCredentials): Promise<string> {
  const scope = 'https://www.googleapis.com/auth/firebase.messaging'
  const now = Math.floor(Date.now() / 1000)

  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claimSet = base64url(
    JSON.stringify({
      iss: sa.client_email,
      scope,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  )

  const unsignedJwt = `${header}.${claimSet}`

  const keyData = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedJwt),
  )

  const signedJwt = `${unsignedJwt}.${base64url(signature)}`

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedJwt}`,
  })

  if (!tokenResponse.ok) {
    const errText = await tokenResponse.text()
    throw new Error(`Token exchange failed: ${errText}`)
  }

  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

function base64url(input: string | ArrayBuffer): string {
  let bytes: Uint8Array
  if (typeof input === 'string') {
    bytes = new TextEncoder().encode(input)
  } else {
    bytes = new Uint8Array(input)
  }
  const binary = Array.from(bytes)
    .map((b) => String.fromCharCode(b))
    .join('')
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function stringifyData(data: Record<string, string | number | boolean | null> | undefined): Record<string, string> {
  if (!data) {
    return {}
  }

  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, value == null ? '' : String(value)]),
  )
}

async function sendFcmBatch(
  projectId: string,
  accessToken: string,
  tokens: string[],
  tokenMap: Map<string, { title: string; body: string; data?: Record<string, string | number | boolean | null> }>,
): Promise<Array<{ token: string; success: boolean; error?: string }>> {
  const fcmUrl = `https://fcm.googleapis.com/batch`
  const results: Array<{ token: string; success: boolean; error?: string }> = []

  // Build multipart batch request
  const boundary = 'batch_' + crypto.randomUUID()
  const parts: string[] = []

  for (const token of tokens) {
    const notification = tokenMap.get(token)!
    const messageBody = JSON.stringify({
      message: {
        token: token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: stringifyData(notification.data),
        android: {
          priority: 'high',
        },
      },
    })

    parts.push(
      `--${boundary}\r\n` +
      `Content-Type: application/http\r\n` +
      `Content-Transfer-Encoding: binary\r\n\r\n` +
      `POST /v1/projects/${projectId}/messages:send HTTP/1.1\r\n` +
      `Content-Type: application/json\r\n\r\n` +
      `${messageBody}\r\n`,
    )
  }

  parts.push(`--${boundary}--\r\n`)

  try {
    const response = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': `multipart/mixed; boundary=${boundary}`,
      },
      body: parts.join(''),
    })

    if (!response.ok) {
      // Batch request failed entirely - mark all as failed
      return tokens.map((token) => ({
        token,
        success: false,
        error: `Batch request failed: ${response.statusText}`,
      }))
    }

    // Parse batch response
    const responseText = await response.text()

    // Simple parsing of multipart response
    for (const token of tokens) {
      if (responseText.includes('"name":"projects/')) {
        results.push({ token, success: true })
      } else if (responseText.includes('error')) {
        const errorMatch = responseText.match(/"message":"([^"]+)"/)
        results.push({ token, success: false, error: errorMatch?.[1] ?? 'Unknown error' })
      } else {
        results.push({ token, success: true })
      }
    }
  } catch (error) {
    // Network or parsing error - mark all as failed
    return tokens.map((token) => ({
      token,
      success: false,
      error: String(error),
    }))
  }

  return results
}

function jsonResponse(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}
