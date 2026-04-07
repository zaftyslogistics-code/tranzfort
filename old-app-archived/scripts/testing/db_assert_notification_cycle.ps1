param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$UserEmail = "trucker@example.com",
  [int]$HoursBack = 168,
  [int]$Limit = 100,
  [switch]$RequireRows
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
$auth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $UserEmail -Passphrase $passphrase
$sinceIso = (Get-Date).ToUniversalTime().AddHours(-1 * $HoursBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }

$uri = "$SupabaseUrl/rest/v1/notifications?select=id,type,title,body,is_read,created_at&created_at=gte.$sinceIso&order=created_at.desc&limit=$Limit"
$rows = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
$rows = @($rows)

$missingInvariants = @()
if ($RequireRows -and @($rows).Count -eq 0) {
  $missingInvariants += 'No notifications found in requested window for user account.'
}

$missingType = @($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.type) })
if ($missingType.Count -gt 0) {
  $missingInvariants += "Notifications missing type: $($missingType.Count)"
}

$missingTitle = @($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.title) })
if ($missingTitle.Count -gt 0) {
  $missingInvariants += "Notifications missing title: $($missingTitle.Count)"
}

$status = if ($missingInvariants.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  user_email = $UserEmail
  since_utc = $sinceIso
  row_count = @($rows).Count
  checked_ids = @($rows | ForEach-Object { $_.id })
  unread_count = @($rows | Where-Object { -not $_.is_read }).Count
  type_counts = @($rows | Group-Object -Property type | ForEach-Object { [PSCustomObject]@{ type = $_.Name; count = $_.Count } })
  missing_invariants = $missingInvariants
  suggested_next_action = if ($missingInvariants.Count -eq 0) { 'No action required.' } else { 'Trigger load/trip/chat flows that emit notifications and re-run this assertion.' }
  sample_rows = @($rows | Select-Object -First 10)
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Notification cycle assertion failed: $($missingInvariants -join '; ')"
}

exit 0
