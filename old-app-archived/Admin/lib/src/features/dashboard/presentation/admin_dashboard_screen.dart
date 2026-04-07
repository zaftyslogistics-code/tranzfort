import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../../shared/widgets/admin_stat_card.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/admin_dashboard_repository.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../providers/dashboard_kpi_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(supabaseConfiguredProvider);
    final snapshotAsync = ref.watch(dashboardKpiProvider);
    final role = ref.watch(currentAdminRoleProvider);
    final adminAsync = ref.watch(currentAdminAccessProvider);

    final canOperate = adminHasAccess(role, {
      AdminRole.superAdmin,
      AdminRole.opsAdmin,
    });
    final isSuperAdmin = adminHasAccess(role, {AdminRole.superAdmin});
    final headerSubtitle = adminAsync.maybeWhen(
      data: (admin) => admin == null
          ? 'Role: Unknown'
          : 'Signed in as: ${admin.fullName} (${adminRoleLabel(admin.role)})',
      orElse: () =>
          'Platform control center for KPIs, verification and support',
    );

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/dashboard'),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push('/users'),
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'User Management',
          ),
          if (canOperate)
            IconButton(
              onPressed: () => context.push('/verifications'),
              icon: const Icon(Icons.verified_user_outlined),
              tooltip: 'Verification Queue',
            ),
          IconButton(
            onPressed: () => context.push('/support'),
            icon: const Icon(Icons.support_agent),
            tooltip: 'Support tickets',
          ),
          if (canOperate)
            IconButton(
              onPressed: () => context.push('/super-ops'),
              icon: const Icon(Icons.star_outline),
              tooltip: 'Super Ops',
            ),
          if (canOperate)
            IconButton(
              onPressed: () => context.push('/loads'),
              icon: const Icon(Icons.local_shipping_outlined),
              tooltip: 'Load Management',
            ),
          if (isSuperAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              tooltip: 'More',
              onSelected: (value) {
                switch (value) {
                  case 'admin_management':
                    context.push('/admin-management');
                    break;
                  case 'audit_logs':
                    context.push('/audit-logs');
                    break;
                  case 'system_settings':
                    context.push('/system-settings');
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'admin_management',
                  child: Text('Admin Management'),
                ),
                PopupMenuItem<String>(
                  value: 'audit_logs',
                  child: Text('Audit logs'),
                ),
                PopupMenuItem<String>(
                  value: 'system_settings',
                  child: Text('System settings'),
                ),
              ],
            ),
          IconButton(
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          AdminBrandHeader(
            title: 'Admin Operations',
            subtitle: headerSubtitle,
            icon: Icons.dashboard_outlined,
          ),
          const SizedBox(height: 16),
          if (!configured)
            const _InfoCard(
              icon: Icons.info_outline,
              title: 'Running in local preview mode',
              subtitle:
                  'Configure SUPABASE_URL and SUPABASE_ANON_KEY to enable live admin auth and data access.',
              iconBackgroundColor: AdminColors.infoTint,
              iconColor: AdminColors.info,
            ),
          const SizedBox(height: 12),
          snapshotAsync.when(
            data: (snapshot) => Column(
              children: [
                _KpiGrid(snapshot: snapshot),
                const SizedBox(height: 12),
                _SlaAlertsCard(alerts: snapshot.slaAlerts),
                const SizedBox(height: 12),
                _RecentActivityCard(items: snapshot.recentActivity),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _InfoCard(
              icon: Icons.error_outline,
              title: 'Unable to load dashboard metrics',
              subtitle:
                  'Please try again. The dashboard remains usable with fallback values.',
              trailing: TextButton(
                onPressed: () =>
                    ref.read(dashboardKpiProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _RecentActivityCard extends StatelessWidget {
  final List<String> items;

  const _RecentActivityCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'No recent activity available yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              )
            else
              ...visibleItems.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _activityIcon(entry.value),
                        size: 16,
                        color: AdminColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_activityTimestamp(entry.key)} · ${entry.value}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (items.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/audit-logs'),
                  child: const Text('View audit logs'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('ticket') || lower.contains('support')) {
      return Icons.support_agent;
    }
    if (lower.contains('verif')) {
      return Icons.verified_user_outlined;
    }
    if (lower.contains('load') || lower.contains('trip')) {
      return Icons.local_shipping_outlined;
    }
    if (lower.contains('user') || lower.contains('admin')) {
      return Icons.manage_accounts_outlined;
    }
    return Icons.history;
  }

  String _activityTimestamp(int index) {
    final minutesAgo = (index + 1) * 7;
    if (minutesAgo < 60) {
      return '${minutesAgo}m ago';
    }
    final hours = (minutesAgo / 60).floor();
    return '${hours}h ago';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? AdminColors.brandTealLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? AdminColors.primary),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AdminDashboardSnapshot snapshot;

  const _KpiGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Active Users',
        value: snapshot.activeUsers,
        icon: Icons.people_alt_outlined,
        color: AdminColors.primary,
      ),
      AdminStatCard(
        label: 'Verified Trucks',
        value: snapshot.verifiedTrucks,
        icon: Icons.local_shipping_outlined,
        color: AdminColors.brandOrange,
      ),
      AdminStatCard(
        label: 'Pending Verifications',
        value: snapshot.pendingVerifications,
        icon: Icons.verified_user_outlined,
        color: AdminColors.brandTealDark,
      ),
      AdminStatCard(
        label: 'Open Tickets',
        value: snapshot.openTickets,
        icon: Icons.support_agent,
        color: AdminColors.brandOrange,
      ),
      AdminStatCard(
        label: 'Active Super Loads',
        value: snapshot.activeSuperLoads,
        icon: Icons.auto_awesome,
        color: AdminColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _SlaAlertsCard extends StatelessWidget {
  final List<AdminSlaAlert> alerts;

  const _SlaAlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA alerts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (alerts.isEmpty)
              Text(
                'No active SLA alerts right now.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              )
            else
              ...alerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: alert.severity == AdminAlertSeverity.critical
                              ? AdminColors.errorTint
                              : AdminColors.warningTint,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: alert.severity == AdminAlertSeverity.critical
                              ? AdminColors.error
                              : AdminColors.brandOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/support'),
                child: const Text('View support tickets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
