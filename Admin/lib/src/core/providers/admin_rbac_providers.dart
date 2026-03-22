import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_app_state_providers.dart';
import '../repositories/admin_session_repository.dart';

enum AdminRoutePermission {
  dashboard,
  verification,
  support,
  superOps,
  loadManagement,
  users,
  adminManagement,
  auditLogs,
  settings,
  notifications,
}

final adminRoleProvider = FutureProvider<AdminRole>((ref) async {
  final snapshot = await ref.watch(adminSessionRepositoryProvider).loadCurrentAccess();
  return snapshot.role;
});

final adminPermissionMatrixProvider = Provider<Map<AdminRole, Set<AdminRoutePermission>>>((ref) {
  return const {
    AdminRole.superAdmin: {
      AdminRoutePermission.dashboard,
      AdminRoutePermission.verification,
      AdminRoutePermission.support,
      AdminRoutePermission.superOps,
      AdminRoutePermission.loadManagement,
      AdminRoutePermission.users,
      AdminRoutePermission.adminManagement,
      AdminRoutePermission.auditLogs,
      AdminRoutePermission.settings,
      AdminRoutePermission.notifications,
    },
    AdminRole.opsAdmin: {
      AdminRoutePermission.dashboard,
      AdminRoutePermission.verification,
      AdminRoutePermission.support,
      AdminRoutePermission.superOps,
      AdminRoutePermission.loadManagement,
      AdminRoutePermission.users,
      AdminRoutePermission.auditLogs,
      AdminRoutePermission.settings,
      AdminRoutePermission.notifications,
    },
    AdminRole.unknown: <AdminRoutePermission>{},
  };
});
