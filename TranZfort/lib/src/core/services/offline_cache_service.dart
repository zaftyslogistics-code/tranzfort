import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/type_safety.dart';

/// Cache entry model for storing cached data with metadata.
class CacheEntry {
  final String data;
  final DateTime timestamp;
  final Duration ttl;
  final int version;

  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.version = 1,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
      ttl: Duration(seconds: json['ttl'] as int),
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inSeconds,
      'version': version,
    };
  }

  /// Check if the cache entry is expired.
  bool get isExpired {
    return DateTime.now().isAfter(timestamp.add(ttl));
  }
}

/// Service for caching read models offline.
/// Uses SharedPreferences for simple key-value storage with TTL support.
class OfflineCacheService {
  OfflineCacheService._();

  static OfflineCacheService? _instance;
  SharedPreferences? _prefs;

  /// Current cache schema version. Increment when cache data shapes change.
  static const int currentSchemaVersion = 1;

  /// Namespace prefix for all cache keys to prevent clearAll() from deleting non-cache keys.
  static const String _namespace = 'cache_';

  /// Maximum number of cache entries before eviction kicks in.
  static const int _maxEntries = 200;

  /// Maximum total cache size in bytes (~5 MB) before eviction.
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  /// Get the singleton instance.
  static OfflineCacheService get instance {
    _instance ??= OfflineCacheService._();
    return _instance!;
  }

  /// Initialize the service.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _prefsInstance {
    if (_prefs == null) {
      throw StateError('OfflineCacheService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  /// Generate a cache key from components.
  /// 
  /// The key includes: userId, userRole, dataType, and query parameters.
  /// This ensures cache isolation between users and query variations.
  /// 
  /// All keys are prefixed with 'cache_' namespace to prevent clearAll() 
  /// from deleting non-cache SharedPreferences keys.
  String generateCacheKey({
    required String userId,
    String? userRole,
    required String dataType,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? paginationParams,
  }) {
    final buffer = StringBuffer();
    buffer.write(_namespace);
    buffer.write(userId);
    
    if (userRole != null) {
      buffer.write(':$userRole');
    }
    
    buffer.write(':$dataType');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final sortedParams = <String, String>{};
      queryParams.forEach((key, value) {
        sortedParams[key] = value.toString();
      });
      final sortedKeys = sortedParams.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write(':$key=${sortedParams[key]}');
      }
    }
    
    if (paginationParams != null && paginationParams.isNotEmpty) {
      final sortedParams = <String, String>{};
      paginationParams.forEach((key, value) {
        sortedParams[key] = value.toString();
      });
      final sortedKeys = sortedParams.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write(':$key=${sortedParams[key]}');
      }
    }
    
    return buffer.toString();
  }

  /// Get cached data for the given key.
  /// 
  /// Returns null if:
  /// - Key doesn't exist in cache
  /// - Cache entry is expired
  /// - Cache entry is corrupt
  /// - Cache entry schema version doesn't match
  /// 
  /// Use generic type parameter [T] to deserialize JSON to the expected type.
  T? get<T>(String key) {
    try {
      final jsonStr = _prefsInstance.getString(key);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(json);
      
      if (entry.version != currentSchemaVersion) {
        invalidate(key);
        return null;
      }
      
      if (entry.isExpired) {
        invalidate(key);
        return null;
      }
      
      return safeCast<T>(jsonDecode(entry.data));
    } catch (e) {
      invalidate(key);
      return null;
    }
  }

  /// Set cached data for the given key with optional TTL.
  /// 
  /// [key] - The cache key (use generateCacheKey() for consistency)
  /// [data] - The data to cache (will be JSON serialized)
  /// [ttl] - Time-to-live for the cache entry
  void set<T>(String key, T data, {Duration? ttl}) {
    try {
      final jsonStr = jsonEncode(data);
      final entry = CacheEntry(
        data: jsonStr,
        timestamp: DateTime.now(),
        ttl: ttl ?? const Duration(hours: 1),
        version: currentSchemaVersion,
      );
      final entryJson = jsonEncode(entry.toJson());
      _prefsInstance.setString(key, entryJson);
      
      _evictIfNeeded();
    } catch (e) {
      // Silently fail on cache write errors
    }
  }

  /// Evict oldest entries if cache exceeds size or count limits.
  void _evictIfNeeded() {
    final allKeys = _prefsInstance.getKeys();
    // Only count cache keys (with namespace prefix)
    final cacheKeys = allKeys.where((key) => key.startsWith(_namespace)).toList();
    
    if (cacheKeys.length <= _maxEntries && getCacheSize() <= _maxSizeBytes) {
      return;
    }

    // Collect entries with timestamps for LRU eviction
    final entries = <_CacheEntryMeta>[];
    for (final key in cacheKeys) {
      final jsonStr = _prefsInstance.getString(key);
      if (jsonStr == null) continue;
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final entry = CacheEntry.fromJson(json);
        entries.add(_CacheEntryMeta(key: key, timestamp: entry.timestamp));
      } catch (_) {
        // Corrupt entry — remove immediately
        _prefsInstance.remove(key);
      }
    }

    // Sort by timestamp ascending (oldest first)
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Evict until under limits
    final currentCacheKeys = _prefsInstance.getKeys().where((key) => key.startsWith(_namespace)).toList();
    while (entries.isNotEmpty &&
           (currentCacheKeys.length > _maxEntries ||
            getCacheSize() > _maxSizeBytes)) {
      final oldest = entries.removeAt(0);
      _prefsInstance.remove(oldest.key);
    }
  }

  /// Invalidate a specific cache entry.
  void invalidate(String key) {
    _prefsInstance.remove(key);
  }

  /// Clear all cache entries with the given prefix.
  /// 
  /// The prefix is automatically prefixed with the cache namespace.
  void clearByPrefix(String prefix) {
    final keys = _prefsInstance.getKeys();
    final fullPrefix = '$_namespace$prefix';
    for (final key in keys) {
      if (key.startsWith(fullPrefix)) {
        _prefsInstance.remove(key);
      }
    }
  }

  /// Clear all cache entries.
  /// 
  /// Only deletes keys that start with the cache namespace prefix.
  /// This prevents deletion of non-cache SharedPreferences keys like 
  /// onboarding_complete, user preferences, etc.
  void clearAll() {
    final keys = _prefsInstance.getKeys();
    for (final key in keys) {
      if (key.startsWith(_namespace)) {
        _prefsInstance.remove(key);
      }
    }
  }

  /// Get the size of the cache in bytes (approximate).
  /// Only counts keys with the cache namespace prefix.
  int getCacheSize() {
    final allKeys = _prefsInstance.getKeys();
    final cacheKeys = allKeys.where((key) => key.startsWith(_namespace));
    int size = 0;
    for (final key in cacheKeys) {
      size += _prefsInstance.getString(key)?.length ?? 0;
    }
    return size;
  }

  /// Get the count of cached entries.
  /// Only counts keys with the cache namespace prefix.
  int getCacheCount() {
    final allKeys = _prefsInstance.getKeys();
    return allKeys.where((key) => key.startsWith(_namespace)).length;
  }
}

class _CacheEntryMeta {
  final String key;
  final DateTime timestamp;
  const _CacheEntryMeta({required this.key, required this.timestamp});
}
