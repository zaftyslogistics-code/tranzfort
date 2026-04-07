param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$AdminPassword = ""
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

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_ANON_KEY"
}
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
  $AdminPassword = $env:TZ_TEST_PASSCODE
}
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
  throw "Missing admin password. Provide -AdminPassword or set TZ_TEST_PASSCODE."
}
if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure Admin/.env"
}

$authHeaders = @{ apikey = $SupabaseAnonKey; "Content-Type" = "application/json" }
$authBody = @{ email = $AdminEmail; password = $AdminPassword } | ConvertTo-Json
$authResult = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/auth/v1/token?grant_type=password" -Headers $authHeaders -Body $authBody
$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($authResult.access_token)" }

$selectProfile = "id,full_name,mobile,email,user_role_type,verification_status,updated_at"
$statusesPreferred = "pending,submitted,under_review"
$statusesLegacy = "pending"
$enumMode = "preferred"

function Invoke-ProfileQueueQuery {
  param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][hashtable]$Headers,
    [Parameter(Mandatory = $true)][string]$Role,
    [Parameter(Mandatory = $true)][string]$Statuses,
    [Parameter(Mandatory = $true)][string]$SelectProfile
  )

  $queueStatusFilter = "verification_status=in.($Statuses)"
  $uri = "$BaseUrl/rest/v1/profiles?select=$SelectProfile&user_role_type=eq.$Role&$queueStatusFilter&order=updated_at.asc"
  return Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
}

$trucksUri = "$SupabaseUrl/rest/v1/trucks?select=id,owner_id,truck_number,status,created_at&status=eq.pending&order=created_at.asc"

try {
  $supplierRows = Invoke-ProfileQueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Role "supplier" -Statuses $statusesPreferred -SelectProfile $selectProfile
  $truckerRows = Invoke-ProfileQueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Role "trucker" -Statuses $statusesPreferred -SelectProfile $selectProfile
} catch {
  $rawError = $_.ErrorDetails.Message
  if ($rawError -and $rawError -match '22P02' -and $rawError -match 'verification_status') {
    $enumMode = "legacy_pending_only"
    $supplierRows = Invoke-ProfileQueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Role "supplier" -Statuses $statusesLegacy -SelectProfile $selectProfile
    $truckerRows = Invoke-ProfileQueueQuery -BaseUrl $SupabaseUrl -Headers $headers -Role "trucker" -Statuses $statusesLegacy -SelectProfile $selectProfile
  } else {
    throw
  }
}

$truckRows = Invoke-RestMethod -Method Get -Uri $trucksUri -Headers $headers

$result = [PSCustomObject]@{
  admin_email = $AdminEmail
  enum_mode = $enumMode
  supplier_count = @($supplierRows).Count
  trucker_count = @($truckerRows).Count
  truck_count = @($truckRows).Count
  supplier_preview = @($supplierRows) | Select-Object -First 5
  trucker_preview = @($truckerRows) | Select-Object -First 5
  truck_preview = @($truckRows) | Select-Object -First 5
}

$result | ConvertTo-Json -Depth 8
