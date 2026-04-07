param(
  [string]$SupabaseUrl = "",
  [string]$SupabaseAnonKey = "",
  [string]$AdminEmail = "zaftyslogistics@gmail.com",
  [string]$NonAdminEmail = "trucker@example.com",
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
    [Parameter(Mandatory = $true)][SecureString]$Passphrase
  )

  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Passphrase)
  try {
    $plainPassphrase = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }

  $headers = @{ apikey = $AnonKey; "Content-Type" = "application/json" }
  $body = @{ email = $Email; password = $plainPassphrase } | ConvertTo-Json
  return Invoke-RestMethod -Method Post -Uri "$Url/auth/v1/token?grant_type=password" -Headers $headers -Body $body
}

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

$passphrasePlain = if ($env:TZ_TEST_PASSCODE) { $env:TZ_TEST_PASSCODE } else { "Tabish%%Khan721" }
$passphraseSecure = ConvertTo-SecureString $passphrasePlain -AsPlainText -Force
$adminAuth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $AdminEmail -Passphrase $passphraseSecure
$nonAdminAuth = Invoke-PasswordAuth -Url $SupabaseUrl -AnonKey $SupabaseAnonKey -Email $NonAdminEmail -Passphrase $passphraseSecure

$adminHeaders = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($adminAuth.access_token)"; Prefer = "return=representation" }
$nonAdminHeaders = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($nonAdminAuth.access_token)"; Prefer = "return=representation" }

# 6.11 / 6.12 live queue contract checks
$statusesPreferred = "pending,submitted,under_review"
$statusesLegacy = "pending"
$enumMode = "preferred"

try {
  $adminSupplierQueue = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $adminHeaders -Statuses $statusesPreferred -Role "supplier"
  $nonAdminSupplierQueue = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $nonAdminHeaders -Statuses $statusesPreferred -Role "supplier"
} catch {
  $rawError = $_.ErrorDetails.Message
  if ($rawError -and $rawError -match '22P02' -and $rawError -match 'verification_status') {
    $enumMode = "legacy_pending_only"
    $adminSupplierQueue = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $adminHeaders -Statuses $statusesLegacy -Role "supplier"
    $nonAdminSupplierQueue = Invoke-QueueQuery -BaseUrl $SupabaseUrl -Headers $nonAdminHeaders -Statuses $statusesLegacy -Role "supplier"
  } else {
    throw
  }
}

$targetProfileRows = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/profiles?select=id,verification_status&id=eq.$ExpectedSupplierUserId" -Headers $adminHeaders
if (@($targetProfileRows).Count -lt 1) {
  throw "Expected target supplier row not found: $ExpectedSupplierUserId"
}
$targetStatus = "$($targetProfileRows[0].verification_status)"
if ([string]::IsNullOrWhiteSpace($targetStatus)) {
  $targetStatus = "pending"
}

$mutationBody = @{ verification_status = $targetStatus } | ConvertTo-Json
$mutationUri = "$SupabaseUrl/rest/v1/profiles?id=eq.$ExpectedSupplierUserId&select=id,verification_status"

$adminMutationRows = @()
$nonAdminMutationRows = @()
$nonAdminMutationError = $null

$adminMutationRows = Invoke-RestMethod -Method Patch -Uri $mutationUri -Headers $adminHeaders -Body $mutationBody -ContentType "application/json"

try {
  $nonAdminMutationRows = Invoke-RestMethod -Method Patch -Uri $mutationUri -Headers $nonAdminHeaders -Body $mutationBody -ContentType "application/json"
} catch {
  $nonAdminMutationError = $_.Exception.Message
}

$missingInvariants = @()

$adminQueueMatches = @(@($adminSupplierQueue) | Where-Object { "$($_.id)" -eq $ExpectedSupplierUserId })
$adminQueueHasExpected = $adminQueueMatches.Count -ge 1
if (-not $adminQueueHasExpected) {
  $missingInvariants += "6.11 failed: admin supplier queue does not include expected user id"
}

$nonAdminQueueMatches = @(@($nonAdminSupplierQueue) | Where-Object { "$($_.id)" -eq $ExpectedSupplierUserId })
$nonAdminQueueHasExpected = $nonAdminQueueMatches.Count -ge 1
if ($nonAdminQueueHasExpected) {
  $missingInvariants += "6.14 failed: non-admin supplier queue unexpectedly includes expected user id"
}

if (@($adminMutationRows).Count -lt 1) {
  $missingInvariants += "6.13 failed: admin mutation did not return target row"
}

if (@($nonAdminMutationRows).Count -gt 0) {
  $missingInvariants += "6.14 failed: non-admin mutation unexpectedly returned target row"
}

$status = if ($missingInvariants.Count -eq 0) { 'PASS' } else { 'FAIL' }

$result = [PSCustomObject]@{
  status = $status
  enum_mode = $enumMode
  target_user_id = $ExpectedSupplierUserId
  target_status_noop = $targetStatus
  admin_queue_count = @($adminSupplierQueue).Count
  non_admin_queue_count = @($nonAdminSupplierQueue).Count
  admin_mutation_row_count = @($adminMutationRows).Count
  non_admin_mutation_row_count = @($nonAdminMutationRows).Count
  non_admin_mutation_error = $nonAdminMutationError
  missing_invariants = $missingInvariants
  suggested_next_action = if ($missingInvariants.Count -eq 0) { 'No action required.' } else { 'Review profiles/trucks RLS policies and Admin repository queue/mutation contracts.' }
}

$result | ConvertTo-Json -Depth 8
if ($status -ne 'PASS') {
  throw "Admin verification mutation permission assertion failed: $($missingInvariants -join '; ')"
}

exit 0
