param(
  [Parameter(Mandatory = $true)][string]$UserId,
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
$auth = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/auth/v1/token?grant_type=password" -Headers $authHeaders -Body $authBody

$headers = @{ apikey = $SupabaseAnonKey; Authorization = "Bearer $($auth.access_token)" }

$profile = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/profiles?select=id,user_role_type,full_name,mobile,email,verification_status,verification_rejection_reason,aadhaar_front_photo_url,aadhaar_back_photo_url,pan_photo_url,updated_at&id=eq.$UserId" -Headers $headers
$supplier = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/suppliers?select=id,company_name,gst_number,gst_photo_url,business_licence_number,business_licence_doc_url&id=eq.$UserId" -Headers $headers
$trucker = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/truckers?select=id,dl_number,dl_front_photo_url,dl_back_photo_url&id=eq.$UserId" -Headers $headers
$trucks = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/trucks?select=id,owner_id,truck_number,status,rejection_reason,rc_photo_url,created_at&owner_id=eq.$UserId" -Headers $headers

$result = [PSCustomObject]@{
  user_id = $UserId
  profile_count = @($profile).Count
  profile = $profile
  supplier_count = @($supplier).Count
  supplier = $supplier
  trucker_count = @($trucker).Count
  trucker = $trucker
  truck_count = @($trucks).Count
  trucks = $trucks
}

$result | ConvertTo-Json -Depth 8
