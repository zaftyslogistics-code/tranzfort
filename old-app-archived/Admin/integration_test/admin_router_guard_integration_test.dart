import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/core/routing/admin_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin router guard integration tests', () {
    test('A-RBAC-01: super-admin route allow matrix', () {
      final verificationsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/verifications',
        role: AdminRole.superAdmin,
      );

      final verificationDetailRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/verification/supplier/supplier-1',
        role: AdminRole.superAdmin,
      );

      final superOpsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/super-ops',
        role: AdminRole.superAdmin,
      );

      final loadsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/loads',
        role: AdminRole.superAdmin,
      );

      final adminManagementRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/admin-management',
        role: AdminRole.superAdmin,
      );

      final auditLogsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/audit-logs',
        role: AdminRole.superAdmin,
      );

      final systemSettingsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/system-settings',
        role: AdminRole.superAdmin,
      );

      expect(verificationsRedirect, isNull);
      expect(verificationDetailRedirect, isNull);
      expect(superOpsRedirect, isNull);
      expect(loadsRedirect, isNull);
      expect(adminManagementRedirect, isNull);
      expect(auditLogsRedirect, isNull);
      expect(systemSettingsRedirect, isNull);
    });

    test('A-RBAC-02: ops restricted routes blocked', () {
      final adminManagementRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/admin-management',
        role: AdminRole.opsAdmin,
      );

      final auditLogsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/audit-logs',
        role: AdminRole.opsAdmin,
      );

      final verificationQueueRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/verifications',
        role: AdminRole.opsAdmin,
      );

      final superOpsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/super-ops/load/load-1',
        role: AdminRole.opsAdmin,
      );

      final loadsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/loads',
        role: AdminRole.opsAdmin,
      );

      final systemSettingsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/system-settings',
        role: AdminRole.opsAdmin,
      );

      expect(adminManagementRedirect, '/dashboard');
      expect(auditLogsRedirect, '/dashboard');
      expect(verificationQueueRedirect, isNull);
      expect(superOpsRedirect, isNull);
      expect(loadsRedirect, isNull);
      expect(systemSettingsRedirect, '/dashboard');
    });

    test('A-RBAC-03: support restricted routes blocked', () {
      final verificationQueueRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/verifications',
        role: AdminRole.supportAgent,
      );

      final superOpsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/super-ops',
        role: AdminRole.supportAgent,
      );

      final adminManagementRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/admin-management',
        role: AdminRole.supportAgent,
      );

      final auditLogsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/audit-logs',
        role: AdminRole.supportAgent,
      );

      final loadsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/loads',
        role: AdminRole.supportAgent,
      );

      final systemSettingsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/system-settings',
        role: AdminRole.supportAgent,
      );

      final supportQueueRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/support',
        role: AdminRole.supportAgent,
      );

      expect(verificationQueueRedirect, '/dashboard');
      expect(superOpsRedirect, '/dashboard');
      expect(adminManagementRedirect, '/dashboard');
      expect(auditLogsRedirect, '/dashboard');
      expect(loadsRedirect, '/dashboard');
      expect(systemSettingsRedirect, '/dashboard');
      expect(supportQueueRedirect, isNull);
    });

    test('3.8: Admin auth guard requires active admin role', () {
      final redirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/dashboard',
        role: null,
      );

      expect(redirect, '/login');
    });

    test('3.9: Non-super-admin role is blocked from super-admin routes', () {
      final supportRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/admin-management',
        role: AdminRole.supportAgent,
      );

      final opsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/audit-logs',
        role: AdminRole.opsAdmin,
      );

      expect(supportRedirect, '/dashboard');
      expect(opsRedirect, '/dashboard');
    });

    test('3.10: Support Agent route matrix allows read areas and blocks ops areas', () {
      final usersRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/users',
        role: AdminRole.supportAgent,
      );

      final userDetailRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/user/user-1',
        role: AdminRole.supportAgent,
      );

      final superOpsRedirect = resolveAdminRouteRedirect(
        configured: true,
        loggedIn: true,
        onLogin: false,
        matchedLocation: '/super-ops',
        role: AdminRole.supportAgent,
      );

      expect(usersRedirect, isNull);
      expect(userDetailRedirect, isNull);
      expect(superOpsRedirect, '/dashboard');

      final allowedForUserDetail = allowedRolesForAdminLocation('/user/user-1');
      expect(allowedForUserDetail, contains(AdminRole.supportAgent));
    });
  });
}
