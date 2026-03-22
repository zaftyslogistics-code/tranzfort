import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/notifications/data/notification_repository.dart';
import 'package:tranzfort/src/features/notifications/data/notification_route_resolver.dart';

AppNotification _notification({
  String? actionRouteHint,
  String? relatedLoadId,
  String? relatedTripId,
  String? relatedCaseId,
}) {
  return AppNotification(
    id: 'notification-1',
    type: AppNotificationType.tripUpdate,
    priority: AppNotificationPriority.medium,
    titleText: 'Title',
    bodyText: 'Body',
    relatedLoadId: relatedLoadId,
    relatedTripId: relatedTripId,
    relatedCaseId: relatedCaseId,
    actionRouteHint: actionRouteHint,
    isRead: false,
    readAt: null,
    createdAt: DateTime(2026, 3, 10, 12),
  );
}

void main() {
  test('resolveNotificationRoute keeps supported trip detail route', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: '/trip-detail/{tripId}', relatedTripId: 'trip-42'),
      AppUserRole.trucker,
    );

    expect(route, '${AppRoutes.tripDetailPath}/trip-42');
  });

  test('resolveNotificationRoute falls back from admin route', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: '/admin/verification-queue'),
      AppUserRole.trucker,
    );

    expect(route, AppRoutes.truckerDashboardPath);
  });

  test('resolveNotificationRoute falls back from restricted support ticket route', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: '/support-ticket/ticket-1'),
      AppUserRole.supplier,
    );

    expect(route, AppRoutes.supplierDashboardPath);
  });

  test('resolveNotificationRoute maps verification hint to supplier verification route', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: '/verification'),
      AppUserRole.supplier,
    );

    expect(route, AppRoutes.supplierVerificationPath);
  });

  test('resolveNotificationRoute maps verification hint to trucker verification route', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: '/verification'),
      AppUserRole.trucker,
    );

    expect(route, AppRoutes.truckerVerificationPath);
  });

  test('resolveNotificationRoute falls back when hinted route mismatches role', () {
    final route = resolveNotificationRoute(
      _notification(actionRouteHint: AppRoutes.myLoadsPath),
      AppUserRole.trucker,
    );

    expect(route, AppRoutes.truckerDashboardPath);
  });

  test('resolveNotificationRoute uses related ids when no route hint exists', () {
    final route = resolveNotificationRoute(
      _notification(relatedLoadId: 'load-7'),
      AppUserRole.supplier,
    );

    expect(route, '${AppRoutes.loadDetailPath}/load-7');
  });

  test('resolveNotificationRouteData materializes supported chat placeholder route', () {
    final route = resolveNotificationRouteData(
      role: AppUserRole.supplier,
      actionRouteHint: '/chat/{caseId}',
      relatedLoadId: 'load-1',
      relatedTripId: null,
      relatedCaseId: 'case-9',
    );

    expect(route, '${AppRoutes.chatPath}/case-9');
  });

  test('resolveNotificationRouteData maps stale my-fleet hint to trucker fleet route', () {
    final route = resolveNotificationRouteData(
      role: AppUserRole.trucker,
      actionRouteHint: '/my-fleet',
      relatedLoadId: null,
      relatedTripId: null,
      relatedCaseId: null,
    );

    expect(route, AppRoutes.fleetPath);
  });

  test('resolveNotificationRouteData rejects fleet route for supplier role', () {
    final route = resolveNotificationRouteData(
      role: AppUserRole.supplier,
      actionRouteHint: AppRoutes.fleetPath,
      relatedLoadId: null,
      relatedTripId: null,
      relatedCaseId: null,
    );

    expect(route, AppRoutes.supplierDashboardPath);
  });

  test('resolveNotificationRouteData falls back from assistant route', () {
    final route = resolveNotificationRouteData(
      role: AppUserRole.trucker,
      actionRouteHint: '/assistant',
      relatedLoadId: null,
      relatedTripId: null,
      relatedCaseId: null,
    );

    expect(route, AppRoutes.truckerDashboardPath);
  });

  test('materializeActionRoute replaces placeholders with available ids', () {
    final route = materializeActionRoute(
      actionRouteHint: '/load-detail/{loadId}',
      relatedLoadId: 'load-123',
      relatedTripId: null,
      relatedCaseId: null,
    );

    expect(route, '${AppRoutes.loadDetailPath}/load-123');
  });
}
