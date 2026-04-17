import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route types for navigation classification
enum RouteType {
  /// Top-level routes (dashboard, messages, profile, settings)
  /// No back arrow needed
  topLevel,

  /// Nested routes (load detail, trip detail, chat)
  /// Should have back arrow
  nested,

  /// Modal routes (dialogs, bottom sheets)
  /// Special back behavior
  modal,

  /// Standalone routes (onboarding, splash, auth)
  /// Independent navigation
  standalone,

  /// Sub-flow routes (multi-step wizards)
  /// Complex back navigation
  subFlow,
}

/// Helper class for accessing route metadata
/// 
/// This class provides methods to retrieve metadata from GoRouter state
/// for controlling navigation behavior across the app.
/// 
/// Note: This implementation is compatible with go_router 14.8.1.
/// Route metadata should be added to route definitions in app_router.dart
/// and accessed via route configuration or path matching.
class RouteMetadataHelper {
  RouteMetadataHelper._();

  /// Route metadata registry
  /// 
  /// This map stores metadata for each route path.
  /// It should be populated when routes are defined in app_router.dart.
  static final Map<String, Map<String, dynamic>> _routeMetadata = {};

  /// Register metadata for a route
  /// 
  /// Call this method when defining routes in app_router.dart:
  /// ```dart
  /// RouteMetadataHelper.registerMetadata('/fleet', {
  ///   'type': RouteType.nested,
  ///   'showBackArrow': false,
  ///   'requirePopScope': true,
  ///   'testId': 'trucker_fleet',
  /// });
  /// ```
  static void registerMetadata(String path, Map<String, dynamic> metadata) {
    _routeMetadata[path] = metadata;
  }

  /// Get the route type from route metadata
  /// 
  /// Returns the RouteType enum value if specified in route metadata,
  /// otherwise returns null.
  static RouteType? getType(BuildContext context) {
    final state = GoRouterState.of(context);
    final metadata = _findMetadata(state.matchedLocation);
    return metadata?['type'] as RouteType?;
  }

  /// Check if the route should show a back arrow
  /// 
  /// Returns true if the route metadata specifies showBackArrow as true,
  /// otherwise returns false (default).
  static bool shouldShowBackArrow(BuildContext context) {
    final state = GoRouterState.of(context);
    final metadata = _findMetadata(state.matchedLocation);
    return metadata?['showBackArrow'] as bool? ?? false;
  }

  /// Check if the route requires PopScope
  /// 
  /// Returns true if the route metadata specifies requirePopScope as true,
  /// otherwise returns false (default).
  /// 
  /// PopScope is used to intercept system back button behavior
  /// for form screens and other screens that need confirmation.
  static bool requirePopScope(BuildContext context) {
    final state = GoRouterState.of(context);
    final metadata = _findMetadata(state.matchedLocation);
    return metadata?['requirePopScope'] as bool? ?? false;
  }

  /// Get the test ID for E2E testing
  /// 
  /// Returns the test ID from route metadata if specified,
  /// otherwise returns null.
  /// 
  /// This is used for future E2E testing infrastructure.
  static String? getTestId(BuildContext context) {
    final state = GoRouterState.of(context);
    final metadata = _findMetadata(state.matchedLocation);
    return metadata?['testId'] as String?;
  }

  /// Find metadata for a given path, supporting parameterized routes
  /// 
  /// This method first tries exact matching, then pattern matching for
  /// routes with parameters (e.g., /load-detail/:loadId matches /load-detail/123).
  static Map<String, dynamic>? _findMetadata(String path) {
    // Try exact match first
    if (_routeMetadata.containsKey(path)) {
      return _routeMetadata[path];
    }

    // Try pattern matching for parameterized routes
    for (final registeredPath in _routeMetadata.keys) {
      if (_matchesPattern(registeredPath, path)) {
        return _routeMetadata[registeredPath];
      }
    }

    return null;
  }

  /// Check if a registered path pattern matches the actual path
  /// 
  /// Supports parameter matching (e.g., /load-detail/:loadId matches /load-detail/123)
  static bool _matchesPattern(String pattern, String path) {
    final patternParts = pattern.split('/');
    final pathParts = path.split('/');

    if (patternParts.length != pathParts.length) {
      return false;
    }

    for (int i = 0; i < patternParts.length; i++) {
      final patternPart = patternParts[i];
      final pathPart = pathParts[i];

      // If pattern part starts with ':', it's a parameter and matches anything
      if (patternPart.startsWith(':')) {
        continue;
      }

      // Otherwise, exact match required
      if (patternPart != pathPart) {
        return false;
      }
    }

    return true;
  }

  /// Clear all route metadata
  /// 
  /// This should only be used in tests or when re-initializing the router.
  static void clearMetadata() {
    _routeMetadata.clear();
  }
}
