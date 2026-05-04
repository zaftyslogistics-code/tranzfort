# TODO-27 Test: Check TtsScreenSummaryEffect widget integration
# Test 14.2.9.9-14.2.9.12: Add widget to all screen scaffolds

$ErrorActionPreference = "Stop"
$TranZfortRoot = "C:\Users\marte\Desktop\tranzfort.com-v-1.1\TranZfort"
$LogFile = "tts_widget_check_log.txt"

# Screens that should have TtsScreenSummaryEffect
$RequiredScreens = @{
    "trucker_dashboard_screen.dart" = "Trucker Dashboard"
    "trucker_marketplace_screen.dart" = "Trucker Marketplace"
    "trucker_load_detail_screen.dart" = "Trucker Load Detail"
    "trucker_trip_detail_screen.dart" = "Trucker Trip Detail"
    "trucker_fleet_screen.dart" = "Trucker Fleet"
    "trucker_profile_screen.dart" = "Trucker Profile"
    "supplier_dashboard_screen.dart" = "Supplier Dashboard"
    "post_load_screen.dart" = "Supplier Post Load"
    "supplier_load_detail_screen.dart" = "Supplier Load Detail"
    "supplier_trip_detail_screen.dart" = "Supplier Trip Detail"
    "supplier_profile_screen.dart" = "Supplier Profile"
    "notifications_screen.dart" = "Common Notifications"
    "chat_screen.dart" = "Common Chat"
    "settings_screen.dart" = "Common Settings"
}

function Write-LogMessage {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

Write-LogMessage "=== TTS Widget Integration Check ==="
Write-LogMessage "Checking for TtsScreenSummaryEffect in required screens..."

$Results = @()
$MissingScreens = @()

foreach ($ScreenFile in $RequiredScreens.Keys) {
    $ScreenName = $RequiredScreens[$ScreenFile]
    
    # Search in multiple possible locations
    $PossiblePaths = @(
        (Join-Path $TranZfortRoot "lib\src\features\trucker\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\supplier\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\shell\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\notifications\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\chat\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\profile\presentation\$ScreenFile"),
        (Join-Path $TranZfortRoot "lib\src\features\settings\presentation\$ScreenFile")
    )
    
    $FoundPath = $null
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            $FoundPath = $Path
            break
        }
    }
    
    if ($null -eq $FoundPath) {
        Write-LogMessage "❌ File not found: $ScreenFile"
        $MissingScreens += $ScreenName
        $Results += [PSCustomObject]@{
            Screen = $ScreenName
            File = $ScreenFile
            Status = "FILE_NOT_FOUND"
            HasWidget = $false
        }
        continue
    }
    
    $Content = Get-Content $FoundPath -Raw
    $HasWidget = $Content -match "TtsScreenSummaryEffect"
    
    if ($HasWidget) {
        Write-LogMessage "✅ $ScreenName - TtsScreenSummaryEffect found"
        $Results += [PSCustomObject]@{
            Screen = $ScreenName
            File = $ScreenFile
            Status = "WIDGET_FOUND"
            HasWidget = $true
        }
    } else {
        Write-LogMessage "❌ $ScreenName - TtsScreenSummaryEffect NOT found"
        $MissingScreens += $ScreenName
        $Results += [PSCustomObject]@{
            Screen = $ScreenName
            File = $ScreenFile
            Status = "WIDGET_MISSING"
            HasWidget = $false
        }
    }
}

Write-LogMessage ""
Write-LogMessage "=== Summary ==="
Write-LogMessage "Total Screens: $($RequiredScreens.Count)"
Write-LogMessage "With Widget: $($Results | Where-Object { $_.HasWidget -eq $true }).Count"
Write-LogMessage "Missing Widget: $($Results | Where-Object { $_.HasWidget -eq $false }).Count"

if ($MissingScreens.Count -eq 0) {
    Write-LogMessage ""
    Write-LogMessage "✅ All screens have TtsScreenSummaryEffect widget"
    exit 0
} else {
    Write-LogMessage ""
    Write-LogMessage "❌ Missing TtsScreenSummaryEffect in:"
    foreach ($Screen in $MissingScreens) {
        Write-LogMessage "  - $Screen"
    }
    Write-LogMessage ""
    Write-LogMessage "Action: Add TtsScreenSummaryEffect to missing screens"
    exit 1
}
