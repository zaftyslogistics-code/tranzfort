part of 'trucker_load_detail_screen.dart';

class _LoadRoutePriceSection extends StatelessWidget {
  final AppLocalizations l10n;
  final TruckerLoadDetail detail;
  final dynamic routeSnapshot;
  final bool hasRoutePreview;
  final Uri? mapsUri;
  final String routeLabel;
  final MapsLauncherService mapsLauncher;
  final String Function(BuildContext, DateTime) formatDate;
  final bool anyMatch;
  final bool isSuperLoad;

  const _LoadRoutePriceSection({
    required this.l10n,
    required this.detail,
    required this.routeSnapshot,
    required this.hasRoutePreview,
    required this.mapsUri,
    required this.routeLabel,
    required this.mapsLauncher,
    required this.formatDate,
    required this.anyMatch,
    required this.isSuperLoad,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = routeSnapshot?.distanceKm;
    final calculatedDurationMin = distanceKm != null ? _calculateDriveTimeMinutes(distanceKm) : null;
    final durationLabel = calculatedDurationMin != null ? _formatDriveTime(calculatedDurationMin) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2220), Color(0xFF0A1614)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route label + badges header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (anyMatch)
                      StatusBadge(
                        label: l10n.truckerLoadDetailTruckMatchAvailable,
                        icon: Icons.verified_outlined,
                        palette: const StatusPalette(
                          foreground: AppColors.success,
                          background: AppColors.successBg,
                        ),
                      ),
                    if (isSuperLoad)
                      StatusBadge(
                        label: l10n.truckerLoadDetailSuperLoadGuarantee,
                        icon: Icons.workspace_premium_outlined,
                        palette: const StatusPalette(
                          foreground: AppColors.superLoadText,
                          background: AppColors.superLoadBg,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Price + pickup header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.truckerLoadDetailPriceLabel(
                    detail.summary.priceAmount.toStringAsFixed(0),
                    _localizedLoadPriceType(l10n, detail.summary.priceType),
                  ),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2A27),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A3B37), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 14, color: Color(0xFF2DD4BF)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        formatDate(context, detail.summary.pickupDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA8BAB6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Curved arc route visualization
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CurvedArcRoute.hero(
              origin: detail.originCity,
              destination: detail.destinationCity,
              originSubtitle: detail.originState,
              destinationSubtitle: detail.destinationState,
              distanceLabel: distanceKm != null ? '${distanceKm.toStringAsFixed(0)} km' : null,
              durationLabel: durationLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Distance and duration chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (distanceKm != null)
                  _DarkChip(
                    icon: Icons.straighten,
                    text: l10n.truckerLoadDetailDistanceLabel(distanceKm.toStringAsFixed(1)),
                  ),
                if (durationLabel != null)
                  _DarkChip(
                    icon: Icons.schedule,
                    text: 'Est. drive time: $durationLabel',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Open in Maps button
          if (mapsUri != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: l10n.commonOpenInGoogleMapsAction,
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri!);
                  },
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
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
    return DetailSectionCard(
      title: l10n.commonNextStepTitle,
      children: [
        if (detail.latestBookingRequest != null)
          StatusBadge(
            label: l10n.truckerLoadDetailBookingStatusLabel(
              _localizedBookingRequestStatus(l10n, detail.latestBookingRequest!.status),
            ),
            icon: Icons.assignment_turned_in_outlined,
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
        Text(
          l10n.truckerLoadDetailApprovedTruckLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasSingleApprovedTruck && selectedTruck != null) ...[
          StatusBadge(
            label: l10n.truckerLoadDetailUsingTruckLabel(selectedTruck!.truckNumber),
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.truckerLoadDetailSelectedTruckSummary(
              selectedTruck!.bodyType,
              selectedTruck!.truckNumber,
              selectedTruck!.tyres,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ] else if (state.approvedTrucks.isNotEmpty)
          AppDropdown<String>(
            label: l10n.truckerLoadDetailApprovedTruckLabel,
            value: state.selectedTruckId,
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
          Text(l10n.truckerLoadDetailNoApprovedTrucksAvailable),
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
          StatusBadge(
            label: selectedTruckMatches
                ? l10n.truckerLoadDetailSelectedTruckMatches
                : l10n.truckerLoadDetailSelectedTruckMayNotMatch,
            icon: selectedTruckMatches ? Icons.check_circle_outline : Icons.info_outline,
            palette: selectedTruckMatches
                ? const StatusPalette(
                    foreground: AppColors.success,
                    background: AppColors.successBg,
                  )
                : const StatusPalette(
                    foreground: AppColors.warning,
                    background: AppColors.warningBg,
                  ),
          ),
        ],
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
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(l10n.truckerLoadDetailShareLoadAction),
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
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(l10n.commonReportSpamOrAbuseAction),
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

class _DarkChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DarkChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3B37), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2DD4BF)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA8BAB6),
            ),
          ),
        ],
      ),
    );
  }
}
