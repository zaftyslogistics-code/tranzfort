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
    final routeLabel = '${detail.summary.originLabel} → ${detail.summary.destinationLabel}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroActionCard(
          title: routeLabel,
          subtitle: l10n.truckerLoadDetailHeroSubtitle(
            detail.summary.id,
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
                  StatusBadge(
                    label: anyMatch
                        ? l10n.truckerLoadDetailTruckMatchAvailable
                        : l10n.truckerLoadDetailNoApprovedTruckMatchYet,
                    icon: anyMatch ? Icons.verified_outlined : Icons.warning_amber_outlined,
                    palette: anyMatch
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
              label: l10n.commonRetry,
              onPressed: () => ref.read(truckerLoadDetailProvider(loadId).notifier).load(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailRoutePriceSummaryTitle,
          children: [
            Text(l10n.truckerLoadDetailOriginLabel(detail.summary.originLabel)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.truckerLoadDetailDestinationLabel(detail.summary.destinationLabel)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.truckerLoadDetailPickupLabel(_formatDate(context, detail.summary.pickupDate))),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerLoadDetailPriceLabel(
                detail.summary.priceAmount.toStringAsFixed(0),
                _localizedLoadPriceType(l10n, detail.summary.priceType),
              ),
            ),
            if (routeSnapshot != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailDistanceLabel(routeSnapshot.distanceKm.toStringAsFixed(1))),
            ],
            if (routeSnapshot != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailDriveTimeLabel(routeSnapshot.durationMinutes)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailTruckRequirementTitle,
          children: [
            Text(l10n.truckerLoadDetailBodyTypeLabel(detail.summary.requiredBodyType ?? l10n.truckerLoadDetailAnyOption)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerLoadDetailTyresLabel(
                detail.summary.requiredTyres.isEmpty
                    ? l10n.truckerLoadDetailAnyOption
                    : detail.summary.requiredTyres.join(', '),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.truckerLoadDetailTrucksNeededLabel(detail.summary.trucksBooked, detail.summary.trucksNeeded)),
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
            Text(l10n.truckerLoadDetailMaterialLabel(detail.summary.material)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.truckerLoadDetailWeightLabel(_tonnes(detail.summary.weightTonnes))),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerLoadDetailOriginCityLabel(
                '${detail.originCity}${detail.originState == null ? '' : ', ${detail.originState}'}',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerLoadDetailDestinationCityLabel(
                '${detail.destinationCity}${detail.destinationState == null ? '' : ', ${detail.destinationState}'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailTripCostEstimateTitle,
          children: [
            if (tripCost == null)
              WarningBlock(
                title: l10n.truckerLoadDetailTripCostUnavailableTitle,
                message: l10n.truckerLoadDetailTripCostUnavailableMessage,
              )
            else ...[
              Text(tripCost.compactLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.truckerLoadDetailDieselLabel(tripCost.dieselCost.toStringAsFixed(0))),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailTollsLabel(tripCost.tollCost.toStringAsFixed(0))),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailMileageUsedLabel(tripCost.mileageUsed.toStringAsFixed(2))),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailDieselPriceLabel(tripCost.dieselPricePerLitre.toStringAsFixed(1))),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.truckerLoadDetailEstimatedTollPlazasLabel(tripCost.tollPlazas)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
          title: l10n.truckerLoadDetailSupplierSummaryTitle,
          children: [
            Text(detail.supplier.companyName?.trim().isNotEmpty == true ? detail.supplier.companyName! : detail.supplier.fullName),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.truckerLoadDetailContactOwnerLabel(detail.supplier.fullName)),
            const SizedBox(height: AppSpacing.xs),
            StatusBadge(
              label: detail.supplier.verificationStatus == 'verified'
                  ? l10n.truckerLoadDetailVerifiedSupplier
                  : l10n.truckerLoadDetailSupplierProfile,
              icon: detail.supplier.verificationStatus == 'verified' ? Icons.verified_outlined : Icons.business_outlined,
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
        const SizedBox(height: AppSpacing.sectionGap),
        DetailSectionCard(
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
                message: gatingMessage,
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
            if (hasSingleApprovedTruck) ...[
              StatusBadge(
                label: l10n.truckerLoadDetailUsingTruckLabel(selectedTruck.truckNumber),
                icon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.truckerLoadDetailSelectedTruckSummary(
                  selectedTruck.bodyType,
                  selectedTruck.truckNumber,
                  selectedTruck.tyres,
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
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.truckerLoadDetailNoApprovedTrucksAvailable),
              const SizedBox(height: AppSpacing.md),
              OutlineButton(
                label: l10n.truckerLoadDetailAddTruckFirstAction,
                onPressed: () async {
                  final goToFleet = await _confirmGoToFleet(context, l10n);
                  if (goToFleet == true && context.mounted) {
                    context.go(AppRoutes.fleetPath);
                  }
                },
              ),
            ],
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

                      final confirmed = await _confirmBooking(
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
            const SizedBox(height: AppSpacing.md),
            _StartConversationButton(
              supplierId: detail.supplierId,
              truckerId: profile?.id,
              loadId: detail.summary.id,
              blockedReason: gatingMessage,
            ),
            const SizedBox(height: AppSpacing.md),
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
            if (mapsLauncher.buildDirectionsUri(
              originLat: detail.originLat,
              originLng: detail.originLng,
              destinationLat: detail.destinationLat,
              destinationLng: detail.destinationLng,
              destinationLabel: detail.summary.destinationLabel,
            ) case final mapsUri?) ...[
              const SizedBox(height: AppSpacing.md),
              OutlineButton(
                label: l10n.truckerLoadDetailOpenInGoogleMapsAction,
                onPressed: () async {
                  await mapsLauncher.launchDirectionsUri(mapsUri);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlineButton(
              label: l10n.truckerLoadDetailReportSpamOrAbuseAction,
              onPressed: () => context.go(
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
            '${detail.summary.originLabel} → ${detail.summary.destinationLabel}',
            truckNumber,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.truckerLoadDetailCancelAction),
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

class _StartConversationButton extends ConsumerStatefulWidget {
  final String supplierId;
  final String? truckerId;
  final String loadId;
  final String? blockedReason;

  const _StartConversationButton({
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
    required this.blockedReason,
  });

  @override
  ConsumerState<_StartConversationButton> createState() => _StartConversationButtonState();
}

class _StartConversationButtonState extends ConsumerState<_StartConversationButton> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final truckerId = (widget.truckerId ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineButton(
          label: l10n.truckerChatSupplierAction,
          isLoading: _isStarting,
          onPressed: truckerId.isEmpty || _isStarting || widget.blockedReason != null
              ? null
              : () async {
                  setState(() {
                    _isStarting = true;
                  });
                  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
                        supplierId: widget.supplierId,
                        truckerId: truckerId,
                        loadId: widget.loadId,
                      );
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _isStarting = false;
                  });
                  result.when(
                    success: (conversationId) {
                      context.go('${AppRoutes.chatPath}/$conversationId');
                    },
                    failure: (failure) {
                      AppSnackbar.show(
                        context: context,
                        message: l10n.truckerLoadChatStartFailureMessage,
                        variant: AppSnackbarVariant.error,
                      );
                    },
                  );
                },
        ),
        if ((widget.blockedReason ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.truckerChatLockedLabel(widget.blockedReason!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _TruckerLoadDetailFailureBlock extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback onRetry;

  const _TruckerLoadDetailFailureBlock({
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (failure is NotFoundFailure) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.truckerLoadDetailLoadNotFoundTitle,
        subtitle: l10n.truckerLoadDetailLoadNotFoundSubtitle,
        actionLabel: l10n.truckerLoadDetailBackToFindLoadsAction,
        onAction: () => context.go(AppRoutes.findLoadsPath),
      );
    }

    return WarningBlock(
      title: l10n.truckerLoadDetailLoadFailureTitle,
      message: l10n.truckerLoadDetailLoadFailureMessage,
      action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
    );
  }
}
