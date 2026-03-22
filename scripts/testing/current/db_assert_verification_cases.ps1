param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$Passphrase = "",
  [int]$HoursBack = 168,
  [int]$Limit = 200,
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
$uri = "$SupabaseUrl/rest/v1/verification_cases?select=id,subject_type,subject_id,case_status,assigned_admin_user_id,submitted_at,last_reviewed_at,updated_at,current_decision_summary,current_review_feedback_json&updated_at=gte.$sinceIso&order=updated_at.desc&limit=$Limit"
$rows = Normalize-RestRows -Value (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers)

$allowedSubjectTypes = @('supplier_profile', 'trucker_profile', 'truck')
$allowedStatuses = @('submitted', 'queued', 'in_review', 'waiting_for_resubmission', 'approved', 'rejected', 'closed')

$failures = New-Object System.Collections.Generic.List[string]

if ($RequireRows -and $rows.Count -eq 0) {
  $failures.Add('No verification_cases rows found in requested window.') | Out-Null
}

$invalidSubjectTypeRows = @($rows | Where-Object { -not ($allowedSubjectTypes -contains $_.subject_type) })
if ($invalidSubjectTypeRows.Count -gt 0) {
  $failures.Add("Found verification_cases rows with invalid subject_type values: $($invalidSubjectTypeRows.Count)") | Out-Null
}

$invalidStatusRows = @($rows | Where-Object { -not ($allowedStatuses -contains $_.case_status) })
if ($invalidStatusRows.Count -gt 0) {
  $failures.Add("Found verification_cases rows with invalid case_status values: $($invalidStatusRows.Count)") | Out-Null
}

$truckRows = @($rows | Where-Object { $_.subject_type -eq 'truck' })
$profileRows = @($rows | Where-Object { $_.subject_type -ne 'truck' })

$status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  since_utc = $sinceIso
  row_count = $rows.Count
  truck_case_count = $truckRows.Count
  profile_case_count = $profileRows.Count
  subject_type_counts = @($rows | Group-Object -Property subject_type | ForEach-Object { [PSCustomObject]@{ subject_type = $_.Name; count = $_.Count } })
  case_status_counts = @($rows | Group-Object -Property case_status | ForEach-Object { [PSCustomObject]@{ case_status = $_.Name; count = $_.Count } })
  failures = $failures
  sample_rows = @($rows | Select-Object -First 15)
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Verification case assertion failed: $($failures -join '; ')"
}

exit 0
