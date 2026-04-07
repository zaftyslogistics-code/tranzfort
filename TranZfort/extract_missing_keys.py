"""Extract all missing AppLocalizations keys from compile errors across the entire project."""
import re
import json
import pathlib
import subprocess
import os

os.chdir(pathlib.Path(__file__).parent)

# Step 1: Run flutter analyze to get ALL compile errors at once
print("Running flutter analyze...")
result = subprocess.run(
    ["flutter", "analyze", "--no-pub"],
    capture_output=True, text=True, encoding="utf-8"
)
output = result.stdout + result.stderr

# Step 2: Extract all missing AppLocalizations keys
missing_getters = set()
for m in re.finditer(r"getter '(\w+)' isn't defined for the type 'AppLocalizations'", output):
    missing_getters.add(m.group(1))
for m in re.finditer(r"method '(\w+)' isn't defined for the type 'AppLocalizations'", output):
    missing_getters.add(m.group(1))

print(f"\nFound {len(missing_getters)} missing keys:")
for k in sorted(missing_getters):
    print(f"  {k}")

# Step 3: For each missing key, find where it's used to understand its signature
# (getter vs method with parameters)
print("\n--- Usage context for each missing key ---")
for key in sorted(missing_getters):
    for root, dirs, files in os.walk("lib/src"):
        for f in files:
            if not f.endswith(".dart"):
                continue
            p = pathlib.Path(root) / f
            text = p.read_text(encoding="utf-8")
            for i, line in enumerate(text.splitlines(), 1):
                if key in line and "AppLocalizations" not in line:
                    print(f"  {key}: {p}:{i}  ->  {line.strip()[:120]}")

# Step 4: Generate ARB entries for missing keys
print("\n--- ARB entries to add ---")
arb = json.load(open("lib/l10n/app_en.arb", encoding="utf-8"))
for key in sorted(missing_getters):
    if key not in arb:
        # Check if it's a method (has parameters) by looking at usage
        is_method = False
        for root, dirs, files in os.walk("lib/src"):
            for f in files:
                if not f.endswith(".dart"):
                    continue
                p = pathlib.Path(root) / f
                text = p.read_text(encoding="utf-8")
                # Check if key is called with parentheses
                if re.search(rf'\.{key}\s*\(', text):
                    is_method = True
                    # Try to extract parameter names
                    match = re.search(rf'\.{key}\s*\(([^)]*)\)', text)
                    if match:
                        print(f'  "{key}": "TODO {key} ({match.group(1).strip()})"')
                    break
            if is_method:
                break
        if not is_method:
            print(f'  "{key}": "TODO {key}"')
