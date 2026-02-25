import 'dart:convert';
import 'dart:io';

import '../config/maps_config.dart';

class CitySuggestion {
  final String city;
  final String state;
  final double? lat;
  final double? lng;

  const CitySuggestion({
    required this.city,
    required this.state,
    this.lat,
    this.lng,
  });

  String get displayName => '$city, $state';
}

class CitySearchService {
  final MapsConfig _mapsConfig;

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

  Future<List<CitySuggestion>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      return const [];
    }

    if (_mapsConfig.hasPlacesApiKey) {
      final online = await _searchGooglePlaces(normalized);
      if (online.isNotEmpty) {
        return online;
      }
    }

    return _fallbackCities
        .where(
          (city) =>
              city.city.toLowerCase().contains(normalized) ||
              city.state.toLowerCase().contains(normalized),
        )
        .take(8)
        .toList();
  }

  Future<List<CitySuggestion>> _searchGooglePlaces(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encoded&types=(cities)&components=country:in&key=${_mapsConfig.placesApiKey}',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        return const [];
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final predictions = (json['predictions'] as List<dynamic>? ?? const []);

      return predictions
          .take(8)
          .map((item) {
            final map = item as Map<String, dynamic>;
            final terms = (map['terms'] as List<dynamic>? ?? const []);
            final city = terms.isNotEmpty
                ? (terms.first as Map<String, dynamic>)['value']?.toString() ??
                      ''
                : '';
            final state = terms.length > 1
                ? (terms[1] as Map<String, dynamic>)['value']?.toString() ?? ''
                : '';
            return CitySuggestion(city: city, state: state);
          })
          .where((item) => item.city.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
}
