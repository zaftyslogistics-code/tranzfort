/// Trucking drive-time estimate based on practical daily distance.
class DriveTimeEstimate {
  const DriveTimeEstimate._();

  /// Typical loaded-truck daily distance used across load detail UI.
  static const double kmPerDay = 300;

  static double estimateDays(double distanceKm) {
    if (distanceKm <= 0) {
      return 0;
    }
    return distanceKm / kmPerDay;
  }

  static String formatDayCount(double days) {
    if (days <= 0) {
      return '0';
    }
    if (days % 1 == 0) {
      return days.toStringAsFixed(0);
    }
    return days.toStringAsFixed(1);
  }
}
