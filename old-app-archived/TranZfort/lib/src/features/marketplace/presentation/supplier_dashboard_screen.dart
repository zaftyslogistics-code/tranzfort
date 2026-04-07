import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/dashboard_verification_banner.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/booking_request_card.dart';
import '../widgets/load_summary_card.dart';

class SupplierDashboardScreen extends ConsumerWidget {
  const SupplierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final verificationStatus = (profile?['verification_status'] ?? '').toString().toLowerCase();
    
    final dashboardDataAsync = ref.watch(supplierDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supplierDashboardTitle),
        actions: [
          AppBarUtilityActions(ttsPreviewText: l10n.supplierDashboardTtsContext),
        ],
      ),
      drawer: const AppDrawer(role: 'supplier'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verificationStatus != 'verified') ...[
              DashboardVerificationBanner(
                status: verificationStatus,
                onTap: () => context.push('/verification/supplier'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            dashboardDataAsync.when(
              data: (data) => _buildDashboardContent(context, data, l10n),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    uiSafeErrorText(context, e, fallback: l10n.tripsLoadError),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRole: 'supplier'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-load'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.postLoadAction,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, SupplierDashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SolidHeader(
          title: l10n.supplierOverview,
          subtitle: l10n.myLoadsOverviewSubtitle,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.myLoadsActiveLabel,
                value: data.activeLoadsCount,
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: l10n.supplierDashboardPendingBookingsLabel,
                value: data.pendingBookingsCount,
                icon: Icons.pending_actions,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.myLoadsInTransitLabel,
                value: data.inTransitTripsCount,
                icon: Icons.local_shipping_outlined,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: l10n.completedTab,
                value: data.completedTripsCount,
                icon: Icons.task_alt_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        
        if (data.needsActionBookings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.supplierDashboardNeedsActionTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/my-loads'),
                child: Text(l10n.myLoadsTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...data.needsActionBookings.take(2).map((booking) => BookingRequestCard(
            booking: booking,
          )),
        ],

        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.supplierDashboardRecentLoadsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-loads'),
              child: Text(l10n.myLoadsTitle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.recentLoads.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              l10n.supplierDashboardNoRecentLoads,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...data.recentLoads.take(3).map((load) => LoadSummaryCard(
            load: load,
            onTap: () => context.push('/load-detail/${load['id']}'),
          )),
          
        const SizedBox(height: AppSpacing.xxxl), // Bottom padding for FAB
      ],
    );
  }
}
