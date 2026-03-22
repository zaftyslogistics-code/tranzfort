import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TruckerCitySuggestion {
  final String city;
  final String state;
  final double? lat;
  final double? lng;

  const TruckerCitySuggestion({
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
  });

  String get label => '$city, $state';
}

abstract class TruckerCitySearchService {
  Future<List<TruckerCitySuggestion>> searchCities(String query);
}

class OfflineTruckerCitySearchService implements TruckerCitySearchService {
  final AssetBundle _assetBundle;
  List<Map<String, dynamic>>? _offlineCities;

  OfflineTruckerCitySearchService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  @override
  Future<List<TruckerCitySuggestion>> searchCities(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      return const <TruckerCitySuggestion>[];
    }

    final cities = await _loadOfflineCities();
    return cities
        .where((city) => _readCityName(city).toLowerCase().contains(normalized))
        .take(20)
        .map(
          (city) => TruckerCitySuggestion(
            city: _readCityName(city),
            state: (city['state'] ?? '').toString(),
            lat: _readDouble(city['lat']),
            lng: _readDouble(city['lng']),
          ),
        )
        .toList(growable: false);
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

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString());
  }

  String _readCityName(Map<String, dynamic> city) {
    return (city['name'] ?? city['city'] ?? '').toString();
  }
}

final truckerCitySearchServiceProvider = Provider<TruckerCitySearchService>((ref) {
  return OfflineTruckerCitySearchService();
});
