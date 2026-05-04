# TODO-27 Test: P2.14.5.15 - Offline Cache Hit/Miss Testing
# Tests cache behavior with network toggle using ADB

param()

$ErrorActionPreference = "Stop"
$DeviceId = "89P7MZVWV4Z9C6GE"
$TestEmail = "testa@example.com"
$TestPassword = "Tabish%%Khan721"

function Write-LogMessage {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor Cyan
}

Write-LogMessage "=========================================="
Write-LogMessage "TODO-27 Test: P2.14.5.15 - Offline Cache Hit/Miss"
Write-LogMessage "=========================================="
Write-LogMessage ""

Write-LogMessage "PRE-REQUISITES:"
Write-LogMessage "- Device connected: $DeviceId"
Write-LogMessage "- Test credentials: $TestEmail / $TestPassword"
Write-LogMessage "- TranZfort app installed"
Write-LogMessage "- Network connection active"
Write-LogMessage ""

# Check device connection
Write-LogMessage "Step 1: Checking device connection..."
$Devices = adb devices
$DeviceConnected = $Devices | Select-String $DeviceId
if (-not $DeviceConnected) {
    Write-LogMessage "❌ Device not connected. Connect device and try again."
    exit 1
}
Write-LogMessage "✅ Device connected"
Write-LogMessage ""

# Manual testing instructions
Write-LogMessage "=========================================="
Write-LogMessage "MANUAL TESTING INSTRUCTIONS"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "Step 2: Launch TranZfort app manually on device"
Write-LogMessage "Step 3: Login with test credentials:"
Write-LogMessage "  - Email: $TestEmail"
Write-LogMessage "  - Password: $TestPassword"
Write-LogMessage ""
Write-LogMessage "Step 4: Navigate to Marketplace"
Write-LogMessage "  [ ] Marketplace loads with network (cache MISS)"
Write-LogMessage "  [ ] Loads are displayed"
Write-LogMessage "  [ ] Note: This is the initial load, data comes from network"
Write-LogMessage ""
Write-LogMessage "Step 5: Enable Airplane Mode (disconnect network)"
Write-LogMessage "  - Run: .\adb_device_control.ps1 -Action toggle_airplane -ToggleAirplane"
Write-LogMessage "  [ ] Airplane mode enabled"
Write-LogMessage ""
Write-LogMessage "Step 6: Navigate away from Marketplace (e.g., to Dashboard)"
Write-LogMessage ""
Write-LogMessage "Step 7: Navigate back to Marketplace"
Write-LogMessage "  [ ] Marketplace loads without network (cache HIT)"
Write-LogMessage "  [ ] Previously loaded data is displayed from cache"
Write-LogMessage "  [ ] No network error shown"
Write-LogMessage "  [ ] Data is not stale (from Step 4)"
Write-LogMessage ""
Write-LogMessage "Step 8: Try to refresh/pull-to-refresh on Marketplace"
Write-LogMessage "  [ ] Shows network error or offline indicator"
Write-LogMessage "  [ ] Does not crash"
Write-LogMessage ""
Write-LogMessage "Step 9: Disable Airplane Mode (reconnect network)"
Write-LogMessage "  - Run: .\adb_device_control.ps1 -Action toggle_airplane"
Write-LogMessage "  [ ] Airplane mode disabled"
Write-LogMessage "  [ ] Network reconnects"
Write-LogMessage ""
Write-LogMessage "Step 10: Refresh Marketplace"
Write-LogMessage "  [ ] Marketplace loads fresh data from network"
Write-LogMessage "  [ ] New data is displayed"
Write-LogMessage "  [ ] Cache is updated"
Write-LogMessage ""
Write-LogMessage "=========================================="
Write-LogMessage "REPORT RESULTS"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "After completing manual testing, report results:"
Write-LogMessage "- If all checks PASS: Test PASSED"
Write-LogMessage "- If any checks FAIL: Test FAILED (note which checks failed)"
Write-LogMessage "- If app crashes or shows errors: Test FAILED"
Write-LogMessage ""
Write-LogMessage "Type 'PASS' or 'FAIL' and press Enter to continue:"
$Result = Read-Host
Write-LogMessage "Result: $Result"
Write-LogMessage ""

# Ensure airplane mode is disabled
Write-LogMessage "Step 11: Ensuring airplane mode is disabled..."
adb -s $DeviceId shell settings put global airplane_mode_on 0
Write-LogMessage "✅ Airplane mode disabled"
Write-LogMessage ""

Write-LogMessage "=========================================="
Write-LogMessage "TEST COMPLETE"
Write-LogMessage "=========================================="
Write-LogMessage "Result: $Result"
Write-LogMessage ""

if ($Result -eq "PASS") {
    Write-LogMessage "✅ Test PASSED - Update TODO-27-april.md to mark P2.14.5.15 as PASSED"
    exit 0
} else {
    Write-LogMessage "❌ Test FAILED - Update TODO-27-april.md to mark P2.14.5.15 as FAILED with notes"
    exit 1
}
