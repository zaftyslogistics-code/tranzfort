import '../../../core/utils/map_readers.dart';

class SupplierPostLoadQuota {
  final int loadsPostedToday;
  final int loadsDailyLimit;
  final int loadsRemainingToday;
  final bool canPostToday;
  final bool verificationRequired;

  const SupplierPostLoadQuota({
    required this.loadsPostedToday,
    required this.loadsDailyLimit,
    required this.loadsRemainingToday,
    required this.canPostToday,
    required this.verificationRequired,
  });

  factory SupplierPostLoadQuota.fromMap(Map<String, dynamic> map) {
    return SupplierPostLoadQuota(
      loadsPostedToday: readInt(map['loads_posted_today']),
      loadsDailyLimit: readInt(map['loads_daily_limit']),
      loadsRemainingToday: readInt(map['loads_remaining_today']),
      canPostToday: map['can_post_today'] == true,
      verificationRequired: map['verification_required'] == true,
    );
  }

  static const SupplierPostLoadQuota fallback = SupplierPostLoadQuota(
    loadsPostedToday: 0,
    loadsDailyLimit: 20,
    loadsRemainingToday: 0,
    canPostToday: false,
    verificationRequired: true,
  );
}
