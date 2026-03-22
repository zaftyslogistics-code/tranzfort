import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/providers/admin_app_state_providers.dart';
import '../../../core/repositories/admin_dashboard_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_dashboard_provider.dart';

part 'admin_dashboard_sections.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(adminDashboardProvider);
    final authState = ref.watch(currentAdminAuthStateProvider);
    final roleLabel = switch (authState.role) {
      AdminRole.superAdmin => 'Super Admin',
      AdminRole.opsAdmin => 'Ops Admin',
      AdminRole.unknown => 'Admin',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 640 ? 16.0 : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 32),
          children: [
            _DashboardHeroCard(roleLabel: roleLabel),
            const SizedBox(height: 16),
            snapshotAsync.when(
              data: (snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!snapshot.isLiveData) ...[
                    const _DashboardInfoCard(
                      title: 'Running with fallback dashboard data',
                      message: 'Live Supabase-backed dashboard counts are not available right now, so the admin home is showing safe zero-state metrics until backend access is configured.',
                      icon: Icons.info_outline,
                      tint: AdminColors.infoBg,
                      iconColor: AdminColors.info,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DashboardMetricGrid(snapshot: snapshot),
                  const SizedBox(height: 16),
                  _DashboardQuickNavCard(role: authState.role),
                  const SizedBox(height: 16),
                  _DashboardAlertsCard(alerts: snapshot.slaAlerts),
                  const SizedBox(height: 16),
                  _DashboardRecentActivityCard(items: snapshot.recentActivity),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _DashboardInfoCard(
                title: 'Unable to load dashboard metrics',
                message: 'The admin dashboard could not load its latest metrics. Retry to refresh the summary and alert sections.',
                icon: Icons.error_outline,
                tint: AdminColors.errorBg,
                iconColor: AdminColors.error,
                trailing: FilledButton.tonal(
                  onPressed: () => ref.read(adminDashboardProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
