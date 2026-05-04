# ADB Device Control Script for TODO-27 Testing
# Handles device language change, network toggle, app restart

param(
    [string]$Action,
    [string]$Language,
    [switch]$ToggleAirplane
)

$ErrorActionPreference = "Stop"
$DeviceId = "89P7MZVWV4Z9C6GE"

function Write-LogMessage {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

Write-LogMessage "=== ADB Device Control ==="

if ($Action -eq "change_language") {
    Write-LogMessage "Changing device language to $Language"
    
    # Change device language using adb shell settings
    adb -s $DeviceId shell settings put global system_locales "$Language"
    adb -s $DeviceId shell settings put global system_locales "$Language"
    
    Write-LogMessage "Language changed to $Language. Restarting app..."
    
    # Force stop app
    adb -s $DeviceId shell am force-stop com.tranzfort.app
    
    Start-Sleep -Seconds 2
    Write-LogMessage "App stopped. Ready for restart."
}

elseif ($Action -eq "toggle_airplane") {
    if ($ToggleAirplane) {
        Write-LogMessage "Enabling airplane mode"
        adb -s $DeviceId shell settings put global airplane_mode_on 1
        Write-LogMessage "Airplane mode enabled"
    } else {
        Write-LogMessage "Disabling airplane mode"
        adb -s $DeviceId shell settings put global airplane_mode_on 0
        Write-LogMessage "Airplane mode disabled"
    }
}

elseif ($Action -eq "restart_app") {
    Write-LogMessage "Restarting TranZfort app"
    adb -s $DeviceId shell am force-stop com.tranzfort.app
    Start-Sleep -Seconds 2
    Write-LogMessage "App stopped. Ready for launch."
}

elseif ($Action -eq "launch_app") {
    Write-LogMessage "Launching TranZfort app"
    adb -s $DeviceId shell monkey -p com.tranzfort.app 1
    Write-LogMessage "App launched"
}

elseif ($Action -eq "kill_app") {
    Write-LogMessage "Killing TranZfort app"
    adb -s $DeviceId shell am force-stop com.tranzfort.app
    Write-LogMessage "App killed"
}

else {
    Write-LogMessage "Unknown action: $Action"
    Write-LogMessage "Available actions:"
    Write-LogMessage "  -Action change_language -Language <lang_code>"
    Write-LogMessage "  -Action toggle_airplane -ToggleAirplane"
    Write-LogMessage "  -Action restart_app"
    Write-LogMessage "  -Action launch_app"
    Write-LogMessage "  -Action kill_app"
    exit 1
}

Write-LogMessage "=== ADB Device Control Complete ==="
