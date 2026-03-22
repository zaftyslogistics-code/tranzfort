import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_app_state_providers.dart';
import '../providers/admin_rbac_providers.dart';
import '../../features/audit_logs/presentation/admin_audit_log_screen.dart';
import '../../features/admin_management/presentation/admin_management_screen.dart';
import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/load_management/presentation/admin_load_detail_screen.dart';
import '../../features/load_management/presentation/admin_load_management_screen.dart';
import '../../features/shell/presentation/admin_app_shell.dart';
import '../../features/shell/presentation/admin_shell_screens.dart';
import '../../features/super_ops/presentation/admin_operational_case_detail_screen.dart';
import '../../features/support/presentation/admin_support_ticket_detail_screen.dart';
import '../../features/verification/presentation/admin_verification_detail_screen.dart';
import '../../features/users/presentation/admin_user_detail_screen.dart';
import '../../features/users/presentation/admin_users_screen.dart';
import 'admin_router_refresh_notifier.dart';
import 'admin_routes.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AdminRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AdminRoutes.dashboardPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(currentAdminAuthStateProvider);
      return resolveAdminRouteRedirect(
        matchedLocation: state.uri.path,
        authState: authState,
      );
    },
    routes: [
      GoRoute(
        path: AdminRoutes.rootPath,
        redirect: (context, state) => AdminRoutes.dashboardPath,
      ),
      GoRoute(
        path: AdminRoutes.loginPath,
        name: AdminRoutes.login,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminAppShell(
            currentLocation: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AdminRoutes.dashboardPath,
            name: AdminRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.verificationPath,
            name: AdminRoutes.verification,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminVerificationScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.verificationDetailPath,
            name: AdminRoutes.verificationDetail,
            pageBuilder: (context, state) => NoTransitionPage(
              child: AdminVerificationDetailScreen(
                caseId: state.pathParameters['caseId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AdminRoutes.supportPath,
            name: AdminRoutes.support,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminSupportScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.supportDetailPath,
            name: AdminRoutes.supportDetail,
            pageBuilder: (context, state) => NoTransitionPage(
              child: AdminSupportTicketDetailScreen(
                ticketId: state.pathParameters['ticketId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AdminRoutes.superOpsPath,
            name: AdminRoutes.superOps,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminSuperOpsScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.loadManagementPath,
            name: AdminRoutes.loadManagement,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminLoadManagementScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.loadDetailPath,
            name: AdminRoutes.loadDetail,
            pageBuilder: (context, state) => NoTransitionPage(
              child: AdminLoadDetailScreen(
                loadId: state.pathParameters['loadId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AdminRoutes.operationalCaseDetailPath,
            name: AdminRoutes.operationalCaseDetail,
            pageBuilder: (context, state) => NoTransitionPage(
              child: AdminOperationalCaseDetailScreen(
                caseId: state.pathParameters['caseId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AdminRoutes.usersPath,
            name: AdminRoutes.users,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminUsersScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.userDetailPath,
            name: AdminRoutes.userDetail,
            pageBuilder: (context, state) => NoTransitionPage(
              child: AdminUserDetailScreen(
                userId: state.pathParameters['userId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AdminRoutes.adminManagementPath,
            name: AdminRoutes.adminManagement,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminManagementScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.auditLogsPath,
            name: AdminRoutes.auditLogs,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminAuditLogScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.settingsPath,
            name: AdminRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminSettingsScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.notificationsPath,
            name: AdminRoutes.notifications,
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

Set<AdminRole> allowedRolesForAdminLocation(String location) {
  final permission = _permissionForLocation(location);
  if (permission == null) {
    return const {AdminRole.superAdmin, AdminRole.opsAdmin};
  }

  return switch (permission) {
    AdminRoutePermission.dashboard ||
    AdminRoutePermission.verification ||
    AdminRoutePermission.support ||
    AdminRoutePermission.superOps ||
    AdminRoutePermission.loadManagement ||
    AdminRoutePermission.users ||
    AdminRoutePermission.auditLogs ||
    AdminRoutePermission.settings ||
    AdminRoutePermission.notifications => const {AdminRole.superAdmin, AdminRole.opsAdmin},
    AdminRoutePermission.adminManagement => const {AdminRole.superAdmin},
  };
}

String? resolveAdminRouteRedirect({
  required String matchedLocation,
  required AdminAuthStateSnapshot authState,
}) {
  final isLoginRoute = matchedLocation == AdminRoutes.loginPath;

  if (authState.isLoading) {
    if (!authState.hasSession && !isLoginRoute) {
      return AdminRoutes.loginPath;
    }
    return null;
  }

  if (!authState.hasSession && !isLoginRoute) {
    return AdminRoutes.loginPath;
  }

  if (!authState.hasSession) {
    return null;
  }

  if (authState.verificationFailed) {
    return isLoginRoute ? null : AdminRoutes.loginPath;
  }

  if (!authState.hasAdminAccess && !isLoginRoute) {
    return AdminRoutes.loginPath;
  }

  if (isLoginRoute && authState.hasAdminAccess) {
    return AdminRoutes.dashboardPath;
  }

  final allowedRoles = allowedRolesForAdminLocation(matchedLocation);
  if (!allowedRoles.contains(authState.role)) {
    return AdminRoutes.dashboardPath;
  }

  return null;
}

AdminRoutePermission? _permissionForLocation(String location) {
  if (location == AdminRoutes.dashboardPath) {
    return AdminRoutePermission.dashboard;
  }
  if (location == AdminRoutes.verificationPath) {
    return AdminRoutePermission.verification;
  }
  if (location.startsWith('${AdminRoutes.verificationPath}/')) {
    return AdminRoutePermission.verification;
  }
  if (location == AdminRoutes.supportPath) {
    return AdminRoutePermission.support;
  }
  if (location.startsWith('${AdminRoutes.supportPath}/')) {
    return AdminRoutePermission.support;
  }
  if (location == AdminRoutes.superOpsPath) {
    return AdminRoutePermission.superOps;
  }
  if (location.startsWith('${AdminRoutes.superOpsPath}/')) {
    return AdminRoutePermission.superOps;
  }
  if (location == AdminRoutes.loadManagementPath) {
    return AdminRoutePermission.loadManagement;
  }
  if (location.startsWith('${AdminRoutes.loadManagementPath}/')) {
    return AdminRoutePermission.loadManagement;
  }
  if (location == AdminRoutes.usersPath) {
    return AdminRoutePermission.users;
  }
  if (location.startsWith('${AdminRoutes.usersPath}/')) {
    return AdminRoutePermission.users;
  }
  if (location == AdminRoutes.adminManagementPath) {
    return AdminRoutePermission.adminManagement;
  }
  if (location == AdminRoutes.auditLogsPath) {
    return AdminRoutePermission.auditLogs;
  }
  if (location == AdminRoutes.settingsPath) {
    return AdminRoutePermission.settings;
  }
  if (location == AdminRoutes.notificationsPath) {
    return AdminRoutePermission.notifications;
  }
  return null;
}
