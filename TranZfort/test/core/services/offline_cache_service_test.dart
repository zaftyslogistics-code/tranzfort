import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/services/offline_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineCacheService', () {
    late OfflineCacheService cacheService;
    late SharedPreferences prefs;

    setUp(() async {
      prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      cacheService = OfflineCacheService.instance;
      await cacheService.initialize();
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('clearAll() removes only cache keys with namespace prefix', () async {
      // Set a cache key
      cacheService.set(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'marketplace',
        ),
        {'data': 'test'},
      );

      // Set a non-cache key
      await prefs.setString('user_preference', 'value');

      // Verify both exist
      expect(prefs.getString('cache_user123:marketplace'), isNotNull);
      expect(prefs.getString('user_preference'), 'value');

      // Clear all cache
      cacheService.clearAll();

      // Verify only cache key is removed
      expect(prefs.getString('cache_user123:marketplace'), isNull);
      expect(prefs.getString('user_preference'), 'value');
    });

    test('clearByPrefix() removes only cache keys with matching prefix', () async {
      // Set cache keys with different prefixes
      cacheService.set(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'marketplace',
        ),
        {'data': 'marketplace_data'},
      );

      cacheService.set(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'trips',
        ),
        {'data': 'trips_data'},
      );

      // Verify both exist
      expect(prefs.getString('cache_user123:marketplace'), isNotNull);
      expect(prefs.getString('cache_user123:trips'), isNotNull);

      // Clear only marketplace prefix
      cacheService.clearByPrefix('user123:marketplace');

      // Verify only marketplace key is removed
      expect(prefs.getString('cache_user123:marketplace'), isNull);
      expect(prefs.getString('cache_user123:trips'), isNotNull);
    });

    test('corrupt cache JSON returns null and invalidates only that key', () async {
      // Set valid cache entry
      cacheService.set(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'valid',
        ),
        {'data': 'valid_data'},
      );

      // Set corrupt cache entry directly
      await prefs.setString('cache_user123:corrupt', 'invalid json {{{');

      // Verify valid entry works
      final validData = cacheService.get<Map<String, dynamic>>(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'valid',
        ),
      );
      expect(validData, isNotNull);

      // Verify corrupt entry returns null and is removed
      final corruptData = cacheService.get<Map<String, dynamic>>(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'corrupt',
        ),
      );
      expect(corruptData, isNull);
      expect(prefs.getString('cache_user123:corrupt'), isNull);
    });

    test('wrong schema version invalidates only that key', () async {
      // Manually set a cache entry with wrong version
      final key = cacheService.generateCacheKey(
        userId: 'user123',
        dataType: 'old_version',
      );

      await prefs.setString(
        key,
        '{"data":"test","timestamp":"2024-01-01T00:00:00.000Z","ttl":3600,"version":999}',
      );

      // Verify entry is invalidated and returns null
      final data = cacheService.get<Map<String, dynamic>>(key);
      expect(data, isNull);
      expect(prefs.getString(key), isNull);
    });

    test('expired cache invalidates only that key', () async {
      // Set cache entry with very short TTL
      cacheService.set(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'expired',
        ),
        {'data': 'test'},
        ttl: const Duration(milliseconds: 1),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify expired entry is invalidated
      final data = cacheService.get<Map<String, dynamic>>(
        cacheService.generateCacheKey(
          userId: 'user123',
          dataType: 'expired',
        ),
      );
      expect(data, isNull);
    });
  });
}
