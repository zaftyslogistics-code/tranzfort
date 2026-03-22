param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$Passphrase = "",
  [int]$HoursBack = 24,
  [int]$Limit = 100,
  [string[]]$RequiredActions = @(),
  [switch]$RequireRows,
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

function Invoke-PasswordAuth {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][string]$AnonKey,
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$Password
  )

  $headers = @{ apikey = $AnonKey; "Content-Type" = "application/json" }
  $body = @{ email = $Email; password = $Password } | ConvertTo-Json
  return Invoke-RestMethod -Method Post -Uri "$Url/auth/v1/token?grant_type=password" -Headers $headers -Body $body
}

function Normalize-RestRows {
  param([Parameter(Mandatory = $true)]$Value)

  if ($null -eq $Value) {
    return @()
  }

  if ($Value -is [System.Array]) {
    if ($Value.Length -eq 1 -and $Value[0] -is [System.Array]) {
      return @($Value[0])
    }
    return @($Value)
  }

  return @($Value)
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_URL"
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Get-EnvValue -FilePath (Join-Path $root "Admin\.env") -Key "SUPABASE_ANON_KEY"
}
if ([string]::IsNullOrWhiteSpace($Passphrase)) {
  $Passphrase = $env:TZ_TEST_PASSCODE
}

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure Admin/.env"
}
if ([string]::IsNullOrWhiteSpace($Passphrase)) {
  throw "Missing test password. Pass -Passphrase or set TZ_TEST_PASSCODE."
}

$auth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $AdminEmail -Password $Passphrase
$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }
$sinceIso = (Get-Date).ToUniversalTime().AddHours(-1 * $HoursBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
$uri = "$SupabaseUrl/rest/v1/audit_logs?select=id,actor_admin_user_id,actor_type,actor_role,action_type,target_object_type,target_object_id,secondary_object_type,secondary_object_id,summary_text,created_at&created_at=gte.$sinceIso&order=created_at.desc&limit=$Limit"
$rows = Normalize-RestRows -Value (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers)

$failures = New-Object System.Collections.Generic.List[string]
if ($RequireRows -and $rows.Count -eq 0) {
  $failures.Add('No audit_logs rows found in requested window.') | Out-Null
}

$missingActionTypeRows = @($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.action_type) })
if ($missingActionTypeRows.Count -gt 0) {
  $failures.Add("Found audit_logs rows missing action_type: $($missingActionTypeRows.Count)") | Out-Null
}

$presentActions = @($rows | ForEach-Object { $_.action_type } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
$missingRequiredActions = @()
foreach ($action in $RequiredActions) {
  if (-not ($presentActions -contains $action)) {
    $missingRequiredActions += $action
  }
}
if ($RequireActions -and $missingRequiredActions.Count -gt 0) {
  $failures.Add("Missing required audit actions: $($missingRequiredActions -join ', ')") | Out-Null
}

$status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  since_utc = $sinceIso
  row_count = $rows.Count
  present_actions = $presentActions
  required_actions = $RequiredActions
  missing_required_actions = $missingRequiredActions
  failures = $failures
  sample_rows = @($rows | Select-Object -First 15)
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Audit log assertion failed: $($failures -join '; ')"
}

exit 0
