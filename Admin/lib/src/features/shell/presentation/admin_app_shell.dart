import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/providers/admin_app_state_providers.dart';
import '../../../core/repositories/admin_auth_repository.dart';
import '../../../core/theme/admin_colors.dart';

class AdminAppShell extends ConsumerWidget {
  final String currentLocation;
  final Widget child;

  const AdminAppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  static const _items = <_AdminNavItem>[
    _AdminNavItem(route: AdminRoutes.dashboardPath, label: 'Dashboard', icon: Icons.dashboard_outlined, title: 'Dashboard'),
    _AdminNavItem(route: AdminRoutes.verificationPath, label: 'Verification', icon: Icons.verified_user_outlined, title: 'Verification'),
    _AdminNavItem(route: AdminRoutes.supportPath, label: 'Support', icon: Icons.support_agent_outlined, title: 'Support'),
    _AdminNavItem(route: AdminRoutes.superOpsPath, label: 'Super Ops', icon: Icons.hub_outlined, title: 'Super Ops'),
    _AdminNavItem(route: AdminRoutes.loadManagementPath, label: 'Loads', icon: Icons.local_shipping_outlined, title: 'Load management'),
    _AdminNavItem(route: AdminRoutes.usersPath, label: 'Users', icon: Icons.manage_accounts_outlined, title: 'Users'),
    _AdminNavItem(route: AdminRoutes.adminManagementPath, label: 'Admins', icon: Icons.admin_panel_settings_outlined, title: 'Admin management'),
    _AdminNavItem(route: AdminRoutes.auditLogsPath, label: 'Audit logs', icon: Icons.history_outlined, title: 'Audit logs'),
    _AdminNavItem(route: AdminRoutes.settingsPath, label: 'Settings', icon: Icons.settings_outlined, title: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAdminAuthStateProvider);
    final visibleItems = authState.verificationFailed
        ? _items.where((item) => item.route == AdminRoutes.dashboardPath).toList(growable: false)
        : authState.role == AdminRole.superAdmin
            ? _items
            : _items.where((item) => item.route != AdminRoutes.adminManagementPath).toList(growable: false);
    final currentIndex = _resolveIndex(currentLocation, visibleItems);
    final currentItem = visibleItems[currentIndex];
    const mobileBreakpoint = 900.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < mobileBreakpoint;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentItem.title),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go(AdminRoutes.notificationsPath),
                icon: const Icon(Icons.notifications_none),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: const Text('Admin'),
                  avatar: const Icon(Icons.shield_outlined, size: 18),
                  side: const BorderSide(color: AdminColors.divider),
                  backgroundColor: AdminColors.raisedSurface,
                ),
              ),
            ],
          ),
          drawer: _AdminDrawer(
            showAdminManagement: authState.role == AdminRole.superAdmin && !authState.verificationFailed,
            onSignOut: () async {
              await ref.read(adminAuthRepositoryProvider).signOut();
              if (context.mounted) {
                context.go(AdminRoutes.loginPath);
              }
            },
          ),
          body: Column(
            children: [
              if (authState.verificationFailed)
                Container(
                  width: double.infinity,
                  color: AdminColors.warning.withValues(alpha: 0.14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    'Admin session verification is unavailable right now. Dashboard access is limited until admin access can be re-verified against the database.',
                    style: TextStyle(color: AdminColors.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: useCompactLayout
                    ? child
                    : Row(
                        children: [
                          NavigationRail(
                            selectedIndex: currentIndex,
                            onDestinationSelected: (index) => context.go(visibleItems[index].route),
                            labelType: NavigationRailLabelType.all,
                            backgroundColor: AdminColors.cardSurface,
                            selectedIconTheme: const IconThemeData(color: AdminColors.accentTeal),
                            selectedLabelTextStyle: const TextStyle(color: AdminColors.accentTeal),
                            destinations: visibleItems
                                .map(
                                  (item) => NavigationRailDestination(
                                    icon: Icon(item.icon),
                                    selectedIcon: Icon(item.icon),
                                    label: Text(item.label),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: child),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _resolveIndex(String location, List<_AdminNavItem> items) {
    final index = items.indexWhere((item) => item.route == location);
    if (index != -1) {
      return index;
    }

    if (location == AdminRoutes.notificationsPath) {
      return 0;
    }

    if (location.startsWith('${AdminRoutes.loadManagementPath}/')) {
      return items.indexWhere((item) => item.route == AdminRoutes.loadManagementPath);
    }

    if (location.startsWith('${AdminRoutes.verificationPath}/')) {
      return items.indexWhere((item) => item.route == AdminRoutes.verificationPath);
    }

    if (location.startsWith('${AdminRoutes.usersPath}/')) {
      return items.indexWhere((item) => item.route == AdminRoutes.usersPath);
    }

    if (location.startsWith('${AdminRoutes.supportPath}/')) {
      return items.indexWhere((item) => item.route == AdminRoutes.supportPath);
    }

    if (location.startsWith('${AdminRoutes.superOpsPath}/')) {
      return items.indexWhere((item) => item.route == AdminRoutes.superOpsPath);
    }

    return 0;
  }
}

class _AdminDrawer extends StatelessWidget {
  final bool showAdminManagement;
  final Future<void> Function() onSignOut;

  const _AdminDrawer({required this.showAdminManagement, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(gradient: AdminColors.adminPrimary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings_outlined, color: AdminColors.accentTeal),
                  ),
                  const SizedBox(height: 16),
                  Text('TranZfort Admin', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Operations workspace', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _AdminDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () => _go(context, AdminRoutes.dashboardPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Verification',
                    onTap: () => _go(context, AdminRoutes.verificationPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Users',
                    onTap: () => _go(context, AdminRoutes.usersPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.support_agent_outlined,
                    label: 'Support',
                    onTap: () => _go(context, AdminRoutes.supportPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.hub_outlined,
                    label: 'Super Ops',
                    onTap: () => _go(context, AdminRoutes.superOpsPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Loads',
                    onTap: () => _go(context, AdminRoutes.loadManagementPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => _go(context, AdminRoutes.notificationsPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.history_outlined,
                    label: 'Audit logs',
                    onTap: () => _go(context, AdminRoutes.auditLogsPath),
                  ),
                  if (showAdminManagement)
                    _AdminDrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admins',
                      onTap: () => _go(context, AdminRoutes.adminManagementPath),
                    ),
                  _AdminDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _go(context, AdminRoutes.settingsPath),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.logout,
                    label: 'Sign out',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await onSignOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _AdminDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AdminColors.accentTeal),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _AdminNavItem {
  final String route;
  final String label;
  final IconData icon;
  final String title;

  const _AdminNavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.title,
  });
}
