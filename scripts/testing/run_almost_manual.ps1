param(
  [string]$DeviceId = '89P7MZVWV4Z9C6GE',
  [ValidateSet('full', 'admin', 'supplier', 'trucker', 'cross-role')]
  [string]$Mode = 'full',
  [switch]$SkipPreflight,
  [switch]$BuildAndInstall,
  [switch]$CaptureLogcat,
  [switch]$PromptForAdminPassword,
  [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logRoot = Join-Path $root "logs\almost-manual\$timestamp"
$summaryDir = Join-Path $logRoot 'summary'
$preflightDir = Join-Path $logRoot 'preflight'
$adminDir = Join-Path $logRoot 'admin'
$supplierDir = Join-Path $logRoot 'supplier'
$truckerDir = Join-Path $logRoot 'trucker'
$crossRoleDir = Join-Path $logRoot 'cross-role'

$dirs = @($logRoot, $summaryDir, $preflightDir, $adminDir, $supplierDir, $truckerDir, $crossRoleDir)
foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$failedSteps = New-Object System.Collections.Generic.List[string]
$completedSteps = New-Object System.Collections.Generic.List[string]
$logcatProcesses = New-Object System.Collections.Generic.List[object]

$adminPackage = 'com.tranzfort.admin'
$userPackage = 'com.tranzfort.app'
$adminApk = Join-Path $root 'Admin\build\app\outputs\flutter-apk\app-debug.apk'
$userApk = Join-Path $root 'TranZfort\build\app\outputs\flutter-apk\app-debug.apk'

function Add-StepResult {
  param(
    [string]$Name,
    [bool]$Succeeded
  )

  if ($Succeeded) {
    $script:completedSteps.Add($Name) | Out-Null
  } else {
    $script:failedSteps.Add($Name) | Out-Null
  }
}

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string]$LogDirectory
  )

  $safeName = ($Name -replace '[^a-zA-Z0-9_-]', '_')
  $logFile = Join-Path $LogDirectory ("$safeName.log")

  Write-Host "`n=== $Name ===" -ForegroundColor Cyan
  Write-Host "cwd: $WorkingDirectory"
  Write-Host "cmd: $Command"

  Push-Location $WorkingDirectory
  try {
    & pwsh -NoProfile -Command $Command 2>&1 | Tee-Object -FilePath $logFile
    if ($LASTEXITCODE -ne 0) {
      throw "Step failed with exit code $LASTEXITCODE"
    }
    Add-StepResult -Name $Name -Succeeded $true
    Write-Host "PASS: $Name" -ForegroundColor Green
  } catch {
    Add-StepResult -Name $Name -Succeeded $false
    Write-Host "FAIL: $Name :: $($_.Exception.Message)" -ForegroundColor Red
    if (-not $ContinueOnError) {
      throw
    }
  } finally {
    Pop-Location
  }
}

function Write-TextArtifact {
  param(
    [string]$Path,
    [string]$Content
  )

  Set-Content -Path $Path -Value $Content -Encoding UTF8
}

function Start-LogcatCapture {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$LogDirectory
  )

  $safeLabel = ($Label -replace '[^a-zA-Z0-9_-]', '_')
  $outputPath = Join-Path $LogDirectory ("$safeLabel-logcat.log")
  $errorPath = Join-Path $LogDirectory ("$safeLabel-logcat.err.log")
  $command = "adb -s $DeviceId logcat"
  $process = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-Command', $command) -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath -PassThru
  $script:logcatProcesses.Add($process) | Out-Null
  return $outputPath
}

function Stop-LogcatCapture {
  foreach ($process in $script:logcatProcesses) {
    try {
      if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
      }
    } catch {}
  }
}

function Write-ManualChecklist {
  param(
    [Parameter(Mandatory = $true)][string]$ModeName,
    [Parameter(Mandatory = $true)][string]$DirectoryPath
  )

  $content = switch ($ModeName) {
    'admin' {
@"
# Admin manual checklist

- Sign in with the approved admin account.
- Run `pwsh -NoProfile -File scripts/verify_admin_access_row.ps1 -Email zaftyslogistics@gmail.com` with service-role env configured and save the output.
- Verify dashboard metrics, especially pending verifications.
- Open verification queue.
- Switch supplier, trucker, and truck tabs.
- Open supplier, trucker, and truck verification details where available.
- Validate uploaded/missing document rows and structured feedback truth.
- Verify approve path.
- Verify reject path with explicit reason / structured document feedback when safe for the target live case.
- Verify status sync back into supplier and trucker apps after review decisions.
- Open users, support, operational cases, Super Ops, load management, and audit logs.
- Record every mismatch in the failure table format from docs/almost-manual-testing.md.
"@
    }
    'supplier' {
@"
# Supplier manual checklist

- Launch the user app and sign in with the supplier identity.
- Validate auth, onboarding continuation, and dashboard landing.
- Open verification and confirm packet state, document state, editable fields, blocked states, and submission truth.
- Submit supplier verification with real data and sample `/rro` documents when the account is not already in a submitted/reviewed state.
- If the supplier account is already rejected, validate rejection summary, next step, editable packet details, and resubmit flow.
- Open Post Load and walk the full stepper.
- Submit or validate blockers honestly.
- Check My Loads and load detail.
- Check booking review, trips, support, notifications, messages, account, settings, and delete-account surfaces.
- Record every mismatch in the failure table format from docs/almost-manual-testing.md.
"@
    }
    'trucker' {
@"
# Trucker manual checklist

- Launch the user app and sign in with Google.
- Choose the Google account mapped to profile id 7aa7562b-c9fc-42f9-b7dc-0f9c1429c8cb.
- Validate onboarding continuation and dashboard landing.
- Open verification and validate identity packet fields, document state, blocked submit guidance, and submit/resubmit truth.
- Open fleet and validate truck packet creation, RC upload, verification-return guidance, and truck review state truth.
- If trucker verification is already rejected, validate rejection summary, next step, editable packet details, truck packet state, and resubmit flow.
- Open Find Loads, load detail, booking, trips, proof upload, support, notifications, messages, account, settings, and delete-account surfaces.
- Record every mismatch in the failure table format from docs/almost-manual-testing.md.
"@
    }
    'cross-role' {
@"
# Cross-role manual checklist

- Confirm trucker and supplier verification status sync after admin approve/reject decisions.
- Confirm truck packet review state aligns between user app and admin verification detail.
- Confirm supplier-posted load discoverability from trucker flow.
- Confirm booking/interest visibility on supplier side.
- Confirm trip assignment state is reflected on trucker side.
- Confirm notifications and chat align with the same business object.
- Confirm admin can inspect related data truthfully where applicable.
"@
    }
    default {
@"
# Full manual checklist

Run the detailed plan in docs/almost-manual-testing.md in this order:

1. Trucker walkthrough
2. Supplier walkthrough
3. Admin verification/review walkthrough
4. Cross-role checks
5. Aggregate follow-through and evidence summary
"@
    }
  }

  Write-TextArtifact -Path (Join-Path $DirectoryPath 'manual-checklist.md') -Content $content
}

Write-Host "Logs: $logRoot" -ForegroundColor Yellow

$adminPasswordSource = 'not_requested'
if ($PromptForAdminPassword) {
  $securePassword = Read-Host 'Enter admin password for live test session' -AsSecureString
  if ($null -ne $securePassword) {
    $adminPasswordSource = 'prompted_secure_string'
  }
}

$sessionManifest = [PSCustomObject]@{
  timestamp = $timestamp
  mode = $Mode
  device_id = $DeviceId
  docs = @{
    master_plan = 'docs/almost-manual-testing.md'
  }
  apps = @{
    admin = @{
      cwd = 'Admin'
      package = $adminPackage
      apk = $adminApk
      email = 'zaftyslogistics@gmail.com'
      password_source = $adminPasswordSource
    }
    supplier = @{
      cwd = 'TranZfort'
      package = $userPackage
      identity = 'coolandwildsome@gmail.com'
      auth_mode = 'manual_live_sign_in'
    }
    trucker = @{
      cwd = 'TranZfort'
      package = $userPackage
      auth_mode = 'manual_google_sign_in'
      expected_profile_id = '7aa7562b-c9fc-42f9-b7dc-0f9c1429c8cb'
    }
  }
}
$sessionManifest | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $summaryDir 'session-manifest.json') -Encoding UTF8

Write-ManualChecklist -ModeName $Mode -DirectoryPath $summaryDir

try {
  if (-not $SkipPreflight) {
    Invoke-Step -Name 'adb_devices' -Command 'adb devices' -WorkingDirectory $root -LogDirectory $preflightDir
    Invoke-Step -Name 'tranzfort_analyze' -Command 'flutter analyze --no-fatal-infos' -WorkingDirectory (Join-Path $root 'TranZfort') -LogDirectory $preflightDir
    Invoke-Step -Name 'admin_analyze' -Command 'flutter analyze --no-fatal-infos' -WorkingDirectory (Join-Path $root 'Admin') -LogDirectory $preflightDir
    Invoke-Step -Name 'tranzfort_tests' -Command 'flutter test' -WorkingDirectory (Join-Path $root 'TranZfort') -LogDirectory $preflightDir
    Invoke-Step -Name 'admin_tests' -Command 'flutter test' -WorkingDirectory (Join-Path $root 'Admin') -LogDirectory $preflightDir
  }

  Invoke-Step -Name 'adb_logcat_clear' -Command "adb -s $DeviceId logcat -c" -WorkingDirectory $root -LogDirectory $preflightDir

  if ($CaptureLogcat) {
    switch ($Mode) {
      'admin' { [void](Start-LogcatCapture -Label 'admin' -LogDirectory $adminDir) }
      'supplier' { [void](Start-LogcatCapture -Label 'supplier' -LogDirectory $supplierDir) }
      'trucker' { [void](Start-LogcatCapture -Label 'trucker' -LogDirectory $truckerDir) }
      'cross-role' { [void](Start-LogcatCapture -Label 'cross-role' -LogDirectory $crossRoleDir) }
      default {
        [void](Start-LogcatCapture -Label 'admin' -LogDirectory $adminDir)
        [void](Start-LogcatCapture -Label 'supplier' -LogDirectory $supplierDir)
        [void](Start-LogcatCapture -Label 'trucker' -LogDirectory $truckerDir)
      }
    }
  }

  if ($BuildAndInstall) {
    if ($Mode -in @('full', 'admin')) {
      Invoke-Step -Name 'admin_build_debug_apk' -Command 'flutter build apk --debug' -WorkingDirectory (Join-Path $root 'Admin') -LogDirectory $adminDir
      Invoke-Step -Name 'admin_install_apk' -Command "adb -s $DeviceId install -r `"$adminApk`"" -WorkingDirectory $root -LogDirectory $adminDir
    }

    if ($Mode -in @('full', 'supplier', 'trucker', 'cross-role')) {
      Invoke-Step -Name 'tranzfort_build_debug_apk' -Command 'flutter build apk --debug' -WorkingDirectory (Join-Path $root 'TranZfort') -LogDirectory $supplierDir
      Invoke-Step -Name 'tranzfort_install_apk' -Command "adb -s $DeviceId install -r `"$userApk`"" -WorkingDirectory $root -LogDirectory $supplierDir
    }
  }

  if ($Mode -in @('full', 'admin')) {
    Invoke-Step -Name 'admin_force_stop' -Command "adb -s $DeviceId shell am force-stop $adminPackage" -WorkingDirectory $root -LogDirectory $adminDir
    Invoke-Step -Name 'admin_launch' -Command "adb -s $DeviceId shell monkey -p $adminPackage -c android.intent.category.LAUNCHER 1" -WorkingDirectory $root -LogDirectory $adminDir
  }

  if ($Mode -in @('full', 'supplier', 'trucker', 'cross-role')) {
    $userLogDirectory = if ($Mode -eq 'trucker') { $truckerDir } elseif ($Mode -eq 'cross-role') { $crossRoleDir } else { $supplierDir }
    Invoke-Step -Name 'tranzfort_force_stop' -Command "adb -s $DeviceId shell am force-stop $userPackage" -WorkingDirectory $root -LogDirectory $userLogDirectory
    Invoke-Step -Name 'tranzfort_launch' -Command "adb -s $DeviceId shell monkey -p $userPackage -c android.intent.category.LAUNCHER 1" -WorkingDirectory $root -LogDirectory $userLogDirectory
  }

  Invoke-Step -Name 'adb_package_dump' -Command "adb -s $DeviceId shell dumpsys package $adminPackage && adb -s $DeviceId shell dumpsys package $userPackage" -WorkingDirectory $root -LogDirectory $summaryDir

  $nextActions = switch ($Mode) {
    'admin' {
      @(
        'Sign in to Admin using the approved admin account.',
        'Validate dashboard, verification queue/detail, users, support, ops, Super Ops, load management, and audit logs.',
        'Record failures against docs/almost-manual-testing.md.'
      )
    }
    'supplier' {
      @(
        'Sign in to the user app with the supplier identity.',
        'Execute the supplier walkthrough from docs/almost-manual-testing.md.',
        'Record failures and evidence paths.'
      )
    }
    'trucker' {
      @(
        'Use Google sign-in and choose the account mapped to profile id 7aa7562b-c9fc-42f9-b7dc-0f9c1429c8cb.',
        'Execute the trucker walkthrough from docs/almost-manual-testing.md.',
        'Record failures and evidence paths.'
      )
    }
    'cross-role' {
      @(
        'Execute supplier -> trucker -> admin cross-role validation on the same object chain where possible.',
        'Record contradictions between roles immediately.'
      )
    }
    default {
      @(
        'Start with Trucker full walkthrough.',
        'Continue with Supplier full walkthrough.',
        'Continue with Admin verification/review walkthrough.',
        'Finish with cross-role and aggregate follow-through validation.'
      )
    }
  }

  $nextActions | Set-Content -Path (Join-Path $summaryDir 'next-actions.txt') -Encoding UTF8
} catch {
  Add-StepResult -Name 'runner_unhandled_error' -Succeeded $false
  $runnerError = $_.Exception.Message
  Write-TextArtifact -Path (Join-Path $summaryDir 'runner-error.txt') -Content $runnerError
  Write-Host "FAIL: runner_unhandled_error :: $runnerError" -ForegroundColor Red
  if (-not $ContinueOnError) {
    Write-Host "`nStopped early due to failure." -ForegroundColor Red
  }
} finally {
  Stop-LogcatCapture
}

$summary = [PSCustomObject]@{
  timestamp = $timestamp
  mode = $Mode
  device_id = $DeviceId
  log_root = $logRoot
  status = if ($failedSteps.Count -eq 0) { 'PASS' } else { 'FAIL' }
  completed_steps = $completedSteps
  failed_steps = $failedSteps
  runner_error_path = Join-Path $summaryDir 'runner-error.txt'
  docs = @(
    'docs/almost-manual-testing.md'
  )
  scripts = @(
    'scripts/testing/run_almost_manual.ps1',
    'scripts/testing/run_phase_c_baseline.ps1'
  )
}

$summary | ConvertTo-Json -Depth 8 | Tee-Object -FilePath (Join-Path $summaryDir 'summary.json')

if ($failedSteps.Count -gt 0) {
  exit 1
}

exit 0
