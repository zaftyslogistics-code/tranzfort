# TODO-27 Test: TTS Voice Settings Screen
# TODO-27 Test: P2.14.1.8.12 - TTS Voice Settings Screen Testing
# Tests the TTS voice settings screen functionality

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
Write-LogMessage "TODO-27 Test: P2.14.1.8.12 - TTS Voice Settings"
Write-LogMessage "=========================================="
Write-LogMessage ""

Write-LogMessage "PRE-REQUISITES:"
Write-LogMessage "- Device connected: $DeviceId"
Write-LogMessage "- Test credentials: $TestEmail / $TestPassword"
Write-LogMessage "- TranZfort app installed"
Write-LogMessage "- TTS engine installed on device"
Write-LogMessage ""

Write-LogMessage ""

# Check device connection
Write-LogMessage "Step 1: Checking device connection..."
$Devices = adb devices
$DeviceConnected = $Devices | Select-String $DeviceId
if (-not $DeviceConnected) {
    Write-LogMessage " Device not connected. Connect device and try again."
    exit 1
}
Write-LogMessage " Device connected"
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
Write-LogMessage "Step 4: Navigate to Settings (gear icon)"
Write-LogMessage "Step 5: Navigate to TTS Voice Settings"
Write-LogMessage ""
Write-LogMessage "Step 6: Verify the following:"
Write-LogMessage "  [ ] Voice settings screen loads without errors"
Write-LogMessage "  [ ] Available voices list is displayed"
Write-LogMessage "  [ ] Currently selected voice is highlighted"
Write-LogMessage "  [ ] Voice names are readable (not cryptic IDs)"
Write-LogMessage "  [ ] Language is shown for each voice"
Write-LogMessage ""
Write-LogMessage "Step 7: Test voice selection:"
Write-LogMessage "  [ ] Tap on a different voice"
Write-LogMessage "  [ ] Voice selection changes"
Write-LogMessage "  [ ] Selection is saved (persisted)"
Write-LogMessage ""
Write-LogMessage "Step 8: Test voice preview (if available):"
Write-LogMessage "  [ ] Tap preview button for a voice"
Write-LogMessage "  [ ] Voice speaks sample text"
Write-LogMessage "  [ ] Audio quality is acceptable"
Write-LogMessage ""
Write-LogMessage "Step 9: Test TTS speed slider (if available):"
Write-LogMessage "  [ ] Adjust speed slider"
Write-LogMessage "  [ ] Speed value updates"
Write-LogMessage "  [ ] Setting is saved"
Write-LogMessage ""
Write-LogMessage "Step 10: Navigate back to main app"
Write-LogMessage "  [ ] Settings are applied"
Write-LogMessage "  [ ] App continues to work normally"
Write-LogMessage ""
Write-LogMessage "Step 11: Test TTS in actual app flow:"
Write-LogMessage "  [ ] Navigate to a screen with TTS (e.g., Dashboard)"
Write-LogMessage "  [ ] Trigger TTS (tap on text or use TTS button)"
Write-LogMessage "  [ ] Selected voice is used"
Write-LogMessage "  [ ] Audio plays correctly"
Write-LogMessage ""
Write-LogMessage "=========================================="
Write-LogMessage "REPORT RESULTS"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "After completing manual testing, report results:"
Write-LogMessage "- If all checks PASS: Test PASSED"
Write-LogMessage "- If any checks FAIL: Test FAILED (note which checks failed)"
Write-LogMessage "- If app crashes or shows errors: Test FAILED"
Write-LogMessage "- If TTS doesn't play: Test FAILED"
Write-LogMessage ""
Write-LogMessage "Type 'PASS' or 'FAIL' and press Enter to continue:"
$Result = Read-Host
Write-LogMessage "Result: $Result"
Write-LogMessage ""

Write-LogMessage "=========================================="
Write-LogMessage "TEST COMPLETE"
Write-LogMessage "=========================================="
Write-LogMessage "Result: $Result"
Write-LogMessage ""

if ($Result -eq "PASS") {
    Write-LogMessage " Test PASSED - Update TODO-27-april.md to mark P2.14.1.8.12 as PASSED"
    exit 0
} else {
    Write-LogMessage " Test FAILED - Update TODO-27-april.md to mark P2.14.1.8.12 as FAILED with notes"
    exit 1
}
