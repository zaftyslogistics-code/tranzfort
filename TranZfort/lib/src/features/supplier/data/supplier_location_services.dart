import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/osrm_route_snapshot_service.dart';
import '../../../core/services/route_snapshot_service.dart';

class PlaceSuggestion {
  final String label;
  final String city;
  final String? state;
  final double? lat;
  final double? lng;
  final String? placeId;
  final String source;

  const PlaceSuggestion({
    required this.label,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
    required this.placeId,
    required this.source,
  });

  bool get hasCoordinates => lat != null && lng != null;

  PlaceSuggestion copyWith({
    String? label,
    String? city,
    String? state,
    double? lat,
    double? lng,
    String? placeId,
    String? source,
  }) {
    return PlaceSuggestion(
      label: label ?? this.label,
      city: city ?? this.city,
      state: state ?? this.state,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeId: placeId ?? this.placeId,
      source: source ?? this.source,
    );
  }
}

typedef RoutePreview = RouteSnapshot;

abstract class SupplierLocationService {
  Future<List<PlaceSuggestion>> searchCities(String query);

  Future<PlaceSuggestion> resolveSuggestion(PlaceSuggestion suggestion);

  Future<RoutePreview?> fetchRoutePreview({
    required PlaceSuggestion origin,
    required PlaceSuggestion destination,
  });
}

class NetworkSupplierLocationService implements SupplierLocationService {
  final AssetBundle _assetBundle;
  final HttpClient Function() _httpClientFactory;
  final OsrmRouteSnapshotService _routeSnapshotService;

  List<Map<String, dynamic>>? _offlineCities;

  NetworkSupplierLocationService({
    AssetBundle? assetBundle,
    HttpClient Function()? httpClientFactory,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _httpClientFactory = httpClientFactory ?? HttpClient.new,
        _routeSnapshotService = OsrmRouteSnapshotService();

  @override
  Future<List<PlaceSuggestion>> searchCities(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const [];
    }

    debugPrint('[SupplierLocationSearch] ========== SEARCH START ==========');
    debugPrint('[SupplierLocationSearch] Searching for: "$query"');
    
    // Try Google Places API first
    final googleSuggestions = await _searchGoogleCities(trimmedQuery);
    if (googleSuggestions.isNotEmpty) {
      debugPrint('[SupplierLocationSearch] ========== USING GOOGLE PLACES API ==========');
      debugPrint('[SupplierLocationSearch] Source: Google Places API');
      debugPrint('[SupplierLocationSearch] Results: ${googleSuggestions.length} cities');
      debugPrint('[SupplierLocationSearch] First 3 results: ${googleSuggestions.take(3).map((s) => s.city).join(", ")}');
      return googleSuggestions;
    }

    debugPrint('[SupplierLocationSearch] ========== USING OFFLINE DATABASE ==========');
    debugPrint('[SupplierLocationSearch] Google Places API returned empty or failed');
    final offlineSuggestions = await _searchOfflineCities(trimmedQuery);
    debugPrint('[SupplierLocationSearch] Source: Offline Database');
    debugPrint('[SupplierLocationSearch] Results: ${offlineSuggestions.length} places');
    debugPrint('[SupplierLocationSearch] First 3 results: ${offlineSuggestions.take(3).map((s) => s.city).join(", ")}');
    debugPrint('[SupplierLocationSearch] ========== SEARCH END ==========');
    return offlineSuggestions;
  }

  @override
  Future<PlaceSuggestion> resolveSuggestion(PlaceSuggestion suggestion) async {
    if (suggestion.hasCoordinates || suggestion.placeId == null || suggestion.source != 'google_places') {
      return suggestion;
    }

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      return suggestion;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': suggestion.placeId!,
        'fields': 'geometry/location,address_component,formatted_address',
        'key': apiKey,
      },
    );

    try {
      final payload = await _getJson(uri);
      final result = payload['result'];
      if (result is! Map<String, dynamic>) {
        return suggestion;
      }

      final geometry = result['geometry'];
      final location = geometry is Map<String, dynamic> ? geometry['location'] : null;
      final lat = location is Map<String, dynamic> ? _readDouble(location['lat']) : null;
      final lng = location is Map<String, dynamic> ? _readDouble(location['lng']) : null;
      final addressComponents = (result['address_components'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final city = _extractAddressComponent(addressComponents, 'locality') ?? suggestion.city;
      final state = _extractAddressComponent(addressComponents, 'administrative_area_level_1') ?? suggestion.state;
      final label = (result['formatted_address'] ?? suggestion.label).toString();

      return suggestion.copyWith(
        label: label,
        city: city,
        state: state,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return suggestion;
    }
  }

  @override
  Future<RoutePreview?> fetchRoutePreview({
    required PlaceSuggestion origin,
    required PlaceSuggestion destination,
  }) async {
    return _routeSnapshotService.fetchDrivingRouteSnapshot(
      originLat: origin.lat,
      originLng: origin.lng,
      destinationLat: destination.lat,
      destinationLng: destination.lng,
    );
  }

  Future<List<PlaceSuggestion>> _searchGoogleCities(String query) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[SupplierLocationSearch] Google Maps API key is empty');
      return const [];
    }

    debugPrint('[SupplierLocationSearch] Using Google Maps API key (length: ${apiKey.length})');

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      <String, String>{
        'input': query,
        'types': '(cities)',
        'components': 'country:in',
        'key': apiKey,
      },
    );

    try {
      debugPrint('[SupplierLocationSearch] Calling Google Places API');
      final payload = await _getJson(uri);
      final predictions = payload['predictions'];
      if (predictions is! List) {
        debugPrint('[SupplierLocationSearch] Google API response: predictions is not a List');
        return const [];
      }

      debugPrint('[SupplierLocationSearch] Google API returned ${predictions.length} predictions');
      return predictions
          .whereType<Map<String, dynamic>>()
          .map((prediction) {
            final description = (prediction['description'] ?? '').toString();
            final parts = description.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
            final city = parts.isNotEmpty ? parts.first : description;
            final state = parts.length > 1 ? parts[1] : null;
            debugPrint('[SupplierLocationSearch] Google result: "$city, $state"');
            return PlaceSuggestion(
              label: description,
              city: city,
              state: state,
              lat: null,
              lng: null,
              placeId: prediction['place_id']?.toString(),
              source: 'google_places',
            );
          })
          .toList(growable: false);
    } catch (e, stackTrace) {
      debugPrint('[SupplierLocationSearch] Google API error: $e');
      if (kDebugMode) {
        debugPrint('[SupplierLocationSearch] Stack trace: $stackTrace');
      }
      return const [];
    }
  }

  Future<List<PlaceSuggestion>> _searchOfflineCities(String query) async {
    final normalized = query.toLowerCase();
    final cities = await _loadOfflineCities();
    
    // indian_cities.json doesn't have place_type field, so we can't filter by city/town
    // Use district field if available to get main city name instead of village
    debugPrint('[SupplierLocationSearch] Offline database has ${cities.length} total places');
    
    final results = cities
        .where((city) => _readCityName(city).toLowerCase().contains(normalized))
        .take(10)
        .map(
          (city) {
            final cityName = (city['district']?.isNotEmpty == true) ? city['district']!.toString() : _readCityName(city);
            final stateName = (city['state'] ?? '').toString();
            debugPrint('[SupplierLocationSearch] Offline result: "$cityName, $stateName" (using district: ${city['district'] != null})');
            return PlaceSuggestion(
              // Use district if available (main city), otherwise use city name (may be village)
              label: '$cityName, $stateName',
              city: cityName,
              state: stateName,
              lat: _readDouble(city['lat']),
              lng: _readDouble(city['lng']),
              placeId: null,
              source: 'offline_asset',
            );
          },
        )
        .toList(growable: false);
    
    debugPrint('[SupplierLocationSearch] Offline search returned ${results.length} results');
    return results;
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

  static String? _extractAddressComponent(
    List<Map<String, dynamic>> components,
    String type,
  ) {
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

  static String _readCityName(Map<String, dynamic> city) {
    return (city['name'] ?? city['city'] ?? '').toString();
  }
}

final supplierLocationServiceProvider = Provider<SupplierLocationService>((ref) {
  return NetworkSupplierLocationService();
});
