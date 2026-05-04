# TranZfort Automated Testing Guide

## Overview

This directory contains PowerShell scripts for automated testing on Android devices using real credentials.

## Prerequisites

1. **Android Device Setup**
   - Enable USB Debugging on your Android device
   - Connect device via USB
   - Verify connection: `adb devices`

2. **Flutter Environment**
   - Flutter SDK installed and in PATH
   - Flutter doctor should pass all checks

3. **Test Credentials**
   - Supplier: `testa@example.com` / `Tabish%%Khan721`
   - Trucker: `testt@example.com` / `Tabish%%Khan721`

## Scripts

### 1. run_automated_android_tests.ps1

Main script that runs all tests sequentially on connected Android device.

**Usage:**
```powershell
# Run all tests (unit + integration + analyze)
.\run_automated_android_tests.ps1

# Skip unit tests, run only integration tests
.\run_automated_android_tests.ps1 -SkipUnitTests

# Skip integration tests, run only unit tests
.\run_automated_android_tests.ps1 -SkipIntegrationTests

# Continue on failure (don't stop at first failure)
.\run_automated_android_tests.ps1 -ContinueOnFailure

# Specify custom output directory
.\run_automated_android_tests.ps1 -OutputDir "custom-results"
```

**What it does:**
1. Checks for connected Android device
2. Runs `flutter analyze` (catches compilation errors)
3. Runs unit tests (test/core, test/features/verification, test/features/trucker, etc.)
4. Runs integration tests (u_auth_live_test, u_verification_live_test, etc.)
5. Captures screenshots on test failures
6. Generates JSON summary and text log
7. Saves results to `TranZfort/test-results/test-run-{timestamp}/`

**Output:**
- `test-log.txt` - Detailed execution log
- `test-summary.json` - Structured test results
- `failure-{test-name}.png` - Screenshots of failed tests

### 2. test_fix_helper.ps1

Analyzes test failures and generates fix suggestions.

**Usage:**
```powershell
# Analyze most recent test results
.\test_fix_helper.ps1

# Analyze specific test results directory
.\test_fix_helper.ps1 -TestResultsDir "test-results/test-run-20260502-143022"

# Auto-fix mode (not yet implemented, manual review required)
.\test_fix_helper.ps1 -AutoFix
```

**What it does:**
1. Reads test summary JSON
2. Analyzes failure patterns (SQL errors, type mismatches, null safety, etc.)
3. Generates fix suggestions based on common error patterns
4. Creates `fix-report.md` with prioritized fix recommendations

**Error Patterns Detected:**
- SQL column does not exist
- Missing AppLocalizations keys
- Type mismatches
- Null safety violations
- Network request failures
- Missing properties/methods

## Test Execution Workflow

### Step 1: Connect Android Device
```powershell
adb devices
# Should show your device with "device" status
```

### Step 2: Run Full Test Suite
```powershell
cd C:\Users\marte\Desktop\tranzfort.com-v-1.1\scripts\testing
.\run_automated_android_tests.ps1
```

### Step 3: Review Results
```powershell
# Check the latest test results
cd C:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\test-results
# Open the most recent test-run-{timestamp} directory
# View test-summary.json for overall results
# View test-log.txt for detailed logs
```

### Step 4: Analyze Failures
```powershell
cd C:\Users\marte\Desktop\tranzfort.com-v-1.1\scripts\testing
.\test_fix_helper.ps1
# This will generate fix-report.md with suggestions
```

### Step 5: Fix Issues
Based on the fix-report.md:
1. Review prioritized suggestions
2. Apply fixes to codebase
3. Re-run tests to verify fixes

## Test Categories

### Unit Tests (Fast, No Device Required)
- Core service tests
- Verification provider/repository tests
- Trucker provider/repository tests
- Review and profile tests

### Integration Tests (Slower, Requires Device)
- Auth flow tests (login, logout)
- Verification flow tests
- Load booking flow tests
- Fleet management tests
- Avatar upload tests

### Flutter Analyze (Fastest)
- Catches compilation errors
- Checks for deprecated APIs
- Validates code style

## Common Issues and Solutions

### Issue: "No Android device connected"
**Solution:**
- Enable USB Debugging on device
- Check USB cable connection
- Run `adb devices` to verify
- Accept USB debugging prompt on device

### Issue: "Network request failed"
**Solution:**
- Check Supabase URL in .env file
- Verify network connectivity
- Check if RPC exists in database
- Verify Supabase project is active

### Issue: "column does not exist"
**Solution:**
- Check migration files for correct column names
- Verify table schema in supabase/migrations/
- Run `supabase db push` to apply migrations

### Issue: "Missing AppLocalizations key"
**Solution:**
- Add key to `app_en.arb` and `app_hi.arb`
- Run `flutter gen-l10n`
- Restart app

## Test Results Interpretation

### Pass Rate
- **95%+**: Excellent, ready for release
- **80-94%**: Good, fix critical failures
- **<80%**: Needs attention, fix all failures

### Priority Levels
- **CRITICAL**: Network/auth errors, blocks core functionality
- **HIGH**: SQL errors, type mismatches, null safety
- **MEDIUM**: Localization, deprecated APIs
- **LOW**: Code style, warnings

## Continuous Testing

To run tests after every code change:

```powershell
# Create a simple loop script
while ($true) {
    Write-Host "Running tests at $(Get-Date)"
    .\run_automated_android_tests.ps1
    Start-Sleep -Seconds 300  # Wait 5 minutes
}
```

## Tips for Faster Testing

1. **Skip Integration Tests** during development
   ```powershell
   .\run_automated_android_tests.ps1 -SkipIntegrationTests
   ```

2. **Run Specific Test Directly**
   ```powershell
   flutter test test/features/trucker/providers/find_loads_provider_test.dart
   ```

3. **Use ContinueOnFailure** to see all failures
   ```powershell
   .\run_automated_android_tests.ps1 -ContinueOnFailure
   ```

4. **Run Flutter Analyze Only** (fastest)
   ```powershell
   flutter analyze
   ```

## Next Steps

1. Connect your Android device
2. Run the full test suite
3. Review results and fix-report.md
4. Apply fixes iteratively
5. Re-run tests to verify
6. Repeat until 95%+ pass rate achieved

## Support

For issues with:
- **Test scripts**: Check this README
- **Flutter/ADB**: Check Flutter doctor output
- **Database errors**: Check migration files
- **Network errors**: Check .env configuration

## Test Credentials Reminder

- **Supplier Email**: testa@example.com
- **Trucker Email**: testt@example.com
- **Password**: Tabish%%Khan721

These are hardcoded in the script for integration tests. Change them if needed.
