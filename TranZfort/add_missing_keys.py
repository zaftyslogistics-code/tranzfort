"""Parse analyze_output.txt, extract all missing AppLocalizations keys, 
look up their usage in Dart source to determine if getter or method with params,
then patch app_en.arb with stub entries."""
import re
import json
import pathlib
import os

os.chdir(pathlib.Path(__file__).parent)

# 1. Parse analyze output for missing keys
analyze = pathlib.Path("analyze_output.txt").read_text(encoding="utf-8")
missing = set()
for m in re.finditer(r"getter '(\w+)' isn't defined for the type 'AppLocalizations'", analyze):
    missing.add(m.group(1))
for m in re.finditer(r"method '(\w+)' isn't defined for the type 'AppLocalizations'", analyze):
    missing.add(m.group(1))

print(f"Total missing keys: {len(missing)}")

# 2. For each key, scan source to determine signature (getter vs method w/ params)
key_info = {}  # key -> (is_method, param_names_or_None)
for key in sorted(missing):
    found_method = False
    for root, dirs, files in os.walk("lib/src"):
        for f in files:
            if not f.endswith(".dart"):
                continue
            text = (pathlib.Path(root) / f).read_text(encoding="utf-8")
            # Look for method call: .keyName(args)
            match = re.search(rf'\.{key}\s*\(([^)]*)\)', text)
            if match:
                args_str = match.group(1).strip()
                # Extract named params or positional
                key_info[key] = (True, args_str)
                found_method = True
                break
        if found_method:
            break
    if not found_method:
        key_info[key] = (False, None)

# 3. Generate sensible default values and add to arb
arb_path = pathlib.Path("lib/l10n/app_en.arb")
arb = json.load(open(arb_path, encoding="utf-8"))

for key in sorted(missing):
    if key in arb:
        continue
    is_method, args = key_info[key]
    # Generate a human-readable default based on the key name
    # Convert camelCase to words
    words = re.sub(r'([A-Z])', r' \1', key).strip()
    
    if is_method and args:
        # Parse parameter names from the call site
        # e.g. "completedCount, totalCount" or "name: 'foo'"
        param_names = []
        for part in args.split(","):
            part = part.strip()
            # named param: name: value
            named = re.match(r'(\w+)\s*:', part)
            if named:
                param_names.append(named.group(1))
            else:
                # positional - try to guess name from variable
                clean = re.sub(r'[^a-zA-Z_]', '', part.split('.')[-1])
                if clean:
                    param_names.append(clean)
        
        # Build placeholder string
        placeholder_str = " ".join(f"{{{p}}}" for p in param_names)
        arb[key] = f"{words}: {placeholder_str}"
        arb[f"@{key}"] = {"placeholders": {p: {} for p in param_names}}
        print(f"  METHOD: {key}({', '.join(param_names)})")
    else:
        arb[key] = words
        print(f"  GETTER: {key}")

# 4. Write updated arb
with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"\nUpdated {arb_path} with {len(missing)} new keys")
print(f"Total keys now: {len([k for k in arb if not k.startswith('@') and k != '@@locale'])}")
