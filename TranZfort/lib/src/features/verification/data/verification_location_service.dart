import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';

class VerificationLocation {
  final String city;
  final String? state;
  final double latitude;
  final double longitude;
  final String source;

  const VerificationLocation({
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.source,
  });
}

class VerificationLocationService {
  final AssetBundle _assetBundle;
  final HttpClient Function() _httpClientFactory;
  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;

  List<Map<String, dynamic>>? _offlineCities;

  VerificationLocationService({
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

  Future<VerificationLocation?> captureSupplierVerificationLocation() async {
    try {
      final servicesEnabled = await _isLocationServiceEnabled();
      if (!servicesEnabled) {
        throw LocationServiceDisabledException();
      }

      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverException();
      }

      final position = await _getCurrentPosition();
      final googleResolved = await _reverseLookupWithGoogle(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (googleResolved != null) {
        return googleResolved;
      }

      return _reverseLookupOffline(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      rethrow;
    } on LocationPermissionDeniedException {
      rethrow;
    } on LocationPermissionDeniedForeverException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<VerificationLocation?> resolveManualSupplierVerificationLocation({
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
    return VerificationLocation(
      city: trimmedCity,
      state: resolvedState,
      latitude: latitude,
      longitude: longitude,
      source: 'manual_city_entry',
    );
  }

  Future<VerificationLocation?> _reverseLookupWithGoogle({
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
        return VerificationLocation(
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

  Future<VerificationLocation?> _reverseLookupOffline({
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

    return VerificationLocation(
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
    return AppConfig.googleMapsApiKey;
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

final verificationLocationServiceProvider = Provider<VerificationLocationService>((ref) {
  return VerificationLocationService();
});

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}

class LocationPermissionDeniedForeverException implements Exception {}
