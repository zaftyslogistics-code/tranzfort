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
    return DetailSectionCard(
      title: l10n.truckerLoadDetailRoutePriceSummaryTitle,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.truckerLoadDetailPriceLabel(
                  detail.summary.priceAmount.toStringAsFixed(0),
                  _localizedLoadPriceType(l10n, detail.summary.priceType),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.truckerLoadDetailPickupLabel(formatDate(context, detail.summary.pickupDate)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (hasRoutePreview)
          StaticRouteMap(
            originLat: detail.originLat!,
            originLng: detail.originLng!,
            destLat: detail.destinationLat!,
            destLng: detail.destinationLng!,
            originLabel: detail.originCity,
            destLabel: detail.destinationCity,
            height: 156,
            distanceLabel: routeSnapshot != null ? '${routeSnapshot!.distanceKm.toStringAsFixed(0)} km' : null,
            durationLabel: routeSnapshot != null ? _durationCompact(routeSnapshot!.durationMinutes) : null,
            onOpenMaps: mapsUri != null
                ? () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri!);
                  }
                : null,
            onTap: () => context.push(
              AppRoutes.routePreviewPath,
              extra: TruckerRoutePreviewArgs(
                routeLabel: routeLabel,
                destinationLabel: detail.summary.destinationLabel,
                originLat: detail.originLat!,
                originLng: detail.originLng!,
                destinationLat: detail.destinationLat!,
                destinationLng: detail.destinationLng!,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.subtleSurface,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    routeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        if (mapsUri != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlineButton(
            label: l10n.truckerLoadDetailOpenInGoogleMapsAction,
            onPressed: () async {
              await mapsLauncher.launchDirectionsUri(mapsUri!);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _DetailFactChip(
              icon: Icons.trip_origin,
              text: l10n.truckerLoadDetailOriginLabel(detail.summary.originLabel),
            ),
            _DetailFactChip(
              icon: Icons.location_on_outlined,
              text: l10n.truckerLoadDetailDestinationLabel(detail.summary.destinationLabel),
            ),
            if (routeSnapshot != null)
              _DetailFactChip(
                icon: Icons.straighten,
                text: l10n.truckerLoadDetailDistanceLabel(routeSnapshot!.distanceKm.toStringAsFixed(1)),
              ),
            if (routeSnapshot != null)
              _DetailFactChip(
                icon: Icons.schedule,
                text: l10n.truckerLoadDetailDriveTimeLabel(routeSnapshot!.durationMinutes),
              ),
          ],
        ),
      ],
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
