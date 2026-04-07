import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../config/maps_config.dart';
import '../error/result.dart';
import '../models/route_result.dart';
import '../utils/coordinate_utils.dart';
import 'osrm_service.dart';

class GoogleRoutesService {
  final MapsConfig _mapsConfig;
  final OsrmService _osrmService;

  static final Map<String, _CachedRoute> _cache = <String, _CachedRoute>{};
  static const Duration _cacheTtl = Duration(hours: 24);

  const GoogleRoutesService(this._mapsConfig, this._osrmService);

  Future<RouteResult> computeRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final cacheKey = _cacheKey(origin, destination);
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.createdAt) <= _cacheTtl) {
      return cached.data;
    }

    final googleResult = await _computeGoogleRoute(origin, destination);
    if (googleResult != null && googleResult.polyline.length > 1) {
      _cache[cacheKey] = _CachedRoute(googleResult, DateTime.now());
      return googleResult;
    }

    final osrmResult = await _osrmService.getRouteData(origin, destination);
    switch (osrmResult) {
      case Success(data: final data):
        final fallback = RouteResult(
          source: 'osrm',
          isFallback: true,
          polyline: data.polyline,
          distanceMeters: data.distanceMeters,
          durationSeconds: data.durationSeconds,
        );
        _cache[cacheKey] = _CachedRoute(fallback, DateTime.now());
        return fallback;
      case Failure():
        final straightLine = RouteResult(
          source: 'straight_line',
          isFallback: true,
          polyline: [origin, destination],
          distanceMeters: _haversineMeters(origin, destination),
          durationSeconds:
              (_haversineMeters(origin, destination) / 13.33).round(), // ~48km/h
        );
        _cache[cacheKey] = _CachedRoute(straightLine, DateTime.now());
        return straightLine;
    }
  }

  Future<RouteResult?> _computeGoogleRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    if (!_mapsConfig.canUseGoogleRoutes) {
      return null;
    }

    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('X-Goog-Api-Key', _mapsConfig.apiKey);
      request.headers.set(
        'X-Goog-FieldMask',
        'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.travelAdvisory.tollInfo,routes.travelAdvisory.fuelConsumptionMicroliters',
      );

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'travelMode': 'DRIVE',
      });

      request.write(body);
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final encoded = (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
              ?.toString() ??
          '';
      if (encoded.isEmpty) {
        return null;
      }

      final distanceMeters = (route['distanceMeters'] as num?)?.toInt();
      final durationSeconds = _parseDurationSeconds(route['duration']?.toString());
      final travelAdvisory = route['travelAdvisory'] as Map<String, dynamic>?;
      final tollEstimate = _parseTollEstimate(travelAdvisory?['tollInfo']);
      final fuelConsumptionLiters =
          _parseFuelLiters(travelAdvisory?['fuelConsumptionMicroliters']);

      return RouteResult(
        source: 'google',
        polyline: _decodePolyline(encoded),
        encodedPolyline: encoded,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        tollEstimate: tollEstimate,
        fuelConsumptionLiters: fuelConsumptionLiters,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<List<LatLng>> getRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    final result = await computeRoute(origin, destination);
    return result.polyline;
  }

  Future<ReverseGeocodeResult?> reverseGeocode(double lat, double lng) async {
    if (!_mapsConfig.canUseGeocoding) {
      return null;
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': _mapsConfig.apiKey,
      'language': 'en',
      'result_type': 'locality|administrative_area_level_2|administrative_area_level_1',
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if ((json['status'] ?? '').toString().toUpperCase() != 'OK') {
        return null;
      }

      final results = (json['results'] as List<dynamic>? ?? const []);
      if (results.isEmpty) {
        return null;
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      final components =
          (first['address_components'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();

      String? city;
      String? state;
      for (final component in components) {
        final types = (component['types'] as List<dynamic>? ?? const [])
            .map((t) => t.toString())
            .toSet();
        final longName = (component['long_name'] ?? '').toString();
        if (longName.isEmpty) {
          continue;
        }

        if (city == null &&
            (types.contains('locality') ||
                types.contains('administrative_area_level_2'))) {
          city = longName;
        }
        if (state == null && types.contains('administrative_area_level_1')) {
          state = longName;
        }
      }

      if ((city == null || city.isEmpty) && (state == null || state.isEmpty)) {
        return null;
      }

      return ReverseGeocodeResult(city: city, state: state);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  int _parseDurationSeconds(String? durationText) {
    if (durationText == null || durationText.isEmpty) {
      return 0;
    }
    final normalized = durationText.endsWith('s')
        ? durationText.substring(0, durationText.length - 1)
        : durationText;
    return double.tryParse(normalized)?.round() ?? 0;
  }

  double? _parseFuelLiters(dynamic microlitersValue) {
    final micro = CoordinateUtils.parseDouble(microlitersValue);
    if (micro == null || micro <= 0) {
      return null;
    }
    return micro / 1000000;
  }

  double? _parseTollEstimate(dynamic tollInfoRaw) {
    if (tollInfoRaw is! Map<String, dynamic>) {
      return null;
    }
    final estimated = tollInfoRaw['estimatedPrice'];
    if (estimated is! List || estimated.isEmpty) {
      return null;
    }

    final first = estimated.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final units = CoordinateUtils.parseDouble(first['units']) ?? 0;
    final nanos = CoordinateUtils.parseDouble(first['nanos']) ?? 0;
    final amount = units + (nanos / 1000000000);
    if (amount <= 0) {
      return null;
    }
    return amount;
  }

  String _cacheKey(LatLng origin, LatLng destination) {
    return '${origin.latitude.toStringAsFixed(5)},${origin.longitude.toStringAsFixed(5)}:${destination.latitude.toStringAsFixed(5)},${destination.longitude.toStringAsFixed(5)}';
  }

  int _haversineMeters(LatLng origin, LatLng destination) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(destination.latitude - origin.latitude);
    final dLng = _degreesToRadians(destination.longitude - origin.longitude);
    final a =
        _sinHalfSquared(dLat) +
        _cos(origin.latitude) * _cos(destination.latitude) * _sinHalfSquared(dLng);
    final c = 2 * _atan2Sqrt(a, 1 - a);
    return (earthRadiusMeters * c).round();
  }

  double _degreesToRadians(double degrees) => degrees * 0.017453292519943295;

  double _cos(double degrees) => math.cos(_degreesToRadians(degrees));

  double _sinHalfSquared(double angle) {
    final sinHalf = math.sin(angle / 2);
    return sinHalf * sinHalf;
  }

  double _atan2Sqrt(double a, double b) =>
      math.atan2(math.sqrt(a), math.sqrt(b));

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      while (true) {
        final byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

class _CachedRoute {
  final RouteResult data;
  final DateTime createdAt;

  const _CachedRoute(this.data, this.createdAt);
}

class ReverseGeocodeResult {
  final String? city;
  final String? state;

  const ReverseGeocodeResult({this.city, this.state});

  String? get cityStateLabel {
    final cityText = city?.trim() ?? '';
    final stateText = state?.trim() ?? '';
    if (cityText.isEmpty && stateText.isEmpty) {
      return null;
    }
    if (cityText.isEmpty) {
      return stateText;
    }
    if (stateText.isEmpty) {
      return cityText;
    }
    return '$cityText, $stateText';
  }
}
