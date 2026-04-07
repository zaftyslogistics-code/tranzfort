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
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../core/utils/error_logger.dart';
import '../../../shared/utils/verification_status_utils.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../widgets/index.dart';

class TruckerDashboardScreen extends ConsumerWidget {
  const TruckerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final verificationStatus = normalizeVerificationStatus(
      profile?['verification_status'],
    );

    ErrorLogger.logDebug(
      'Trucker dashboard profile snapshot',
      context: {
        'module': 'trucker_dashboard',
        'userId': profile?['id'],
        'role': profile?['user_role_type'],
        'rawVerificationStatus': profile?['verification_status'],
        'normalizedVerificationStatus': verificationStatus,
      },
    );
    
    final dashboardDataAsync = ref.watch(truckerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.truckerDashboardTitle),
        actions: [
          AppBarUtilityActions(ttsPreviewText: l10n.truckerDashboardTtsContext),
        ],
      ),
      drawer: const AppDrawer(role: 'trucker'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verificationStatus != 'verified') ...[
              DashboardVerificationBanner(
                status: verificationStatus,
                onTap: () => context.push('/verification/trucker'),
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
      bottomNavigationBar: const BottomNavBar(currentRole: 'trucker'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bot-chat'),
        backgroundColor: AppColors.secondaryAmber,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, TruckerDashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SolidHeader(
          title: l10n.truckerOverview,
          subtitle: l10n.tripOverviewSubtitle,
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.truckerDashboardActiveBidsLabel,
                value: data.activeBidsCount,
                icon: Icons.gavel,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                label: l10n.truckerDashboardUpcomingTripsLabel,
                value: data.upcomingTripsCount,
                icon: Icons.event,
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
                label: l10n.tripStageInTransit,
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
        
        if (data.pendingBidsList.isEmpty &&
            data.upcomingTripsList.isEmpty &&
            data.inTransitTripsCount == 0) ...[
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookLoadPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: () => context.push('/find-loads'),
                    label: l10n.findLoadsAction,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (data.pendingBidsList.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.truckerDashboardPendingBidsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/my-trips'),
                child: Text(l10n.myTripsTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...data.pendingBidsList.take(3).map((trip) => TripSummaryCard(
            trip: trip,
            onTap: () => context.push('/trip-detail/${trip['id']}'),
          )),
        ],

        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.truckerDashboardUpcomingActiveTripsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-trips'),
              child: Text(l10n.myTripsTitle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.upcomingTripsList.isEmpty && data.inTransitTripsCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              l10n.noActiveTrips,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...data.upcomingTripsList.take(5).map((trip) => TripSummaryCard(
            trip: trip,
            onTap: () => context.push('/trip-detail/${trip['id']}'),
          )),
          
        const SizedBox(height: AppSpacing.xxxl), // Bottom padding for FAB
      ],
    );
  }
}
