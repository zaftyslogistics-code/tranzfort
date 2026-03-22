import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import 'notification_repository.dart';

String resolveNotificationRoute(AppNotification notification, AppUserRole role) {
  return resolveNotificationRouteData(
    role: role,
    actionRouteHint: notification.actionRouteHint,
    relatedLoadId: notification.relatedLoadId,
    relatedTripId: notification.relatedTripId,
    relatedCaseId: notification.relatedCaseId,
  );
}

String resolveNotificationRouteData({
  required AppUserRole role,
  String? actionRouteHint,
  String? relatedLoadId,
  String? relatedTripId,
  String? relatedCaseId,
}) {
  final fallback = roleHomePath(role);
  final hintedRoute = materializeActionRoute(
    actionRouteHint: actionRouteHint,
    relatedLoadId: relatedLoadId,
    relatedTripId: relatedTripId,
    relatedCaseId: relatedCaseId,
  );
  if (hintedRoute == null) {
    if ((relatedTripId ?? '').trim().isNotEmpty) {
      return '${AppRoutes.tripDetailPath}/${relatedTripId!.trim()}';
    }
    if ((relatedLoadId ?? '').trim().isNotEmpty) {
      return '${AppRoutes.loadDetailPath}/${relatedLoadId!.trim()}';
    }
    return fallback;
  }

  if (hintedRoute.startsWith('/admin/')) {
    return fallback;
  }

  if (hintedRoute == '/support-ticket' || hintedRoute.startsWith('/support-ticket/')) {
    return fallback;
  }

  if (hintedRoute == '/verification') {
    return role == AppUserRole.supplier ? AppRoutes.supplierVerificationPath : AppRoutes.truckerVerificationPath;
  }

  if (hintedRoute == AppRoutes.supplierVerificationPath && role != AppUserRole.supplier) {
    return fallback;
  }

  if (hintedRoute == AppRoutes.truckerVerificationPath && role != AppUserRole.trucker) {
    return fallback;
  }

  if (hintedRoute == '/my-fleet') {
    return role == AppUserRole.trucker ? AppRoutes.fleetPath : fallback;
  }

  if (hintedRoute == AppRoutes.dashboardPath) {
    return fallback;
  }

  if (hintedRoute == AppRoutes.findLoadsPath && role != AppUserRole.trucker) {
    return fallback;
  }

  if ((hintedRoute == AppRoutes.myLoadsPath || hintedRoute == AppRoutes.postLoadPath) &&
      role != AppUserRole.supplier) {
    return fallback;
  }

  if (hintedRoute == AppRoutes.tripsPath && role != AppUserRole.trucker) {
    return fallback;
  }

  final supportedPrefixes = <String>[
    AppRoutes.loadDetailPath,
    AppRoutes.tripDetailPath,
    AppRoutes.chatPath,
  ];
  if (supportedPrefixes.any((prefix) => hintedRoute == prefix || hintedRoute.startsWith('$prefix/'))) {
    return hintedRoute;
  }

  final supportedExactRoutes = <String>{
    AppRoutes.notificationsPath,
    AppRoutes.messagesPath,
    AppRoutes.fleetPath,
    AppRoutes.findLoadsPath,
    AppRoutes.myLoadsPath,
    AppRoutes.postLoadPath,
    AppRoutes.tripsPath,
    AppRoutes.supplierDashboardPath,
    AppRoutes.supplierVerificationPath,
    AppRoutes.truckerDashboardPath,
    AppRoutes.truckerVerificationPath,
  };

  if (!supportedExactRoutes.contains(hintedRoute)) {
    return fallback;
  }
  if (hintedRoute == AppRoutes.fleetPath && role != AppUserRole.trucker) {
    return fallback;
  }
  if (hintedRoute == AppRoutes.supplierDashboardPath && role != AppUserRole.supplier) {
    return fallback;
  }
  if (hintedRoute == AppRoutes.truckerDashboardPath && role != AppUserRole.trucker) {
    return fallback;
  }
  return hintedRoute;
}

String roleHomePath(AppUserRole role) {
  return role == AppUserRole.supplier ? AppRoutes.supplierDashboardPath : AppRoutes.truckerDashboardPath;
}

String? materializeActionRoute({
  required String? actionRouteHint,
  required String? relatedLoadId,
  required String? relatedTripId,
  required String? relatedCaseId,
}) {
  final raw = actionRouteHint?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return raw
      .replaceAll('{loadId}', relatedLoadId?.trim() ?? '')
      .replaceAll('{tripId}', relatedTripId?.trim() ?? '')
      .replaceAll('{caseId}', relatedCaseId?.trim() ?? '');
}
