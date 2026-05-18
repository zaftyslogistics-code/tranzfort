import 'dart:convert';
import 'dart:io';

import '../utils/map_readers.dart';
import 'route_snapshot_service.dart';

typedef RouteJsonFetcher = Future<Map<String, dynamic>> Function(Uri uri);

class OsrmRouteSnapshotService {
  final RouteJsonFetcher _getJson;

  OsrmRouteSnapshotService({RouteJsonFetcher? getJsonFn}) : _getJson = getJsonFn ?? _defaultGetJson;

  Future<RouteSnapshot?> fetchDrivingRouteSnapshot({
    required double? originLat,
    required double? originLng,
    required double? destinationLat,
    required double? destinationLng,
  }) async {
    if (originLat == null || originLng == null || destinationLat == null || destinationLng == null) {
      return null;
    }

    final uri = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$originLng,$originLat;$destinationLng,$destinationLat?overview=false',
    );

    try {
      final payload = await _getJson(uri);
      final routes = payload['routes'];
      if (routes is! List || routes.isEmpty) {
        return null;
      }

      final firstRoute = routes.first;
      if (firstRoute is! Map<String, dynamic>) {
        return null;
      }

      final distanceMeters = readDoubleNullable(firstRoute['distance']);
      final durationSeconds = readDoubleNullable(firstRoute['duration']);
      if (distanceMeters == null || durationSeconds == null) {
        return null;
      }

      return RouteSnapshot(
        distanceKm: distanceMeters / 1000,
        durationMinutes: (durationSeconds / 60).round(),
        source: 'osrm',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _defaultGetJson(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } finally {
      client.close(force: true);
    }
  }
}
