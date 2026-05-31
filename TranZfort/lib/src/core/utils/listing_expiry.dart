/// Whether a marketplace listing ends within [window] (default 48h).
bool isListingExpiringSoon(
  DateTime? marketplaceVisibleUntil, {
  Duration window = const Duration(hours: 48),
}) {
  if (marketplaceVisibleUntil == null) {
    return false;
  }
  final now = DateTime.now();
  final until = marketplaceVisibleUntil.toLocal();
  if (!until.isAfter(now)) {
    return false;
  }
  return until.difference(now) <= window;
}
