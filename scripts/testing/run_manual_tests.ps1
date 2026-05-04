# TODO-27 Manual Test Runner
# Runs all pending manual tests in order with step-by-step guidance

param(
    [switch]$SkipLocalization,
    [switch]$SkipTTS,
    [switch]$SkipOffline,
    [switch]$ContinueOnFailure
)

$ErrorActionPreference = "Stop"
$ScriptsDir = "C:\Users\marte\Desktop\tranzfort.com-v-1.1\scripts\testing"

function Write-LogMessage {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor Cyan
}

Write-LogMessage "=========================================="
Write-LogMessage "TODO-27 Manual Test Runner"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "This script will guide you through all TODO-27 tests"
Write-LogMessage "Each test has step-by-step instructions"
Write-LogMessage "You will perform manual steps on the device"
Write-LogMessage ""
Write-LogMessage "Test Credentials:"
Write-LogMessage "  Supplier: testa@example.com / Tabish%%Khan721"
Write-LogMessage "  Trucker: testt@example.com / Tabish%%Khan721"
Write-LogMessage ""
Write-LogMessage "Press Enter to start..."
Read-Host

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

# P0 Tests - Localization
if (-not $SkipLocalization) {
    Write-LogMessage ""
    Write-LogMessage "=========================================="
    Write-LogMessage "P0 Tests: Localization"
    Write-LogMessage "=========================================="
    
    Write-LogMessage ""
    Write-LogMessage "Running test: P0.1.4.6 - Hindi Locale"
    $TotalTests++
    & "$ScriptsDir\test_hindi_locale.ps1" -AutoRevert
    if ($LASTEXITCODE -eq 0) {
        $PassedTests++
        Write-LogMessage "✅ P0.1.4.6 PASSED"
    } else {
        $FailedTests++
        Write-LogMessage "❌ P0.1.4.6 FAILED"
        if (-not $ContinueOnFailure) {
            Write-LogMessage "Stopping due to failure. Use -ContinueOnFailure to continue."
            exit 1
        }
    }
    
    Write-LogMessage ""
    Write-LogMessage "Running test: P0.1.5.6-1.5.7 - Date Picker Localization"
    $TotalTests++
    & "$ScriptsDir\test_date_picker_localization.ps1" -AutoRevert
    if ($LASTEXITCODE -eq 0) {
        $PassedTests++
        Write-LogMessage "✅ P0.1.5.6-1.5.7 PASSED"
    } else {
        $FailedTests++
        Write-LogMessage "❌ P0.1.5.6-1.5.7 FAILED"
        if (-not $ContinueOnFailure) {
            Write-LogMessage "Stopping due to failure. Use -ContinueOnFailure to continue."
            exit 1
        }
    }
}

# P2 Tests - TTS
if (-not $SkipTTS) {
    Write-LogMessage ""
    Write-LogMessage "=========================================="
    Write-LogMessage "P2 Tests: TTS/Accessibility"
    Write-LogMessage "=========================================="
    
    Write-LogMessage ""
    Write-LogMessage "Running test: P2.14.1.8.12 - TTS Voice Settings"
    $TotalTests++
    & "$ScriptsDir\test_tts_voice_settings.ps1"
    if ($LASTEXITCODE -eq 0) {
        $PassedTests++
        Write-LogMessage "✅ P2.14.1.8.12 PASSED"
    } else {
        $FailedTests++
        Write-LogMessage "❌ P2.14.1.8.12 FAILED"
        if (-not $ContinueOnFailure) {
            Write-LogMessage "Stopping due to failure. Use -ContinueOnFailure to continue."
            exit 1
        }
    }
    
    Write-LogMessage ""
    Write-LogMessage "NOTE: Remaining TTS tests require code modification or manual installation"
    Write-LogMessage "These are not included in this script runner:"
    Write-LogMessage "  - 14.1.12.5: Invalid voice ID (requires code modification)"
    Write-LogMessage "  - 14.1.13: Multiple TTS engines (requires manual TTS engine installation)"
    Write-LogMessage "  - 14.1.15: Uninstalled voice (requires manual TTS engine uninstall)"
    Write-LogMessage "  - 14.2.6.8: Priority queue (requires code modification)"
    Write-LogMessage "  - 14.2.7.7: Navigation cancellation (requires code modification)"
    Write-LogMessage "  - 14.2.8: Tap cancellation (feature not implemented)"
    Write-LogMessage "  - 14.2.10: Navigation cancellation (depends on widget integration)"
    Write-LogMessage "  - 14.2.11: Priority ordering (depends on 14.2.6.8)"
    Write-LogMessage ""
    Write-LogMessage "Mark these as DEFERRED in TODO-27-april.md"
}

# P2 Tests - Offline
if (-not $SkipOffline) {
    Write-LogMessage ""
    Write-LogMessage "=========================================="
    Write-LogMessage "P2 Tests: Offline Architecture"
    Write-LogMessage "=========================================="
    
    Write-LogMessage ""
    Write-LogMessage "Running test: P2.14.5.15 - Offline Cache Hit/Miss"
    $TotalTests++
    & "$ScriptsDir\test_offline_cache.ps1"
    if ($LASTEXITCODE -eq 0) {
        $PassedTests++
        Write-LogMessage "✅ P2.14.5.15 PASSED"
    } else {
        $FailedTests++
        Write-LogMessage "❌ P2.14.5.15 FAILED"
        if (-not $ContinueOnFailure) {
            Write-LogMessage "Stopping due to failure. Use -ContinueOnFailure to continue."
            exit 1
        }
    }
    
    Write-LogMessage ""
    Write-LogMessage "Running test: P2.14.5.16 - Offline Mutation Queue"
    $TotalTests++
    & "$ScriptsDir\test_offline_mutation_queue.ps1"
    if ($LASTEXITCODE -eq 0) {
        $PassedTests++
        Write-LogMessage "✅ P2.14.5.16 PASSED"
    } else {
        $FailedTests++
        Write-LogMessage "❌ P2.14.5.16 FAILED"
        if (-not $ContinueOnFailure) {
            Write-LogMessage "Stopping due to failure. Use -ContinueOnFailure to continue."
            exit 1
        }
    }
}

# Summary
Write-LogMessage ""
Write-LogMessage "=========================================="
Write-LogMessage "Test Summary"
Write-LogMessage "=========================================="
Write-LogMessage "Total Tests: $TotalTests"
Write-LogMessage "Passed: $PassedTests"
Write-LogMessage "Failed: $FailedTests"
Write-LogMessage ""

Write-LogMessage "Next Steps:"
Write-LogMessage "1. Update TODO-27-april.md with test results"
Write-LogMessage "2. For failed tests, investigate and fix bugs"
Write-LogMessage "3. Rerun failed tests after fixes"
Write-LogMessage "4. For deferred tests, implement required features"
Write-LogMessage ""

if ($FailedTests -gt 0) {
    Write-LogMessage "❌ Some tests failed. Review failures and fix bugs."
    exit 1
} else {
    Write-LogMessage "✅ All tests passed!"
    exit 0
}
