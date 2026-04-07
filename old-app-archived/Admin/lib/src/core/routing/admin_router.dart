import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/repositories/admin_access_repository.dart';
import '../../core/repositories/admin_verification_repository.dart';
import '../../features/admin_management/presentation/admin_management_screen.dart';
import '../../features/audit_logs/presentation/audit_logs_screen.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/load_management/presentation/load_management_screen.dart';
import '../../features/super_ops/presentation/super_ops_console_screen.dart';
import '../../features/super_ops/presentation/super_ops_load_detail_screen.dart';
import '../../features/super_ops/presentation/super_ops_post_on_behalf_screen.dart';
import '../../features/support/presentation/support_ticket_detail_screen.dart';
import '../../features/support/presentation/support_ticket_queue_screen.dart';
import '../../features/system_settings/presentation/system_settings_screen.dart';
import '../../features/users/presentation/user_detail_screen.dart';
import '../../features/users/presentation/user_list_screen.dart';
import '../../features/verification/presentation/verification_detail_screen.dart';
import '../../features/verification/presentation/verification_queue_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final configured = ref.watch(supabaseConfiguredProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      if (!configured) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final onLogin = state.matchedLocation == '/login';

      final role = loggedIn ? await _fetchCurrentRole() : null;
      final redirectTarget = resolveAdminRouteRedirect(
        configured: configured,
        loggedIn: loggedIn,
        onLogin: onLogin,
        matchedLocation: state.matchedLocation,
        role: role,
      );

      if (loggedIn && role == null && redirectTarget == '/login') {
        await Supabase.instance.client.auth.signOut();
      }

      return redirectTarget;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/verifications',
        builder: (context, state) => const VerificationQueueScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportTicketQueueScreen(),
      ),
      GoRoute(
        path: '/loads',
        builder: (context, state) => const LoadManagementScreen(),
      ),
      GoRoute(
        path: '/support/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId'] ?? '';
          if (ticketId.isEmpty) return const SupportTicketQueueScreen();
          return SupportTicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/super-ops',
        builder: (context, state) => const SuperOpsConsoleScreen(),
      ),
      GoRoute(
        path: '/super-ops/load/:loadId',
        builder: (context, state) {
          final loadId = state.pathParameters['loadId'] ?? '';
          if (loadId.isEmpty) return const SuperOpsConsoleScreen();
          return SuperOpsLoadDetailScreen(loadId: loadId);
        },
      ),
      GoRoute(
        path: '/super-ops/post-on-behalf',
        builder: (context, state) => const SuperOpsPostOnBehalfScreen(),
      ),
      GoRoute(
        path: '/admin-management',
        builder: (context, state) => const AdminManagementScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/system-settings',
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          if (userId.isEmpty) return const UserListScreen();
          return UserDetailScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/verification/:type/:id',
        builder: (context, state) {
          final typePath = (state.pathParameters['type'] ?? '').toLowerCase();
          final id = state.pathParameters['id'] ?? '';
          final type = verificationTypeFromPath(typePath);

          if (type == null || id.isEmpty) {
            return const VerificationQueueScreen();
          }

          return VerificationDetailScreen(type: type, id: id);
        },
      ),
    ],
  );
});

Future<AdminRole?> _fetchCurrentRole() async {
  final authUserId = Supabase.instance.client.auth.currentUser?.id;
  if (authUserId == null) return null;

  try {
    final row = await Supabase.instance.client
        .from('admin_users')
        .select('role,is_active')
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    if (row == null || row['is_active'] != true) return null;
    return adminRoleFromDb((row['role'] ?? '').toString());
  } catch (_) {
    return null;
  }
}

String? resolveAdminRouteRedirect({
  required bool configured,
  required bool loggedIn,
  required bool onLogin,
  required String matchedLocation,
  required AdminRole? role,
}) {
  if (!configured) return null;

  if (!loggedIn && !onLogin) return '/login';

  if (!loggedIn) return null;

  if (role == null) return '/login';

  if (onLogin) return '/dashboard';

  final allowedRoles = allowedRolesForAdminLocation(matchedLocation);
  if (allowedRoles != null && !allowedRoles.contains(role)) {
    return '/dashboard';
  }

  return null;
}

Set<AdminRole>? allowedRolesForAdminLocation(String location) {
  if (location.startsWith('/verifications') ||
      location.startsWith('/verification/') ||
      location.startsWith('/super-ops') ||
      location.startsWith('/loads')) {
    return {AdminRole.superAdmin, AdminRole.opsAdmin};
  }

  if (location.startsWith('/support') ||
      location.startsWith('/users') ||
      location.startsWith('/user/')) {
    return {AdminRole.superAdmin, AdminRole.opsAdmin, AdminRole.supportAgent};
  }

  if (location.startsWith('/admin-management') ||
      location.startsWith('/audit-logs') ||
      location.startsWith('/system-settings')) {
    return {AdminRole.superAdmin};
  }

  if (location.startsWith('/dashboard')) {
    return {AdminRole.superAdmin, AdminRole.opsAdmin, AdminRole.supportAgent};
  }

  return null;
}
