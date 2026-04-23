# Fix a trailing comma on the last key line of an ARB file.
# The ARB parser rejects `",\n}` — we need `"\n}`.
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$lines = [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
# Walk backwards from the end, skipping blank lines and the final `}`.
$i = $lines.Count - 1
while ($i -ge 0 -and $lines[$i].Trim() -eq '') { $i-- }
if ($lines[$i].Trim() -ne '}') {
    Write-Host "Unexpected last non-blank line in $Path (expected '}'): $($lines[$i])"
    exit 1
}
# Previous non-blank line should be the last entry.
$j = $i - 1
while ($j -ge 0 -and $lines[$j].Trim() -eq '') { $j-- }
$prev = $lines[$j]
if ($prev.EndsWith(',')) {
    $lines[$j] = $prev.Substring(0, $prev.Length - 1)
    [System.IO.File]::WriteAllLines($Path, $lines, $utf8NoBom)
    Write-Host "Trimmed trailing comma on line $($j + 1) of $Path"
} else {
    Write-Host "No trailing comma found on line $($j + 1) of $Path - nothing to fix"
}
