import 'package:admin/src/core/navigation/admin_router.dart';
import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/providers/admin_app_state_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin RBAC route resolution', () {
    test('super admin can access all current shell routes', () {
      for (final route in [
        AdminRoutes.dashboardPath,
        AdminRoutes.verificationPath,
        AdminRoutes.supportPath,
        AdminRoutes.superOpsPath,
        AdminRoutes.usersPath,
        AdminRoutes.settingsPath,
        AdminRoutes.notificationsPath,
      ]) {
        final redirect = resolveAdminRouteRedirect(
          matchedLocation: route,
          authState: const AdminAuthStateSnapshot(
            hasSession: true,
            role: AdminRole.superAdmin,
            isActive: true,
          ),
        );
        expect(redirect, isNull, reason: 'Expected no redirect for $route');
      }
    });

    test('ops admin can access current operational routes including users', () {
      for (final route in [
        AdminRoutes.dashboardPath,
        AdminRoutes.verificationPath,
        AdminRoutes.supportPath,
        AdminRoutes.superOpsPath,
        AdminRoutes.usersPath,
        AdminRoutes.settingsPath,
        AdminRoutes.notificationsPath,
      ]) {
        final redirect = resolveAdminRouteRedirect(
          matchedLocation: route,
          authState: const AdminAuthStateSnapshot(
            hasSession: true,
            role: AdminRole.opsAdmin,
            isActive: true,
          ),
        );
        expect(redirect, isNull, reason: 'Expected no redirect for $route');
      }
    });

    test('signed out admin is redirected to login', () {
      final redirect = resolveAdminRouteRedirect(
        matchedLocation: AdminRoutes.dashboardPath,
        authState: AdminAuthStateSnapshot.signedOut(),
      );

      expect(redirect, AdminRoutes.loginPath);
    });

    test('unauthorized active session is redirected to login', () {
      final redirect = resolveAdminRouteRedirect(
        matchedLocation: AdminRoutes.dashboardPath,
        authState: const AdminAuthStateSnapshot(
          hasSession: true,
          role: AdminRole.unknown,
          isActive: false,
        ),
      );

      expect(redirect, AdminRoutes.loginPath);
    });

    test('dashboard does not redirect during admin auth hydration when a session already exists', () {
      final redirect = resolveAdminRouteRedirect(
        matchedLocation: AdminRoutes.dashboardPath,
        authState: const AdminAuthStateSnapshot(
          hasSession: true,
          role: AdminRole.unknown,
          isActive: false,
          isLoading: true,
        ),
      );

      expect(redirect, isNull);
    });

    test('login route does not bounce to dashboard during admin auth hydration', () {
      final redirect = resolveAdminRouteRedirect(
        matchedLocation: AdminRoutes.loginPath,
        authState: const AdminAuthStateSnapshot(
          hasSession: true,
          role: AdminRole.unknown,
          isActive: false,
          isLoading: true,
        ),
      );

      expect(redirect, isNull);
    });

    test('login route redirects authorized admin to dashboard', () {
      final redirect = resolveAdminRouteRedirect(
        matchedLocation: AdminRoutes.loginPath,
        authState: const AdminAuthStateSnapshot(
          hasSession: true,
          role: AdminRole.opsAdmin,
          isActive: true,
        ),
      );

      expect(redirect, AdminRoutes.dashboardPath);
    });

    test('allowed roles resolve correctly for current shell locations', () {
      expect(
        allowedRolesForAdminLocation(AdminRoutes.usersPath),
        containsAll([AdminRole.superAdmin, AdminRole.opsAdmin]),
      );
      expect(
        allowedRolesForAdminLocation(AdminRoutes.dashboardPath),
        containsAll([AdminRole.superAdmin, AdminRole.opsAdmin]),
      );
    });
  });
}
