# TODO-27 Test: P2.14.5.16 - Offline Mutation Queue Testing
# Tests mutation queue with offline booking, then sync on reconnect

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
Write-LogMessage "TODO-27 Test: P2.14.5.16 - Offline Mutation Queue"
Write-LogMessage "=========================================="
Write-LogMessage ""

Write-LogMessage "PRE-REQUISITES:"
Write-LogMessage "- Device connected: $DeviceId"
Write-LogMessage "- Test credentials: $TestEmail / $TestPassword"
Write-LogMessage "- TranZfort app installed"
Write-LogMessage "- Network connection active"
Write-LogMessage "- Supplier account (to post loads)"
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
Write-LogMessage "  [ ] Marketplace loads"
Write-LogMessage ""
Write-LogMessage "Step 5: Enable Airplane Mode (disconnect network)"
Write-LogMessage "  - Run: .\adb_device_control.ps1 -Action toggle_airplane -ToggleAirplane"
Write-LogMessage "  [ ] Airplane mode enabled"
Write-LogMessage ""
Write-LogMessage "Step 6: Navigate to Post Load screen"
Write-LogMessage "  [ ] Post Load screen loads (may show cached data or empty)"
Write-LogMessage ""
Write-LogMessage "Step 7: Fill in a test load (offline):"
Write-LogMessage "  - Origin: Test Origin"
Write-LogMessage "  - Destination: Test Destination"
Write-LogMessage "  - Material: Test Material"
Write-LogMessage "  - Weight: 10 tonnes"
Write-LogMessage "  - Price: 10000 (fixed)"
Write-LogMessage "  - Pickup Date: Tomorrow's date"
Write-LogMessage ""
Write-LogMessage "Step 8: Tap 'Post Load' button"
Write-LogMessage "  [ ] Shows 'Queued' or 'Pending' indicator"
Write-LogMessage "  [ ] Shows offline indicator"
Write-LogMessage "  [ ] Does not crash"
Write-LogMessage "  [ ] Load is added to 'My Loads' with queued status"
Write-LogMessage ""
Write-LogMessage "Step 9: Navigate to My Loads screen"
Write-LogMessage "  [ ] Queued load is visible"
Write-LogMessage "  [ ] Shows 'Queued' or 'Pending' status"
Write-LogMessage "  [ ] Shows offline indicator"
Write-LogMessage ""
Write-LogMessage "Step 10: Post another load offline (optional)"
Write-LogMessage "  [ ] Second load also queues"
Write-LogMessage "  [ ] Both loads show in queue"
Write-LogMessage ""
Write-LogMessage "Step 11: Disable Airplane Mode (reconnect network)"
Write-LogMessage "  - Run: .\adb_device_control.ps1 -Action toggle_airplane"
Write-LogMessage "  [ ] Airplane mode disabled"
Write-LogMessage "  [ ] Network reconnects"
Write-LogMessage ""
Write-LogMessage "Step 12: Wait for sync (give it 5-10 seconds)"
Write-LogMessage "  [ ] Queued loads show 'Syncing...' status"
Write-LogMessage "  [ ] Loads sync to backend"
Write-LogMessage "  [ ] Status changes from 'Queued' to 'Posted' or 'Active'"
Write-LogMessage ""
Write-LogMessage "Step 13: Refresh My Loads screen"
Write-LogMessage "  [ ] Loads are now visible in backend"
Write-LogMessage "  [ ] No longer show 'Queued' status"
Write-LogMessage "  [ ] Show normal load status (e.g., 'Active', 'Open')"
Write-LogMessage ""
Write-LogMessage "Step 14: Check on another device or web (if available)"
Write-LogMessage "  [ ] Posted loads are visible on backend"
Write-LogMessage "  [ ] Data matches what was posted offline"
Write-LogMessage ""
Write-LogMessage "=========================================="
Write-LogMessage "REPORT RESULTS"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "After completing manual testing, report results:"
Write-LogMessage "- If all checks PASS: Test PASSED"
Write-LogMessage "- If any checks FAIL: Test FAILED (note which checks failed)"
Write-LogMessage "- If app crashes or shows errors: Test FAILED"
Write-LogMessage "- If loads don't sync: Test FAILED"
Write-LogMessage ""
Write-LogMessage "Type 'PASS' or 'FAIL' and press Enter to continue:"
$Result = Read-Host
Write-LogMessage "Result: $Result"
Write-LogMessage ""

# Ensure airplane mode is disabled
Write-LogMessage "Step 15: Ensuring airplane mode is disabled..."
adb -s $DeviceId shell settings put global airplane_mode_on 0
Write-LogMessage "✅ Airplane mode disabled"
Write-LogMessage ""

Write-LogMessage "=========================================="
Write-LogMessage "TEST COMPLETE"
Write-LogMessage "=========================================="
Write-LogMessage "Result: $Result"
Write-LogMessage ""

if ($Result -eq "PASS") {
    Write-LogMessage "✅ Test PASSED - Update TODO-27-april.md to mark P2.14.5.16 as PASSED"
    exit 0
} else {
    Write-LogMessage "❌ Test FAILED - Update TODO-27-april.md to mark P2.14.5.16 as FAILED with notes"
    exit 1
}
