# Compare a few known Hindi values between HEAD and current file to confirm
# the cleanup preserved UTF-8 encoding.
$ErrorActionPreference = 'Stop'
$origText = (& git show HEAD:TranZfort/lib/l10n/app_hi.arb) -join "`n"
$currText = [System.IO.File]::ReadAllText(
    'TranZfort/lib/l10n/app_hi.arb',
    [System.Text.Encoding]::UTF8)

$sampleKeys = @(
    'authWelcomeTitle',
    'appTitle',
    'authPasswordLabel',
    'splashLoadingWorkspace'
)
foreach ($k in $sampleKeys) {
    $pattern = '"' + $k + '":\s*"([^"]+)"'
    $origVal = if ($origText -match $pattern) { $matches[1] } else { '(missing)' }
    $currVal = if ($currText -match $pattern) { $matches[1] } else { '(missing)' }
    $ok = if ($origVal -eq $currVal) { 'OK' } else { 'MISMATCH' }
    Write-Host "$ok  $k"
    if ($origVal -ne $currVal) {
        Write-Host "    orig: $origVal"
        Write-Host "    curr: $currVal"
    }
}
