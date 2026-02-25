import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/error/result.dart';
import '../../../core/services/osrm_service.dart';

final osrmServiceProvider = Provider<OsrmService>((ref) {
  return OsrmService();
});

class RoutePreviewData {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> polyline;
  final bool isFallback;

  RoutePreviewData({
    required this.origin,
    required this.destination,
    required this.polyline,
    this.isFallback = false,
  });
}

final routePreviewProvider = FutureProvider.family<RoutePreviewData?, String>((ref, loadId) async {
  // 1. Fetch Load details to get origin/dest names
  // We mock the exact city coords for Sprint 8 if we don't have them in the DB yet,
  // or fetch from cities JSON if matched. For Phase 1 we will just use dummy coords if none provided
  // In a real app we'd fetch the exact LatLng from load or lookup city coordinates.
  
  // Hardcoded example fallback coords if actual lookup fails:
  final origin = const LatLng(28.6139, 77.2090); // New Delhi
  final dest = const LatLng(19.0760, 72.8777); // Mumbai

  final osrm = ref.read(osrmServiceProvider);
  final result = await osrm.getRoutePolyline(origin, dest);

  switch (result) {
    case Success(data: final polyline):
      return RoutePreviewData(
        origin: origin,
        destination: dest,
        polyline: polyline,
      );
    case Failure():
      return RoutePreviewData(
        origin: origin,
        destination: dest,
        polyline: osrm.getFallbackRoute(origin, dest),
        isFallback: true,
      );
  }
});
