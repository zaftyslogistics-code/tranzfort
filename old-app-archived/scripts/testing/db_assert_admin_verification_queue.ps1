param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$ExpectedSupplierUserId = "8410db32-df32-4c35-b1bd-0b20cf8ca350"
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

$passphrase = if ($env:TZ_TEST_PASSCODE) { $env:TZ_TEST_PASSCODE } else { "Tabish%%Khan721" }
$adminAuth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $AdminEmail -Passphrase $passphrase
$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($adminAuth.access_token)" }

$statusesPreferred = "pending,submitted,under_review"
$statusesLegacy = "pending"
$enumMode = "preferred"

function Invoke-QueueQuery {
  param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][hashtable]$Headers,
    [Parameter(Mandatory = $true)][string]$Statuses,
    [Parameter(Mandatory = $true)][string]$Role
  )
  $selectProfile = "id,user_role_type,verification_status,updated_at,full_name,email"
  $uri = "$BaseUrl/rest/v1/profiles?select=$selectProfile&user_role_type=eq.$Role&verification_status=in.($Statuses)&order=updated_at.asc"
  return Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
}

try {
  $supplierRows = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Statuses $statusesPreferred -Role "supplier"
  $truckerRows = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Statuses $statusesPreferred -Role "trucker"
} catch {
  $rawError = $_.ErrorDetails.Message
  if ($rawError -and $rawError -match '22P02' -and $rawError -match 'verification_status') {
    $enumMode = "legacy_pending_only"
    $supplierRows = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Statuses $statusesLegacy -Role "supplier"
    $truckerRows = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Statuses $statusesLegacy -Role "trucker"
  } else {
    throw
  }
}

$missingInvariants = @()
if (@($supplierRows).Count -lt 1) {
  $missingInvariants += "Supplier verification queue is empty for admin query"
}
if ([string]::IsNullOrWhiteSpace($ExpectedSupplierUserId) -eq $false) {
  $matched = @($supplierRows) | Where-Object { "$($_.id)" -eq $ExpectedSupplierUserId }
  if (@($matched).Count -lt 1) {
    $missingInvariants += "Expected supplier user id not found in queue: $ExpectedSupplierUserId"
  }
}

$status = if ($missingInvariants.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  enum_mode = $enumMode
  checked_ids = @($ExpectedSupplierUserId)
  supplier_count = @($supplierRows).Count
  trucker_count = @($truckerRows).Count
  supplier_preview = @($supplierRows) | Select-Object -First 5
  trucker_preview = @($truckerRows) | Select-Object -First 5
  missing_invariants = $missingInvariants
  suggested_next_action = if ($missingInvariants.Count -eq 0) { 'No action required.' } else { 'Verify profile verification_status, admin RLS policies, and enum compatibility for verification_status.' }
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Admin verification queue assertion failed: $($missingInvariants -join '; ')"
}

exit 0
