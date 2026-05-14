import 'dart:collection';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for creating and caching signed URLs for avatar images.
/// Uses in-memory LRU cache with 1-hour expiration to reduce network requests.
class AvatarUrlService {
  final SupabaseClient? _client;
  
  // LRU cache: key = storage path, value = (signed URL, expiration timestamp)
  final _cache = LRUCache<String, _CacheEntry>(maxSize: 100);
  
  static const int _cacheExpirationSeconds = 3600; // 1 hour

  AvatarUrlService(this._client);

  /// Gets a signed URL for the given storage path.
  /// Checks cache first, then generates signed URL if not cached or expired.
  /// Returns null if the client is not available or if the operation fails.
  Future<String?> getSignedUrl(String path) async {
    if (_client == null) {
      return null;
    }

    // Check cache first
    final cachedEntry = _cache.get(path);
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.url;
    }

    // Generate new signed URL
    final signedUrl = await _generateSignedUrl(path);
    if (signedUrl != null) {
      // Cache the result
      _cache.put(path, _CacheEntry(signedUrl));
    }

    return signedUrl;
  }

  /// Generates a signed URL by trying both buckets.
  Future<String?> _generateSignedUrl(String path) async {
    try {
      // Try verification-documents bucket first (for user's own profile)
      try {
        return await _client!.storage
            .from('verification-documents')
            .createSignedUrl(path, _cacheExpirationSeconds);
      } catch (_) {
        // Fallback to profile-photos bucket (for supplier profiles)
        return await _client!.storage
            .from('profile-photos')
            .createSignedUrl(path, _cacheExpirationSeconds);
      }
    } catch (_) {
      return null;
    }
  }

  /// Clears the entire cache.
  /// Should be called on logout to prevent showing stale avatars.
  void clearCache() {
    _cache.clear();
  }

  /// Returns the current cache size for debugging.
  int get cacheSize => _cache.length;
}

/// Internal cache entry with expiration tracking.
class _CacheEntry {
  final String url;
  final DateTime expiresAt;

  _CacheEntry(this.url) : expiresAt = DateTime.now().add(const Duration(seconds: 3600));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Simple LRU (Least Recently Used) cache implementation.
class LRUCache<K, V> {
  final LinkedHashMap<K, V> _storage;
  final int maxSize;

  LRUCache({required this.maxSize}) : _storage = LinkedHashMap();

  V? get(K key) {
    if (_storage.containsKey(key)) {
      // Move to end (most recently used)
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
      // Update existing: remove and re-add to move to end
      _storage.remove(key);
    } else if (_storage.length >= maxSize) {
      // Remove least recently used (first item)
      _storage.remove(_storage.keys.first);
    }
    _storage[key] = value;
  }

  void clear() {
    _storage.clear();
  }

  int get length => _storage.length;
}
