import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/offline_cache_service.dart';

/// Provider for the OfflineCacheService singleton.
/// 
/// This provider ensures that the cache service is initialized
/// when first accessed and provides a consistent instance
/// across the application.
final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  final service = OfflineCacheService.instance;
  
  // Initialize the service asynchronously
  // Note: This is fire-and-forget. If initialization fails,
  // the service will throw StateError on first use.
  service.initialize();
  
  return service;
});
