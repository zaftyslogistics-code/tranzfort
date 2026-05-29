# Regenerate TTS ARB outputs (separate arb-dir from app l10n.yaml).
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..
if (Test-Path l10n.yaml) { Move-Item -Force l10n.yaml l10n_app.yaml }
Copy-Item l10n_tts.yaml l10n.yaml
flutter gen-l10n
Remove-Item l10n.yaml
Move-Item -Force l10n_app.yaml l10n.yaml
flutter gen-l10n
Write-Host 'Generated app + TTS localizations.'
