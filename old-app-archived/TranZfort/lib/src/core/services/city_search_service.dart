import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../config/maps_config.dart';
import '../utils/coordinate_utils.dart';
import '../utils/error_logger.dart';

enum CitySearchMode { google, fallback, offline }

class CitySearchResult {
  final List<CitySuggestion> suggestions;
  final CitySearchMode mode;
  final String? errorMessage;

  const CitySearchResult({
    required this.suggestions,
    required this.mode,
    this.errorMessage,
  });
}

class CitySuggestion {
  final String city;
  final String state;
  final double? lat;
  final double? lng;
  final String? placeId;

  const CitySuggestion({
    required this.city,
    required this.state,
    this.lat,
    this.lng,
    this.placeId,
  });

  CitySuggestion copyWith({
    String? city,
    String? state,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    return CitySuggestion(
      city: city ?? this.city,
      state: state ?? this.state,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeId: placeId ?? this.placeId,
    );
  }

  String get displayName => '$city, $state';
}

class CitySearchService {
  final MapsConfig _mapsConfig;
  static List<CitySuggestion>? _jsonFallbackCache;

  const CitySearchService(this._mapsConfig);

  static const List<CitySuggestion> _fallbackCities = [
    CitySuggestion(
      city: 'Mumbai',
      state: 'Maharashtra',
      lat: 19.0760,
      lng: 72.8777,
    ),
    CitySuggestion(
      city: 'Pune',
      state: 'Maharashtra',
      lat: 18.5204,
      lng: 73.8567,
    ),
    CitySuggestion(
      city: 'Nagpur',
      state: 'Maharashtra',
      lat: 21.1458,
      lng: 79.0882,
    ),
    CitySuggestion(
      city: 'Chandrapur',
      state: 'Maharashtra',
      lat: 19.9615,
      lng: 79.2961,
    ),
    CitySuggestion(
      city: 'Nashik',
      state: 'Maharashtra',
      lat: 19.9975,
      lng: 73.7898,
    ),
    CitySuggestion(city: 'Delhi', state: 'Delhi', lat: 28.6139, lng: 77.2090),
    CitySuggestion(
      city: 'Jaipur',
      state: 'Rajasthan',
      lat: 26.9124,
      lng: 75.7873,
    ),
    CitySuggestion(
      city: 'Ahmedabad',
      state: 'Gujarat',
      lat: 23.0225,
      lng: 72.5714,
    ),
    CitySuggestion(city: 'Surat', state: 'Gujarat', lat: 21.1702, lng: 72.8311),
    CitySuggestion(
      city: 'Indore',
      state: 'Madhya Pradesh',
      lat: 22.7196,
      lng: 75.8577,
    ),
    CitySuggestion(
      city: 'Bhopal',
      state: 'Madhya Pradesh',
      lat: 23.2599,
      lng: 77.4126,
    ),
    CitySuggestion(
      city: 'Lucknow',
      state: 'Uttar Pradesh',
      lat: 26.8467,
      lng: 80.9462,
    ),
    CitySuggestion(
      city: 'Kanpur',
      state: 'Uttar Pradesh',
      lat: 26.4499,
      lng: 80.3319,
    ),
    CitySuggestion(
      city: 'Kolkata',
      state: 'West Bengal',
      lat: 22.5726,
      lng: 88.3639,
    ),
    CitySuggestion(city: 'Patna', state: 'Bihar', lat: 25.5941, lng: 85.1376),
    CitySuggestion(
      city: 'Ranchi',
      state: 'Jharkhand',
      lat: 23.3441,
      lng: 85.3096,
    ),
    CitySuggestion(
      city: 'Bengaluru',
      state: 'Karnataka',
      lat: 12.9716,
      lng: 77.5946,
    ),
    CitySuggestion(
      city: 'Chennai',
      state: 'Tamil Nadu',
      lat: 13.0827,
      lng: 80.2707,
    ),
    CitySuggestion(
      city: 'Hyderabad',
      state: 'Telangana',
      lat: 17.3850,
      lng: 78.4867,
    ),
    CitySuggestion(
      city: 'Visakhapatnam',
      state: 'Andhra Pradesh',
      lat: 17.6868,
      lng: 83.2185,
    ),
  ];

  Future<CitySearchResult> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      return const CitySearchResult(suggestions: [], mode: CitySearchMode.offline);
    }

    if (_mapsConfig.canUsePlaces) {
      debugPrint('Attempting Google Places search for: $query');
      final online = await _searchGooglePlaces(normalized);
      if (online.isNotEmpty) {
        debugPrint('Google Places returned ${online.length} results');
        return CitySearchResult(
          suggestions: online,
          mode: CitySearchMode.google,
        );
      }
      debugPrint('Google Places failed or returned empty, using fallback');
    }

    final jsonFallback = await _searchJsonFallback(normalized);
    if (jsonFallback.isNotEmpty) {
      return CitySearchResult(
        suggestions: jsonFallback,
        mode: CitySearchMode.fallback,
        errorMessage: _mapsConfig.canUsePlaces
            ? 'Using offline database (Google Places unavailable)'
            : null,
      );
    }

    final offlineResults = _fallbackCities
        .where(
          (city) =>
              city.city.toLowerCase().contains(normalized) ||
              city.state.toLowerCase().contains(normalized),
        )
        .take(8)
        .toList();

    return CitySearchResult(
      suggestions: offlineResults,
      mode: CitySearchMode.offline,
      errorMessage: _mapsConfig.canUsePlaces
          ? 'Limited results (Google Places unavailable)'
          : null,
    );
  }

  Future<List<CitySuggestion>> _searchJsonFallback(String normalized) async {
    try {
      _jsonFallbackCache ??= await _loadJsonFallback();
      return _jsonFallbackCache!
          .where(
            (city) =>
                city.city.toLowerCase().contains(normalized) ||
                city.state.toLowerCase().contains(normalized),
          )
          .take(8)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CitySuggestion>> _loadJsonFallback() async {
    final raw = await rootBundle.loadString('assets/data/indian_locations.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) {
          final map = item as Map<String, dynamic>;
          return CitySuggestion(
            city: (map['city'] ?? '').toString(),
            state: (map['state'] ?? '').toString(),
            lat: CoordinateUtils.parseDouble(map['lat']),
            lng: CoordinateUtils.parseDouble(map['lng']),
          );
        })
        .where((item) => item.city.isNotEmpty)
        .toList();
  }

  Future<List<CitySuggestion>> _searchGooglePlaces(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encoded&types=(cities)&components=country:in&key=${_mapsConfig.apiKey}',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint('Google Places API status code: ${response.statusCode}');
        debugPrint('Request URL: $uri');
        return const [];
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final predictions = (json['predictions'] as List<dynamic>? ?? const []);

      final items = await Future.wait(
        predictions.take(8).map((item) async {
            final map = item as Map<String, dynamic>;
            final terms = (map['terms'] as List<dynamic>? ?? const []);
            final city = terms.isNotEmpty
                ? (terms.first as Map<String, dynamic>)['value']?.toString() ??
                      ''
                : '';
            final state = terms.length > 1
                ? (terms[1] as Map<String, dynamic>)['value']?.toString() ?? ''
                : '';
            final placeId = map['place_id']?.toString();
            return CitySuggestion(
              city: city,
              state: state,
              placeId: placeId,
            );
          }),
      );
      return items.where((item) => item.city.isNotEmpty).toList();
    } catch (e) {
      ErrorLogger.logNetworkError(
        'Google Places API',
        e,
      );
      debugPrint('Google Places API error: $e');
      debugPrint('Request URL: $uri');
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  Future<(double, double)?> _fetchPlaceLatLng(String placeId) async {
    if (!_mapsConfig.canUseGeocoding) {
      return null;
    }

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry/location&key=${_mapsConfig.apiKey}',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final result = json['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = CoordinateUtils.parseDouble(location?['lat']);
      final lng = CoordinateUtils.parseDouble(location?['lng']);
      if (lat == null || lng == null) return null;
      return (lat, lng);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<CitySuggestion> resolveSelection(CitySuggestion selected) async {
    if (selected.lat != null && selected.lng != null) {
      return selected;
    }

    final placeId = selected.placeId;
    if (placeId == null || placeId.isEmpty) {
      return selected;
    }

    final latLng = await _fetchPlaceLatLng(placeId);
    if (latLng == null) {
      return selected;
    }

    return selected.copyWith(lat: latLng.$1, lng: latLng.$2);
  }
}
