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
    final dieselPrice = DieselPriceRepository.estimateDieselPricePerLitre(
      dieselPriceMap,
      detail.originState,
    );
    final localizedPickupDate = MaterialLocalizations.of(context).formatMediumDate(detail.summary.pickupDate);
    final sharePayload = shareService.buildPayload(l10n, localizedPickupDate, detail);
    final routeSnapshot = detail.routeSnapshot;
    final isPerTonPrice = detail.summary.priceType.trim().toLowerCase() == 'per_ton';
    final tripCost = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: detail.summary.weightTonnes,
      dieselPricePerLitre: dieselPrice,
      priceAmountPerTonne: isPerTonPrice ? detail.summary.priceAmount : null,
      fixedPriceAmount: isPerTonPrice ? null : detail.summary.priceAmount,
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
    final routeLabel = l10n.supplierLoadCardRouteTitle(detail.originCity, detail.destinationCity);
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: detail.originLat,
      originLng: detail.originLng,
      destinationLat: detail.destinationLat,
      destinationLng: detail.destinationLng,
      destinationLabel: detail.summary.destinationLabel,
    );
    final ttsL10n = TtsLocalizations.of(context);
    final loadTts = const LoadDetailTtsBuilder();
    final heroTts = loadTts.buildTruckerHeroSummary(detail: detail, tts: ttsL10n, ui: l10n);

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
        _LoadRoutePriceSection(
          l10n: l10n,
          detail: detail,
          routeSnapshot: routeSnapshot,
          mapsUri: mapsUri,
          routeLabel: routeLabel,
          mapsLauncher: mapsLauncher,
          formatDate: _formatDate,
          anyMatch: anyMatch,
          isSuperLoad: detail.summary.isSuperLoad,
          ttsMessage: heroTts,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          useInkGradient: true,
          sectionIcon: Icons.local_shipping_outlined,
          title: l10n.truckerLoadDetailTruckRequirementTitle,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _InkDetailFactChip(
                    icon: Icons.inventory_2_outlined,
                    text: l10n.truckerLoadDetailMaterialLabel(detail.summary.material),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _InkDetailFactChip(
                    icon: Icons.local_shipping_outlined,
                    text: l10n.truckerLoadDetailBodyTypeLabel(
                      detail.summary.requiredBodyType ?? l10n.commonAnyLabel,
                    ),
                    accent: AppColors.secondaryOnDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _InkDetailFactChip(
                    icon: Icons.tire_repair_outlined,
                    text: l10n.truckerLoadDetailTyresLabel(
                      detail.summary.requiredTyres.isEmpty
                          ? l10n.commonAnyLabel
                          : detail.summary.requiredTyres.join(', '),
                    ),
                    accent: AppColors.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _InkDetailMetricTile(
                        icon: Icons.scale_outlined,
                        label: l10n.truckerLoadDetailFactWeightLabel,
                        value: '${_tonnes(detail.summary.weightTonnes)} T',
                        accent: AppColors.primaryOnDark,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _InkDetailMetricTile(
                        icon: Icons.inventory_2_outlined,
                        label: l10n.truckerLoadDetailFactTrucksLabel,
                        value: '${detail.summary.trucksBooked}/${detail.summary.trucksNeeded}',
                        accent: AppColors.secondaryOnDark,
                      ),
                    ),
                    if (detail.summary.derivedMinTruckCapacityTonnes != null &&
                        detail.summary.derivedMaxTruckCapacityTonnes != null)
                      SizedBox(
                        width: tileWidth,
                        child: _InkDetailMetricTile(
                          icon: Icons.fitness_center_outlined,
                          label: l10n.truckerLoadDetailFactCapacityLabel,
                          value: l10n.truckerLoadDetailCapacityRangeLabel(
                            _tonnes(detail.summary.derivedMinTruckCapacityTonnes!),
                            _tonnes(detail.summary.derivedMaxTruckCapacityTonnes!),
                          ),
                          accent: AppColors.info,
                        ),
                      ),
                    if (detail.summary.trucksNeeded > detail.summary.trucksBooked)
                      SizedBox(
                        width: tileWidth,
                        child: _InkDetailMetricTile(
                          icon: Icons.add_circle_outline,
                          label: l10n.truckerLoadDetailFactSlotsLabel,
                          value: '${detail.summary.trucksNeeded - detail.summary.trucksBooked}',
                          accent: AppColors.primaryOnDark,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        if (tripCost == null)
          DetailSectionCard(
            useInkGradient: true,
            sectionIcon: Icons.local_gas_station_outlined,
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
          useInkGradient: true,
          sectionIcon: Icons.storefront_outlined,
          title: l10n.truckerLoadDetailSupplierSummaryTitle,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.publicProfileLocation(detail.supplierId)),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.inkDeep,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.inkBorder),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: detail.supplier.avatarUrl ?? detail.summary.supplierAvatarUrl,
                      userId: detail.supplierId,
                      initials: detail.supplier.fullName.isNotEmpty ? detail.supplier.fullName[0].toUpperCase() : 'S',
                      radius: 20,
                      fallbackColor: AppColors.primaryOnDark.withValues(alpha: 0.15),
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.inkTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _RouteDarkStatusPill(
                            icon: detail.supplier.verificationStatus == 'verified'
                                ? Icons.verified_outlined
                                : Icons.business_outlined,
                            label: detail.supplier.verificationStatus == 'verified'
                                ? l10n.truckerLoadDetailVerifiedSupplier
                                : l10n.truckerLoadDetailSupplierProfile,
                            accent: detail.supplier.verificationStatus == 'verified'
                                ? AppColors.primaryOnDark
                                : AppColors.inkTextSecondary,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryOnDark),
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
