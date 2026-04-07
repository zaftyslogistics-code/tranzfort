import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/result.dart';
import 'shared_providers.dart';

class RouteState {
  final bool isCalculating;
  final List<LatLng> routePoints;
  final double distance;
  final Duration estimatedDuration;
  final String? error;

  const RouteState({
    this.isCalculating = false,
    this.routePoints = const [],
    this.distance = 0.0,
    this.estimatedDuration = Duration.zero,
    this.error,
  });

  RouteState copyWith({
    bool? isCalculating,
    List<LatLng>? routePoints,
    double? distance,
    Duration? estimatedDuration,
    String? error,
  }) {
    return RouteState(
      isCalculating: isCalculating ?? this.isCalculating,
      routePoints: routePoints ?? this.routePoints,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      error: error,
    );
  }
}

class RouteNotifier extends StateNotifier<RouteState> {
  final Ref _ref;

  RouteNotifier(this._ref) : super(const RouteState());

  Future<void> calculateRoute(LatLng origin, LatLng destination) async {
    state = state.copyWith(isCalculating: true, error: null);

    final mapsConfig = _ref.read(mapsConfigProvider);
    
    try {
      if (mapsConfig.hasApiKey) {
        final result = await _ref
            .read(googleRoutesServiceProvider)
            .getRoutePolyline(origin, destination);
        
        state = state.copyWith(
          isCalculating: false,
          routePoints: result,
        );
      } else {
        final routeData = await _ref
            .read(osrmServiceProvider)
            .getRoutePolyline(origin, destination);
            
        switch (routeData) {
          case Success(data: final points):
            state = state.copyWith(
              isCalculating: false,
              routePoints: points,
            );
          case Failure(debugMessage: final msg):
            state = state.copyWith(
              isCalculating: false,
              error: msg ?? 'Failed to calculate route',
            );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        error: 'Failed to calculate route: $e',
      );
    }
  }

  void clearRoute() {
    state = const RouteState();
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier(ref);
});

final nearbyLoadsProvider = FutureProvider.family<List<Map<String, dynamic>>, LatLng>(
  (ref, location) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) return [];

    final result = await ref.read(loadRepositoryProvider).findLoads(
      page: 1,
      pageSize: 20,
    );
    
    switch (result) {
      case Success(data: final data):
        return data;
      case Failure():
        return <Map<String, dynamic>>[];
    }
  },
);

class RoutingCalculationUtils {
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = math.pi * start.latitude / 180.0;
    final lat2 = math.pi * end.latitude / 180.0;
    final deltaLong = math.pi * (end.longitude - start.longitude) / 180.0;

    final y = math.sin(deltaLong) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLong);

    final bearing = math.atan2(y, x);
    return (bearing * 180.0 / math.pi + 360) % 360;
  }

  static List<LatLng> interpolateRoute(List<LatLng> points, {int interval = 100}) {
    if (points.length < 2) return points;

    final interpolated = <LatLng>[];
    
    for (int i = 0; i < points.length - 1; i++) {
      interpolated.add(points[i]);
      
      final start = points[i];
      final end = points[i + 1];
      final distance = const Distance().as(LengthUnit.Meter, start, end);
      final steps = (distance / interval).floor();
      
      for (int j = 1; j < steps; j++) {
        final fraction = j / steps;
        final lat = start.latitude + (end.latitude - start.latitude) * fraction;
        final lng = start.longitude + (end.longitude - start.longitude) * fraction;
        interpolated.add(LatLng(lat, lng));
      }
    }
    
    interpolated.add(points.last);
    return interpolated;
  }

  static double calculateDeviation(List<LatLng> actualRoute, List<LatLng> plannedRoute) {
    if (actualRoute.isEmpty || plannedRoute.isEmpty) return 0.0;

    double totalDeviation = 0.0;
    int count = 0;

    for (final point in actualRoute) {
      double minDistance = double.infinity;
      
      for (final plannedPoint in plannedRoute) {
        final distance = const Distance().as(LengthUnit.Meter, point, plannedPoint);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      
      totalDeviation += minDistance;
      count++;
    }

    return count > 0 ? totalDeviation / count : 0.0;
  }
}
