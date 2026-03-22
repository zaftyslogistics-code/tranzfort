param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY,
  [string]$Email = $env:SUPER_ADMIN_EMAIL,
  [string]$ExpectedRole = 'super_admin',
  [switch]$AllowInactive
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  throw 'SUPABASE_URL is required. Pass -SupabaseUrl or set the environment variable.'
}
if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
  throw 'SUPABASE_SERVICE_ROLE_KEY is required. Pass -ServiceRoleKey or set the environment variable.'
}
if ([string]::IsNullOrWhiteSpace($Email)) {
  throw 'Email is required. Pass -Email or set SUPER_ADMIN_EMAIL.'
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
  }
  elseif ($response.PSObject.Methods.Name -contains 'GetResponseStream') {
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
  throw "No auth user found for $Email."
}
if ([string]::IsNullOrWhiteSpace([string]$authUser.id)) {
  throw "Auth user lookup for $Email returned a blank id."
}

$escapedEmail = [System.Uri]::EscapeDataString($Email)
$escapedAuthUserId = [System.Uri]::EscapeDataString([string]$authUser.id)
$adminRows = @(
  Invoke-Supabase -Method GET -Url "$SupabaseUrl/rest/v1/admin_users?select=id,auth_user_id,email,role,is_active&email=eq.$escapedEmail" -RequestHeaders $Headers
)

if ($adminRows.Count -eq 0) {
  throw "No admin_users row found for $Email."
}
if ($adminRows.Count -gt 1) {
  throw "Expected exactly one admin_users row for $Email but found $($adminRows.Count)."
}

$adminRow = $adminRows[0]
if ([string]::IsNullOrWhiteSpace([string]$adminRow.auth_user_id)) {
  throw "admin_users.auth_user_id is blank for $Email."
}
if ([string]$adminRow.auth_user_id -ne [string]$authUser.id) {
  throw "admin_users.auth_user_id=$($adminRow.auth_user_id) does not match auth user id $($authUser.id) for $Email."
}

$mappedRows = @(
  Invoke-Supabase -Method GET -Url "$SupabaseUrl/rest/v1/admin_users?select=id,email,auth_user_id&auth_user_id=eq.$escapedAuthUserId" -RequestHeaders $Headers
)
if ($mappedRows.Count -eq 0) {
  throw "No admin_users row is reachable through auth_user_id=$($authUser.id)."
}
if ($mappedRows.Count -gt 1) {
  throw "Expected exactly one admin_users row for auth_user_id=$($authUser.id) but found $($mappedRows.Count)."
}
if ([string]$mappedRows[0].id -ne [string]$adminRow.id) {
  throw "admin_users email lookup row id $($adminRow.id) does not match auth_user_id lookup row id $($mappedRows[0].id)."
}

if (-not [string]::IsNullOrWhiteSpace($ExpectedRole) -and [string]$adminRow.role -ne $ExpectedRole) {
  throw "Expected role $ExpectedRole for $Email but found $($adminRow.role)."
}
if (-not $AllowInactive -and $adminRow.is_active -ne $true) {
  throw "Expected admin_users row for $Email to be active, but is_active=$($adminRow.is_active)."
}

Write-Host "Admin access row verified for $Email"
Write-Host "Auth user id: $($authUser.id)"
Write-Host "Admin row id: $($adminRow.id)"
Write-Host "Role: $($adminRow.role)"
Write-Host "Active: $($adminRow.is_active)"
