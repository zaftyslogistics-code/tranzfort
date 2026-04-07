import 'dart:convert';
import 'dart:io';

import '../config/maps_config.dart';
import '../utils/coordinate_utils.dart';

class WeatherSnapshot {
  final double temperatureC;
  final String summary;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.summary,
  });
}

class WeatherService {
  final MapsConfig _mapsConfig;
  static final Map<String, _CachedWeather> _cache = <String, _CachedWeather>{};
  static const Duration _cacheTtl = Duration(minutes: 20);

  const WeatherService(this._mapsConfig);

  Future<WeatherSnapshot?> getCurrentWeather({
    required double lat,
    required double lng,
  }) async {
    final key = _cacheKey(lat, lng);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.createdAt) <= _cacheTtl) {
      return cached.snapshot;
    }

    if (!_mapsConfig.hasApiKey) {
      return null;
    }

    final uri = Uri.https(
      'weather.googleapis.com',
      '/v1/currentConditions:lookup',
      {
        'key': _mapsConfig.apiKey,
        'location.latitude': '$lat',
        'location.longitude': '$lng',
        'unitsSystem': 'METRIC',
      },
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final temp = (json['temperature'] as Map<String, dynamic>?)?['degrees'];
      final weatherText =
          (json['weatherCondition'] as Map<String, dynamic>?)?['description']
              ?.toString();

      final temperature = CoordinateUtils.parseDouble(temp);
      if (temperature == null || weatherText == null || weatherText.isEmpty) {
        return null;
      }

      final snapshot = WeatherSnapshot(
        temperatureC: temperature,
        summary: weatherText,
      );
      _cache[key] = _CachedWeather(snapshot, DateTime.now());
      return snapshot;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  String _cacheKey(double lat, double lng) {
    return '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }
}

class _CachedWeather {
  final WeatherSnapshot snapshot;
  final DateTime createdAt;

  const _CachedWeather(this.snapshot, this.createdAt);
}
