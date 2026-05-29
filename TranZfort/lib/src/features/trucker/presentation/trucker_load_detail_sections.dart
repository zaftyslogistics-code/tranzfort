part of 'trucker_load_detail_screen.dart';

class _TruckerLoadDetailBody extends ConsumerWidget {
  final String loadId;
  final TruckerLoadDetail detail;
  final TruckerLoadDetailState state;
  final TruckerProfile? profile;
  final Map<String, double> dieselPriceMap;
  final TripCostingService tripCostingService;
  final TruckerLoadShareService shareService;

  const _TruckerLoadDetailBody({
    required this.loadId,
    required this.detail,
    required this.state,
    required this.profile,
    required this.dieselPriceMap,
    required this.tripCostingService,
    required this.shareService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mapsLauncher = ref.watch(mapsLauncherServiceProvider);
    final selectedTruck = state.approvedTrucks.where((truck) => truck.id == state.selectedTruckId).firstOrNull;
    final anyMatch = state.approvedTrucks.any((truck) => truckMatchesLoad(truck, detail.summary));
    final selectedTruckMatches = selectedTruck != null && truckMatchesLoad(selectedTruck, detail.summary);
    final dieselPrice = dieselPriceMap[(detail.originState ?? '').trim().toLowerCase()];
    final localizedPickupDate = MaterialLocalizations.of(context).formatMediumDate(detail.summary.pickupDate);
    final sharePayload = shareService.buildPayload(l10n, localizedPickupDate, detail);
    final routeSnapshot = detail.routeSnapshot;
    final tripCost = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: detail.summary.weightTonnes,
      dieselPricePerLitre: dieselPrice,
      priceAmountPerTonne: detail.summary.priceAmount,
      mileageEmptyKmpl: selectedTruck?.mileageEmptyKmpl,
      mileageLoadedKmpl: selectedTruck?.mileageLoadedKmpl,
      payloadKg: selectedTruck?.payloadKg?.toDouble(),
      axles: selectedTruck?.axles,
    );
    final bookingStatus = detail.latestBookingRequest?.status;
    final bookingAllowed = _bookingAllowed(detail, profile, state);
    final bookingLabel = switch (bookingStatus) {
      'submitted' => l10n.truckerLoadDetailRequestSubmittedAction,
      'approved' => l10n.truckerLoadDetailBookedAction,
      _ => l10n.truckerLoadDetailBookThisLoadAction,
    };
    final gatingMessage = _trustGatingMessage(l10n, profile, state.approvedTrucks);
    final hasNoApprovedTrucks = state.approvedTrucks.isEmpty;
    final hasSingleApprovedTruck = state.approvedTrucks.length == 1 && selectedTruck != null;
    final routeLabel = '${detail.originCity} to ${detail.destinationCity}';
    final hasRoutePreview =
        detail.originLat != null && detail.originLng != null && detail.destinationLat != null && detail.destinationLng != null;
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: detail.originLat,
      originLng: detail.originLng,
      destinationLat: detail.destinationLat,
      destinationLng: detail.destinationLng,
      destinationLabel: detail.summary.destinationLabel,
    );
    final ttsL10n = TtsLocalizations.of(context);
    final loadTts = const LoadDetailTtsBuilder();
    final overviewTts = loadTts.buildTruckerOverview(detail: detail, tts: ttsL10n, ui: l10n);
    final truckRequirementsTts =
        loadTts.buildTruckerTruckRequirements(detail: detail, tts: ttsL10n, ui: l10n);
    final readAllTts = loadTts.buildTruckerAll(detail: detail, tts: ttsL10n, ui: l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          WarningBlock(
            title: l10n.truckerLoadDetailSupportUnavailableTitle,
            message: _loadSupportFailureMessage(l10n),
            action: OutlineButton(
              label: l10n.commonRetryAction,
              onPressed: () => ref.read(truckerLoadDetailProvider(loadId).notifier).load(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        TtsReadAllButton(message: readAllTts),
        const SizedBox(height: AppSpacing.sm),
        _LoadRoutePriceSection(
          l10n: l10n,
          detail: detail,
          routeSnapshot: routeSnapshot,
          hasRoutePreview: hasRoutePreview,
          mapsUri: mapsUri,
          routeLabel: routeLabel,
          mapsLauncher: mapsLauncher,
          formatDate: _formatDate,
          anyMatch: anyMatch,
          isSuperLoad: detail.summary.isSuperLoad,
          ttsMessage: overviewTts,
        ),
        if (hasRoutePreview) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          _LoadRouteMapSection(
            originLat: detail.originLat!,
            originLng: detail.originLng!,
            destinationLat: detail.destinationLat!,
            destinationLng: detail.destinationLng!,
            originLabel: '${detail.originCity}${detail.originState == null ? '' : ', ${detail.originState}'}',
            destinationLabel:
                '${detail.destinationCity}${detail.destinationState == null ? '' : ', ${detail.destinationState}'}',
            mapsUri: mapsUri,
            mapsLauncher: mapsLauncher,
            l10n: l10n,
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailTruckRequirementTitle,
          ttsMessage: truckRequirementsTts,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _DetailFactChip(
                  icon: Icons.inventory_2_outlined,
                  text: l10n.truckerLoadDetailMaterialLabel(detail.summary.material),
                ),
                _DetailFactChip(
                  icon: Icons.local_shipping_outlined,
                  text: l10n.truckerLoadDetailBodyTypeLabel(
                    detail.summary.requiredBodyType ?? l10n.commonAnyLabel,
                  ),
                ),
                _DetailFactChip(
                  icon: Icons.tire_repair_outlined,
                  text: l10n.truckerLoadDetailTyresLabel(
                    detail.summary.requiredTyres.isEmpty
                        ? l10n.commonAnyLabel
                        : detail.summary.requiredTyres.join(', '),
                  ),
                ),
                _DetailFactChip(
                  icon: Icons.scale_outlined,
                  text: l10n.truckerLoadDetailPerTruckWeightLabel(
                    _tonnes(detail.summary.perTruckWeightTonnes),
                  ),
                ),
                if (detail.summary.derivedMinTruckCapacityTonnes != null &&
                    detail.summary.derivedMaxTruckCapacityTonnes != null)
                  _DetailFactChip(
                    icon: Icons.fitness_center_outlined,
                    text: l10n.truckerLoadDetailCapacityRangeLabel(
                      _tonnes(detail.summary.derivedMinTruckCapacityTonnes!),
                      _tonnes(detail.summary.derivedMaxTruckCapacityTonnes!),
                    ),
                  ),
                _DetailFactChip(
                  icon: Icons.inventory_2_outlined,
                  text: l10n.truckerLoadDetailTrucksNeededLabel(
                    detail.summary.trucksBooked,
                    detail.summary.trucksNeeded,
                  ),
                ),
                if (detail.summary.trucksNeeded > detail.summary.trucksBooked)
                  _DetailFactChip(
                    icon: Icons.add_circle_outline,
                    text: l10n.truckerLoadDetailSlotsOpenLabel(
                      detail.summary.trucksNeeded - detail.summary.trucksBooked,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        if (tripCost == null)
          DetailSectionCard(
            title: l10n.truckerLoadDetailTripCostEstimateTitle,
            children: [
              WarningBlock(
                title: l10n.truckerLoadDetailTripCostUnavailableTitle,
                message: l10n.truckerLoadDetailTripCostUnavailableMessage,
              ),
            ],
          )
        else
          _EarningsEstimateCard(tripCost: tripCost),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailSupplierSummaryTitle,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.publicProfileLocation(detail.supplierId)),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: detail.supplier.avatarUrl,
                      userId: detail.supplierId,
                      initials: detail.supplier.fullName.isNotEmpty ? detail.supplier.fullName[0].toUpperCase() : 'S',
                      radius: 20,
                      fallbackColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.supplier.companyName?.trim().isNotEmpty == true
                                ? detail.supplier.companyName!
                                : detail.supplier.fullName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          StatusBadge(
                            label: detail.supplier.verificationStatus == 'verified'
                                ? l10n.truckerLoadDetailVerifiedSupplier
                                : l10n.truckerLoadDetailSupplierProfile,
                            icon: detail.supplier.verificationStatus == 'verified'
                                ? Icons.verified_outlined
                                : Icons.business_outlined,
                            palette: detail.supplier.verificationStatus == 'verified'
                                ? const StatusPalette(
                                    foreground: AppColors.success,
                                    background: AppColors.successBg,
                                  )
                                : const StatusPalette(
                                    foreground: AppColors.neutral,
                                    background: AppColors.neutralBg,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      tooltip: l10n.truckerChatSupplierAction,
                      onPressed: () => _startChat(context, ref, loadId, detail),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _LoadNextStepSection(
          loadId: loadId,
          l10n: l10n,
          detail: detail,
          state: state,
          profile: profile,
          hasNoApprovedTrucks: hasNoApprovedTrucks,
          bookingAllowed: bookingAllowed,
          hasSingleApprovedTruck: hasSingleApprovedTruck,
          selectedTruck: selectedTruck,
          selectedTruckMatches: selectedTruckMatches,
          bookingLabel: bookingLabel,
          gatingMessage: gatingMessage,
          routeLabel: routeLabel,
          shareService: shareService,
          sharePayload: sharePayload,
          confirmGoToFleet: _confirmGoToFleet,
          confirmBooking: _confirmBooking,
        ),
      ],
    );
  }

  bool _bookingAllowed(TruckerLoadDetail detail, TruckerProfile? profile, TruckerLoadDetailState state) {
    if (_trustGatingMessage(null, profile, state.approvedTrucks) != null) {
      return false;
    }
    final status = detail.summary.status;
    if (status != 'active' && status != 'assigned_partial') {
      return false;
    }
    final bookingStatus = detail.latestBookingRequest?.status;
    if (bookingStatus == 'submitted' || bookingStatus == 'approved') {
      return false;
    }
    return state.selectedTruckId != null && state.selectedTruckId!.trim().isNotEmpty;
  }

  String? _trustGatingMessage(AppLocalizations? l10n, TruckerProfile? profile, List<TruckerApprovedTruck> approvedTrucks) {
    if (profile == null || !profile.isVerified) {
      return l10n?.truckerLoadDetailVerificationRequiredMessage ??
          'Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.';
    }
    if (approvedTrucks.isEmpty) {
      return l10n?.truckerLoadDetailTruckApprovalRequiredMessage ??
          'Add and approve at least one truck before booking this load or unlocking supplier chat.';
    }
    return null;
  }

  Future<bool?> _confirmGoToFleet(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.truckerLoadDetailAddTruckDialogTitle),
        content: Text(l10n.truckerLoadDetailAddTruckDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.truckerLoadDetailNotNowAction),
          ),
          PrimaryButton(
            label: l10n.truckerLoadDetailOpenFleetAction,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmBooking(
    BuildContext context,
    TruckerLoadDetail detail,
    String truckNumber,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.truckerLoadDetailConfirmBookingTitle),
        content: Text(
          l10n.truckerLoadDetailConfirmBookingMessage(
            detail.summary.material,
            '${detail.summary.originLabel} to ${detail.summary.destinationLabel}',
            truckNumber,
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
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _tonnes(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _LoadRouteMapSection extends StatelessWidget {
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final String originLabel;
  final String destinationLabel;
  final Uri? mapsUri;
  final MapsLauncherService mapsLauncher;
  final AppLocalizations l10n;

  const _LoadRouteMapSection({
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.originLabel,
    required this.destinationLabel,
    required this.mapsUri,
    required this.mapsLauncher,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final origin = LatLng(originLat, originLng);
    final destination = LatLng(destinationLat, destinationLng);
    final bounds = LatLngBounds.fromPoints(<LatLng>[origin, destination]);

    return DetailSectionCard(
      title: l10n.truckerLoadDetailRouteMapTitle,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tranzfort.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: <LatLng>[origin, destination],
                          strokeWidth: 4,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: origin,
                          width: 36,
                          height: 36,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.trip_origin, color: AppColors.primary, size: 28),
                        ),
                        Marker(
                          point: destination,
                          width: 36,
                          height: 36,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on, color: AppColors.secondary, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                // Route visualization only; origin/destination shown in hero section above.
              ],
            ),
          ),
        ),
        // Open in Maps action is in the route section above.
      ],
    );
  }
}
