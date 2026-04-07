param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$SupplierEmail = "supplier@example.com",
  [int]$HoursBack = 168,
  [int]$Limit = 100
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
  $SupabaseUrl = Get-EnvValue -FilePath (Join-Path $root "TranZfort\.env") -Key "SUPABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Get-EnvValue -FilePath (Join-Path $root "TranZfort\.env") -Key "SUPABASE_ANON_KEY"
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_ANON_KEY"
}
if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure TranZfort/.env or Admin/.env"
}

$passphrase = if ($env:TZ_TEST_PASSCODE) { $env:TZ_TEST_PASSCODE } else { "Tabish%%Khan721" }
$auth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $SupplierEmail -Passphrase $passphrase
$sinceIso = (Get-Date).ToUniversalTime().AddHours(-1 * $HoursBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }

$loadsUri = "$SupabaseUrl/rest/v1/loads?select=id,status,assigned_trucker_id,created_at,updated_at,origin_city,dest_city&created_at=gte.$sinceIso&order=created_at.desc&limit=$Limit"
$loads = Invoke-RestMethod -Method Get -Uri $loadsUri -Headers $headers
$loads = @($loads)

$missingInvariants = @()
$invalidStatus = @($loads | Where-Object { $_.status -notin @('active','pending_approval','booked','in_transit','completed','cancelled','expired') })
if ($invalidStatus.Count -gt 0) {
  $missingInvariants += "Loads with invalid status values: $($invalidStatus.Count)"
}

$status = if ($missingInvariants.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  supplier_email = $SupplierEmail
  since_utc = $sinceIso
  checked_ids = @($loads | ForEach-Object { $_.id })
  row_count = @($loads).Count
  status_counts = @($loads | Group-Object -Property status | ForEach-Object { [PSCustomObject]@{ status = $_.Name; count = $_.Count } })
  missing_invariants = $missingInvariants
  suggested_next_action = if ($missingInvariants.Count -eq 0) { 'No action required.' } else { 'Validate load state transitions for affected IDs and re-run assertion.' }
  sample_rows = @($loads | Select-Object -First 10)
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Marketplace cycle assertion failed: $($missingInvariants -join '; ')"
}

exit 0
