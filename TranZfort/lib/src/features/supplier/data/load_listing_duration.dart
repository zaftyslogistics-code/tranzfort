/// Marketplace listing duration (matches DB `load_listing_duration` enum).
enum LoadListingDuration {
  hours48('48_hours'),
  days7('7_days'),
  days30('30_days');

  const LoadListingDuration(this.rpcValue);

  final String rpcValue;

  static const LoadListingDuration defaultDuration = LoadListingDuration.days7;

  static LoadListingDuration? fromRpcValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    for (final option in LoadListingDuration.values) {
      if (option.rpcValue == value.trim()) {
        return option;
      }
    }
    return null;
  }
}
