import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/result.dart';
import '../../../core/services/google_routes_service.dart';
import '../../../core/services/osrm_service.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../marketplace/providers/marketplace_providers.dart';

final googleRoutesServiceProvider = Provider<GoogleRoutesService>((ref) {
  return GoogleRoutesService(ref.watch(mapsConfigProvider), OsrmService());
});

class RoutePreviewData {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> polyline;
  final int? distanceMeters;
  final int? durationSeconds;
  final double? tollEstimate;
  final double? fuelConsumptionLiters;
  final bool isFallback;

  RoutePreviewData({
    required this.origin,
    required this.destination,
    required this.polyline,
    this.distanceMeters,
    this.durationSeconds,
    this.tollEstimate,
    this.fuelConsumptionLiters,
    this.isFallback = false,
  });
}

final routePreviewProvider = FutureProvider.family<RoutePreviewData?, String>((
  ref,
  loadId,
) async {
  final loadResult = await ref
      .watch(loadRepositoryProvider)
      .getLoadDetail(loadId);
  final load = switch (loadResult) {
    Success(data: final data) => data,
    Failure() => null,
  };

  if (load == null) {
    return null;
  }

  final origin = CoordinateUtils.toLatLngFromMap(
    load,
    latKey: 'origin_lat',
    lngKey: 'origin_lng',
  );
  final dest = CoordinateUtils.toLatLngFromMap(
    load,
    latKey: 'dest_lat',
    lngKey: 'dest_lng',
  );

  if (origin == null || dest == null) {
    return null;
  }

  final googleRoutes = ref.read(googleRoutesServiceProvider);
  final route = await googleRoutes.computeRoute(origin, dest);
  return RoutePreviewData(
    origin: origin,
    destination: dest,
    polyline: route.polyline,
    distanceMeters: route.distanceMeters,
    durationSeconds: route.durationSeconds,
    tollEstimate: route.tollEstimate,
    fuelConsumptionLiters: route.fuelConsumptionLiters,
    isFallback: route.isFallback,
  );
});
