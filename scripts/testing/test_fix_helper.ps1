# TranZfort Test Fix Helper
# Helps analyze test failures and generate fix suggestions

param(
    [string]$TestResultsDir,
    [switch]$AutoFix = $false
)

$ErrorActionPreference = "Stop"

# Common error patterns and their fixes
$ErrorPatterns = @{
    "column.*does not exist" = @{
        Description = "SQL column reference error"
        Fix = "Check migration files for correct column names. Verify table schema in supabase/migrations/"
        Priority = "HIGH"
    }
    "undefined.*AppLocalizations" = @{
        Description = "Missing localization key"
        Fix = "Add missing key to app_en.arb and app_hi.arb, then run flutter gen-l10n"
        Priority = "MEDIUM"
    }
    "type.*is not a subtype" = @{
        Description = "Type mismatch error"
        Fix = "Check model fromMap/toMap methods. Verify RPC response structure matches expected types."
        Priority = "HIGH"
    }
    "NoSuchMethodError" = @{
        Description = "Method not found"
        Fix = "Check if method signature changed. Update test mocks to match new interface."
        Priority = "HIGH"
    }
    "Null check operator used on a null value" = @{
        Description = "Null safety error"
        Fix = "Add null checks or use nullable types. Use readDoubleNullable instead of readDouble for numbers."
        Priority = "MEDIUM"
    }
    "The getter.*is not defined" = @{
        Description = "Missing property"
        Fix = "Add missing property to model or DTO. Check if field was renamed in migration."
        Priority = "HIGH"
    }
    "Network request failed" = @{
        Description = "Network error"
        Fix = "Check Supabase URL and keys. Verify network connectivity. Check if RPC exists in database."
        Priority = "CRITICAL"
    }
}

function Get-TestFailureAnalysis {
    param([string]$Output)
    
    $Analysis = @{
        Errors = @()
        Suggestions = @()
    }
    
    foreach ($Pattern in $ErrorPatterns.Keys) {
        if ($Output -match $Pattern) {
            $Analysis.Errors += $ErrorPatterns[$Pattern].Description
            $Analysis.Suggestions += $ErrorPatterns[$Pattern].Fix
        }
    }
    
    return $Analysis
}

function New-FixReport {
    param([string]$ResultsDir)
    
    $SummaryFile = Join-Path $ResultsDir "test-summary.json"
    if (-not (Test-Path $SummaryFile)) {
        Write-Error "Test summary not found: $SummaryFile"
        return
    }
    
    $Summary = Get-Content $SummaryFile | ConvertFrom-Json
    $FixReport = @()
    
    foreach ($Result in $Summary.TestResults) {
        if ($Result.Status -eq "FAILED") {
            $Analysis = Get-TestFailureAnalysis -Output $Result.Output
            $FixReport += [PSCustomObject]@{
                Test = $Result.Path
                Type = $Result.Type
                Errors = $Analysis.Errors -join ", "
                Suggestions = $Analysis.Suggestions -join "`n"
                Priority = if ($Analysis.Errors.Count -gt 0) { "HIGH" } else { "MEDIUM" }
            }
        }
    }
    
    $ReportPath = Join-Path $ResultsDir "fix-report.md"
    $ReportContent = "# Test Fix Report`n`n"
    $ReportContent += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    $ReportContent += "## Failed Tests`n`n"
    
    foreach ($Item in $FixReport | Sort-Object -Property Priority -Descending) {
        $ReportContent += "### $($Item.Test) [$($Item.Type)]`n`n"
        $ReportContent += "**Priority:** $($Item.Priority)`n`n"
        $ReportContent += "**Errors:** $($Item.Errors)`n`n"
        $ReportContent += "**Suggestions:**`n`n"
        $ReportContent += "$($Item.Suggestions)`n`n"
        $ReportContent += "---`n`n"
    }
    
    $ReportContent | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Fix report generated: $ReportPath"
    
    return $FixReport
}

function Set-AutoFixes {
    param([string]$ResultsDir)
    
    Write-Host "Auto-fix mode not implemented yet. Manual review required." -ForegroundColor Yellow
    Write-Host "Please review the fix report and apply fixes manually."
}

# Main execution
if (-not $TestResultsDir) {
    # Find most recent test results
    $BaseDir = "C:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort\test-results"
    if (Test-Path $BaseDir) {
        $Latest = Get-ChildItem $BaseDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $TestResultsDir = $Latest.FullName
    } else {
        Write-Error "No test results directory found. Please specify TestResultsDir parameter."
        exit 1
    }
}

Write-Host "Analyzing test results from: $TestResultsDir"
$FixReport = New-FixReport -ResultsDir $TestResultsDir

if ($AutoFix) {
    Set-AutoFixes -ResultsDir $TestResultsDir
}

Write-Host "`nFix analysis complete."
