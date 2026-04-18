import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/monitoring_service.dart';

/// Navigation service that wraps GoRouter with logging capabilities
/// 
/// This service provides:
/// - High-level navigation methods
/// - Automatic event logging via MonitoringService
/// - Error tracking
class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final _monitoringService = MonitoringService.instance;

  /// Navigate to a route
  void navigate(BuildContext context, String route, {Object? extra}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    try {
      context.go(route, extra: extra);
      _monitoringService.logRouteTransition(
        fromRoute: currentLocation,
        toRoute: route,
        type: NavigationTransitionType.go,
      );
    } catch (e) {
      _monitoringService.logNavigationError(
        route: route,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Push a route onto the navigation stack
  void push(BuildContext context, String route, {Object? extra}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    try {
      context.push(route, extra: extra);
      _monitoringService.logRouteTransition(
        fromRoute: currentLocation,
        toRoute: route,
        type: NavigationTransitionType.push,
      );
    } catch (e) {
      _monitoringService.logNavigationError(
        route: route,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Pop the current route
  void pop(BuildContext context, {Object? result}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    try {
      Navigator.of(context).pop(result);
      _monitoringService.logRouteTransition(
        fromRoute: currentLocation,
        toRoute: '<back>',
        type: NavigationTransitionType.pop,
      );
    } catch (e) {
      _monitoringService.logNavigationError(
        route: currentLocation,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Replace the current route
  void replace(BuildContext context, String route, {Object? extra}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    try {
      context.pushReplacement(route, extra: extra);
      _monitoringService.logRouteTransition(
        fromRoute: currentLocation,
        toRoute: route,
        type: NavigationTransitionType.replace,
      );
    } catch (e) {
      _monitoringService.logNavigationError(
        route: route,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Navigate to a named route
  void goNamed(BuildContext context, String name, {Map<String, String>? pathParameters, Map<String, dynamic>? queryParameters}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    try {
      context.goNamed(name, pathParameters: pathParameters ?? const {}, queryParameters: queryParameters ?? const {});
      _monitoringService.logRouteTransition(
        fromRoute: currentLocation,
        toRoute: name,
        type: NavigationTransitionType.goNamed,
        metadata: {
          if (pathParameters != null) 'pathParameters': pathParameters,
          if (queryParameters != null) 'queryParameters': queryParameters,
        },
      );
    } catch (e) {
      _monitoringService.logNavigationError(
        route: name,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Log a back button press
  void logBackButtonPress(BuildContext context, {String? contextInfo}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    _monitoringService.logBackButton(
      route: currentLocation,
      action: BackButtonAction.pressed,
      context: contextInfo,
    );
  }

  /// Log a back button prevention (e.g., unsaved changes)
  void logBackButtonPrevented(BuildContext context, {String? reason}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    _monitoringService.logBackButton(
      route: currentLocation,
      action: BackButtonAction.prevented,
      context: reason,
    );
  }

  /// Log a PopScope confirmation
  void logPopScopeConfirmation(BuildContext context, bool confirmed, {String? reason}) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    _monitoringService.logPopScopeConfirmation(
      route: currentLocation,
      confirmed: confirmed,
      reason: reason ?? 'unknown',
    );
  }

  /// Get the current route location
  String getCurrentLocation(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }

  /// Check if a route can be popped
  bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Get the current GoRouterState
  GoRouterState getRouterState(BuildContext context) {
    return GoRouterState.of(context);
  }
}
