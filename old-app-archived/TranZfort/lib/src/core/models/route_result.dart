import 'package:latlong2/latlong.dart';

import '../utils/coordinate_utils.dart';

class RouteResult {
  final List<LatLng> polyline;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? encodedPolyline;
  final double? tollEstimate;
  final double? fuelConsumptionLiters;
  final bool isFallback;
  final String source;

  const RouteResult({
    required this.polyline,
    required this.source,
    this.distanceMeters,
    this.durationSeconds,
    this.encodedPolyline,
    this.tollEstimate,
    this.fuelConsumptionLiters,
    this.isFallback = false,
  });

  factory RouteResult.fromMap({
    required Map<String, dynamic> map,
    required List<LatLng> polyline,
    required String source,
    bool isFallback = false,
  }) {
    final distanceMeters = CoordinateUtils.parseDouble(map['distanceMeters'])?.round();
    final durationSeconds = CoordinateUtils.parseDouble(map['durationSeconds'])?.round();

    return RouteResult(
      polyline: polyline,
      source: source,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: map['encodedPolyline']?.toString(),
      tollEstimate: CoordinateUtils.parseDouble(map['tollEstimate']),
      fuelConsumptionLiters: CoordinateUtils.parseDouble(map['fuelConsumptionLiters']),
      isFallback: isFallback,
    );
  }

  double? get distanceKm =>
      distanceMeters == null ? null : distanceMeters!.toDouble() / 1000;

  double? get durationHours =>
      durationSeconds == null ? null : durationSeconds!.toDouble() / 3600;
}
