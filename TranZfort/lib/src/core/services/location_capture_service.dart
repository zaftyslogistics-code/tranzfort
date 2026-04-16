import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Location data model for captured or resolved locations
class LocationData {
  final String city;
  final String? state;
  final double latitude;
  final double longitude;
  final String source;

  const LocationData({
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  @override
  String toString() => 'LocationData(city: $city, state: $state, lat: $latitude, lng: $longitude, source: $source)';
}

/// Exception thrown when location services (GPS) are disabled
class LocationServiceDisabledException implements Exception {
  final String message;
  const LocationServiceDisabledException({this.message = 'Location services are disabled'});
  @override
  String toString() => message;
}

/// Exception thrown when location permission is denied
class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException({this.message = 'Location permission denied'});
  @override
  String toString() => message;
}

/// Exception thrown when location permission is permanently denied
class LocationPermissionDeniedForeverException implements Exception {
  final String message;
  const LocationPermissionDeniedForeverException({this.message = 'Location permission permanently denied'});
  @override
  String toString() => message;
}

/// General-purpose location capture service for onboarding and verification
class LocationCaptureService {
  final AssetBundle _assetBundle;
  final HttpClient Function() _httpClientFactory;
  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;

  List<Map<String, dynamic>>? _offlineCities;

  LocationCaptureService({
    AssetBundle? assetBundle,
    HttpClient Function()? httpClientFactory,
    Future<bool> Function()? isLocationServiceEnabledFn,
    Future<LocationPermission> Function()? checkPermissionFn,
    Future<LocationPermission> Function()? requestPermissionFn,
    Future<Position> Function()? getCurrentPositionFn,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _httpClientFactory = httpClientFactory ?? HttpClient.new,
        _isLocationServiceEnabled = isLocationServiceEnabledFn ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermissionFn ?? Geolocator.checkPermission,
        _requestPermission = requestPermissionFn ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPositionFn ?? _defaultGetCurrentPosition;

  /// Capture current GPS location and resolve city/state
  /// Throws [LocationServiceDisabledException] if GPS is disabled
  /// Throws [LocationPermissionDeniedException] if permission denied (once)
  /// Throws [LocationPermissionDeniedForeverException] if permission denied forever
  Future<LocationData> captureLocation() async {
    try {
      final servicesEnabled = await _isLocationServiceEnabled();
      if (!servicesEnabled) {
        throw const LocationServiceDisabledException();
      }

      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedForeverException();
      }

      final position = await _getCurrentPosition();
      final googleResolved = await _reverseLookupWithGoogle(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (googleResolved != null) {
        return googleResolved;
      }

      final offlineResult = await _reverseLookupOffline(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (offlineResult != null) {
        return offlineResult;
      }

      throw Exception('Unable to resolve location from coordinates');
    } on LocationServiceDisabledException {
      rethrow;
    } on LocationPermissionDeniedException {
      rethrow;
    } on LocationPermissionDeniedForeverException {
      rethrow;
    } catch (e) {
      throw Exception('Location capture failed: $e');
    }
  }

  /// Resolve location from manually entered city/state
  /// Looks up coordinates from offline city database
  Future<LocationData?> resolveManualLocation({
    required String city,
    String? state,
  }) async {
    final trimmedCity = city.trim();
    final trimmedState = state?.trim();
    if (trimmedCity.isEmpty) {
      return null;
    }

    final cities = await _loadOfflineCities();
    Map<String, dynamic>? matchedCity;
    for (final candidate in cities) {
      final candidateName = (candidate['name'] ?? candidate['city'] ?? '').toString().trim().toLowerCase();
      final candidateState = (candidate['state'] ?? '').toString().trim().toLowerCase();
      if (candidateName != trimmedCity.toLowerCase()) {
        continue;
      }
      if ((trimmedState ?? '').isNotEmpty && candidateState != trimmedState!.toLowerCase()) {
        continue;
      }
      matchedCity = candidate;
      break;
    }

    final latitude = _readDouble(matchedCity?['lat']);
    final longitude = _readDouble(matchedCity?['lng']);
    
    // Validate coordinates - reject 0,0 or null coordinates
    if (latitude == null || longitude == null || latitude == 0 || longitude == 0) {
      return null;  // City not found in database or invalid coordinates
    }
    
    final matchedState = matchedCity == null ? null : matchedCity['state']?.toString();
    final resolvedState = (trimmedState == null || trimmedState.isEmpty)
        ? matchedState
        : trimmedState;
    return LocationData(
      city: trimmedCity,
      state: resolvedState,
      latitude: latitude,
      longitude: longitude,
      source: 'manual_city_entry',
    );
  }

  Future<LocationData?> _reverseLookupWithGoogle({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = _readGoogleMapsApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'latlng': '$latitude,$longitude',
        'key': apiKey,
      },
    );

    try {
      final payload = await _getJson(uri);
      final results = payload['results'];
      if (results is! List || results.isEmpty) {
        return null;
      }
      for (final entry in results.whereType<Map<String, dynamic>>()) {
        final addressComponents = (entry['address_components'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        // Prioritize district/city (administrative_area_level_2) over locality (which can be village/sub-district)
        final city = _extractAddressComponent(addressComponents, 'administrative_area_level_2') ??
            _extractAddressComponent(addressComponents, 'locality');
        if ((city ?? '').trim().isEmpty) {
          continue;
        }
        final state = _extractAddressComponent(addressComponents, 'administrative_area_level_1');
        return LocationData(
          city: city!.trim(),
          state: state?.trim(),
          latitude: latitude,
          longitude: longitude,
          source: 'google_geocode',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<LocationData?> _reverseLookupOffline({
    required double latitude,
    required double longitude,
  }) async {
    final cities = await _loadOfflineCities();
    if (cities.isEmpty) {
      return null;
    }

    // Filter for cities/towns only (exclude villages) to get main district/city
    final citiesAndTowns = cities.where((city) {
      final placeType = (city['place_type'] ?? '').toString().toLowerCase();
      return placeType == 'city' || placeType == 'town';
    }).toList();

    // If no cities/towns found, fall back to all places
    final searchCities = citiesAndTowns.isNotEmpty ? citiesAndTowns : cities;

    Map<String, dynamic>? nearest;
    double? bestDistanceKm;
    for (final city in searchCities) {
      final cityLat = _readDouble(city['lat']);
      final cityLng = _readDouble(city['lng']);
      if (cityLat == null || cityLng == null) {
        continue;
      }
      final distanceKm = _distanceKm(latitude, longitude, cityLat, cityLng);
      if (bestDistanceKm == null || distanceKm < bestDistanceKm) {
        bestDistanceKm = distanceKm;
        nearest = city;
      }
    }

    if (nearest == null) {
      return null;
    }

    // Use district if available, otherwise use city name
    final district = nearest['district']?.toString();
    final cityName = (nearest['name'] ?? nearest['city'] ?? '').toString();

    return LocationData(
      city: (district?.isNotEmpty == true) ? district! : cityName,
      state: nearest['state']?.toString(),
      latitude: latitude,
      longitude: longitude,
      source: 'offline_nearest_city',
    );
  }

  Future<List<Map<String, dynamic>>> _loadOfflineCities() async {
    if (_offlineCities != null) {
      return _offlineCities!;
    }

    try {
      final jsonString = await _assetBundle.loadString('assets/data/indian_cities.json');
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        _offlineCities = const <Map<String, dynamic>>[];
        return _offlineCities!;
      }
      _offlineCities = decoded.whereType<Map<String, dynamic>>().toList(growable: false);
      return _offlineCities!;
    } catch (_) {
      _offlineCities = const <Map<String, dynamic>>[];
      return _offlineCities!;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = _httpClientFactory();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
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

  static String? _extractAddressComponent(List<Map<String, dynamic>> components, String type) {
    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? const <dynamic>[]).map((value) => value.toString());
      if (types.contains(type)) {
        return component['long_name']?.toString();
      }
    }
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  static String _readGoogleMapsApiKey() {
    try {
      return dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<Position> _defaultGetCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}

/// Provider for LocationCaptureService
final locationCaptureServiceProvider = Provider<LocationCaptureService>((ref) {
  return LocationCaptureService();
});
