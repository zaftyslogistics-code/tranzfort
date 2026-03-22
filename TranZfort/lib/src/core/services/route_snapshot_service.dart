class RouteSnapshot {
  final double distanceKm;
  final int durationMinutes;
  final String source;
  final String? polyline;

  const RouteSnapshot({
    required this.distanceKm,
    required this.durationMinutes,
    required this.source,
    this.polyline,
  });

  factory RouteSnapshot.fromStoredFields({
    required double? distanceKm,
    required int? durationMinutes,
    required String? source,
    String? polyline,
  }) {
    return RouteSnapshot(
      distanceKm: distanceKm ?? 0,
      durationMinutes: durationMinutes ?? 0,
      source: (source ?? '').trim(),
      polyline: polyline,
    );
  }
}
