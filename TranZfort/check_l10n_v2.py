import json

arb = json.load(open('lib/l10n/app_en.arb', encoding='utf-8'))
keys = [
    'truckerFindLoadsStatusActive',
    'truckerFindLoadsStatusAssignedPartial',
    'truckerFindLoadsStatusUnknown',
    'truckerFindLoadsBodyTypeOpen',
    'truckerFindLoadsBodyTypeTrailer',
    'truckerFindLoadsBodyTypeContainer',
    'truckerFindLoadsBodyTypeTanker',
    'truckerFindLoadsBodyTypeUnknown',
    'truckerFindLoadsAnyBodyFallback',
    'truckerFindLoadsViewDetailsAction',
    'truckerFindLoadsPriceAdvancePickup',
    'truckerFindLoadsAllLoadsTab',
    'truckerFindLoadsSuperLoadsTab',
]
for k in keys:
    v = arb.get(k, 'MISSING')
    print(f'  {k} = {v}')
