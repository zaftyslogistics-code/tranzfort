import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  String generateCacheKey({
    required String userId,
    String? userRole,
    required String dataType,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? paginationParams,
  }) {
    final buffer = StringBuffer();
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
  /// 
  /// Use generic type parameter [T] to deserialize JSON to the expected type.
  T? get<T>(String key) {
    try {
      final jsonStr = _prefsInstance.getString(key);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(json);
      
      if (entry.isExpired) {
        // Auto-delete expired entry
        invalidate(key);
        return null;
      }
      
      return jsonDecode(entry.data) as T?;
    } catch (e) {
      // If cache is corrupt, invalidate it
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
        ttl: ttl ?? const Duration(hours: 1), // Default 1 hour
      );
      final entryJson = jsonEncode(entry.toJson());
      _prefsInstance.setString(key, entryJson);
    } catch (e) {
      // Silently fail on cache write errors
    }
  }

  /// Invalidate a specific cache entry.
  void invalidate(String key) {
    _prefsInstance.remove(key);
  }

  /// Clear all cache entries with the given prefix.
  void clearByPrefix(String prefix) {
    final keys = _prefsInstance.getKeys();
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        _prefsInstance.remove(key);
      }
    }
  }

  /// Clear all cache entries.
  void clearAll() {
    _prefsInstance.clear();
  }

  /// Get the size of the cache in bytes (approximate).
  /// 
  /// This is an estimate based on SharedPreferences storage.
  int getCacheSize() {
    final keys = _prefsInstance.getKeys();
    int size = 0;
    for (final key in keys) {
      size += _prefsInstance.getString(key)?.length ?? 0;
    }
    return size;
  }

  /// Get the count of cached entries.
  int getCacheCount() {
    return _prefsInstance.getKeys().length;
  }
}
