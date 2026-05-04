@echo off
REM TranZfort Automated Test Runner
REM Quick launcher for PowerShell test script

echo ========================================
echo TranZfort Automated Test Runner
echo ========================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found in PATH
    echo Please install PowerShell or add it to PATH
    pause
    exit /b 1
)

REM Check if Android device is connected
echo Checking for Android device...
adb devices | findstr "device" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No Android device connected
    echo Please enable USB debugging and connect your device
    echo.
    echo Run 'adb devices' to verify connection
    pause
    exit /b 1
)

echo Android device connected successfully
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0run_automated_android_tests.ps1" %*

REM Check exit code
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo All tests passed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Tests completed with failures
    echo ========================================
    echo.
    echo Run test_fix_helper.ps1 to analyze failures
)

pause
