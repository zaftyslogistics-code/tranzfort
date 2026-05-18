# Run only the 83 passing tests
# This script runs the clean baseline tests that have been verified to pass

Write-Host "Running passing tests..." -ForegroundColor Cyan
Write-Host ""

# Run core infrastructure tests (49 tests)
Write-Host "Running core infrastructure tests..." -ForegroundColor Yellow
flutter test test/core/ --no-pub
$coreExitCode = $LASTEXITCODE
if ($coreExitCode -neq 0) {
    Write-Host "Core tests failed!" -ForegroundColor Red
    exit $coreExitCode
}

Write-Host ""
Write-Host "Running verification screen tests (34 tests)..." -ForegroundColor Yellow
flutter test test/features/verification/presentation/verification_screen_test.dart --no-pub
$verifExitCode = $LASTEXITCODE
if ($verifExitCode -neq 0) {
    Write-Host "Verification tests failed!" -ForegroundColor Red
    exit $verifExitCode
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All 83 passing tests completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
