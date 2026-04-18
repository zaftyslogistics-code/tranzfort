import 'package:flutter/foundation.dart';

/// Monitoring service for tracking navigation events
/// 
/// This service tracks:
/// - Route transitions
/// - Back button events
/// - PopScope confirmations
/// - Navigation errors
class MonitoringService {
  MonitoringService._();

  static final MonitoringService instance = MonitoringService._();

  final List<NavigationEvent> _events = [];

  List<NavigationEvent> get events => List.unmodifiable(_events);

  /// Log a route transition event
  void logRouteTransition({
    required String fromRoute,
    required String toRoute,
    required NavigationTransitionType type,
    Map<String, dynamic>? metadata,
  }) {
    final event = NavigationEvent(
      type: NavigationEventType.routeTransition,
      timestamp: DateTime.now(),
      data: {
        'fromRoute': fromRoute,
        'toRoute': toRoute,
        'transitionType': type.name,
        if (metadata != null) 'metadata': metadata,
      },
    );
    _events.add(event);
    _logEvent(event);
  }

  /// Log a back button event
  void logBackButton({
    required String route,
    required BackButtonAction action,
    String? context,
  }) {
    final event = NavigationEvent(
      type: NavigationEventType.backButton,
      timestamp: DateTime.now(),
      data: {
        'route': route,
        'action': action.name,
        if (context != null) 'context': context,
      },
    );
    _events.add(event);
    _logEvent(event);
  }

  /// Log a PopScope confirmation event
  void logPopScopeConfirmation({
    required String route,
    required bool confirmed,
    required String reason,
  }) {
    final event = NavigationEvent(
      type: NavigationEventType.popScopeConfirmation,
      timestamp: DateTime.now(),
      data: {
        'route': route,
        'confirmed': confirmed,
        'reason': reason,
      },
    );
    _events.add(event);
    _logEvent(event);
  }

  /// Log a navigation error event
  void logNavigationError({
    required String route,
    required String error,
    String? stackTrace,
  }) {
    final event = NavigationEvent(
      type: NavigationEventType.error,
      timestamp: DateTime.now(),
      data: {
        'route': route,
        'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace,
      },
    );
    _events.add(event);
    _logEvent(event);
  }

  /// Clear all events (useful for testing)
  void clearEvents() {
    _events.clear();
  }

  /// Get events by type
  List<NavigationEvent> getEventsByType(NavigationEventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// Get events by route
  List<NavigationEvent> getEventsByRoute(String route) {
    return _events
        .where((e) => e.data['route'] == route || 
                    e.data['fromRoute'] == route || 
                    e.data['toRoute'] == route)
        .toList();
  }

  /// Get events in a time range
  List<NavigationEvent> getEventsInTimeRange(DateTime start, DateTime end) {
    return _events
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  void _logEvent(NavigationEvent event) {
    if (kDebugMode) {
      print('[MonitoringService] ${event.type.name}: ${event.data}');
    }
  }
}

/// Types of navigation events
enum NavigationEventType {
  routeTransition,
  backButton,
  popScopeConfirmation,
  error,
}

/// Types of route transitions
enum NavigationTransitionType {
  push,
  pop,
  replace,
  go,
  goNamed,
}

/// Types of back button actions
enum BackButtonAction {
  pressed,
  prevented,
  confirmed,
  cancelled,
}

/// Navigation event data class
class NavigationEvent {
  final NavigationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  NavigationEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  @override
  String toString() {
    return 'NavigationEvent(type: $type, timestamp: $timestamp, data: $data)';
  }
}
