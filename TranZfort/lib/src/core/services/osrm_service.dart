import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

class OsrmService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1/driving';

  Future<Result<List<LatLng>>> getRoutePolyline(LatLng origin, LatLng destination) async {
    try {
      final url = '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return const Failure(
          AppFailureType.network, 
          debugMessage: 'OSRM returned non-200 status code',
        );
      }

      final data = json.decode(response.body);
      
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

      final geometry = routes[0]['geometry'];
      final coordinates = geometry['coordinates'] as List;

      // OSRM returns [longitude, latitude], latlong2 uses LatLng(latitude, longitude)
      final List<LatLng> polyline = coordinates.map((coord) {
        return LatLng(coord[1] as double, coord[0] as double);
      }).toList();

      return Success(polyline);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  // Fallback Haversine generated direct line if routing fails
  List<LatLng> getFallbackRoute(LatLng origin, LatLng destination) {
    return [origin, destination];
  }
}
