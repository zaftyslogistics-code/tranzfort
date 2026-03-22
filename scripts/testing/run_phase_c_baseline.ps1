param(
  [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logRoot = Join-Path $root "logs\phase-c-baseline\$timestamp"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

$failedSteps = New-Object System.Collections.Generic.List[string]

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory
  )

  $safeName = ($Name -replace '[^a-zA-Z0-9_-]', '_')
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
  Invoke-Step -Name 'tranzfort_analyze' -Command 'flutter analyze --no-fatal-infos' -WorkingDirectory (Join-Path $root 'TranZfort')
  Invoke-Step -Name 'tranzfort_tests' -Command 'flutter test' -WorkingDirectory (Join-Path $root 'TranZfort')
  Invoke-Step -Name 'tranzfort_debug_apk' -Command 'flutter build apk --debug' -WorkingDirectory (Join-Path $root 'TranZfort')

  Invoke-Step -Name 'admin_analyze' -Command 'flutter analyze --no-fatal-infos' -WorkingDirectory (Join-Path $root 'Admin')
  Invoke-Step -Name 'admin_tests' -Command 'flutter test' -WorkingDirectory (Join-Path $root 'Admin')
  Invoke-Step -Name 'admin_debug_apk' -Command 'flutter build apk --debug' -WorkingDirectory (Join-Path $root 'Admin')
} catch {
  if (-not $ContinueOnError) {
    Write-Host "`nStopped early due to failure." -ForegroundColor Red
  }
}

$summary = [PSCustomObject]@{
  timestamp = $timestamp
  log_root = $logRoot
  failedSteps = $failedSteps
  status = if ($failedSteps.Count -eq 0) { 'PASS' } else { 'FAIL' }
  tranzfort_apk = Join-Path $root 'TranZfort\build\app\outputs\flutter-apk\app-debug.apk'
  admin_apk = Join-Path $root 'Admin\build\app\outputs\flutter-apk\app-debug.apk'
}

$summary | ConvertTo-Json -Depth 5 | Tee-Object -FilePath (Join-Path $logRoot 'summary.json')

if ($failedSteps.Count -gt 0) {
  exit 1
}

exit 0
