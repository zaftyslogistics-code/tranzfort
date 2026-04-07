import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
en_path = root / 'lib/l10n/app_en.arb'
hi_path = root / 'lib/l10n/app_hi.arb'
dart_path = root / 'lib/src/l10n/app_localizations_hi.dart'

en = json.loads(en_path.read_text(encoding='utf-8'))
hi = json.loads(hi_path.read_text(encoding='utf-8'))
text = dart_path.read_text(encoding='utf-8')

missing = [k for k in en if not k.startswith('@') and k not in hi]
values: dict[str, str] = {}

for key in missing:
    getter_pattern = re.compile(
        rf"String get {re.escape(key)} =>\s*'((?:[^'\\]|\\.)*)';",
        re.S,
    )
    getter_match = getter_pattern.search(text)
    if getter_match:
        values[key] = bytes(getter_match.group(1), 'utf-8').decode('unicode_escape')
        continue

    method_pattern = re.compile(
        rf"String {re.escape(key)}\(([^)]*)\) \{{\s*return '((?:[^'\\]|\\.)*)';\s*\}}",
        re.S,
    )
    method_match = method_pattern.search(text)
    if method_match:
        template = bytes(method_match.group(2), 'utf-8').decode('unicode_escape')
        params = [chunk.strip().split()[-1] for chunk in method_match.group(1).split(',') if chunk.strip()]
        for param in params:
            template = template.replace(f'${param}', '{' + param + '}')
        values[key] = template

for key in missing:
    hi[key] = values.get(key, en[key])
    meta_key = f'@{key}'
    if meta_key in en and meta_key not in hi:
        hi[meta_key] = en[meta_key]

ordered: dict[str, object] = {}
for key, value in en.items():
    if key in hi:
        ordered[key] = hi[key]
for key, value in hi.items():
    if key not in ordered:
        ordered[key] = value

hi_path.write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

print(f'missing before: {len(missing)}')
print(f'filled from generated hi.dart: {sum(1 for key in missing if key in values)}')
print(f'fallback to app_en.arb values: {sum(1 for key in missing if key not in values)}')
