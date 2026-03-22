param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$SupplierEmail = "supplier@example.com",
  [string]$TruckerEmail = "trucker@example.com",
  [string]$Passphrase = ""
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

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path

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
if ([string]::IsNullOrWhiteSpace($Passphrase)) {
  $Passphrase = $env:TZ_TEST_PASSCODE
}

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  throw "SUPABASE_URL/SUPABASE_ANON_KEY not found. Pass params or configure TranZfort/.env or Admin/.env"
}
if ([string]::IsNullOrWhiteSpace($Passphrase)) {
  throw "Missing test password. Pass -Passphrase or set TZ_TEST_PASSCODE."
}

$identities = @(
  @{ role = "admin"; email = $AdminEmail; expectedRole = $null },
  @{ role = "supplier"; email = $SupplierEmail; expectedRole = "supplier" },
  @{ role = "trucker"; email = $TruckerEmail; expectedRole = "trucker" }
)

$results = @()
$failures = New-Object System.Collections.Generic.List[string]

foreach ($identity in $identities) {
  try {
    $auth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $identity.email -Password $Passphrase
    $result = [ordered]@{
      role = $identity.role
      email = $identity.email
      auth_ok = $true
      auth_user_id = $auth.user.id
      profile_role = $null
      admin_row_found = $false
      error = $null
    }

    if ($identity.role -eq "admin") {
      $headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }
      $rows = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/admin_users?select=id,auth_user_id,email,role,is_active&auth_user_id=eq.$($auth.user.id)" -Headers $headers
      $row = @($rows) | Select-Object -First 1
      if ($null -eq $row) {
        $failures.Add("Admin auth succeeded but no admin_users row matched auth_user_id=$($auth.user.id)") | Out-Null
      } else {
        $result.admin_row_found = $true
        $result.admin_role = $row.role
        $result.admin_is_active = $row.is_active
        if ($row.role -ne 'super_admin' -and $row.role -ne 'ops_admin') {
          $failures.Add("Admin row has unexpected role '$($row.role)' for $($identity.email)") | Out-Null
        }
        if (-not $row.is_active) {
          $failures.Add("Admin row is inactive for $($identity.email)") | Out-Null
        }
      }
    } else {
      $headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }
      $rows = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/profiles?select=id,user_role_type,verification_status,full_name,email&id=eq.$($auth.user.id)" -Headers $headers
      $row = @($rows) | Select-Object -First 1
      if ($null -eq $row) {
        $failures.Add("No profile row found for $($identity.role) auth_user_id=$($auth.user.id)") | Out-Null
      } else {
        $result.profile_role = $row.user_role_type
        $result.verification_status = $row.verification_status
        if ($row.user_role_type -ne $identity.expectedRole) {
          $failures.Add("Expected profile role '$($identity.expectedRole)' for $($identity.email) but found '$($row.user_role_type)'") | Out-Null
        }
      }
    }

    $results += [PSCustomObject]$result
  } catch {
    $results += [PSCustomObject]@{
      role = $identity.role
      email = $identity.email
      auth_ok = $false
      auth_user_id = $null
      profile_role = $null
      admin_row_found = $false
      error = $_.Exception.Message
    }
    $failures.Add("Auth failed for $($identity.email): $($_.Exception.Message)") | Out-Null
  }
}

$status = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$result = [PSCustomObject]@{
  status = $status
  checked_emails = @($identities | ForEach-Object { $_.email })
  identities = $results
  failures = $failures
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Auth identity assertion failed: $($failures -join '; ')"
}

exit 0
