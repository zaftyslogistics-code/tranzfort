param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY,
  [string]$Email = $env:SUPER_ADMIN_EMAIL,
  [string]$Password = $env:SUPER_ADMIN_PASSWORD,
  [string]$FullName = 'Zafty Logistics'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  throw 'SUPABASE_URL is required. Pass -SupabaseUrl or set the environment variable.'
}
if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
  throw 'SUPABASE_SERVICE_ROLE_KEY is required. Pass -ServiceRoleKey or set the environment variable.'
}
if ([string]::IsNullOrWhiteSpace($Email)) {
  throw 'SUPER_ADMIN_EMAIL is required. Pass -Email or set the environment variable.'
}
if ([string]::IsNullOrWhiteSpace($Password)) {
  throw 'SUPER_ADMIN_PASSWORD is required. Pass -Password or set the environment variable.'
}

$SupabaseUrl = $SupabaseUrl.TrimEnd('/')
$Headers = @{
  apikey = $ServiceRoleKey
  Authorization = "Bearer $ServiceRoleKey"
}
$JsonHeaders = @{
  apikey = $ServiceRoleKey
  Authorization = "Bearer $ServiceRoleKey"
  'Content-Type' = 'application/json'
  Prefer = 'return=representation'
}

function Get-ErrorMessage {
  param([Parameter(ValueFromPipeline = $true)]$ErrorRecord)

  if ($null -eq $ErrorRecord) {
    return 'Unknown request failure.'
  }

  if ($ErrorRecord.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
    return $ErrorRecord.ErrorDetails.Message
  }

  $response = $ErrorRecord.Exception.Response
  if ($null -eq $response) {
    return $ErrorRecord.Exception.Message
  }

  $body = $null
  if ($response -is [System.Net.Http.HttpResponseMessage]) {
    try {
      $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    }
    catch {
      $body = $null
    }
  } elseif ($response.PSObject.Methods.Name -contains 'GetResponseStream') {
    try {
      $stream = $response.GetResponseStream()
      if ($null -ne $stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
      }
    }
    catch {
      $body = $null
    }
  }

  if ([string]::IsNullOrWhiteSpace($body)) {
    return $ErrorRecord.Exception.Message
  }

  try {
    $parsed = $body | ConvertFrom-Json
    if ($parsed.msg) { return [string]$parsed.msg }
    if ($parsed.message) { return [string]$parsed.message }
    if ($parsed.error_description) { return [string]$parsed.error_description }
  }
  catch {
  }

  return $body
}

function Invoke-Supabase {
  param(
    [Parameter(Mandatory = $true)][ValidateSet('GET', 'POST', 'PATCH', 'PUT')] [string]$Method,
    [Parameter(Mandatory = $true)][string]$Url,
    [object]$Body,
    [hashtable]$RequestHeaders = $JsonHeaders
  )

  try {
    if ($PSBoundParameters.ContainsKey('Body')) {
      return Invoke-RestMethod -Method $Method -Uri $Url -Headers $RequestHeaders -Body ($Body | ConvertTo-Json -Depth 8)
    }
    return Invoke-RestMethod -Method $Method -Uri $Url -Headers $RequestHeaders
  }
  catch {
    $message = Get-ErrorMessage $_
    throw "Request failed for $Method $Url`n$message"
  }
}

$listUrl = "$SupabaseUrl/auth/v1/admin/users?page=1&per_page=1000"
$userListResponse = Invoke-Supabase -Method GET -Url $listUrl -RequestHeaders $Headers
$userList = @()
if ($userListResponse -is [System.Collections.IEnumerable] -and -not ($userListResponse -is [string])) {
  $userList = @($userListResponse)
}
if ($userListResponse.users) {
  $userList = @($userListResponse.users)
}

$authUser = $userList | Where-Object { $_.email -and $_.email.ToLower() -eq $Email.ToLower() } | Select-Object -First 1

if ($null -eq $authUser) {
  $authUser = Invoke-Supabase -Method POST -Url "$SupabaseUrl/auth/v1/admin/users" -Body @{
    email = $Email
    password = $Password
    email_confirm = $true
    user_metadata = @{
      full_name = $FullName
    }
  }
}
elseif ($authUser.id) {
  $authUser = Invoke-Supabase -Method PUT -Url "$SupabaseUrl/auth/v1/admin/users/$($authUser.id)" -Body @{
    password = $Password
    email_confirm = $true
    user_metadata = @{
      full_name = $FullName
    }
  }
}

if ([string]::IsNullOrWhiteSpace($authUser.id)) {
  throw 'Unable to resolve the auth user id for the requested super admin account.'
}

$escapedEmail = [System.Uri]::EscapeDataString($Email)
$adminLookupUrl = "$SupabaseUrl/rest/v1/admin_users?select=id,auth_user_id,email&email=eq.$escapedEmail"
$existingAdminRows = @(Invoke-Supabase -Method GET -Url $adminLookupUrl -RequestHeaders $Headers)
$existingAdmin = $existingAdminRows | Select-Object -First 1
$existingAdminId = $null
if ($null -ne $existingAdmin) {
  $existingAdminId = [string]$existingAdmin.id
}

$adminPayload = @{
  auth_user_id = $authUser.id
  full_name = $FullName
  email = $Email
  role = 'super_admin'
  is_active = $true
}

if ([string]::IsNullOrWhiteSpace($existingAdminId)) {
  $adminResult = Invoke-Supabase -Method POST -Url "$SupabaseUrl/rest/v1/admin_users" -Body $adminPayload
}
else {
  $adminResult = Invoke-Supabase -Method PATCH -Url "$SupabaseUrl/rest/v1/admin_users?id=eq.$existingAdminId" -Body $adminPayload
}

$verifiedAdminRows = @(
  Invoke-Supabase -Method GET -Url "$SupabaseUrl/rest/v1/admin_users?select=id,auth_user_id,email,role,is_active&email=eq.$escapedEmail" -RequestHeaders $Headers
)
$verifiedAdmin = $verifiedAdminRows | Select-Object -First 1
if ($null -eq $verifiedAdmin) {
  throw 'Super admin provisioning completed the write call, but the admin_users row could not be re-read for verification.'
}
if ([string]::IsNullOrWhiteSpace([string]$verifiedAdmin.auth_user_id)) {
  throw 'Super admin provisioning completed the write call, but admin_users.auth_user_id is blank.'
}
if ([string]$verifiedAdmin.auth_user_id -ne [string]$authUser.id) {
  throw "Super admin provisioning mismatch: admin_users.auth_user_id=$($verifiedAdmin.auth_user_id) does not match auth user id $($authUser.id)."
}
if ([string]$verifiedAdmin.role -ne 'super_admin') {
  throw "Super admin provisioning mismatch: expected role super_admin but found $($verifiedAdmin.role)."
}
if ($verifiedAdmin.is_active -ne $true) {
  throw 'Super admin provisioning mismatch: admin_users row is not active after sync.'
}

Write-Host "Super admin ready for $Email"
Write-Host "Auth user id: $($authUser.id)"
if ($adminResult) {
  Write-Host 'Admin row synced successfully.'
}
