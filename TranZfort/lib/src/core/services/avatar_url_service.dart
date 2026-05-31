import 'dart:collection';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../logger/app_logger.dart';
import '../utils/avatar_storage_path.dart';

/// Service for creating and caching signed URLs for avatar images.
/// Uses in-memory LRU cache with 1-hour expiration to reduce network requests.
class AvatarUrlService {
  final SupabaseClient? _client;

  final _cache = LRUCache<String, _CacheEntry>(maxSize: 100);
  final Map<String, Future<String?>> _inFlight = <String, Future<String?>>{};

  static const int _cacheExpirationSeconds = 3600;

  AvatarUrlService(this._client);

  Future<String?> getSignedUrl(String path) async {
    if (_client == null) {
      return null;
    }

    final normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final cachedEntry = _cache.get(normalized);
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.url;
    }

    final inFlight = _inFlight[normalized];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _resolveSignedUrl(normalized);
    _inFlight[normalized] = future;
    try {
      final signedUrl = await future;
      if (signedUrl != null) {
        _cache.put(normalized, _CacheEntry(signedUrl));
      }
      return signedUrl;
    } finally {
      _inFlight.remove(normalized);
    }
  }

  Future<String?> _resolveSignedUrl(String path) async {
    for (final candidate in AvatarStoragePath.storagePathCandidates(path)) {
      final signedUrl = await _generateSignedUrl(candidate);
      if (signedUrl != null) {
        return signedUrl;
      }
    }
    AppLogger.debug('AvatarUrlService: no signed URL for $path');
    return null;
  }

  Future<String?> _generateSignedUrl(String path) async {
    final buckets = path.contains('/profile_photo/')
        ? const ['profile-photos', 'verification-documents']
        : const ['verification-documents', 'profile-photos'];

    for (final bucket in buckets) {
      try {
        return await _client!.storage.from(bucket).createSignedUrl(path, _cacheExpirationSeconds);
      } catch (error) {
        AppLogger.debug('AvatarUrlService: $bucket/$path failed: $error');
        continue;
      }
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
  }

  int get cacheSize => _cache.length;
}

class _CacheEntry {
  final String url;
  final DateTime expiresAt;

  _CacheEntry(this.url) : expiresAt = DateTime.now().add(const Duration(seconds: AvatarUrlService._cacheExpirationSeconds));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class LRUCache<K, V> {
  final LinkedHashMap<K, V> _storage;
  final int maxSize;

  LRUCache({required this.maxSize}) : _storage = LinkedHashMap();

  V? get(K key) {
    if (_storage.containsKey(key)) {
      final value = _storage.remove(key);
      if (value != null) {
        _storage[key] = value;
      }
      return value;
    }
    return null;
  }

  void put(K key, V value) {
    if (_storage.containsKey(key)) {
      _storage.remove(key);
    } else if (_storage.length >= maxSize) {
      _storage.remove(_storage.keys.first);
    }
    _storage[key] = value;
  }

  void clear() {
    _storage.clear();
  }

  int get length => _storage.length;
}
