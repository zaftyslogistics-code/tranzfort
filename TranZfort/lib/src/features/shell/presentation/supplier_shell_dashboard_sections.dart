import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_dashboard_repository.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/data/supplier_profile_repository.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../../features/supplier/providers/supplier_providers.dart';
import 'shell_components.dart';
import 'supplier_shell_shared_helpers.dart';

String _localizedLinkedTripProofStatus(AppLocalizations l10n, LinkedTrip trip) {
  String normalized;
  if (trip.hasPodProof) {
    normalized = 'pod_uploaded';
  } else if (trip.hasLrProof) {
    normalized = 'lr_uploaded';
  } else {
    normalized = switch (trip.stage.trim().toLowerCase()) {
      'delivered' => 'awaiting_pod',
      'proof_submitted' => 'proof_submitted',
      _ => 'other',
    };
  }
  return l10n.proofStatusValue(normalized);
}




class BookingRequestCard extends StatelessWidget {
  final LoadBookingRequest booking;
  final bool isApproving;
  final bool isRejecting;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  const BookingRequestCard({
    super.key,
    required this.booking,
    required this.isApproving,
    required this.isRejecting,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final truckerMeta = <String>[
      if (booking.truckerVerificationStatus == 'verified') l10n.supplierBookingVerifiedLabel,
      if (booking.truckerRating != null && booking.truckerRating! > 0)
        l10n.supplierBookingRatingLabel(booking.truckerRating!.toStringAsFixed(1)),
    ].join(' - ');
    final truckMeta = <String>[
      if (booking.truckBodyType != null) booking.truckBodyType!,
      if (booking.truckTyres != null) l10n.supplierBookingTyres('${booking.truckTyres}'),
    ].join(' - ');

    return StandardListCard(
      accent: statusPaletteFor(booking.status).foreground,
      title: booking.displayTruckerName,
      subtitle: l10n.supplierBookingSubmittedAt(
        booking.displayTruckLabel,
        formatSupplierDateTime(context, booking.createdAt),
      ),
      leading: InkWell(
        onTap: () => context.push(AppRoutes.publicProfileLocation(booking.truckerId)),
        borderRadius: BorderRadius.circular(20),
        child: UserAvatar(
          avatarUrl: booking.truckerAvatarUrl,
          userId: booking.truckerId,
          initials: booking.displayTruckerName.isNotEmpty ? booking.displayTruckerName[0].toUpperCase() : 'T',
          radius: 20,
          fallbackColor: statusPaletteFor(booking.status).foreground.withValues(alpha: 0.1),
        ),
      ),
      trailing: StatusChip(label: localizedSupplierBookingStatus(l10n, booking.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (truckerMeta.isNotEmpty) ...[
            Text(truckerMeta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (truckMeta.isNotEmpty) ...[
            Text(truckMeta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (booking.decisionReason != null) ...[
            Text(booking.decisionReason!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (booking.isSubmitted)
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: l10n.chatActionApprove,
                    isLoading: isApproving,
                    onPressed: isApproving || isRejecting || onApprove == null ? null : () => onApprove!.call(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlineButton(
                    label: l10n.chatActionReject,
                    isLoading: isRejecting,
                    onPressed: isApproving || isRejecting || onReject == null ? null : () => onReject!.call(),
                  ),
                ),
              ],
            )
          else if (booking.decidedAt != null)
            Text(
              l10n.supplierBookingDecisionRecorded(formatSupplierDateTime(context, booking.decidedAt!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class LinkedTripCard extends StatelessWidget {
  final LinkedTrip trip;

  const LinkedTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripPath = '${AppRoutes.tripDetailPath}/${trip.id}';

    return StandardListCard(
      accent: statusPaletteFor(trip.stage).foreground,
      title: trip.routeLabel,
      subtitle: l10n.supplierLinkedTripSubtitle(
        trip.material,
        shortId(trip.truckerId),
        shortId(trip.truckId),
      ),
      trailing: StatusChip(label: localizedSupplierTripStage(l10n, trip.stage)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierLinkedTripAssignedLabel(formatSupplierDateTime(context, trip.assignedAt)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.supplierLinkedTripProofLabel(_localizedLinkedTripProofStatus(l10n, trip)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          TextActionButton(
            label: l10n.supplierLinkedTripTrackAction,
            onPressed: () => context.go(tripPath),
          ),
        ],
      ),
      onTap: () => context.go(tripPath),
    );
  }
}




class _HeroSummary extends StatelessWidget {
  final SupplierProfile? profile;

  const _HeroSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verificationLabel = localizedSupplierDashboardVerificationStatus(
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
            if ((profile?.companyName ?? '').trim().isNotEmpty)
              StatusBadge(
                label: profile!.companyName!.trim(),
                icon: Icons.business_outlined,
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

class _DashboardStatsSection extends StatelessWidget {
  final AsyncValue<SupplierDashboardStats> dashboardAsync;
  final VoidCallback onRetry;

  const _DashboardStatsSection({
    required this.dashboardAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (dashboardAsync.isLoading) {
      return const LoadingShimmer(height: 112, itemCount: 4);
    }

    if (dashboardAsync.hasError) {
      return WarningBlock(
        title: l10n.supplierDashboardLoadFailureTitle,
        message: supplierAsyncFailure(dashboardAsync)?.message ?? l10n.supplierDashboardLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }

    final stats = dashboardAsync.valueOrNull ??
        const SupplierDashboardStats(
          activeLoads: 0,
          pendingBookings: 0,
          inTransitTrips: 0,
          completedTrips: 0,
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
          label: l10n.supplierDashboardStatsActiveLoadsLabel,
          value: '${stats.activeLoads}',
          accent: AppColors.primary,
        ),
        StatCard(
          label: l10n.supplierDashboardStatsPendingBookingsLabel,
          value: '${stats.pendingBookings}',
          accent: AppColors.secondary,
        ),
        StatCard(
          label: l10n.supplierDashboardStatsInTransitTripsLabel,
          value: '${stats.inTransitTrips}',
          accent: AppColors.info,
        ),
        StatCard(
          label: l10n.supplierDashboardStatsCompletedTripsLabel,
          value: '${stats.completedTrips}',
          accent: AppColors.success,
        ),
      ],
    );
  }
}

class _SuperLoadReadinessSection extends StatelessWidget {
  final SupplierProfile? profile;

  const _SuperLoadReadinessSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasBusinessLicence = (profile?.businessLicenceNumber ?? '').trim().isNotEmpty;
    final verificationStatus = (profile?.verificationStatus ?? 'unverified').trim().toLowerCase();
    final isVerified = profile?.isVerificationApproved == true;
    final hasWorkspaceSetup = profile?.canAccessWorkspace == true;
    final isPending = verificationStatus == 'pending';
    final isRejected = verificationStatus == 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(
          label: isVerified
              ? l10n.supplierDashboardSuperLoadVerificationComplete
              : localizedSupplierDashboardVerificationStatus(l10n, verificationStatus),
          icon: Icons.verified_user_outlined,
          palette: StatusPalette(
            foreground: isVerified
                ? AppColors.success
                : isRejected
                    ? AppColors.error
                    : AppColors.warning,
            background: isVerified
                ? AppColors.successBg
                : isRejected
                    ? AppColors.errorBg
                    : AppColors.warningBg,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatusBadge(
          label: hasBusinessLicence
              ? l10n.supplierDashboardSuperLoadBusinessLicenceOnFile
              : l10n.supplierDashboardSuperLoadBusinessLicenceMissing,
          icon: Icons.workspace_premium_outlined,
          palette: StatusPalette(
            foreground: hasBusinessLicence ? AppColors.success : AppColors.warning,
            background: hasBusinessLicence ? AppColors.successBg : AppColors.warningBg,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatusBadge(
          label: l10n.supplierDashboardSuperLoadCompanyAgeUnavailable,
          icon: Icons.info_outline,
          palette: const StatusPalette(
            foreground: AppColors.info,
            background: AppColors.infoBg,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlineButton(
                label: hasWorkspaceSetup && hasBusinessLicence
                    ? l10n.supplierReviewVerification
                    : isRejected
                        ? l10n.supplierFixVerification
                        : isPending
                            ? l10n.supplierReviewVerification
                            : l10n.commonOpenVerificationAction,
                onPressed: () => context.go(AppRoutes.supplierVerificationPath),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlineButton(
                label: isVerified ? l10n.commonOpenMyLoadsAction : l10n.commonSupportLabel,
                onPressed: () => context.go(isVerified ? AppRoutes.myLoadsPath : AppRoutes.supportPath),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentLoadsSection extends StatelessWidget {
  final AsyncValue<List<Load>> recentLoadsAsync;
  final VoidCallback onRetry;

  const _RecentLoadsSection({
    required this.recentLoadsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (recentLoadsAsync.isLoading) {
      return const LoadingShimmer(height: 110, itemCount: 3);
    }

    if (recentLoadsAsync.hasError) {
      return WarningBlock(
        title: l10n.supplierDashboardRecentLoadsUnavailableTitle,
        message: l10n.supplierDashboardRecentLoadsUnavailableMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }

    final loads = recentLoadsAsync.valueOrNull ?? const <Load>[];
    if (loads.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.supplierDashboardNoLoadsPostedTitle,
        subtitle: l10n.supplierDashboardNoLoadsPostedSubtitle,
        actionLabel: l10n.commonOpenMyLoadsAction,
        onAction: () => context.go(AppRoutes.myLoadsPath),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < loads.length; index++) ...[
          _RecentLoadCard(load: loads[index]),
          if (index != loads.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RecentLoadCard extends StatelessWidget {
  final Load load;

  const _RecentLoadCard({required this.load});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(load.status);
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);

    return StandardListCard(
      accent: palette.foreground,
      title: '${load.originLabel} to ${load.destinationLabel}',
      subtitle: '${load.material} - ${tonnes}T - ${localizedSupplierPriceType(l10n, load.priceType)}',
      trailing: StatusChip(label: localizedSupplierDashboardLoadStatus(l10n, load.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierDashboardTrucksBooked(load.trucksBooked, load.trucksNeeded),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierDashboardLoadPickup(formatSupplierShortDate(context, load.pickupDate)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hasSuperLoadState(isSuperLoad: load.isSuperLoad, superStatus: load.superStatus)) ...[
            const SizedBox(height: AppSpacing.sm),
            SuperLoadStatusBlock(
              isSuperLoad: load.isSuperLoad,
              superStatus: load.superStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextActionButton(
            label: l10n.supplierDashboardOpenLoadsWorkspace,
            onPressed: () => context.go(AppRoutes.myLoadsPath),
          ),
        ],
      ),
      onTap: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
    );
  }
}

class SupplierDashboardScreen extends ConsumerWidget {
  const SupplierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(supplierProfileProvider);
    final dashboardAsync = ref.watch(supplierDashboardProvider);
    final recentLoadsAsync = ref.watch(supplierRecentLoadsProvider);
    final profile = profileAsync.valueOrNull;
    final profileResolved = !profileAsync.isLoading && !profileAsync.hasError && profile != null;
    final canPostLoads = _canPostLoads(profile);
    final Widget? topBanner = _buildTopBanner(context, ref, profileAsync);
    final List<Widget>? topBannerSection = topBanner == null ? null : <Widget>[topBanner];

    return ShellScrollView(
      onRefresh: () async {
        ref.invalidate(supplierDashboardProvider);
        ref.invalidate(supplierProfileProvider);
        ref.invalidate(supplierRecentLoadsProvider);
        await Future.wait([
          ref.read(supplierDashboardProvider.future),
          ref.read(supplierProfileProvider.future),
        ]);
      },
      children: [
        ...?topBannerSection,
        HeroActionCard(
          title: _heroTitle(context, profile),
          subtitle: '',
          compact: true,
          useDarkTheme: true,
          primaryAction: GradientButton(
            label: !profileResolved
                ? l10n.commonSupportLabel
                : canPostLoads
                ? l10n.commonPostLoadAction
                : l10n.supplierCompleteVerification,
            onPressed: () => context.go(
              !profileResolved
                  ? AppRoutes.supportPath
                  : canPostLoads
                  ? AppRoutes.postLoadPath
                  : AppRoutes.supplierVerificationPath,
            ),
          ),
          child: _HeroSummary(profile: profile),
        ),
        DetailSectionCard(
          title: l10n.commonDashboardOverviewTitle,
          children: [
            _DashboardStatsSection(
              dashboardAsync: dashboardAsync,
              onRetry: () => ref.refresh(supplierDashboardProvider),
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierDashboardSuperLoadReadinessTitle,
          children: [
            if (profileResolved)
              _SuperLoadReadinessSection(profile: profile)
            else
              WarningBlock(
                title: l10n.supplierDashboardAccountStateUnavailableTitle,
                message: l10n.supplierDashboardAccountStateUnavailableMessage,
                action: OutlineButton(
                  label: l10n.commonSupportLabel,
                  onPressed: () => context.go(AppRoutes.supportPath),
                ),
              ),
          ],
        ),
        DetailSectionCard(
          title: l10n.commonQuickActionsTitle,
          children: [
            QuickActionGrid(
              items: [
                QuickActionItem(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.shellTitleMyLoads,
                  onTap: () => context.go(AppRoutes.myLoadsPath),
                ),
                QuickActionItem(
                  icon: Icons.alt_route_outlined,
                  label: l10n.commonTripsLabel,
                  onTap: () => context.go(AppRoutes.supplierTripsPath),
                ),
                QuickActionItem(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.commonChatLabel,
                  onTap: () => context.go(AppRoutes.messagesPath),
                ),
                QuickActionItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.commonNotificationsLabel,
                  onTap: () => context.go(AppRoutes.notificationsPath),
                ),
              ],
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierRecentLoadsTitle,
          children: [
            _RecentLoadsSection(
              recentLoadsAsync: recentLoadsAsync,
              onRetry: () => ref.refresh(supplierRecentLoadsProvider),
            ),
          ],
        ),
      ],
    );
  }

  String _heroTitle(BuildContext context, SupplierProfile? profile) {
    final l10n = AppLocalizations.of(context);
    final businessName = (profile?.companyName ?? '').trim();
    if (businessName.isNotEmpty) {
      return l10n.supplierDashboardWelcomeBack(businessName);
    }

    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return l10n.supplierDashboardWelcomeBack(fullName);
    }

    return l10n.shellTitleSupplierDashboard;
  }

  Widget? _buildTopBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SupplierProfile?> profileAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final profile = profileAsync.valueOrNull;
    final verificationStatus = (profile?.verificationStatus ?? '').trim().toLowerCase();

    if (profileAsync.hasError) {
      return WarningBlock(
        title: l10n.supplierDashboardAccountStateUnavailableTitle,
        message: supplierAsyncFailure(profileAsync)?.message ?? l10n.supplierDashboardAccountStateUnavailableMessage,
        action: OutlineButton(
          label: l10n.commonRetryAction,
          onPressed: () => ref.refresh(supplierProfileProvider),
        ),
      );
    }

    if (profileAsync.isLoading) {
      return const LoadingShimmer(height: 92, itemCount: 1);
    }

    if (profile == null) {
      return WarningBlock(
        title: l10n.supplierDashboardAccountStateUnavailableTitle,
        message: l10n.supplierDashboardAccountStateUnavailableMessage,
        action: OutlineButton(
          label: l10n.commonRetryAction,
          onPressed: () => ref.refresh(supplierProfileProvider),
        ),
      );
    }

    if (verificationStatus == 'pending') {
      return SupplierVerificationBannerWithAction(
        banner: VerificationBanner(
          status: VerificationBannerStatus.pending,
          title: l10n.commonVerificationPendingTitle,
          description: l10n.supplierVerificationPendingMessage,
        ),
        actionLabel: l10n.commonOpenVerificationAction,
        onTap: () => context.go(AppRoutes.supplierVerificationPath),
      );
    }

    if (verificationStatus == 'verified' && profile.canAccessWorkspace) {
      return null;
    }

    if (verificationStatus == 'rejected') {
      return SupplierVerificationBannerWithAction(
        banner: VerificationBanner(
          status: VerificationBannerStatus.rejected,
          title: l10n.commonVerificationNeedsAttentionTitle,
          description: l10n.supplierVerificationNeedsAttentionDescription,
        ),
        actionLabel: l10n.supplierFixVerification,
        onTap: () => context.go(AppRoutes.supplierVerificationPath),
      );
    }

    if (verificationStatus == 'unverified' || !profile.hasCompanyName) {
      return WarningBlock(
        title: l10n.supplierCompleteSetupTitle,
        message: l10n.supplierCompleteSetupMessage,
        action: OutlineButton(
          label: l10n.commonOpenVerificationAction,
          onPressed: () => context.go(AppRoutes.supplierVerificationPath),
        ),
      );
    }

    return null;
  }

  bool _canPostLoads(SupplierProfile? profile) {
    return profile?.canAccessWorkspace == true;
  }
}
