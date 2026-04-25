import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../shell/presentation/shell_components.dart';
import '../data/trucker_dashboard_repository.dart';
import '../data/trucker_profile_repository.dart';
import '../providers/trucker_providers.dart';

class TruckerDashboardScreen extends ConsumerWidget {
  const TruckerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(truckerProfileProvider);
    final dashboardAsync = ref.watch(truckerDashboardProvider);
    final profile = profileAsync.valueOrNull;
    final Widget? topBanner = _buildTopBanner(context, ref, profileAsync, l10n);
    final List<Widget>? topBannerSection = topBanner == null ? null : <Widget>[topBanner];

    return ShellScrollView(
      children: [
        ...?topBannerSection,
        HeroActionCard(
          title: _heroTitle(profile, l10n),
          subtitle: '',
          compact: true,
          useDarkTheme: true,
          primaryAction: GradientButton(
            label: l10n.shellTitleFindLoads,
            onPressed: () => context.go(AppRoutes.findLoadsPath),
          ),
          child: _HeroSummary(profile: profile),
        ),
        DetailSectionCard(
          title: l10n.commonDashboardOverviewTitle,
          children: [
            _DashboardStatsSection(
              dashboardAsync: dashboardAsync,
              onRetry: () => ref.refresh(truckerDashboardProvider),
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.commonQuickActionsTitle,
          children: [
            QuickActionGrid(
              items: [
                QuickActionItem(
                  icon: Icons.search,
                  label: l10n.shellTitleFindLoads,
                  onTap: () => context.go(AppRoutes.findLoadsPath),
                ),
                QuickActionItem(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.commonFleetLabel,
                  onTap: () => context.go(AppRoutes.fleetPath),
                ),
                QuickActionItem(
                  icon: Icons.alt_route_outlined,
                  label: l10n.truckerDashboardQuickActionTripsLabel,
                  onTap: () => context.go(AppRoutes.tripsPath),
                ),
                QuickActionItem(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.commonChatLabel,
                  onTap: () => context.go(AppRoutes.messagesPath),
                ),
              ],
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.truckerDashboardRecentActivityTitle,
          children: [
            _RecentActivitySection(
              dashboardAsync: dashboardAsync,
              onRetry: () => ref.refresh(truckerDashboardProvider),
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.truckerDashboardReadinessNextStepsTitle,
          children: [
            _ReadinessSection(profileAsync: profileAsync, dashboardAsync: dashboardAsync),
          ],
        ),
      ],
    );
  }

  String _heroTitle(TruckerProfile? profile, AppLocalizations l10n) {
    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return l10n.truckerDashboardWelcomeBack(fullName);
    }

    return l10n.truckerDashboardTitle;
  }

  Widget? _buildTopBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TruckerProfile?> profileAsync,
    AppLocalizations l10n,
  ) {
    final profile = profileAsync.valueOrNull;
    final verificationStatus = (profile?.verificationStatus ?? '').trim().toLowerCase();

    if (profileAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardReadinessUnavailableTitle,
        message: l10n.truckerDashboardReadinessFailureMessage,
        compact: true,
        action: OutlineButton(
          label: l10n.commonRetryAction,
          onPressed: () => ref.refresh(truckerProfileProvider),
        ),
      );
    }

    if (profileAsync.isLoading) {
      return const LoadingShimmer(height: 92, itemCount: 1);
    }

    if (profile != null && profile.isVerified && profile.hasApprovedTruck) {
      return null;
    }

    if (verificationStatus == 'pending') {
      return _CompactDashboardBanner(
        status: VerificationBannerStatus.pending,
        title: l10n.commonVerificationPendingTitle,
        actionLabel: l10n.commonOpenVerificationAction,
        onTap: () => context.go(AppRoutes.truckerVerificationPath),
      );
    }

    if (verificationStatus == 'rejected') {
      return _CompactDashboardBanner(
        status: VerificationBannerStatus.rejected,
        title: l10n.commonVerificationNeedsAttentionTitle,
        actionLabel: l10n.truckerDashboardFixVerificationAction,
        onTap: () => context.go(AppRoutes.truckerVerificationPath),
      );
    }

    if (verificationStatus == 'unverified' && profile != null && !profile.hasApprovedTruck) {
      return _CompactDashboardBanner(
        status: VerificationBannerStatus.pending,
        title: l10n.truckerDashboardCompleteFleetVerificationTitle,
        actionLabel: l10n.truckerDashboardOpenFleetVerificationAction,
        onTap: () => context.go(AppRoutes.truckerVerificationPath),
      );
    }

    if (profile != null && !profile.hasApprovedTruck) {
      return _CompactDashboardBanner(
        status: VerificationBannerStatus.pending,
        title: l10n.truckerDashboardAddApproveFirstTruckTitle,
        actionLabel: l10n.truckerDashboardOpenFleetAction,
        onTap: () => context.go(AppRoutes.fleetPath),
      );
    }

    if (verificationStatus == 'unverified') {
      return _CompactDashboardBanner(
        status: VerificationBannerStatus.pending,
        title: l10n.truckerDashboardCompleteVerificationTitle,
        actionLabel: l10n.truckerDashboardOpenFleetVerificationAction,
        onTap: () => context.go(AppRoutes.truckerVerificationPath),
      );
    }

    return null;
  }
}

class _CompactDashboardBanner extends StatelessWidget {
  final VerificationBannerStatus status;
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _CompactDashboardBanner({
    required this.status,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      VerificationBannerStatus.pending => (AppColors.warningBg, AppColors.warning, Icons.hourglass_top_outlined),
      VerificationBannerStatus.approved => (AppColors.successBg, AppColors.success, Icons.verified_outlined),
      VerificationBannerStatus.rejected => (AppColors.errorBg, AppColors.error, Icons.cancel_outlined),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              side: BorderSide(color: foreground.withValues(alpha: 0.4)),
              foregroundColor: foreground,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final TruckerProfile? profile;

  const _HeroSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final verificationLabel = _localizedTruckerDashboardVerificationStatus(
      l10n,
      profile?.verificationStatus,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusBadge(
              label: verificationLabel,
              icon: Icons.verified_outlined,
            ),
            if ((profile?.approvedTrucks ?? 0) > 0)
              StatusBadge(
                label: l10n.truckerDashboardApprovedTruckCount(profile!.approvedTrucks),
                icon: Icons.local_shipping_outlined,
                palette: const StatusPalette(
                  foreground: AppColors.primary,
                  background: AppColors.neutralBg,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String _localizedTruckerDashboardVerificationStatus(AppLocalizations l10n, String? status) {
  final normalized = (status ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'verified':
      return l10n.verificationStatusVerified;
    case 'pending':
      return l10n.commonPendingLabel;
    case 'rejected':
      return l10n.verificationStatusRejected;
    case 'unverified':
      return l10n.verificationStatusUnverified;
    case '':
      return l10n.truckerDashboardSetupInProgress;
    default:
      return l10n.commonUnknownLabel;
  }
}

class _DashboardStatsSection extends StatelessWidget {
  final AsyncValue<TruckerDashboardStats> dashboardAsync;
  final VoidCallback onRetry;

  const _DashboardStatsSection({
    required this.dashboardAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (dashboardAsync.isLoading) {
      return const LoadingShimmer(height: 112, itemCount: 4);
    }

    if (dashboardAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardLoadFailureTitle,
        message: l10n.truckerDashboardLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }

    final stats = dashboardAsync.valueOrNull ??
        const TruckerDashboardStats(
          activeBids: 0,
          upcomingTrips: 0,
          inTransitTrips: 0,
          completedTrips: 0,
          totalTrucks: 0,
          approvedTrucks: 0,
          pendingTrucks: 0,
          rejectedTrucks: 0,
          pendingReapprovalTrucks: 0,
        );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        StatCard(
          label: l10n.truckerDashboardStatActiveBidsLabel,
          value: '${stats.activeBids}',
          accent: AppColors.secondary,
        ),
        StatCard(
          label: l10n.truckerDashboardStatUpcomingTripsLabel,
          value: '${stats.upcomingTrips}',
          accent: AppColors.warning,
        ),
        StatCard(
          label: l10n.truckerDashboardStatInTransitLabel,
          value: '${stats.inTransitTrips}',
          accent: AppColors.info,
        ),
        StatCard(
          label: l10n.commonCompletedLabel,
          value: '${stats.completedTrips}',
          accent: AppColors.success,
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final AsyncValue<TruckerDashboardStats> dashboardAsync;
  final VoidCallback onRetry;

  const _RecentActivitySection({
    required this.dashboardAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (dashboardAsync.isLoading) return const LoadingShimmer(height: 96, itemCount: 2);
    if (dashboardAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardRecentActivityUnavailableTitle,
        message: l10n.truckerDashboardRecentActivityUnavailableMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }
    final stats = dashboardAsync.valueOrNull ?? const TruckerDashboardStats(activeBids: 0, upcomingTrips: 0, inTransitTrips: 0, completedTrips: 0, totalTrucks: 0, approvedTrucks: 0, pendingTrucks: 0, rejectedTrucks: 0, pendingReapprovalTrucks: 0);
    final hasActivity = stats.activeBids > 0 || stats.upcomingTrips > 0 || stats.inTransitTrips > 0 || stats.completedTrips > 0 || stats.hasTruckLifecycleAttention;
    if (!hasActivity) {
      return EmptyStateView(
        icon: Icons.history_outlined,
        title: l10n.truckerDashboardNoRecentActivityTitle,
        subtitle: l10n.truckerDashboardNoRecentActivitySubtitle,
      );
    }
    return Column(
      children: [
        StandardListCard(
          accent: AppColors.secondary,
          title: l10n.truckerDashboardBookingActivityTitle,
          subtitle: l10n.truckerDashboardBookingActivitySubtitle(stats.activeBids),
          trailing: StatusChip(label: l10n.truckerDashboardStatusValue(stats.activeBids > 0 ? 'open' : 'clear')),
        ),
        const SizedBox(height: AppSpacing.md),
        StandardListCard(
          accent: stats.inTransitTrips > 0 ? AppColors.info : AppColors.warning,
          title: l10n.truckerDashboardTripActivityTitle,
          subtitle: l10n.truckerDashboardTripActivitySubtitle(
            stats.upcomingTrips,
            stats.inTransitTrips,
            stats.completedTrips,
          ),
          trailing: StatusChip(label: l10n.truckerDashboardStatusValue(stats.inTransitTrips > 0 ? 'moving' : 'tracked')),
        ),
        if (stats.hasTruckLifecycleAttention) ...[
          const SizedBox(height: AppSpacing.md),
          StandardListCard(
            accent: AppColors.warning,
            title: l10n.truckerDashboardFleetReviewActivityTitle,
            subtitle: l10n.truckerDashboardFleetReviewActivitySubtitle(
              stats.pendingTrucks,
              stats.rejectedTrucks,
              stats.pendingReapprovalTrucks,
            ),
            trailing: StatusChip(label: l10n.truckerDashboardStatusValue('attention')),
          ),
        ],
      ],
    );
  }
}

class _ReadinessSection extends StatelessWidget {
  final AsyncValue<TruckerProfile?> profileAsync;
  final AsyncValue<TruckerDashboardStats> dashboardAsync;

  const _ReadinessSection({
    required this.profileAsync,
    required this.dashboardAsync,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (profileAsync.isLoading || dashboardAsync.isLoading) {
      return const LoadingShimmer(height: 110, itemCount: 2);
    }

    if (profileAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardReadinessSummaryUnavailableTitle,
        message: l10n.truckerDashboardReadinessSummaryUnavailableMessage,
      );
    }

    final profile = profileAsync.valueOrNull;
    final stats = dashboardAsync.valueOrNull;
    if (profile == null) {
      return EmptyStateView(
        icon: Icons.person_outline,
        title: l10n.truckerDashboardProfileSetupInProgressTitle,
        subtitle: l10n.truckerDashboardProfileSetupInProgressSubtitle,
      );
    }
    final resolvedStats = stats ?? TruckerDashboardStats(
      activeBids: 0,
      upcomingTrips: 0,
      inTransitTrips: 0,
      completedTrips: 0,
      totalTrucks: profile.totalTrucks,
      approvedTrucks: profile.approvedTrucks,
      pendingTrucks: 0,
      rejectedTrucks: 0,
      pendingReapprovalTrucks: 0,
    );

    return Column(
      children: [
        StandardListCard(
          accent: statusPaletteFor(profile.verificationStatus).foreground,
          title: l10n.truckerDashboardVerificationStatusTitle,
          subtitle: _localizedTruckerDashboardVerificationStatus(l10n, profile.verificationStatus),
          trailing: StatusChip(label: _localizedTruckerDashboardVerificationStatus(l10n, profile.verificationStatus)),
          footer: (profile.dlNumber ?? '').trim().isEmpty
              ? null
              : Text(l10n.truckerDashboardDlLabel(profile.dlNumber!), style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: AppSpacing.md),
        StandardListCard(
          accent: resolvedStats.hasApprovedTruck ? AppColors.success : AppColors.warning,
          title: l10n.truckerDashboardFleetReadinessTitle,
          subtitle: l10n.truckerDashboardApprovedTrucksSummary(
            resolvedStats.approvedTrucks,
            resolvedStats.totalTrucks,
          ),
          trailing: StatusChip(
            label: resolvedStats.hasApprovedTruck ? l10n.truckerDashboardReadyStatus : l10n.truckerDashboardActionNeededStatus,
          ),
          footer: resolvedStats.hasTruckLifecycleAttention
              ? Text(
                  _truckLifecycleAttentionMessage(resolvedStats, l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
        ),
      ],
    );
  }

  String _truckLifecycleAttentionMessage(TruckerDashboardStats stats, AppLocalizations l10n) {
    final segments = <String>[];
    if (stats.pendingTrucks > 0) {
      segments.add(l10n.truckerDashboardTruckAwaitingReview(stats.pendingTrucks));
    }
    if (stats.rejectedTrucks > 0) {
      segments.add(l10n.truckerDashboardTruckRejected(stats.rejectedTrucks));
    }
    if (stats.pendingReapprovalTrucks > 0) {
      segments.add(l10n.truckerDashboardTruckPendingReapproval(stats.pendingReapprovalTrucks));
    }
    return l10n.truckerDashboardTruckLifecycleAttention(segments.join(' - '));
  }
}
