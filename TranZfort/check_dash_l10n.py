import json
arb = json.load(open('lib/l10n/app_en.arb', encoding='utf-8'))
keys = [
    'truckerDashboardVerificationStatusVerified',
    'truckerDashboardVerificationStatusPending',
    'truckerDashboardVerificationStatusRejected',
    'truckerDashboardVerificationStatusUnverified',
    'truckerDashboardSetupInProgress',
    'truckerDashboardVerificationStatusUnknown',
    'truckerDashboardVerificationStatusTitle',
    'truckerDashboardVerificationCompleteTitle',
    'supplierDashboardSuperLoadVerificationComplete',
    'supplierDashboardSuperLoadVerificationRequired',
    'supplierDashboardSuperLoadBusinessLicenceOnFile',
    'supplierDashboardSuperLoadBusinessLicenceMissing',
    'supplierDashboardSuperLoadReadinessSummaryComplete',
    'supplierDashboardSuperLoadReadinessSummaryMissingBusinessLicence',
    'supplierDashboardSuperLoadCompanyAgeUnavailable',
    'supplierVerificationCompleteDescription',
]
for k in keys:
    v = arb.get(k, 'MISSING')
    print(f'  {k} = {v}')
