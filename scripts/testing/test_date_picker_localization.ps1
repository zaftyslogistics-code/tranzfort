# TODO-27 Test: P0.1.5.6-1.5.7 - Date Picker Localization Testing
# Tests that the date picker displays in Hindi when device language is set to Hindi

param(
    [switch]$AutoRevert
)

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
Write-LogMessage "TODO-27 Test: P0.1.5.6-1.5.7 - Date Picker Localization"
Write-LogMessage "=========================================="
Write-LogMessage ""

Write-LogMessage "PRE-REQUISITES:"
Write-LogMessage "- Device connected: $DeviceId"
Write-LogMessage "- Test credentials: $TestEmail / $TestPassword"
Write-LogMessage "- TranZfort app installed"
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

# Save current language
Write-LogMessage "Step 2: Saving current device language..."
$CurrentLanguage = adb -s $DeviceId shell settings get global system_locales
Write-LogMessage "Current language: $CurrentLanguage"
Write-LogMessage ""

# Change language to Hindi
Write-LogMessage "Step 3: Changing device language to Hindi (hi-IN)..."
adb -s $DeviceId shell settings put global system_locales "hi-IN"
adb -s $DeviceId shell settings put global system_locales "hi-IN"
Write-LogMessage "✅ Language changed to Hindi"
Write-LogMessage ""

# Stop app
Write-LogMessage "Step 4: Stopping TranZfort app..."
adb -s $DeviceId shell am force-stop com.tranzfort.app
Write-LogMessage "✅ App stopped"
Write-LogMessage ""

# Manual testing instructions
Write-LogMessage "=========================================="
Write-LogMessage "MANUAL TESTING INSTRUCTIONS"
Write-LogMessage "=========================================="
Write-LogMessage ""
Write-LogMessage "Step 5: Launch TranZfort app manually on device"
Write-LogMessage "Step 6: Login with test credentials:"
Write-LogMessage "  - Email: $TestEmail"
Write-LogMessage "  - Password: $TestPassword"
Write-LogMessage ""
Write-LogMessage "Step 7: Navigate to Post Load screen"
Write-LogMessage "Step 8: Tap on 'Pickup Date' field to open date picker"
Write-LogMessage ""
Write-LogMessage "Step 9: Verify the following:"
Write-LogMessage "  [ ] Date picker dialog title is in Hindi"
Write-LogMessage "  [ ] Days of week are in Hindi (e.g., सोम, मंगल, बुध)"
Write-LogMessage "  [ ] Month names are in Hindi (e.g., जनवरी, फरवरी)"
Write-LogMessage "  [ ] Year selector shows Hindi numerals or format"
Write-LogMessage "  [ ] Confirm/Cancel buttons are in Hindi"
Write-LogMessage ""
Write-LogMessage "Step 10: Select a date and confirm"
Write-LogMessage "  [ ] Selected date displays in Hindi format on the form"
Write-LogMessage ""
Write-LogMessage "Step 11: Test with English locale for comparison (optional)"
Write-LogMessage "  [ ] Change language to English (en-US)"
Write-LogMessage "  [ ] Restart app"
Write-LogMessage "  [ ] Open date picker again"
Write-LogMessage "  [ ] Verify date picker shows in English"
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

# Revert language if requested or if failed
if ($AutoRevert -or $Result -eq "FAIL") {
    Write-LogMessage "Step 12: Reverting device language to original..."
    adb -s $DeviceId shell settings put global system_locales "$CurrentLanguage"
    adb -s $DeviceId shell settings put global system_locales "$CurrentLanguage"
    Write-LogMessage "✅ Language reverted to: $CurrentLanguage"
    Write-LogMessage ""
    
    Write-LogMessage "Step 13: Stopping app to apply language change..."
    adb -s $DeviceId shell am force-stop com.tranzfort.app
    Write-LogMessage "✅ App stopped"
}

Write-LogMessage "=========================================="
Write-LogMessage "TEST COMPLETE"
Write-LogMessage "=========================================="
Write-LogMessage "Result: $Result"
Write-LogMessage ""

if ($Result -eq "PASS") {
    Write-LogMessage "✅ Test PASSED - Update TODO-27-april.md to mark P0.1.5.6-1.5.7 as PASSED"
    exit 0
} else {
    Write-LogMessage "❌ Test FAILED - Update TODO-27-april.md to mark P0.1.5.6-1.5.7 as FAILED with notes"
    exit 1
}
