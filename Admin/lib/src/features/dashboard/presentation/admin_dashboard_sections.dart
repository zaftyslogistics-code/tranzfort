part of 'admin_dashboard_screen.dart';

class _DashboardHeroCard extends StatelessWidget {
  final String roleLabel;

  const _DashboardHeroCard({required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AdminColors.adminPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(roleLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 14),
          Text(
            'Operations Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track platform pressure, SLA risk, and the fastest next admin actions from one dark-theme control surface.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  final AdminDashboardSnapshot snapshot;

  const _DashboardMetricGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricCardData(
        label: 'Active users',
        value: snapshot.activeUsers.toString(),
        icon: Icons.people_alt_outlined,
        color: AdminColors.accentTeal,
        route: AdminRoutes.usersPath,
        actionLabel: 'Open users',
      ),
      _MetricCardData(label: 'Verified trucks', value: snapshot.verifiedTrucks.toString(), icon: Icons.local_shipping_outlined, color: AdminColors.accentBlue),
      _MetricCardData(
        label: 'Pending verifications',
        value: snapshot.pendingVerifications.toString(),
        icon: Icons.verified_user_outlined,
        color: AdminColors.warning,
        route: AdminRoutes.verificationPath,
        actionLabel: 'Open verification queue',
      ),
      _MetricCardData(
        label: 'Open tickets',
        value: snapshot.openTickets.toString(),
        icon: Icons.support_agent_outlined,
        color: AdminColors.error,
        route: AdminRoutes.supportPath,
        actionLabel: 'Open support queue',
      ),
      _MetricCardData(
        label: 'Active Super Loads',
        value: snapshot.activeSuperLoads.toString(),
        icon: Icons.hub_outlined,
        color: AdminColors.accentTeal,
        route: AdminRoutes.superOpsPath,
        actionLabel: 'Open Super Ops',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: metrics
                .map(
                  (metric) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardMetricCard(data: metric),
                  ),
                )
                .toList(growable: false),
          );
        }

        final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth >= 1100 ? 1.8 : 1.45;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) => _DashboardMetricCard(data: metrics[index]),
        );
      },
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? route;
  final String? actionLabel;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.route,
    this.actionLabel,
  });
}

class _DashboardMetricCard extends StatelessWidget {
  final _MetricCardData data;

  const _DashboardMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
                if ((data.route ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    key: ValueKey('dashboard-metric-action-${data.label}'),
                    onPressed: () => context.go(data.route!),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(data.actionLabel ?? 'Open'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardQuickNavCard extends StatelessWidget {
  final AdminRole role;

  const _DashboardQuickNavCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickNavItem(label: 'Verification', subtitle: 'Open review queue', icon: Icons.verified_user_outlined, route: AdminRoutes.verificationPath),
      _QuickNavItem(label: 'Support', subtitle: 'Follow open tickets', icon: Icons.support_agent_outlined, route: AdminRoutes.supportPath),
      _QuickNavItem(label: 'Users', subtitle: 'Inspect users and admins', icon: Icons.manage_accounts_outlined, route: AdminRoutes.usersPath),
      _QuickNavItem(label: 'Super Ops', subtitle: 'Track Super Load operations', icon: Icons.hub_outlined, route: AdminRoutes.superOpsPath),
      if (role == AdminRole.superAdmin)
        _QuickNavItem(
          label: 'Admin Management',
          subtitle: 'Review admin accounts',
          icon: Icons.admin_panel_settings_outlined,
          route: AdminRoutes.adminManagementPath,
        ),
      if (role == AdminRole.superAdmin)
        _QuickNavItem(
          label: 'Audit Logs',
          subtitle: 'Inspect platform audit events',
          icon: Icons.history_toggle_off_outlined,
          route: AdminRoutes.auditLogsPath,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactWidth = constraints.maxWidth < 560;
            final itemWidth = compactWidth ? constraints.maxWidth : 240.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick navigation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  role == AdminRole.superAdmin
                      ? 'Jump into oversight, operational, and management surfaces quickly.'
                      : 'Jump into the operational queues and shared admin surfaces you can work from now.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: items
                      .map(
                        (item) => SizedBox(
                          width: itemWidth,
                          child: OutlinedButton(
                            onPressed: () => context.go(item.route),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.centerLeft,
                              side: const BorderSide(color: AdminColors.divider),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.icon, color: AdminColors.accentTeal),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.label),
                                      const SizedBox(height: 4),
                                      Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickNavItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;

  const _QuickNavItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

class _DashboardAlertsCard extends StatelessWidget {
  final List<AdminSlaAlert> alerts;

  const _DashboardAlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SLA alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (alerts.isEmpty)
              Text(
                'No active SLA alerts right now.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
              )
            else
              ...alerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: alert.severity == AdminAlertSeverity.critical ? AdminColors.error : AdminColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(alert.message, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                      if ((alert.route ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: OutlinedButton(
                            key: ValueKey('dashboard-alert-action-${alert.actionLabel ?? alert.route}'),
                            onPressed: () => context.go(alert.route!),
                            child: Text(alert.actionLabel ?? 'Open related queue'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRecentActivityCard extends StatelessWidget {
  final List<AdminRecentActivityItem> items;

  const _DashboardRecentActivityCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'No recent activity available yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
              )
            else
              ...items.take(5).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history, size: 16, color: AdminColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
                            if (_recentActivityDetailPath(item) case final detailPath?) ...[
                              const SizedBox(height: 6),
                              OutlinedButton(
                                key: ValueKey('dashboard-open-recent-${item.targetObjectType}-${item.targetObjectId}'),
                                onPressed: () => context.go(detailPath),
                                child: const Text('Open related item'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String? _recentActivityDetailPath(AdminRecentActivityItem item) {
  final objectType = item.targetObjectType.trim().toLowerCase();
  final objectId = item.targetObjectId.trim();
  if (objectId.isEmpty) {
    return null;
  }
  return switch (objectType) {
    'profile' => AdminRoutes.userDetailPathFor(objectId),
    'support_ticket' => AdminRoutes.supportDetailPathFor(objectId),
    'verification_case' => AdminRoutes.verificationDetailPathFor(objectId),
    'operational_case' => AdminRoutes.operationalCaseDetailPathFor(objectId),
    'load' => AdminRoutes.loadDetailPathFor(objectId),
    _ => null,
  };
}

class _DashboardInfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final Widget? trailing;

  const _DashboardInfoCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.tint,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(message),
        trailing: trailing,
      ),
    );
  }
}
