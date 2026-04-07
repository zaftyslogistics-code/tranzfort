String normalizeVerificationStatus(dynamic raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  switch (value) {
    case 'verified':
    case 'approved':
    case 'active':
      return 'verified';
    case 'pending':
    case 'under_review':
    case 'in_review':
    case 'submitted':
      return 'pending';
    case 'rejected':
    case 'declined':
      return 'rejected';
    case 'unverified':
    case 'not_verified':
    case 'not verified':
    case '':
      return 'unverified';
    default:
      return value;
  }
}

bool isVerifiedStatus(dynamic raw) {
  return normalizeVerificationStatus(raw) == 'verified';
}

bool isPendingVerificationStatus(dynamic raw) {
  return normalizeVerificationStatus(raw) == 'pending';
}
