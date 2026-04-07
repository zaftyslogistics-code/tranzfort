import json, re

with open('TranZfort/lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove any comments
content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)

try:
    data = json.loads(content)
    print(f'Loaded {len(data)} keys')
    
    # Find keys without descriptions
    added = 0
    for key in list(data.keys()):
        if not key.startswith('@') and isinstance(data[key], str):
            desc_key = f'@{key}'
            if desc_key not in data:
                words = re.sub(r'([A-Z])', r' \1', key).replace('_', ' ').strip()
                words = words.lower().title()
                if key.startswith('_section'):
                    continue
                data[desc_key] = {'description': f'{words} - User-facing text for the app interface.'}
                added += 1
    
    print(f'Adding {added} descriptions...')
    
    with open('TranZfort/lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    # Verify
    with open('TranZfort/lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
        data2 = json.load(f)
    sk = sum(1 for k in data2 if not k.startswith('@'))
    dk = sum(1 for k in data2 if k.startswith('@'))
    print(f'After: String keys: {sk}, Description keys: {dk}, Missing: {sk-dk}')
    print('Done')
except json.JSONDecodeError as e:
    print(f'JSON error: {e}')
