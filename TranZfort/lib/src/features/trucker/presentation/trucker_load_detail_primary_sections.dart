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

  const _LoadRoutePriceSection({
    required this.l10n,
    required this.detail,
    required this.routeSnapshot,
    required this.hasRoutePreview,
    required this.mapsUri,
    required this.routeLabel,
    required this.mapsLauncher,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = routeSnapshot?.distanceKm;
    final durationMin = routeSnapshot?.durationMinutes;

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
          // Price header on dark gradient
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
                Text(
                  l10n.truckerLoadDetailPickupLabel(formatDate(context, detail.summary.pickupDate)),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA8BAB6),
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
              distanceLabel: distanceKm != null ? '${distanceKm.toStringAsFixed(0)} km' : null,
              durationLabel: durationMin != null ? _durationCompact(durationMin) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Key stats strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2A27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3B37), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.trip_origin,
                    label: detail.summary.originLabel,
                    value: 'Origin',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFF2A3B37),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.location_on_outlined,
                    label: detail.summary.destinationLabel,
                    value: 'Destination',
                  ),
                ),
              ],
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
                if (durationMin != null)
                  _DarkChip(
                    icon: Icons.schedule,
                    text: l10n.truckerLoadDetailDriveTimeLabel(durationMin),
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
                  label: l10n.truckerLoadDetailOpenInGoogleMapsAction,
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
      title: l10n.truckerLoadDetailNextStepTitle,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.subtleSurface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GradientButton(
          label: bookingLabel,
          isLoading: state.isSubmittingBooking,
          onPressed: bookingAllowed
              ? () async {
                  final selectedTruckId = state.selectedTruckId;
                  final selectedTruckLabel = selectedTruck?.truckNumber ?? 'selected truck';
                  if (selectedTruckId == null || selectedTruckId.trim().isEmpty) {
                    return;
                  }

                  final confirmed = await confirmBooking(
                    context,
                    detail,
                    selectedTruckLabel,
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
        ),
        const SizedBox(height: AppSpacing.sm),
        _StartConversationButton(
          supplierId: detail.supplierId,
          truckerId: profile?.id,
          loadId: detail.summary.id,
          blockedReason: gatingMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              OutlineButton(
                label: l10n.truckerLoadDetailShareLoadAction,
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
              const SizedBox(height: AppSpacing.sm),
              OutlineButton(
                label: l10n.truckerLoadDetailReportSpamOrAbuseAction,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2DD4BF)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B807B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA8BAB6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
