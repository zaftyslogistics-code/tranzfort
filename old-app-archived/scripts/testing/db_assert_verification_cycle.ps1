param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$TruckerEmail = "trucker@example.com",
  [string]$SupplierEmail = "supplier@example.com"
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
$headers = @{ apikey = $SupabaseAnonKey }

$truckerAuth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $TruckerEmail -Passphrase $passphrase
$supplierAuth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $SupplierEmail -Passphrase $passphrase

$truckerProfile = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/profiles?select=id,user_role_type,verification_status,verification_rejection_reason,aadhaar_front_photo_url,aadhaar_back_photo_url,pan_photo_url,avatar_url&id=eq.$($truckerAuth.user.id)" -Headers (@{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($truckerAuth.access_token)" })
$truckerDocs = $truckerProfile[0]

$supplierProfile = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/profiles?select=id,user_role_type,verification_status,verification_rejection_reason,aadhaar_front_photo_url,aadhaar_back_photo_url,pan_photo_url,avatar_url&id=eq.$($supplierAuth.user.id)" -Headers (@{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($supplierAuth.access_token)" })
$supplierDocs = $supplierProfile[0]

$missingInvariants = @()
if ($truckerDocs.user_role_type -ne 'trucker') {
  $missingInvariants += "Trucker profile role mismatch: $($truckerDocs.user_role_type)"
}
if ($supplierDocs.user_role_type -ne 'supplier') {
  $missingInvariants += "Supplier profile role mismatch: $($supplierDocs.user_role_type)"
}

$status = if ($missingInvariants.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  checked_ids = @($truckerAuth.user.id, $supplierAuth.user.id)
  trucker_profile = $truckerDocs
  supplier_profile = $supplierDocs
  missing_invariants = $missingInvariants
  suggested_next_action = if ($missingInvariants.Count -eq 0) { 'No action required.' } else { 'Fix profile role/verification rows for seeded identities and re-run.' }
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Verification cycle assertion failed: $($missingInvariants -join '; ')"
}

exit 0
