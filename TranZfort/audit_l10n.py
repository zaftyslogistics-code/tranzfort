"""
Complete L10n audit script:
1. Scan ALL Dart source files for AppLocalizations key references
2. Determine getter vs method signatures by parsing actual Dart code
3. Compare with app_en.arb
4. Add ALL missing keys with correct placeholders
5. Replace Unicode bullet/arrow in .arb + all Dart files
"""
import re, json, pathlib, os

ROOT = pathlib.Path(__file__).parent
os.chdir(ROOT)

# ─── 1. Load current .arb ───────────────────────────────────────────
arb_en = json.load(open("lib/l10n/app_en.arb", encoding="utf-8"))
arb_keys = {k for k in arb_en if not k.startswith("@") and k != "@@locale"}
print(f"[1] Current EN .arb keys: {len(arb_keys)}")

# ─── 2. Scan Dart source for ALL l10n key references ────────────────
# We look for patterns like:
#   l10n.someKey          (getter)
#   l10n.someKey(args)    (method)
#   loc.someKey           (getter)
#   loc.someKey(args)     (method)

getter_refs = set()  # keys used as getters
method_refs = {}     # key -> number of positional args

for root, dirs, files in os.walk("lib/src"):
    for fname in files:
        if not fname.endswith(".dart"):
            continue
        p = pathlib.Path(root) / fname
        text = p.read_text(encoding="utf-8")
        
        # Find method calls: l10n.key(arg1, arg2, ...)
        for m in re.finditer(r"(?:l10n|loc)\.(\w+)\s*\(", text):
            key = m.group(1)
            if key in ("of",):
                continue
            # Count args by finding the matching closing paren
            start = m.end()
            depth = 1
            pos = start
            while pos < len(text) and depth > 0:
                if text[pos] == "(":
                    depth += 1
                elif text[pos] == ")":
                    depth -= 1
                pos += 1
            args_str = text[start:pos-1].strip()
            
            if not args_str:
                # Called with empty parens - treat as getter
                getter_refs.add(key)
                continue
            
            # Count actual args (respecting nested parens/brackets)
            arg_count = 0
            d = 0
            for ch in args_str:
                if ch in "([{":
                    d += 1
                elif ch in ")]}":
                    d -= 1
                elif ch == "," and d == 0:
                    arg_count += 1
            arg_count += 1  # last arg has no trailing comma
            
            if key in method_refs:
                method_refs[key] = max(method_refs[key], arg_count)
            else:
                method_refs[key] = arg_count
        
        # Find getter references: l10n.key (not followed by open paren)
        for m in re.finditer(r"(?:l10n|loc)\.(\w+)(?!\s*\()", text):
            key = m.group(1)
            if key in ("of", "localeName"):
                continue
            if key not in method_refs:
                getter_refs.add(key)

all_referenced = getter_refs | set(method_refs.keys())
print(f"[2] Referenced keys: {len(all_referenced)} ({len(getter_refs)} getters, {len(method_refs)} methods)")

# ─── 3. Find missing keys ───────────────────────────────────────────
missing_getters = sorted(getter_refs - arb_keys - set(method_refs.keys()))
missing_methods = sorted(set(method_refs.keys()) - arb_keys)

# Also find keys in arb that are used as methods but declared without placeholders
wrong_signature = []
for key in sorted(method_refs.keys()):
    if key in arb_keys:
        meta = arb_en.get(f"@{key}", {})
        placeholders = meta.get("placeholders", {})
        if len(placeholders) != method_refs[key]:
            wrong_signature.append((key, method_refs[key], len(placeholders)))

print(f"[3] Missing getters: {len(missing_getters)}")
print(f"    Missing methods: {len(missing_methods)}")
print(f"    Wrong signature: {len(wrong_signature)}")

for k in missing_getters:
    print(f"  +GETTER {k}")
for k in missing_methods:
    print(f"  +METHOD {k}({method_refs[k]} args)")
for k, expected, actual in wrong_signature:
    print(f"  !SIGNATURE {k}: has {actual} placeholders, needs {expected}")

# ─── 4. Add missing keys to arb ─────────────────────────────────────
added = 0

for key in missing_getters:
    # Generate human-readable default from camelCase
    words = re.sub(r"([A-Z])", r" \1", key).strip()
    arb_en[key] = words
    added += 1

for key in missing_methods:
    n = method_refs[key]
    words = re.sub(r"([A-Z])", r" \1", key).strip()
    params = [f"p{i+1}" for i in range(n)]
    placeholder_str = " ".join(f"{{{p}}}" for p in params)
    arb_en[key] = f"{words} {placeholder_str}"
    arb_en[f"@{key}"] = {"placeholders": {p: {} for p in params}}
    added += 1

# Fix wrong signatures (keys exist but need more/different placeholders)
for key, expected, actual in wrong_signature:
    if expected > actual:
        # Need to add more placeholders
        meta = arb_en.get(f"@{key}", {"placeholders": {}})
        placeholders = meta.get("placeholders", {})
        for i in range(actual, expected):
            pname = f"p{i+1}"
            placeholders[pname] = {}
        meta["placeholders"] = placeholders
        arb_en[f"@{key}"] = meta
        # Also add placeholder refs to value string if not present
        val = arb_en[key]
        for i in range(actual, expected):
            pname = f"p{i+1}"
            if f"{{{pname}}}" not in val:
                val += f" {{{pname}}}"
        arb_en[key] = val
        added += 1
        print(f"  Fixed signature: {key}")

print(f"\n[4] Added/fixed {added} keys")

# ─── 5. Write updated arb ───────────────────────────────────────────
with open("lib/l10n/app_en.arb", "w", encoding="utf-8") as f:
    json.dump(arb_en, f, ensure_ascii=False, indent=2)
    f.write("\n")

final_keys = len([k for k in arb_en if not k.startswith("@") and k != "@@locale"])
print(f"[5] Written app_en.arb with {final_keys} keys")

# ─── 6. Replace Unicode in .arb files ───────────────────────────────
for arb_file in ["lib/l10n/app_en.arb", "lib/l10n/app_hi.arb"]:
    p = pathlib.Path(arb_file)
    t = p.read_text(encoding="utf-8")
    bullets = t.count("\u2022")
    arrows = t.count("\u2192")
    t2 = t.replace("\u2022", "-").replace("\u2192", ">")
    p.write_text(t2, encoding="utf-8")
    print(f"[6] {arb_file}: replaced {bullets} bullets, {arrows} arrows")

# ─── 7. Replace Unicode in ALL Dart files ────────────────────────────
fixed_count = 0
for search_dir in ["lib/src", "test"]:
    for root, dirs, files in os.walk(search_dir):
        for fname in files:
            if not fname.endswith(".dart"):
                continue
            p = pathlib.Path(root) / fname
            t = p.read_text(encoding="utf-8")
            if "\u2022" in t or "\u2192" in t:
                t2 = t.replace("\u2022", "-").replace("\u2192", ">")
                p.write_text(t2, encoding="utf-8")
                fixed_count += 1

print(f"[7] Replaced Unicode in {fixed_count} Dart files")
print("\nDone! Now run: flutter gen-l10n && flutter analyze --no-pub")
