part of 'supplier_shell_screens.dart';

String _localizedLinkedTripProofStatus(AppLocalizations l10n, LinkedTrip trip) {
  if (trip.hasPodProof) {
    return l10n.truckerTripDetailProofStatusPodUploaded;
  }
  if (trip.hasLrProof) {
    return l10n.truckerTripDetailProofStatusLrUploaded;
  }
  switch (trip.stage.trim().toLowerCase()) {
    case 'delivered':
      return l10n.truckerTripDetailProofStatusAwaitingPod;
    case 'proof_submitted':
      return l10n.truckerTripDetailProofStatusProofSubmitted;
    default:
      return l10n.truckerTripDetailProofStatusProofPending;
  }
}

String _formatSupplierShortDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatShortDate(value);
}

String _formatSupplierDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
  return '${material.formatShortDate(value)} • $timeLabel';
}

String _localizedSupplierBookingStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return l10n.shellMessagesBookingStatusSubmitted;
    case 'approved':
      return l10n.shellMessagesBookingStatusApproved;
    case 'rejected':
      return l10n.shellMessagesBookingStatusRejected;
    case 'pending':
      return l10n.shellMessagesBookingStatusPending;
    default:
      return l10n.shellMessagesBookingStatusUnknown;
  }
}

String _localizedSupplierPriceType(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'fixed':
      return l10n.supplierPostLoadPriceTypeFixed;
    case 'per_ton':
    case 'negotiable':
      return l10n.supplierPostLoadPriceTypeNegotiable;
    default:
      return l10n.supplierPostLoadPriceTypeUnknown;
  }
}

class _SupplierVerificationBannerWithAction extends StatelessWidget {
  final VerificationBanner banner;
  final String actionLabel;
  final VoidCallback onTap;

  const _SupplierVerificationBannerWithAction({
    required this.banner,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: AppSpacing.md),
        OutlineButton(
          label: actionLabel,
          onPressed: onTap,
        ),
      ],
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final LoadBookingRequest booking;
  final bool isApproving;
  final bool isRejecting;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  const _BookingRequestCard({
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
      if (booking.truckerVerificationStatus == 'verified') _supplierBookingVerifiedLabel(l10n),
      if (booking.truckerRating != null && booking.truckerRating! > 0)
        _supplierBookingRatingLabel(l10n, booking.truckerRating!.toStringAsFixed(1)),
    ].join(' • ');
    final truckMeta = <String>[
      if (booking.truckBodyType != null) booking.truckBodyType!,
      if (booking.truckTyres != null) _supplierBookingTyres(l10n, '${booking.truckTyres}'),
    ].join(' • ');

    return StandardListCard(
      accent: statusPaletteFor(booking.status).foreground,
      title: booking.displayTruckerName,
      subtitle: _supplierBookingSubmittedAt(
        l10n,
        booking.displayTruckLabel,
        _formatSupplierDateTime(context, booking.createdAt),
      ),
      trailing: StatusChip(label: _localizedSupplierBookingStatus(l10n, booking.status)),
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
              _supplierBookingDecisionRecorded(l10n, _formatSupplierDateTime(context, booking.decidedAt!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _LinkedTripCard extends StatelessWidget {
  final LinkedTrip trip;

  const _LinkedTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripPath = '${AppRoutes.tripDetailPath}/${trip.id}';

    return StandardListCard(
      accent: statusPaletteFor(trip.stage).foreground,
      title: trip.routeLabel,
      subtitle: _supplierLinkedTripSubtitle(
        l10n,
        trip.material,
        _shortId(trip.truckerId),
        _shortId(trip.truckId),
      ),
      trailing: StatusChip(label: _localizedSupplierTripStage(l10n, trip.stage)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierLinkedTripAssignedLabel(_formatSupplierDateTime(context, trip.assignedAt)),
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

String _shortId(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 8) {
    return trimmed;
  }
  return trimmed.substring(0, 8);
}

bool _hasSuperLoadState({required bool isSuperLoad, required String superStatus}) {
  return isSuperLoad || superStatus.trim().toLowerCase() != 'none';
}

String _localizedSupplierDashboardVerificationStatus(AppLocalizations l10n, String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'verified':
      return l10n.supplierDashboardVerificationStatusVerified;
    case 'pending':
      return l10n.supplierDashboardVerificationStatusPending;
    case 'rejected':
      return l10n.supplierDashboardVerificationStatusRejected;
    case 'unverified':
    case '':
      return l10n.accountProfileStatusNeedsAttention;
    default:
      return l10n.supplierDashboardVerificationStatusUnknown;
  }
}

String _localizedSupplierDashboardLoadStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return l10n.supplierDashboardLoadStatusActive;
    case 'assigned_partial':
      return l10n.supplierLoadStatusAssignedPartial;
    case 'assigned_full':
      return l10n.supplierLoadStatusAssignedFull;
    case 'in_transit':
      return l10n.supplierLoadStatusInTransit;
    case 'completed':
      return l10n.supplierLoadStatusCompleted;
    case 'filled_outside_app':
      return l10n.supplierLoadStatusFilledOutsideApp;
    case 'cancelled':
      return l10n.supplierLoadStatusCancelled;
    case 'expired':
      return l10n.supplierLoadStatusExpired;
    case 'deactivated':
      return l10n.supplierLoadStatusDeactivated;
    default:
      return l10n.supplierLoadStatusUnknown;
  }
}

String _superLoadStatusLabel(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  final normalized = superStatus.trim().toLowerCase();
  return switch (normalized) {
    'request_submitted' => l10n.supplierDashboardSuperLoadStatusRequestSubmitted,
    'under_review' => l10n.supplierDashboardSuperLoadStatusUnderReview,
    'approved_payment_pending' => l10n.supplierDashboardSuperLoadStatusApproved,
    'active' => l10n.supplierDashboardSuperLoadStatusActive,
    'rejected' => l10n.supplierDashboardSuperLoadStatusRejected,
    'expired_or_closed' => l10n.supplierDashboardSuperLoadStatusExpiredOrClosed,
    _ when isSuperLoad => l10n.supplierDashboardSuperLoadStatusActive,
    _ => l10n.supplierDashboardSuperLoadStatusNotActive,
  };
}

String _superLoadStatusGuidance(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  final normalized = superStatus.trim().toLowerCase();
  return switch (normalized) {
    'request_submitted' => l10n.supplierDashboardSuperLoadGuidanceRequestSubmitted,
    'under_review' => l10n.supplierDashboardSuperLoadGuidanceUnderReview,
    'approved_payment_pending' => l10n.supplierDashboardSuperLoadGuidanceApproved,
    'active' => l10n.supplierDashboardSuperLoadGuidanceActive,
    'rejected' => l10n.supplierDashboardSuperLoadGuidanceRejected,
    'expired_or_closed' => l10n.supplierDashboardSuperLoadGuidanceExpiredOrClosed,
    _ when isSuperLoad => l10n.supplierDashboardSuperLoadGuidanceActive,
    _ => l10n.supplierDashboardSuperLoadGuidanceNotActive,
  };
}

class _SuperLoadStatusBlock extends StatelessWidget {
  final bool isSuperLoad;
  final String superStatus;

  const _SuperLoadStatusBlock({
    required this.isSuperLoad,
    required this.superStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_hasSuperLoadState(isSuperLoad: isSuperLoad, superStatus: superStatus)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.superLoadBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: l10n.supplierDashboardSuperLoadBadge(
              _superLoadStatusLabel(l10n, superStatus, isSuperLoad: isSuperLoad),
            ),
            icon: Icons.workspace_premium_outlined,
            palette: const StatusPalette(
              foreground: AppColors.superLoadText,
              background: AppColors.superLoadBg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _superLoadStatusGuidance(l10n, superStatus, isSuperLoad: isSuperLoad),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final SupplierProfile? profile;

  const _HeroSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verificationLabel = _localizedSupplierDashboardVerificationStatus(
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
        action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
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
              : _localizedSupplierDashboardVerificationStatus(l10n, verificationStatus),
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
                            : l10n.supplierOpenVerification,
                onPressed: () => context.go(AppRoutes.supplierVerificationPath),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlineButton(
                label: isVerified ? l10n.supplierDashboardOpenMyLoadsAction : l10n.navSupport,
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
        action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
      );
    }

    final loads = recentLoadsAsync.valueOrNull ?? const <Load>[];
    if (loads.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.supplierDashboardNoLoadsPostedTitle,
        subtitle: l10n.supplierDashboardNoLoadsPostedSubtitle,
        actionLabel: l10n.supplierDashboardOpenMyLoadsAction,
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
      title: '${load.originLabel} → ${load.destinationLabel}',
      subtitle: '${load.material} • ${tonnes}T • ${_localizedSupplierPriceType(l10n, load.priceType)}',
      trailing: StatusChip(label: _localizedSupplierDashboardLoadStatus(l10n, load.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierDashboardTrucksBooked(load.trucksBooked, load.trucksNeeded),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierDashboardLoadPickup(_formatSupplierShortDate(context, load.pickupDate)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_hasSuperLoadState(isSuperLoad: load.isSuperLoad, superStatus: load.superStatus)) ...[
            const SizedBox(height: AppSpacing.sm),
            _SuperLoadStatusBlock(
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
      onTap: () => context.go('${AppRoutes.loadDetailPath}/${load.id}'),
    );
  }
}
