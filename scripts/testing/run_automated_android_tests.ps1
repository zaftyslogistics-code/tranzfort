# TranZfort Automated Android Testing Script
# Runs all tests sequentially on connected Android device
# Uses real credentials from environment variables

param(
    [string]$TestCredentialEmail = $env:TZ_TEST_EMAIL,
    [string]$TestCredentialPassword = $env:TZ_TEST_PASSWORD,
    [switch]$SkipUnitTests = $false,
    [switch]$SkipIntegrationTests = $false,
    [switch]$ContinueOnFailure = $false,
    [string]$OutputDir = "test-results"
)

# Configuration
$ErrorActionPreference = "Stop"
$TranZfortRoot = "C:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ResultsDir = Join-Path $TranZfortRoot $OutputDir
$TestRunDir = Join-Path $ResultsDir "test-run-$Timestamp"
$LogFile = Join-Path $TestRunDir "test-log.txt"
$SummaryFile = Join-Path $TestRunDir "test-summary.json"

# Create results directory
New-Item -ItemType Directory -Force -Path $TestRunDir | Out-Null

# Initialize counters
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$SkippedTests = 0
$TestResults = @()

# Logging function
function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

# Check if Android device is connected
function Test-AndroidDevice {
    Log-Message "Checking for connected Android device..."
    $Devices = adb devices
    if ($Devices -match "device$") {
        Log-Message "Android device connected successfully" "SUCCESS"
        return $true
    } else {
        Log-Message "No Android device connected. Please connect a device and enable USB debugging." "ERROR"
        return $false
    }
}

# Run unit tests
function Invoke-UnitTests {
    Log-Message "=== Starting Unit Tests ===" "INFO"
    
    $UnitTestDirs = @(
        "test\core",
        "test\features\verification",
        "test\features\trucker\providers",
        "test\features\trucker\data",
        "test\reviews",
        "test\profile"
    )
    
    foreach ($Dir in $UnitTestDirs) {
        $TestPath = Join-Path $TranZfortRoot $Dir
        if (Test-Path $TestPath) {
            Log-Message "Running tests in $Dir..." "INFO"
            
            try {
                Push-Location $TranZfortRoot
                $Output = flutter test $Dir --reporter expanded 2>&1
                Pop-Location
                
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "✓ Tests passed in $Dir" "SUCCESS"
                    $PassedTests++
                    $TestResults += @{
                        Type = "Unit"
                        Path = $Dir
                        Status = "PASSED"
                        Duration = 0
                        Output = $Output
                    }
                } else {
                    Log-Message "✗ Tests failed in $Dir" "ERROR"
                    $FailedTests++
                    $TestResults += @{
                        Type = "Unit"
                        Path = $Dir
                        Status = "FAILED"
                        Duration = 0
                        Output = $Output
                    }
                    
                    if (-not $ContinueOnFailure) {
                        throw "Unit tests failed in $Dir. Stopping execution."
                    }
                }
                $TotalTests++
            } catch {
                Log-Message "Error running tests in $Dir: $_" "ERROR"
                $FailedTests++
                $TotalTests++
            }
        } else {
            Log-Message "Directory not found: $Dir" "WARN"
            $SkippedTests++
        }
    }
}

# Run integration tests
function Invoke-IntegrationTests {
    Log-Message "=== Starting Integration Tests ===" "INFO"
    
    $IntegrationTests = @(
        "u_auth_live_test.dart",
        "u_verification_live_test.dart",
        "u_ordered_live_flow_test.dart",
        "trucker_fleet_live_flow_test.dart",
        "avatar_integration_test.dart"
    )
    
    # Set credentials for integration tests
    $env:TZ_SUPPLIER_EMAIL = "testa@example.com"
    $env:TZ_TRUCKER_EMAIL = "testt@example.com"
    $env:TZ_TEST_PASSCODE = "Tabish%%Khan721"
    
    foreach ($TestFile in $IntegrationTests) {
        $TestPath = Join-Path $TranZfortRoot "integration_test\$TestFile"
        if (Test-Path $TestPath) {
            Log-Message "Running integration test: $TestFile..." "INFO"
            
            try {
                $StartTime = Get-Date
                Push-Location $TranZfortRoot
                
                # Run integration test with screenshot capture on failure
                $Output = flutter drive --target=integration_test/$TestFile 2>&1
                $Duration = (Get-Date).Subtract($StartTime).TotalSeconds
                
                Pop-Location
                
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "✓ Integration test passed: $TestFile ($($Duration.ToString('0.00'))s)" "SUCCESS"
                    $PassedTests++
                    $TestResults += @{
                        Type = "Integration"
                        Path = $TestFile
                        Status = "PASSED"
                        Duration = $Duration
                        Output = $Output
                    }
                } else {
                    Log-Message "✗ Integration test failed: $TestFile ($($Duration.ToString('0.00'))s)" "ERROR"
                    $FailedTests++
                    
                    # Capture screenshot on failure
                    $ScreenshotPath = Join-Path $TestRunDir "failure-$($TestFile -replace '\.dart$', '.png')"
                    adb shell screencap -p > $ScreenshotPath
                    Log-Message "Screenshot saved to: $ScreenshotPath" "INFO"
                    
                    $TestResults += @{
                        Type = "Integration"
                        Path = $TestFile
                        Status = "FAILED"
                        Duration = $Duration
                        Output = $Output
                        Screenshot = $ScreenshotPath
                    }
                    
                    if (-not $ContinueOnFailure) {
                        throw "Integration test failed: $TestFile. Stopping execution."
                    }
                }
                $TotalTests++
            } catch {
                Log-Message "Error running integration test $TestFile: $_" "ERROR"
                $FailedTests++
                $TotalTests++
            }
        } else {
            Log-Message "Integration test not found: $TestFile" "WARN"
            $SkippedTests++
        }
    }
}

# Run flutter analyze
function Invoke-FlutterAnalyze {
    Log-Message "=== Running Flutter Analyze ===" "INFO"
    
    try {
        Push-Location $TranZfortRoot
        $Output = flutter analyze 2>&1
        Pop-Location
        
        $ErrorCount = ($Output | Select-String "error •").Count
        
        if ($ErrorCount -eq 0) {
            Log-Message "✓ Flutter analyze passed with 0 errors" "SUCCESS"
            $PassedTests++
            $TestResults += @{
                Type = "Analyze"
                Path = "flutter analyze"
                Status = "PASSED"
                Duration = 0
                Output = $Output
            }
        } else {
            Log-Message "✗ Flutter analyze found $ErrorCount errors" "ERROR"
            $FailedTests++
            $TestResults += @{
                Type = "Analyze"
                Path = "flutter analyze"
                Status = "FAILED"
                Duration = 0
                Output = $Output
            }
        }
        $TotalTests++
    } catch {
        Log-Message "Error running flutter analyze: $_" "ERROR"
        $FailedTests++
        $TotalTests++
    }
}

# Generate test summary
function Invoke-GenerateSummary {
    Log-Message "=== Generating Test Summary ===" "INFO"
    
    $Summary = @{
        Timestamp = $Timestamp
        TotalTests = $TotalTests
        PassedTests = $PassedTests
        FailedTests = $FailedTests
        SkippedTests = $SkippedTests
        PassRate = if ($TotalTests -gt 0) { [math]::Round(($PassedTests / $TotalTests) * 100, 2) } else { 0 }
        TestResults = $TestResults
    }
    
    $Summary | ConvertTo-Json -Depth 10 | Out-File -FilePath $SummaryFile -Encoding UTF8
    
    Log-Message "Test Summary:" "INFO"
    Log-Message "  Total Tests: $TotalTests" "INFO"
    Log-Message "  Passed: $PassedTests" "SUCCESS"
    Log-Message "  Failed: $FailedTests" "ERROR"
    Log-Message "  Skipped: $SkippedTests" "WARN"
    Log-Message "  Pass Rate: $($Summary.PassRate)%" "INFO"
    Log-Message "  Results saved to: $TestRunDir" "INFO"
    
    return $Summary
}

# Main execution
try {
    Log-Message "=== TranZfort Automated Android Test Suite ===" "INFO"
    Log-Message "Test Run: $Timestamp" "INFO"
    Log-Message "Results Directory: $TestRunDir" "INFO"
    Log-Message ""
    
    # Check Android device
    if (-not (Test-AndroidDevice)) {
        Log-Message "Android device check failed. Exiting." "ERROR"
        exit 1
    }
    
    # Run flutter analyze first
    Invoke-FlutterAnalyze
    
    # Run unit tests
    if (-not $SkipUnitTests) {
        Invoke-UnitTests
    } else {
        Log-Message "Skipping unit tests as requested" "WARN"
    }
    
    # Run integration tests
    if (-not $SkipIntegrationTests) {
        Invoke-IntegrationTests
    } else {
        Log-Message "Skipping integration tests as requested" "WARN"
    }
    
    # Generate summary
    $Summary = Invoke-GenerateSummary
    
    # Exit with appropriate code
    if ($Summary.FailedTests -gt 0) {
        Log-Message "Test suite completed with failures" "ERROR"
        exit 1
    } else {
        Log-Message "Test suite completed successfully" "SUCCESS"
        exit 0
    }
    
} catch {
    Log-Message "Fatal error: $_" "ERROR"
    Log-Message "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
