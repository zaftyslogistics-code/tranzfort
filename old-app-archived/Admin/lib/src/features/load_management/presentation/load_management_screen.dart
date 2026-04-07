import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';

class LoadManagementScreen extends ConsumerWidget {
  const LoadManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentAdminRoleProvider);
    final canOperate = adminHasAccess(role, {
      AdminRole.superAdmin,
      AdminRole.opsAdmin,
    });

    if (!canOperate) {
      return Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/loads'),
        appBar: AppBar(title: const Text('Load management')),
        body: const Center(
          child: Text('Only Super Admins and Ops Admins can access load management.'),
        ),
      );
    }

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/loads'),
      appBar: AppBar(title: const Text('Load management')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: const [
          AdminBrandHeader(
            title: 'Load Control Center',
            subtitle:
                'Review active, booked, transit, and completed loads across the network',
            icon: Icons.local_shipping_outlined,
          ),
          SizedBox(height: 12),
          _LoadManagementEmptyStateCard(),
        ],
      ),
    );
  }
}

class _LoadManagementEmptyStateCard extends StatelessWidget {
  const _LoadManagementEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Load management controls are being expanded.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use related modules meanwhile for live operations.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/super-ops'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Open Super Ops'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/users'),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Open Users'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
