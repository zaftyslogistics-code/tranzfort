"""
One-shot script to:
1. Parse flutter analyze output for ALL missing AppLocalizations keys
2. Determine each key's signature (getter vs method with named params)
3. Add them to app_en.arb with correct placeholders (only missing ones)
4. NOT touch any existing keys
"""
import re
import json
import pathlib
import os

os.chdir(pathlib.Path(__file__).parent)

# --- Step 1: Read analyze output ---
analyze = pathlib.Path("analyze_output.txt").read_text(encoding="utf-8")
missing_keys = set()
for m in re.finditer(r"getter '(\w+)' isn't defined for the type 'AppLocalizations'", analyze):
    missing_keys.add(m.group(1))
for m in re.finditer(r"method '(\w+)' isn't defined for the type 'AppLocalizations'", analyze):
    missing_keys.add(m.group(1))

print(f"Missing keys from analyze: {len(missing_keys)}")

# --- Step 2: For each key, find ALL usages to determine signature ---
# Build a map: key -> list of arg strings from call sites
key_calls = {}
for root, dirs, files in os.walk("lib/src"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = pathlib.Path(root) / f
        text = p.read_text(encoding="utf-8")
        for line in text.splitlines():
            for key in missing_keys:
                # Check for method call: .key(args)
                pattern = rf'\.{re.escape(key)}\s*\(([^)]*)\)'
                for m in re.finditer(pattern, line):
                    args = m.group(1).strip()
                    if key not in key_calls:
                        key_calls[key] = []
                    key_calls[key].append(args)

# --- Step 3: Load existing arb ---
arb_path = pathlib.Path("lib/l10n/app_en.arb")
arb = json.load(open(arb_path, encoding="utf-8"))

# --- Step 4: Add missing keys with proper signatures ---
added = 0
for key in sorted(missing_keys):
    if key in arb:
        continue  # Don't touch existing keys
    
    # Convert camelCase to readable words for default value
    words = re.sub(r'([A-Z])', r' \1', key).strip().lower()
    
    if key in key_calls and key_calls[key]:
        # It's a method - parse the first call site for param count
        args_str = key_calls[key][0]
        # Count actual arguments (split by comma, but respect nested parens)
        depth = 0
        arg_parts = []
        current = ""
        for ch in args_str:
            if ch == '(':
                depth += 1
                current += ch
            elif ch == ')':
                depth -= 1
                current += ch
            elif ch == ',' and depth == 0:
                arg_parts.append(current.strip())
                current = ""
            else:
                current += ch
        if current.strip():
            arg_parts.append(current.strip())
        
        # Generate clean placeholder names
        param_names = []
        for i, part in enumerate(arg_parts):
            # Try to extract a clean name
            # Named param: name: value
            named = re.match(r'(\w+)\s*:', part)
            if named:
                param_names.append(named.group(1))
            else:
                # Use generic names based on position
                param_names.append(f"p{i+1}")
        
        if not param_names:
            param_names = ["value"]
        
        placeholder_str = " ".join(f"{{{p}}}" for p in param_names)
        arb[key] = f"{words} {placeholder_str}"
        arb[f"@{key}"] = {"placeholders": {p: {} for p in param_names}}
        print(f"  +METHOD {key}({', '.join(param_names)})")
    else:
        # It's a getter
        arb[key] = words
        print(f"  +GETTER {key}")
    added += 1

# --- Step 5: Write updated arb ---
with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"\nAdded {added} keys to {arb_path}")
print(f"Total keys: {len([k for k in arb if not k.startswith('@') and k != '@@locale'])}")
