param(
  [string]$DeviceId = "89P7MZVWV4Z9C6GE",
  [switch]$SkipPreflight,
  [switch]$SkipDbAssertions,
  [switch]$RunLiveAuthProbes,
  [switch]$RunP1TruckerBaseline,
  [switch]$RunP2SupplierBaseline,
  [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logRoot = Join-Path $root "logs\almost-manual\$timestamp"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

$failedSteps = New-Object System.Collections.Generic.List[string]

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory
  )

  $safeName = ($Name -replace "[^a-zA-Z0-9_-]", "_")
  $logFile = Join-Path $logRoot ("$safeName.log")

  Write-Host "`n=== $Name ===" -ForegroundColor Cyan
  Write-Host "cwd: $WorkingDirectory"
  Write-Host "cmd: $Command"

  Push-Location $WorkingDirectory
  try {
    & pwsh -NoProfile -Command $Command 2>&1 | Tee-Object -FilePath $logFile
    if ($LASTEXITCODE -ne 0) {
      throw "Step failed with exit code $LASTEXITCODE"
    }
    Write-Host "PASS: $Name" -ForegroundColor Green
  } catch {
    Write-Host "FAIL: $Name :: $($_.Exception.Message)" -ForegroundColor Red
    $script:failedSteps.Add($Name) | Out-Null
    if (-not $ContinueOnError) {
      throw
    }
  } finally {
    Pop-Location
  }
}

Write-Host "Logs: $logRoot" -ForegroundColor Yellow

try {
  if (-not $SkipPreflight) {
    Invoke-Step -Name "tranZfort_analyze" -Command "flutter analyze --no-fatal-infos" -WorkingDirectory (Join-Path $root "TranZfort")
    Invoke-Step -Name "admin_analyze" -Command "flutter analyze --no-fatal-infos" -WorkingDirectory (Join-Path $root "Admin")
    Invoke-Step -Name "tranZfort_unit_tests" -Command "flutter test" -WorkingDirectory (Join-Path $root "TranZfort")
    Invoke-Step -Name "admin_unit_tests" -Command "flutter test" -WorkingDirectory (Join-Path $root "Admin")
    Invoke-Step -Name "layer_boundary" -Command "python scripts/check_layer_boundaries.py" -WorkingDirectory $root
    Invoke-Step -Name "supabase_db_lint" -Command "supabase db lint" -WorkingDirectory $root
  }

  Invoke-Step -Name "u_pack_existing_integration" -Command "flutter test integration_test -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "TranZfort")
  Invoke-Step -Name "a_pack_existing_integration" -Command "flutter test integration_test -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "Admin")

  if ($RunLiveAuthProbes) {
    Invoke-Step -Name "u0_live_auth_role_probe" -Command "flutter test integration_test/u0_live_auth_role_probe_integration_test.dart -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "TranZfort")
    Invoke-Step -Name "a0_live_admin_auth_probe" -Command "flutter test integration_test/a0_live_admin_auth_probe_integration_test.dart -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "Admin")
  }

  if ($RunP1TruckerBaseline) {
    Invoke-Step -Name "p1_trucker_permissions_baseline" -Command "flutter test integration_test/p1_trucker_permissions_integration_test.dart -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "TranZfort")
  }

  if ($RunP2SupplierBaseline) {
    Invoke-Step -Name "p2_supplier_baseline" -Command "flutter test integration_test/p2_supplier_baseline_integration_test.dart -d $DeviceId -r expanded" -WorkingDirectory (Join-Path $root "TranZfort")
  }

  if (-not $SkipDbAssertions) {
    Invoke-Step -Name "db_assert_admin_seed" -Command "pwsh -NoProfile -File scripts/testing/db_assert_admin_seed.ps1" -WorkingDirectory $root
    Invoke-Step -Name "db_assert_admin_verification_queue" -Command "pwsh -NoProfile -File scripts/testing/db_assert_admin_verification_queue.ps1" -WorkingDirectory $root
    Invoke-Step -Name "db_assert_admin_verification_mutation_permissions" -Command "pwsh -NoProfile -File scripts/testing/db_assert_admin_verification_mutation_permissions.ps1" -WorkingDirectory $root
    Invoke-Step -Name "db_assert_audit_rows" -Command "pwsh -NoProfile -File scripts/testing/db_assert_audit_rows.ps1" -WorkingDirectory $root
  }
} catch {
  if (-not $ContinueOnError) {
    Write-Host "`nStopped early due to failure." -ForegroundColor Red
  }
}

$summary = [PSCustomObject]@{
  timestamp   = $timestamp
  log_root    = $logRoot
  failedSteps = $failedSteps
  status      = if ($failedSteps.Count -eq 0) { "PASS" } else { "FAIL" }
}

$summary | ConvertTo-Json -Depth 5 | Tee-Object -FilePath (Join-Path $logRoot "summary.json")

if ($failedSteps.Count -gt 0) {
  exit 1
}

exit 0
