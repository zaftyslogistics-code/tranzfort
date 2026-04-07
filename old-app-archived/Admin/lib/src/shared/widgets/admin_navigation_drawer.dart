import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/repositories/admin_access_repository.dart';
import '../../features/auth/providers/admin_auth_provider.dart';

class AdminNavigationDrawer extends ConsumerWidget {
  const AdminNavigationDrawer({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentAdminRoleProvider);
    final canOperate = adminHasAccess(role, {
      AdminRole.superAdmin,
      AdminRole.opsAdmin,
    });
    final isSuperAdmin = adminHasAccess(role, {AdminRole.superAdmin});

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'TranZfort Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _DrawerNavTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: _selectedFor('/dashboard'),
              onTap: () => _go(context, '/dashboard'),
            ),
            if (canOperate)
              _DrawerNavTile(
                icon: Icons.verified_user_outlined,
                label: 'Verifications',
                selected: _selectedFor('/verifications') ||
                    _selectedFor('/verification/'),
                onTap: () => _go(context, '/verifications'),
              ),
            _DrawerNavTile(
              icon: Icons.manage_accounts_outlined,
              label: 'Users',
              selected: _selectedFor('/users') || _selectedFor('/user/'),
              onTap: () => _go(context, '/users'),
            ),
            _DrawerNavTile(
              icon: Icons.support_agent,
              label: 'Support',
              selected: _selectedFor('/support'),
              onTap: () => _go(context, '/support'),
            ),
            if (canOperate)
              _DrawerNavTile(
                icon: Icons.star_outline,
                label: 'Super Ops',
                selected: _selectedFor('/super-ops'),
                onTap: () => _go(context, '/super-ops'),
              ),
            if (canOperate)
              _DrawerNavTile(
                icon: Icons.local_shipping_outlined,
                label: 'Load management',
                selected: _selectedFor('/loads'),
                onTap: () => _go(context, '/loads'),
              ),
            if (isSuperAdmin)
              _DrawerNavTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin management',
                selected: _selectedFor('/admin-management'),
                onTap: () => _go(context, '/admin-management'),
              ),
            if (isSuperAdmin)
              _DrawerNavTile(
                icon: Icons.fact_check_outlined,
                label: 'Audit logs',
                selected: _selectedFor('/audit-logs'),
                onTap: () => _go(context, '/audit-logs'),
              ),
            if (isSuperAdmin)
              _DrawerNavTile(
                icon: Icons.settings_outlined,
                label: 'System settings',
                selected: _selectedFor('/system-settings'),
                onTap: () => _go(context, '/system-settings'),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(adminAuthProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _selectedFor(String routePrefix) => currentRoute.startsWith(routePrefix);

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (!currentRoute.startsWith(route)) {
      context.go(route);
    }
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
