import json

arb = json.load(open('lib/l10n/app_en.arb', encoding='utf-8'))
keys = [
    'truckerFindLoadsMarketplaceTabsTitle',
    'truckerFindLoadsAllLoadsTab',
    'truckerFindLoadsSuperLoadsTab',
    'truckerFindLoadsEmptyTitle',
    'truckerFindLoadsEmptySubtitle',
    'truckerFindLoadsLoadFailureTitle',
    'truckerFindLoadsResetFiltersAction',
    'truckerFindLoadsSuperLoadBadge',
    'shellTitleFindLoads',
    'truckerFindLoadsMaterialSummary',
    'truckerFindLoadsLoadCardViewDetails',
    'truckerFindLoadsStatusActive',
    'truckerFindLoadsStatusPaused',
    'truckerFindLoadsStatusFilled',
    'truckerFindLoadsStatusUnknown',
    'truckerFindLoadsBodyTypeUnknown',
    'truckerFindLoadsTripCostUnavailable',
]
for k in keys:
    v = arb.get(k, 'MISSING')
    print(f'  {k} = {v}')
