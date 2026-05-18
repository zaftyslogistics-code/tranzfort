import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/utils/map_readers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TruckerCitySuggestion {
  final String city;
  final String state;
  final double? lat;
  final double? lng;
  final String? placeId;
  final String source;

  const TruckerCitySuggestion({
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
    this.placeId,
    required this.source,
  });

  String get label => '$city, $state';

  TruckerCitySuggestion copyWith({
    String? city,
    String? state,
    double? lat,
    double? lng,
    String? placeId,
    String? source,
  }) {
    return TruckerCitySuggestion(
      city: city ?? this.city,
      state: state ?? this.state,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeId: placeId ?? this.placeId,
      source: source ?? this.source,
    );
  }
}

abstract class TruckerCitySearchService {
  Future<List<TruckerCitySuggestion>> searchCities(String query);
}

class NetworkTruckerCitySearchService implements TruckerCitySearchService {
  final AssetBundle _assetBundle;
  final HttpClient Function() _httpClientFactory;
  List<Map<String, dynamic>>? _offlineCities;

  NetworkTruckerCitySearchService({
    AssetBundle? assetBundle,
    HttpClient Function()? httpClientFactory,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _httpClientFactory = httpClientFactory ?? HttpClient.new;

  @override
  Future<List<TruckerCitySuggestion>> searchCities(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const <TruckerCitySuggestion>[];
    }

    AppLogger.info('[TruckerLocationSearch] ========== SEARCH START ==========');
    AppLogger.info('[TruckerLocationSearch] Searching for: "$query"');
    
    // Try Google Places API first
    final googleSuggestions = await _searchGoogleCities(trimmedQuery);
    if (googleSuggestions.isNotEmpty) {
      AppLogger.info('[TruckerLocationSearch] ========== USING GOOGLE PLACES API ==========');
      AppLogger.info('[TruckerLocationSearch] Source: Google Places API');
      AppLogger.info('[TruckerLocationSearch] Results: ${googleSuggestions.length} cities');
      AppLogger.info('[TruckerLocationSearch] First 3 results: ${googleSuggestions.take(3).map((s) => s.city).join(", ")}');
      return googleSuggestions;
    }

    AppLogger.info('[TruckerLocationSearch] ========== USING OFFLINE DATABASE ==========');
    AppLogger.warning('[TruckerLocationSearch] Google Places API returned empty or failed');
    final offlineSuggestions = await _searchOfflineCities(trimmedQuery);
    AppLogger.info('[TruckerLocationSearch] Source: Offline Database');
    AppLogger.info('[TruckerLocationSearch] Results: ${offlineSuggestions.length} places');
    AppLogger.info('[TruckerLocationSearch] First 3 results: ${offlineSuggestions.take(3).map((s) => s.city).join(", ")}');
    AppLogger.info('[TruckerLocationSearch] ========== SEARCH END ==========');
    return offlineSuggestions;
  }

  Future<List<TruckerCitySuggestion>> _searchGoogleCities(String query) async {
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      AppLogger.warning('[TruckerLocationSearch] Google Maps API key is empty');
      return const [];
    }

    AppLogger.info('[TruckerLocationSearch] Using Google Maps API key (length: ${apiKey.length})');

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
      AppLogger.info('[TruckerLocationSearch] Calling Google Places API');
      final payload = await _getJson(uri);
      final predictions = payload['predictions'];
      if (predictions is! List) {
        AppLogger.warning('[TruckerLocationSearch] Google API response: predictions is not a List');
        return const [];
      }

      AppLogger.info('[TruckerLocationSearch] Google API returned ${predictions.length} predictions');
      final suggestions = predictions
          .whereType<Map<String, dynamic>>()
          .map((prediction) {
            final description = (prediction['description'] ?? '').toString();
            final parts = description.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
            final city = parts.isNotEmpty ? parts.first : description;
            final state = parts.length > 1 ? parts[1] : null;
            AppLogger.info('[TruckerLocationSearch] Google result: "$city, $state"');
            return TruckerCitySuggestion(
              city: city,
              state: state ?? '',
              lat: null,
              lng: null,
              placeId: prediction['place_id']?.toString(),
              source: 'google_places',
            );
          })
          .toList(growable: false);
      return suggestions.cast<TruckerCitySuggestion>().toList();
    } catch (e, stackTrace) {
      AppLogger.warning('[TruckerLocationSearch] Google API error: $e');
      AppLogger.info('[TruckerLocationSearch] Stack trace: $stackTrace');
      return const [];
    }
  }

  Future<List<TruckerCitySuggestion>> _searchOfflineCities(String query) async {
    final normalized = query.toLowerCase();
    final cities = await _loadOfflineCities();
    
    // indian_cities.json doesn't have place_type field, so we can't filter by city/town
    // Just use district field if available to get main city name instead of village
    AppLogger.info('[TruckerLocationSearch] Offline database has ${cities.length} total places');
    
    final results = cities
        .where((city) => _readCityName(city).toLowerCase().contains(normalized))
        .take(20)
        .map(
          (city) {
            final cityName = (city['district']?.isNotEmpty == true) ? city['district']!.toString() : _readCityName(city);
            final stateName = (city['state'] ?? '').toString();
            AppLogger.info('[TruckerLocationSearch] Offline result: "$cityName, $stateName" (using district: ${city['district'] != null})');
            return TruckerCitySuggestion(
              city: cityName,
              state: stateName,
              lat: readDoubleNullable(city['lat']),
              lng: readDoubleNullable(city['lng']),
              placeId: null,
              source: 'offline_asset',
            );
          },
        )
        .toList(growable: false);
    
    AppLogger.info('[TruckerLocationSearch] Offline search returned ${results.length} results');
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

  String _readCityName(Map<String, dynamic> city) {
    return (city['name'] ?? city['city'] ?? '').toString();
  }
}

final truckerCitySearchServiceProvider = Provider<TruckerCitySearchService>((ref) {
  return NetworkTruckerCitySearchService();
});
