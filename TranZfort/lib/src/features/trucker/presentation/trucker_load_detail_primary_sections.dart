part of 'trucker_load_detail_screen.dart';

class _LoadRoutePriceSection extends StatelessWidget {
  final AppLocalizations l10n;
  final TruckerLoadDetail detail;
  final dynamic routeSnapshot;
  final Uri? mapsUri;
  final String routeLabel;
  final MapsLauncherService mapsLauncher;
  final String Function(BuildContext, DateTime) formatDate;
  final bool anyMatch;
  final bool isSuperLoad;
  final String? ttsMessage;

  const _LoadRoutePriceSection({
    required this.l10n,
    required this.detail,
    required this.routeSnapshot,
    required this.mapsUri,
    required this.routeLabel,
    required this.mapsLauncher,
    required this.formatDate,
    required this.anyMatch,
    required this.isSuperLoad,
    this.ttsMessage,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = routeSnapshot?.distanceKm;
    final driveDaysLabel = distanceKm != null
        ? l10n.commonDurationDaysShort(DriveTimeEstimate.formatDayCount(DriveTimeEstimate.estimateDays(distanceKm)))
        : null;
    final pickupDateLabel = formatDate(context, detail.summary.pickupDate);
    final priceTypeLabel = _localizedLoadPriceType(l10n, detail.summary.priceType);
    final routeStatesLabel = _compactRouteStatesLabel(detail);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkSurface, AppColors.inkMid, AppColors.inkDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadows.elevation3,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOnDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.iconChip),
                ),
                child: const Icon(
                  Icons.alt_route_outlined,
                  color: AppColors.primaryOnDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.truckerLoadDetailRoutePriceSummaryTitle,
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.primaryOnDark,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.inkTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if ((ttsMessage ?? '').trim().isNotEmpty)
                TtsCardSpeakerButton(message: ttsMessage!.trim()),
            ],
          ),
          if (anyMatch || isSuperLoad) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (isSuperLoad)
                  _RouteDarkStatusPill(
                    icon: Icons.workspace_premium_outlined,
                    label: l10n.truckerLoadDetailSuperLoadGuarantee,
                    accent: AppColors.secondaryOnDark,
                  ),
                if (anyMatch)
                  _RouteDarkStatusPill(
                    icon: Icons.verified_outlined,
                    label: l10n.truckerLoadDetailTruckMatchAvailable,
                    accent: AppColors.primaryOnDark,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryOnDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.primaryOnDark.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.truckerLoadDetailTotalFareLabel,
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.primaryOnDark,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${detail.summary.priceAmount.toStringAsFixed(0)}',
                      style: AppTypography.displayHero.copyWith(
                        color: AppColors.primaryOnDark,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        priceTypeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: AppColors.inkTextSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.truckerLoadDetailPickupLabel(pickupDateLabel),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkTextSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (distanceKm != null || driveDaysLabel != null)
            Row(
              children: [
                if (distanceKm != null)
                  Expanded(
                    child: _CostBreakdownTile(
                      icon: Icons.straighten_outlined,
                      label: l10n.truckerLoadDetailFactDistanceLabel,
                      value: l10n.commonCompactDistanceKm(distanceKm.toStringAsFixed(0)),
                      accent: AppColors.primaryOnDark,
                    ),
                  ),
                if (distanceKm != null && driveDaysLabel != null) const SizedBox(width: AppSpacing.sm),
                if (driveDaysLabel != null)
                  Expanded(
                    child: _CostBreakdownTile(
                      icon: Icons.schedule_outlined,
                      label: l10n.truckerLoadDetailFactDriveLabel,
                      value: driveDaysLabel,
                      accent: AppColors.secondaryOnDark,
                    ),
                  ),
              ],
            ),
          if (routeStatesLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CostBreakdownTile(
              icon: Icons.map_outlined,
              label: l10n.truckerLoadDetailFactRouteLabel,
              value: routeStatesLabel,
              accent: AppColors.info,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CurvedArcRoute(
            origin: detail.originCity,
            destination: detail.destinationCity,
            originSubtitle: detail.originState,
            destinationSubtitle: detail.destinationState,
            onDarkSurface: true,
            height: 80,
          ),
          if (mapsUri != null) ...[
            const SizedBox(height: AppSpacing.md),
            GoogleMapsOpenButton(
              label: l10n.commonOpenInGoogleMapsAction,
              onPressed: () async {
                await mapsLauncher.launchDirectionsUri(mapsUri!);
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _compactRouteStatesLabel(TruckerLoadDetail detail) {
    final from = (detail.originState ?? detail.originCity).trim();
    final to = (detail.destinationState ?? detail.destinationCity).trim();
    if (from.isEmpty && to.isEmpty) {
      return '';
    }
    if (from.isEmpty) {
      return to;
    }
    if (to.isEmpty) {
      return from;
    }
    return '$from → $to';
  }
}

class _LoadNextStepSection extends ConsumerWidget {
  final String loadId;
  final AppLocalizations l10n;
  final TruckerLoadDetail detail;
  final TruckerLoadDetailState state;
  final TruckerProfile? profile;
  final bool hasNoApprovedTrucks;
  final bool bookingAllowed;
  final bool hasSingleApprovedTruck;
  final TruckerApprovedTruck? selectedTruck;
  final bool selectedTruckMatches;
  final String bookingLabel;
  final String? gatingMessage;
  final String routeLabel;
  final TruckerLoadShareService shareService;
  final dynamic sharePayload;
  final Future<bool?> Function(BuildContext, AppLocalizations) confirmGoToFleet;
  final Future<bool?> Function(BuildContext, TruckerLoadDetail, String) confirmBooking;

  const _LoadNextStepSection({
    required this.loadId,
    required this.l10n,
    required this.detail,
    required this.state,
    required this.profile,
    required this.hasNoApprovedTrucks,
    required this.bookingAllowed,
    required this.hasSingleApprovedTruck,
    required this.selectedTruck,
    required this.selectedTruckMatches,
    required this.bookingLabel,
    required this.gatingMessage,
    required this.routeLabel,
    required this.shareService,
    required this.sharePayload,
    required this.confirmGoToFleet,
    required this.confirmBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inkLabel = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.inkTextPrimary,
          fontWeight: FontWeight.w700,
        );
    final inkBody = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.inkTextSecondary,
        );

    return DetailSectionCard(
      useInkGradient: true,
      sectionIcon: Icons.play_circle_outline,
      title: l10n.commonNextStepTitle,
      children: [
        if (detail.latestBookingRequest != null)
          _RouteDarkStatusPill(
            icon: Icons.assignment_turned_in_outlined,
            label: l10n.truckerLoadDetailBookingStatusLabel(
              _localizedBookingRequestStatus(l10n, detail.latestBookingRequest!.status),
            ),
            accent: AppColors.secondaryOnDark,
          ),
        if (detail.latestBookingRequest?.decisionReason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          WarningBlock(
            title: l10n.truckerLoadDetailBookingFeedbackTitle,
            message: detail.latestBookingRequest!.decisionReason!,
          ),
        ],
        if (gatingMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          WarningBlock(
            title: l10n.truckerLoadDetailBookingBlockedTitle,
            message: gatingMessage!,
          ),
        ],
        if (state.actionFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          WarningBlock(
            title: l10n.truckerLoadDetailActionFailureTitle,
            message: _loadActionFailureMessage(l10n),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(l10n.truckerLoadDetailApprovedTruckLabel, style: inkLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.inkDeep,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.inkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSingleApprovedTruck && selectedTruck != null) ...[
                _RouteDarkStatusPill(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.truckerLoadDetailUsingTruckLabel(selectedTruck!.truckNumber),
                  accent: AppColors.primaryOnDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.truckerLoadDetailSelectedTruckSummary(
                    selectedTruck!.bodyType,
                    selectedTruck!.truckNumber,
                    selectedTruck!.tyres,
                  ),
                  style: inkBody,
                ),
              ] else if (state.approvedTrucks.isNotEmpty)
                AppDropdown<String>(
                  label: l10n.truckerLoadDetailApprovedTruckLabel,
                  value: state.selectedTruckId,
                  onDarkSurface: true,
                  items: [
                    for (final truck in state.approvedTrucks)
                      DropdownMenuItem(
                        value: truck.id,
                        child: Text(
                          l10n.truckerLoadDetailTruckOptionLabel(
                            truck.truckNumber,
                            truck.bodyType,
                            truck.tyres,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => ref.read(truckerLoadDetailProvider(loadId).notifier).selectTruck(value),
                ),
              if (hasNoApprovedTrucks) ...[
                Text(l10n.truckerLoadDetailNoApprovedTrucksAvailable, style: inkBody),
                const SizedBox(height: AppSpacing.md),
                OutlineButton(
                  label: l10n.truckerLoadDetailAddTruckFirstAction,
                  onPressed: () async {
                    final goToFleet = await confirmGoToFleet(context, l10n);
                    if (goToFleet == true && context.mounted) {
                      context.go(AppRoutes.fleetPath);
                    }
                  },
                ),
              ],
              if (selectedTruck != null) ...[
                const SizedBox(height: AppSpacing.md),
                _RouteDarkStatusPill(
                  icon: selectedTruckMatches ? Icons.check_circle_outline : Icons.info_outline,
                  label: selectedTruckMatches
                      ? l10n.truckerLoadDetailSelectedTruckMatches
                      : l10n.truckerLoadDetailSelectedTruckMayNotMatch,
                  accent: selectedTruckMatches ? AppColors.primaryOnDark : AppColors.secondaryOnDark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StartConversationButton(
          supplierId: detail.supplierId,
          truckerId: profile?.id,
          loadId: detail.summary.id,
          blockedReason: gatingMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.primaryOnDark),
                label: Text(
                  l10n.truckerLoadDetailShareLoadAction,
                  style: const TextStyle(color: AppColors.primaryOnDark),
                ),
                onPressed: () async {
                  final action = await showAppBottomSheet<String>(
                    context: context,
                    title: l10n.truckerLoadDetailShareLoadTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.truckerLoadDetailShareLoadMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: l10n.truckerLoadDetailSystemShareAction,
                          onPressed: () => Navigator.of(context).pop('system'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlineButton(
                          label: l10n.truckerLoadDetailShareToWhatsAppAction,
                          onPressed: () => Navigator.of(context).pop('whatsapp'),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted || action == null) {
                    return;
                  }
                  if (action == 'system') {
                    await shareService.shareSystem(sharePayload);
                    return;
                  }
                  final launched = await shareService.shareToWhatsApp(sharePayload);
                  if (!context.mounted) {
                    return;
                  }
                  if (!launched) {
                    AppSnackbar.show(
                      context: context,
                      message: l10n.truckerLoadDetailWhatsAppUnavailableMessage,
                      variant: AppSnackbarVariant.info,
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.primaryOnDark),
                label: Text(
                  l10n.commonReportSpamOrAbuseAction,
                  style: const TextStyle(color: AppColors.primaryOnDark),
                ),
                onPressed: () => context.push(
                  AppRoutes.reportIssuePath,
                  extra: ReportIssueContext(
                    initialCategory: 'spam_or_scam',
                    relatedLoadId: detail.summary.id,
                    relatedTripId: '',
                    sourceLabel: l10n.truckerLoadDetailReportSourceLabel(routeLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StickyBookingBar extends ConsumerWidget {
  final String loadId;

  const _StickyBookingBar({required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerLoadDetailProvider(loadId));
    final detail = state.detail;
    final profileAsync = ref.watch(truckerProfileProvider);
    final profile = profileAsync.valueOrNull;

    if (detail == null) return const SizedBox.shrink();

    final selectedTruck = state.approvedTrucks.where((t) => t.id == state.selectedTruckId).firstOrNull;
    final bookingStatus = detail.latestBookingRequest?.status;

    final bool bookingAllowed;
    {
      final gating = _trustGatingMessageSticky(l10n, profile, state.approvedTrucks);
      if (gating != null) {
        bookingAllowed = false;
      } else {
        final loadStatus = detail.summary.status;
        if (loadStatus != 'active' && loadStatus != 'assigned_partial') {
          bookingAllowed = false;
        } else if (bookingStatus == 'submitted' || bookingStatus == 'approved') {
          bookingAllowed = false;
        } else {
          bookingAllowed = state.selectedTruckId != null && state.selectedTruckId!.trim().isNotEmpty;
        }
      }
    }

    final bookingLabel = switch (bookingStatus) {
      'submitted' => l10n.truckerLoadDetailRequestSubmittedAction,
      'approved' => l10n.truckerLoadDetailBookedAction,
      _ => l10n.truckerLoadDetailBookThisLoadAction,
    };

    return GradientButton(
      label: bookingLabel,
      isLoading: state.isSubmittingBooking,
      onPressed: bookingAllowed
          ? () async {
              final selectedTruckId = state.selectedTruckId;
              final selectedTruckLabel = selectedTruck?.truckNumber ?? 'selected truck';
              if (selectedTruckId == null || selectedTruckId.trim().isEmpty) {
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.truckerLoadDetailConfirmBookingTitle),
                  content: Text(
                    l10n.truckerLoadDetailConfirmBookingMessage(
                      detail.summary.material,
                      '${detail.summary.originLabel} to ${detail.summary.destinationLabel}',
                      selectedTruckLabel,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(l10n.commonCancelAction),
                    ),
                    PrimaryButton(
                      label: l10n.truckerLoadDetailBookThisLoadAction,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) {
                return;
              }

              final result = await ref.read(truckerLoadDetailProvider(loadId).notifier).submitBookingRequest();
              if (!context.mounted) {
                return;
              }
              AppSnackbar.show(
                context: context,
                message: result.isSuccess
                    ? l10n.truckerLoadDetailLoadBookedSuccess
                    : _bookingSubmitFailureMessage(l10n),
                variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
              );
            }
          : null,
    );
  }

  static String? _trustGatingMessageSticky(AppLocalizations? l10n, TruckerProfile? profile, List<TruckerApprovedTruck> approvedTrucks) {
    if (profile == null || !profile.isVerified) {
      return l10n?.truckerLoadDetailVerificationRequiredMessage ??
          'Complete trucker verification before booking loads or starting supplier chat.';
    }
    if (approvedTrucks.isEmpty) {
      return l10n?.truckerLoadDetailTruckApprovalRequiredMessage ??
          'Add and approve at least one truck before booking this load.';
    }
    return null;
  }
}
