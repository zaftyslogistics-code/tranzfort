import json, sys

with open('lib/l10n/app_en.arb', encoding='utf-8') as f:
    data = json.load(f)

values = {}
for k, v in data.items():
    if k.startswith('@') or k.startswith('_') or not isinstance(v, str) or '{' in v:
        continue
    values.setdefault(v, []).append(k)

dupes = {v: ks for v, ks in values.items() if len(ks) > 1}

for v, ks in sorted(dupes.items(), key=lambda x: -len(x[1])):
    if len(ks) >= 2:
        print(f'{len(ks)} keys: {ks}')
        print(f'  -> {v[:100]}')
        print()
