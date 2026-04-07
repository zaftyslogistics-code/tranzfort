param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [int]$HoursBack = 24,
  [int]$Limit = 50,
  [string[]]$RequiredActions = @(),
  [switch]$RequireActions
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

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure Admin/.env"
}

$adminPassphrase = if ($env:TZ_TEST_PASSCODE) { $env:TZ_TEST_PASSCODE } else { "Tabish%%Khan721" }

$authHeaders = @{ apikey = $SupabaseAnonKey; "Content-Type" = "application/json" }
$authBody = @{ email = $AdminEmail; password = $adminPassphrase } | ConvertTo-Json
$auth = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/auth/v1/token?grant_type=password" -Headers $authHeaders -Body $authBody

$sinceIso = (Get-Date).ToUniversalTime().AddHours(-1 * $HoursBack).ToString("yyyy-MM-ddTHH:mm:ssZ")

$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }
$uri = "$SupabaseUrl/rest/v1/audit_logs?select=id,admin_id,action,entity_type,entity_id,created_at&created_at=gte.$sinceIso&order=created_at.desc&limit=$Limit"
$rows = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

$presentActions = @($rows | ForEach-Object { $_.action } | Select-Object -Unique)
$missingActions = @()
if ($RequiredActions.Count -gt 0) {
  foreach ($action in $RequiredActions) {
    if (-not ($presentActions -contains $action)) {
      $missingActions += $action
    }
  }
}

$result = [PSCustomObject]@{
  admin_email      = $AdminEmail
  since_utc        = $sinceIso
  row_count        = @($rows).Count
  present_actions  = $presentActions
  required_actions = $RequiredActions
  missing_actions  = $missingActions
  sample_rows      = @($rows | Select-Object -First 10)
}

$result | ConvertTo-Json -Depth 8

if ($RequireActions -and $missingActions.Count -gt 0) {
  throw "Missing required audit actions: $($missingActions -join ', ')"
}

exit 0
