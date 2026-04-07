"""Find all l10n keys that are called as methods (with parentheses) in Dart source,
cross-reference with app_en.arb, and fix any that are declared as getters but used as methods."""
import re
import json
import pathlib
import os

os.chdir(pathlib.Path(__file__).parent)

arb_path = pathlib.Path("lib/l10n/app_en.arb")
arb = json.load(open(arb_path, encoding="utf-8"))

# Find all l10n method calls: l10n.keyName(args) or loc.keyName(args)
method_calls = {}  # key -> list of (file, line, args_str)
for root, dirs, files in os.walk("lib/src"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = pathlib.Path(root) / f
        text = p.read_text(encoding="utf-8")
        for i, line in enumerate(text.splitlines(), 1):
            for m in re.finditer(r'(?:l10n|loc)\.(\w+)\s*\(([^)]*)\)', line):
                key = m.group(1)
                args = m.group(2).strip()
                if key in ('of',):
                    continue
                if key not in method_calls:
                    method_calls[key] = []
                method_calls[key].append((str(p), i, args))

# Check which method-call keys exist in arb WITHOUT placeholders
needs_fix = []
for key in sorted(method_calls):
    meta_key = f"@{key}"
    has_placeholders = meta_key in arb and "placeholders" in arb.get(meta_key, {})
    if key in arb and not has_placeholders:
        # Key exists but has no placeholders - needs fixing
        args_example = method_calls[key][0][2]
        needs_fix.append((key, args_example))
        print(f"NEEDS FIX: {key} called with ({args_example})")
    elif key not in arb:
        args_example = method_calls[key][0][2]
        needs_fix.append((key, args_example))
        print(f"MISSING:   {key} called with ({args_example})")

print(f"\nTotal keys needing fix: {len(needs_fix)}")

# Now fix them
for key, args_str in needs_fix:
    # Parse param names from call site
    param_names = []
    for part in args_str.split(","):
        part = part.strip()
        if not part:
            continue
        # named param: name: value
        named = re.match(r'(\w+)\s*:', part)
        if named:
            param_names.append(named.group(1))
        else:
            # positional - extract variable name
            # Handle things like: email, widget.name, someVar
            clean = part.split('.')[-1].strip()
            clean = re.sub(r'[^a-zA-Z_]', '', clean)
            if clean:
                param_names.append(clean)

    if not param_names:
        param_names = ["value"]

    # Update arb entry
    current_value = arb.get(key, key)
    # Add placeholders to the string value
    placeholder_refs = " ".join(f"{{{p}}}" for p in param_names)
    if "{" not in current_value:
        arb[key] = f"{current_value} {placeholder_refs}"
    arb[f"@{key}"] = {"placeholders": {p: {} for p in param_names}}
    print(f"  Fixed: {key} -> placeholders: {param_names}")

# Write back
with open(arb_path, "w", encoding="utf-8") as f:
    json.dump(arb, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"\nDone. Updated {arb_path}")
