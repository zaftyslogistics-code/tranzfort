param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$SuperAdminEmail = "zaftyslogistics@gmail.com",
  [string]$ExpectedRole = "super_admin",
  [switch]$ValidateAllIdentities
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-EnvValue {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$Key
  )

  if (-not (Test-Path $FilePath)) { return "" }

  $line = Get-Content $FilePath |
    Where-Object { $_ -match "^\s*$Key\s*=" } |
    Select-Object -First 1

  if (-not $line) { return "" }

  return (($line -split "=", 2)[1]).Trim()
}

function Invoke-PasswordAuth {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][string]$AnonKey,
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$Passphrase
  )

  $headers = @{ apikey = $AnonKey; "Content-Type" = "application/json" }
  $body = @{ email = $Email; password = $Passphrase } | ConvertTo-Json

  return Invoke-RestMethod -Method Post -Uri "$Url/auth/v1/token?grant_type=password" -Headers $headers -Body $body
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_ANON_KEY"
}

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure Admin/.env"
}

$superAdminPassphrase = if ($env:TZ_TEST_PASSCODE) { $env:TZ_TEST_PASSCODE } else { "Tabish%%Khan721" }

$identities = @(
  @{ role = "super_admin"; email = $SuperAdminEmail; password = $superAdminPassphrase }
)

if ($ValidateAllIdentities) {
  $identities += @(
    @{ role = "trucker"; email = "trucker@example.com"; password = "Tabish%%Khan721" },
    @{ role = "supplier"; email = "supplier@example.com"; password = "Tabish%%Khan721" }
  )
}

$authResults = @()
foreach ($identity in $identities) {
  try {
    $auth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $identity.email -Passphrase $identity.password

    $authResults += [PSCustomObject]@{
      identity_role = $identity.role
      email         = $identity.email
      auth_ok       = $true
      auth_user_id  = $auth.user.id
      error         = $null
    }
  } catch {
    $authResults += [PSCustomObject]@{
      identity_role = $identity.role
      email         = $identity.email
      auth_ok       = $false
      auth_user_id  = $null
      error         = $_.Exception.Message
    }
  }
}

$superAuth = $authResults | Where-Object { $_.identity_role -eq "super_admin" } | Select-Object -First 1
if (-not $superAuth -or -not $superAuth.auth_ok) {
  $authResults | ConvertTo-Json -Depth 5
  throw "Super admin auth failed; cannot verify admin_users seed row."
}

$adminHeaders = @{
  apikey        = $SupabaseAnonKey
  Authorization = "Bearer $((Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $SuperAdminEmail -Passphrase $superAdminPassphrase).access_token)"
}

$adminRows = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/admin_users?select=id,email,role,is_active,auth_user_id&auth_user_id=eq.$($superAuth.auth_user_id)" -Headers $adminHeaders

$adminRow = if ($adminRows.Count -gt 0) { $adminRows[0] } else { $null }

$result = [PSCustomObject]@{
  super_admin_email   = $SuperAdminEmail
  super_admin_auth_ok = $superAuth.auth_ok
  expected_role       = $ExpectedRole
  admin_row_found     = ($null -ne $adminRow)
  admin_row           = $adminRow
  identities          = $authResults
}

$result | ConvertTo-Json -Depth 8

if ($null -eq $adminRow) {
  throw "admin_users row missing for super admin auth_user_id=$($superAuth.auth_user_id)"
}
if ($adminRow.role -ne $ExpectedRole) {
  throw "admin_users role mismatch. expected=$ExpectedRole actual=$($adminRow.role)"
}
if (-not $adminRow.is_active) {
  throw "admin_users row is inactive for $SuperAdminEmail"
}

exit 0
