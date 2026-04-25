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
    final routeLabel = '${detail.summary.originLabel} > ${detail.summary.destinationLabel}';
    final hasRoutePreview =
        detail.originLat != null && detail.originLng != null && detail.destinationLat != null && detail.destinationLng != null;
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: detail.originLat,
      originLng: detail.originLng,
      destinationLat: detail.destinationLat,
      destinationLng: detail.destinationLng,
      destinationLabel: detail.summary.destinationLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroActionCard(
          title: routeLabel,
          subtitle: l10n.truckerLoadDetailHeroSubtitle(
            _formatDate(context, detail.summary.pickupDate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusBadge(
                    label: _localizedLoadDetailStatus(l10n, detail.summary.status),
                    icon: Icons.local_shipping_outlined,
                  ),
                  StatusBadge(
                    label: l10n.truckerLoadDetailPriceBadge(
                      detail.summary.priceAmount.toStringAsFixed(0),
                      _localizedLoadPriceType(l10n, detail.summary.priceType),
                    ),
                    icon: Icons.payments_outlined,
                    palette: const StatusPalette(
                      foreground: AppColors.primary,
                      background: AppColors.neutralBg,
                    ),
                  ),
                  if (anyMatch)
                    StatusBadge(
                      label: l10n.truckerLoadDetailTruckMatchAvailable,
                      icon: Icons.verified_outlined,
                      palette: const StatusPalette(
                        foreground: AppColors.success,
                        background: AppColors.successBg,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.truckerLoadDetailMaterialSummary(
                  detail.summary.material,
                  _tonnes(detail.summary.weightTonnes),
                  detail.summary.advancePercentage,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (detail.summary.isSuperLoad) ...[
                const SizedBox(height: AppSpacing.md),
                StatusBadge(
                  label: l10n.truckerLoadDetailSuperLoadGuarantee,
                  icon: Icons.workspace_premium_outlined,
                  palette: const StatusPalette(
                    foreground: AppColors.superLoadText,
                    background: AppColors.superLoadBg,
                  ),
                ),
              ],
            ],
          ),
        ),
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
        _LoadRoutePriceSection(
          l10n: l10n,
          detail: detail,
          routeSnapshot: routeSnapshot,
          hasRoutePreview: hasRoutePreview,
          mapsUri: mapsUri,
          routeLabel: routeLabel,
          mapsLauncher: mapsLauncher,
          formatDate: _formatDate,
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
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
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
                  icon: Icons.inventory_2_outlined,
                  text: l10n.truckerLoadDetailTrucksNeededLabel(
                    detail.summary.trucksBooked,
                    detail.summary.trucksNeeded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StatusBadge(
              label: selectedTruck == null
                  ? l10n.truckerLoadDetailNoApprovedTruckSelected
                  : selectedTruckMatches
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
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailCargoScheduleTitle,
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
                  icon: Icons.scale_outlined,
                  text: l10n.truckerLoadDetailWeightLabel(_tonnes(detail.summary.weightTonnes)),
                ),
                _DetailFactChip(
                  icon: Icons.trip_origin,
                  text: l10n.truckerLoadDetailOriginCityLabel(
                    '${detail.originCity}${detail.originState == null ? '' : ', ${detail.originState}'}',
                  ),
                ),
                _DetailFactChip(
                  icon: Icons.location_on_outlined,
                  text: l10n.truckerLoadDetailDestinationCityLabel(
                    '${detail.destinationCity}${detail.destinationState == null ? '' : ', ${detail.destinationState}'}',
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
                    _AvatarCircle(
                      avatarUrl: detail.supplier.avatarUrl,
                      radius: 20,
                      fallback: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Center(
                          child: Text(
                            detail.supplier.fullName.isNotEmpty ? detail.supplier.fullName[0].toUpperCase() : 'S',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
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
                    const Icon(Icons.chevron_right, color: AppColors.neutral),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlineButton(
              label: l10n.truckerChatSupplierAction,
              onPressed: () => _startChat(context, ref, loadId, detail),
              height: 40,
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
            '${detail.summary.originLabel} > ${detail.summary.destinationLabel}',
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

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Widget fallback;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: fallback,
      );
    }

    return FutureBuilder<String?>(
      future: _createSignedUrl(avatarUrl!),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data;
        if (resolvedUrl == null) {
          return SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: fallback,
          );
        }
        return _AvatarImage(url: resolvedUrl, radius: radius, fallback: fallback);
      },
    );
  }

  Future<String?> _createSignedUrl(String path) async {
    try {
      final client = Supabase.instance.client;
      // Try verification-documents bucket first (for user's own profile)
      try {
        return await client.storage.from('verification-documents').createSignedUrl(path, 3600);
      } catch (_) {
        // Fallback to profile-photos bucket (for supplier profiles)
        return await client.storage.from('profile-photos').createSignedUrl(path, 3600);
      }
    } catch (_) {
      return null;
    }
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
      title: l10n.truckerLoadDetailRoutePriceSummaryTitle,
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
                // Floating legend with from/to city labels.
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trip_origin, size: 12, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            originLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            destinationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (mapsUri != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: l10n.commonOpenInGoogleMapsAction,
            onPressed: () async {
              await mapsLauncher.launchDirectionsUri(mapsUri!);
            },
          ),
        ],
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  final double radius;
  final Widget fallback;

  const _AvatarImage({
    required this.url,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: fallback,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: fallback,
          );
        },
      ),
    );
  }
}
