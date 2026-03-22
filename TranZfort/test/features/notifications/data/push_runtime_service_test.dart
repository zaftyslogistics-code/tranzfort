import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/notifications/data/push_runtime_service.dart';

void main() {
  test('routeFromPushData resolves action_route_hint placeholder for trip detail', () {
    final route = routeFromPushData(
      <String, dynamic>{
        'action_route_hint': '/trip-detail/{tripId}',
        'related_trip_id': 'trip-42',
      },
      AppUserRole.trucker,
    );

    expect(route, '${AppRoutes.tripDetailPath}/trip-42');
  });

  test('routeFromPushData falls back safely for restricted supplier route on trucker role', () {
    final route = routeFromPushData(
      <String, dynamic>{
        'action_route_hint': AppRoutes.myLoadsPath,
      },
      AppUserRole.trucker,
    );

    expect(route, AppRoutes.truckerDashboardPath);
  });

  test('routeFromPushData supports legacy fallback keys from push payload', () {
    final route = routeFromPushData(
      <String, dynamic>{
        'route': '/load-detail/{loadId}',
        'loadId': 'load-7',
      },
      AppUserRole.supplier,
    );

    expect(route, '${AppRoutes.loadDetailPath}/load-7');
  });

  test('normalizePushPayloadRoute trims valid payload routes', () {
    expect(normalizePushPayloadRoute('  /notifications  '), AppRoutes.notificationsPath);
  });

  test('normalizePushPayloadRoute returns null for blank payloads', () {
    expect(normalizePushPayloadRoute('   '), isNull);
    expect(normalizePushPayloadRoute(null), isNull);
  });
}
