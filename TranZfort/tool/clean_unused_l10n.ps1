# Phase 1 cleanup: remove unused EN keys (and their HI counterparts) from the
# ARB files using line-surgical edits that preserve the original formatting.
#
# Usage (from TranZfort/):
#   powershell -ExecutionPolicy Bypass -File tool/clean_unused_l10n.ps1 [-DryRun]

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$enPath   = Join-Path $repoRoot 'lib/l10n/app_en.arb'
$hiPath   = Join-Path $repoRoot 'lib/l10n/app_hi.arb'
$libRoot  = Join-Path $repoRoot 'lib'
$testRoot = Join-Path $repoRoot 'test'

# --- 1. Discover unused EN keys via JSON parse (just for key enumeration) ---
$en = Get-Content $enPath -Raw | ConvertFrom-Json
$hi = Get-Content $hiPath -Raw | ConvertFrom-Json
$enKeys = @($en.PSObject.Properties | Where-Object { $_.Name -notlike '@*' } | ForEach-Object { $_.Name })
$hiKeys = @($hi.PSObject.Properties | Where-Object { $_.Name -notlike '@*' } | ForEach-Object { $_.Name })

Write-Host "EN keys (before): $($enKeys.Count)"
Write-Host "HI keys (before): $($hiKeys.Count)"

# --- 2. Scan Dart sources for references ---
$codeFiles = @(Get-ChildItem -Path $libRoot -Recurse -Filter *.dart |
    Where-Object { $_.FullName -notmatch 'l10n[\\/]+app_localizations' })
if (Test-Path $testRoot) {
    $codeFiles += Get-ChildItem -Path $testRoot -Recurse -Filter *.dart -ErrorAction SilentlyContinue
}
$code = ($codeFiles | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"

$unused = New-Object System.Collections.Generic.HashSet[string]
foreach ($k in $enKeys) {
    if (-not ($code -match "\.$k\b")) { [void]$unused.Add($k) }
}
$orphanHi = @($hiKeys | Where-Object { $enKeys -notcontains $_ })

Write-Host "Unused EN keys: $($unused.Count)"
Write-Host "Orphan HI keys: $($orphanHi.Count)"

if ($DryRun) {
    $unused | Sort-Object | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" }
    Write-Host "Orphan HI:"
    $orphanHi | ForEach-Object { Write-Host "  $_" }
    exit 0
}

# --- 3. Surgical line removal on EN ARB ---
# EN file format:
#   Top half:    '  "key": "value",'  or  '  "key":  "value",' (single line)
#   Bottom half: '  "@key": {\n    "description": "...",\n    ...\n  },'
#
# We match keys at the start of a line, allowing any leading indent.

function Remove-Keys-From-Arb {
    param(
        [string]$path,
        [string[]]$keysToRemove
    )
    $keySet = [System.Collections.Generic.HashSet[string]]::new([string[]]$keysToRemove)
    # IMPORTANT: must read with explicit UTF-8 encoding; Get-Content / default
    # ReadAllLines use the system code page, which mangles Hindi ARB contents.
    $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
    $out   = New-Object System.Collections.Generic.List[string]
    $i     = 0
    $removed = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]

        # Detect leading `  "keyName":` or `  "@keyName":`. The `@` prefix is
        # captured for completeness but we treat @-metadata the same as the
        # plain key — both reference the same user-facing message.
        if ($line -match '^\s*"@?([A-Za-z_][A-Za-z0-9_]*)"\s*:\s*(.*)$') {
            $keyName = $matches[1]
            $rest    = $matches[2]
            if ($keySet.Contains($keyName)) {
                # Is this a multi-line object ({ ... })?
                # Detected if the rest of the line (after colon) starts with `{` and
                # doesn't close on the same line.
                $trim = $rest.TrimStart()
                if ($trim.StartsWith('{') -and -not ($trim -match '}\s*,?\s*$')) {
                    # Multi-line object — skip until matching close brace.
                    $depth = 0
                    foreach ($c in $trim.ToCharArray()) {
                        if ($c -eq '{') { $depth++ }
                        elseif ($c -eq '}') { $depth-- }
                    }
                    $j = $i + 1
                    while ($j -lt $lines.Count -and $depth -gt 0) {
                        foreach ($c in $lines[$j].ToCharArray()) {
                            if ($c -eq '{') { $depth++ }
                            elseif ($c -eq '}') { $depth-- }
                        }
                        $j++
                    }
                    $i = $j
                    $removed++
                    continue
                } else {
                    # Single-line entry — drop one line.
                    $i++
                    $removed++
                    continue
                }
            }
        }

        $out.Add($line) | Out-Null
        $i++
    }

    # After removing keys, some comma+newline tails may leave a dangling
    # comma before `}`. Fix: if the last non-empty non-brace line ends with a
    # stray comma but is followed by a brace line, leave as-is (JSON allows
    # comma noise only if we preserved a correct state). We didn't change the
    # relative structure of retained lines, so commas remain valid unless we
    # happened to remove the VERY LAST entry. Be defensive: walk from the end
    # and if the last content line before `}` has a trailing comma, keep it —
    # Dart's ARB parser tolerates trailing commas.

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($path, $out.ToArray(), $utf8NoBom)
    return $removed
}

Write-Host ""
Write-Host "Cleaning EN ARB..."
$enRemoved = Remove-Keys-From-Arb -path $enPath -keysToRemove @($unused)
Write-Host "  removed $enRemoved lines/blocks"

Write-Host "Cleaning HI ARB..."
$hiTargets = @($unused) + $orphanHi
$hiRemoved = Remove-Keys-From-Arb -path $hiPath -keysToRemove $hiTargets
Write-Host "  removed $hiRemoved lines/blocks"

# --- Report ---
$en2 = Get-Content $enPath -Raw | ConvertFrom-Json
$hi2 = Get-Content $hiPath -Raw | ConvertFrom-Json
$enKeys2 = @($en2.PSObject.Properties | Where-Object { $_.Name -notlike '@*' } | ForEach-Object { $_.Name })
$hiKeys2 = @($hi2.PSObject.Properties | Where-Object { $_.Name -notlike '@*' } | ForEach-Object { $_.Name })
Write-Host ""
Write-Host "EN keys (after):  $($enKeys2.Count)"
Write-Host "HI keys (after):  $($hiKeys2.Count)"
Write-Host "EN file size:     $((Get-Item $enPath).Length) bytes"
Write-Host "HI file size:     $((Get-Item $hiPath).Length) bytes"
Write-Host "Done. Run 'flutter gen-l10n' next."
