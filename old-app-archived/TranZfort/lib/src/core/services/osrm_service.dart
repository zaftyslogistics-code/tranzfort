import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../error/app_failure.dart';
import '../error/result.dart';
import '../utils/coordinate_utils.dart';

class OsrmRouteData {
  final List<LatLng> polyline;
  final int distanceMeters;
  final int durationSeconds;

  const OsrmRouteData({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OsrmService {
  static const String _baseUrl =
      'http://router.project-osrm.org/route/v1/driving';

  Future<Result<OsrmRouteData>> getRouteData(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url =
          '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return const Failure(
          AppFailureType.network,
          debugMessage: 'OSRM returned non-200 status code',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        return Failure(
          AppFailureType.network,
          debugMessage: 'OSRM returned error code: ${data['code']}',
        );
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return const Failure(
          AppFailureType.unknown,
          debugMessage: 'OSRM returned no routes',
        );
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) {
        return const Failure(
          AppFailureType.unknown,
          debugMessage: 'OSRM route geometry missing',
        );
      }

      // OSRM returns [longitude, latitude], latlong2 uses LatLng(latitude, longitude)
      final polyline = coordinates
          .whereType<List<dynamic>>()
          .map((coord) => CoordinateUtils.toLatLng(coord.elementAtOrNull(1), coord.elementAtOrNull(0)))
          .whereType<LatLng>()
          .toList(growable: false);
      if (polyline.isEmpty) {
        return const Failure(
          AppFailureType.unknown,
          debugMessage: 'OSRM route geometry could not be parsed',
        );
      }

      final distanceMeters =
          (CoordinateUtils.parseDouble(firstRoute['distance']) ?? 0).round();
      final durationSeconds =
          (CoordinateUtils.parseDouble(firstRoute['duration']) ?? 0).round();

      return Success(
        OsrmRouteData(
          polyline: polyline,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
        ),
      );
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<LatLng>>> getRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    final result = await getRouteData(origin, destination);
    return switch (result) {
      Success(data: final data) => Success(data.polyline),
      Failure(type: final type, debugMessage: final debugMessage) =>
        Failure(type, debugMessage: debugMessage),
    };
  }

  // Fallback Haversine generated direct line if routing fails
  List<LatLng> getFallbackRoute(LatLng origin, LatLng destination) {
    return [origin, destination];
  }
}
