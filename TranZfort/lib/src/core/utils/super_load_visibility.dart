/// Super Load states visible to truckers on marketplace (badge, Super Loads tab, guarantee copy).
const publicSuperLoadStatuses = <String>{
  'approved_payment_pending',
  'active',
};

/// True when a load should show the public Super Load badge on marketplace surfaces.
bool isPublicSuperLoad({
  required bool isSuperLoad,
  required String superStatus,
}) {
  if (!isSuperLoad) {
    return false;
  }
  return publicSuperLoadStatuses.contains(superStatus.trim().toLowerCase());
}
