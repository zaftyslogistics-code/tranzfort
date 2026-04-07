import { createClient } from '@supabase/supabase-js'

const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('APP_ORIGIN') ?? 'https://tranzfort.com',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type PushNotificationRequest = {
  target_user_id: string
  title: string
  body: string
  data?: Record<string, string | number | boolean | null>
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

  let payload: PushNotificationRequest
  try {
    payload = await request.json()
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400)
  }

  const targetUserId = payload.target_user_id?.trim()
  const title = payload.title?.trim()
  const body = payload.body?.trim()

  if (!targetUserId || !title || !body) {
    return jsonResponse(
      {
        error: 'target_user_id, title, and body are required',
      },
      400,
    )
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  })

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, push_token')
    .eq('id', targetUserId)
    .maybeSingle()

  if (profileError) {
    return jsonResponse({ error: profileError.message }, 500)
  }

  const pushToken = profile?.push_token?.toString().trim() ?? ''
  if (!pushToken) {
    return jsonResponse({ delivered: false, reason: 'No push token for target user' }, 200)
  }

  let accessToken: string
  try {
    accessToken = await getAccessToken(serviceAccount)
  } catch (err) {
    return jsonResponse({ error: 'Failed to obtain FCM access token', details: String(err) }, 500)
  }

  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`

  const response = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: pushToken,
        notification: {
          title,
          body,
        },
        data: stringifyData(payload.data),
        android: {
          priority: 'high' as const,
        },
      },
    }),
  })

  const responseText = await response.text()
  if (!response.ok) {
    return jsonResponse(
      {
        delivered: false,
        error: 'FCM request failed',
        details: responseText,
      },
      502,
    )
  }

  return jsonResponse({ delivered: true, details: responseText }, 200)
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

function stringifyData(data: PushNotificationRequest['data']): Record<string, string> {
  if (!data) {
    return {}
  }

  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, value == null ? '' : String(value)]),
  )
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
