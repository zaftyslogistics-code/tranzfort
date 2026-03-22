part of 'supplier_shell_screens.dart';

class SupplierLoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const SupplierLoadDetailScreen({
    super.key,
    required this.loadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(loadDetailProvider(loadId));
    final mapsLauncher = ref.watch(mapsLauncherServiceProvider);
    final detail = state.detail;

    return DetailPageScaffold(
      title: _supplierLoadDetailScreenTitle(l10n),
      children: [
        if (state.isLoading) const LoadingShimmer(height: 120, itemCount: 4),
        if (!state.isLoading && state.failure != null && detail == null)
          _LoadDetailFailureBlock(
            failure: state.failure!,
            onRetry: () => ref.read(loadDetailProvider(loadId).notifier).load(),
          ),
        if (!state.isLoading && detail != null) ...[
              HeroActionCard(
                title: '${detail.summary.originLabel} → ${detail.summary.destinationLabel}',
                subtitle: _supplierLoadDetailHeroSubtitle(
                  l10n,
                  detail.summary.id,
                  _formatSupplierShortDate(context, detail.summary.pickupDate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        StatusBadge(
                          label: _localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                          icon: Icons.local_shipping_outlined,
                        ),
                        if (_hasSuperLoadState(
                          isSuperLoad: detail.summary.isSuperLoad,
                          superStatus: detail.summary.superStatus,
                        ))
                          StatusBadge(
                            label: l10n.supplierDashboardSuperLoadBadge(
                              _superLoadStatusLabel(
                                l10n,
                                detail.summary.superStatus,
                                isSuperLoad: detail.summary.isSuperLoad,
                              ),
                            ),
                            icon: Icons.workspace_premium_outlined,
                            palette: const StatusPalette(
                              foreground: AppColors.superLoadText,
                              background: AppColors.superLoadBg,
                            ),
                          ),
                        StatusBadge(
                          label: l10n.supplierDashboardTrucksBooked(
                            detail.summary.trucksBooked,
                            detail.summary.trucksNeeded,
                          ),
                          icon: Icons.inventory_2_outlined,
                          palette: const StatusPalette(
                            foreground: AppColors.primary,
                            background: AppColors.neutralBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${detail.summary.material} • ₹${detail.summary.priceAmount.toStringAsFixed(0)} • ${_localizedSupplierPriceType(l10n, detail.summary.priceType)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (state.failure != null) ...[
                WarningBlock(
                  title: _supplierLoadDetailLinkedExecutionUnavailableTitle(l10n),
                  message: _supplierLoadSupportFailureMessage(l10n),
                  action: OutlineButton(
                    label: l10n.commonRetry,
                    onPressed: () => ref.read(loadDetailProvider(loadId).notifier).load(),
                  ),
                ),
              ],
              DetailSectionCard(
                title: _supplierLoadDetailStatusAndActionsTitle(l10n),
                children: [
                  Text(
                    _supplierLoadDetailCurrentStatus(
                      l10n,
                      _localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _supplierLoadDetailActionsSubtitle(l10n),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_hasSuperLoadState(
                    isSuperLoad: detail.summary.isSuperLoad,
                    superStatus: detail.summary.superStatus,
                  )) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SuperLoadStatusBlock(
                      isSuperLoad: detail.summary.isSuperLoad,
                      superStatus: detail.summary.superStatus,
                    ),
                  ],
                  if (state.actionFailure != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    WarningBlock(
                      title: _supplierLoadDetailActionUnavailableTitle(l10n),
                      message: _supplierLoadActionFailureMessage(l10n),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (_canCancel(detail)) ...[
                    DestructiveButton(
                      label: _supplierLoadDetailCancelAction(l10n),
                      isLoading: state.isCancelling,
                      onPressed: state.isCancelling
                          ? null
                          : () async {
                              final result = await ref.read(loadDetailProvider(loadId).notifier).cancelLoad();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackbar.build(
                                  context: context,
                                  message: result.isSuccess
                                      ? _supplierLoadDetailCancelledSuccess(l10n)
                                      : _supplierLoadCancelFailureMessage(l10n),
                                  variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_canCloseFilledOutsideApp(detail))
                    OutlineButton(
                      label: _supplierLoadDetailCloseFilledOutsideAction(l10n),
                      isLoading: state.isClosingFilledOutsideApp,
                      onPressed: state.isClosingFilledOutsideApp
                          ? null
                          : () async {
                              final result = await ref.read(loadDetailProvider(loadId).notifier).closeFilledOutsideApp();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackbar.build(
                                  context: context,
                                  message: result.isSuccess
                                      ? _supplierLoadDetailClosedFilledOutsideSuccess(l10n)
                                      : _supplierLoadCloseFailureMessage(l10n),
                                  variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                ),
                              );
                            },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlineButton(
                    label: l10n.chatMenuReportSpamOrAbuse,
                    onPressed: () => context.go(
                      AppRoutes.reportIssuePath,
                      extra: ReportIssueContext(
                        initialCategory: 'spam_or_scam',
                        relatedLoadId: detail.summary.id,
                        relatedTripId: '',
                        sourceLabel: 'Supplier load • ${detail.summary.originLabel} → ${detail.summary.destinationLabel}',
                      ),
                    ),
                  ),
                ],
              ),
          DetailSectionCard(
            title: _supplierLoadDetailRouteAndScheduleTitle(l10n),
            children: [
              Text(
                _supplierLoadDetailOriginCity(
                  l10n,
                  '${detail.originCity}${detail.originState == null ? '' : ', ${detail.originState}'}',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_supplierLoadDetailOriginPoint(l10n, detail.summary.originLabel)),
              const SizedBox(height: AppSpacing.md),
              Text(
                _supplierLoadDetailDestinationCity(
                  l10n,
                  '${detail.destinationCity}${detail.destinationState == null ? '' : ', ${detail.destinationState}'}',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_supplierLoadDetailDestinationPoint(l10n, detail.summary.destinationLabel)),
              const SizedBox(height: AppSpacing.md),
              Text(_supplierLoadDetailPickupDate(l10n, _formatSupplierShortDate(context, detail.summary.pickupDate))),
              if (detail.routeDistanceKm != null && detail.routeDurationMinutes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_supplierLoadDetailDistance(l10n, '${detail.routeDistanceKm!.toStringAsFixed(1)} km')),
                const SizedBox(height: AppSpacing.xs),
                Text(_supplierLoadDetailDriveTime(l10n, '${detail.routeDurationMinutes} min')),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                WarningBlock(
                  title: _supplierLoadDetailRoutePreviewUnavailableTitle(l10n),
                  message: _supplierLoadDetailRoutePreviewUnavailableMessage(l10n),
                ),
              ],
              if (mapsLauncher.buildDirectionsUri(
                originLat: detail.originLat,
                originLng: detail.originLng,
                destinationLat: detail.destinationLat,
                destinationLng: detail.destinationLng,
                destinationLabel: detail.summary.destinationLabel,
              ) case final mapsUri?) ...[
                const SizedBox(height: AppSpacing.md),
                OutlineButton(
                  label: _supplierLoadDetailOpenInGoogleMaps(l10n),
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri);
                  },
                ),
              ],
            ],
          ),
          DetailSectionCard(
            title: _supplierLoadDetailCargoAndRequirementsTitle(l10n),
            children: [
              Text(_supplierLoadDetailMaterial(l10n, detail.summary.material)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _supplierLoadDetailWeight(
                  l10n,
                  '${detail.summary.weightTonnes.toStringAsFixed(detail.summary.weightTonnes % 1 == 0 ? 0 : 1)} tonnes',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_supplierLoadDetailBodyType(l10n, detail.summary.requiredBodyType ?? _supplierLoadDetailAnyValue(l10n))),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _supplierLoadDetailTyres(
                  l10n,
                  detail.summary.requiredTyres.isEmpty
                      ? _supplierLoadDetailAnyValue(l10n)
                      : detail.summary.requiredTyres.join(', '),
                ),
              ),
            ],
          ),
          DetailSectionCard(
            title: _supplierLoadDetailBookingAndTripLinkageTitle(l10n),
            children: [
              Text(
                state.bookingRequests.isEmpty
                    ? _supplierLoadDetailBookingLinkageEmptyDescription(l10n)
                    : _supplierLoadDetailBookingLinkageDescription(l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.bookingRequests.isEmpty)
                EmptyStateView(
                  icon: Icons.assignment_outlined,
                  title: _supplierLoadDetailNoBookingRequestsTitle(l10n),
                  subtitle: _supplierLoadDetailNoBookingRequestsSubtitle(l10n),
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < state.bookingRequests.length; index++) ...[
                      _BookingRequestCard(
                        booking: state.bookingRequests[index],
                        isApproving: state.approvingBookingId == state.bookingRequests[index].id,
                        isRejecting: state.rejectingBookingId == state.bookingRequests[index].id,
                        onApprove: state.bookingRequests[index].isSubmitted
                            ? () async {
                                final confirmed = await _confirmApproveBooking(
                                  context,
                                  detail.summary,
                                );
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }

                                final result = await ref.read(loadDetailProvider(loadId).notifier).approveBookingRequest(
                                      state.bookingRequests[index].id,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppSnackbar.build(
                                    context: context,
                                    message: result.isSuccess
                                        ? _supplierBookingApprovedSuccessMessage(l10n)
                                        : _supplierLoadApproveBookingFailureMessage(l10n),
                                    variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                  ),
                                );
                              }
                            : null,
                        onReject: state.bookingRequests[index].isSubmitted
                            ? () async {
                                final reason = await _promptRejectReason(
                                  context,
                                  state.bookingRequests[index],
                                );
                                if (reason == null || !context.mounted) {
                                  return;
                                }

                                final result = await ref.read(loadDetailProvider(loadId).notifier).rejectBookingRequest(
                                      state.bookingRequests[index].id,
                                      reason: reason,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppSnackbar.build(
                                    context: context,
                                    message: result.isSuccess
                                        ? _supplierBookingRejectedSuccessMessage(l10n)
                                        : _supplierLoadRejectBookingFailureMessage(l10n),
                                    variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                  ),
                                );
                              }
                            : null,
                      ),
                      if (index != state.bookingRequests.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(_supplierLoadDetailLinkedTripsTitle(l10n), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (state.linkedTrips.isEmpty)
                EmptyStateView(
                  icon: Icons.alt_route_outlined,
                  title: _supplierLoadDetailNoLinkedTripsTitle(l10n),
                  subtitle: _supplierLoadDetailNoLinkedTripsSubtitle(l10n),
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < state.linkedTrips.length; index++) ...[
                      _LinkedTripCard(trip: state.linkedTrips[index]),
                      if (index != state.linkedTrips.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
            ],
          ),
          DetailSectionCard(
            title: _supplierLoadDetailActivityTimelineTitle(l10n),
            children: [
              TimelineBlock(
                events: [
                  TimelineEvent(
                    title: _supplierLoadDetailTimelineCreatedTitle(l10n),
                    timestamp: _formatSupplierDateTime(context, detail.createdAt),
                    description: _supplierLoadDetailTimelineCreatedDescription(l10n),
                  ),
                  if (detail.summary.publishedAt != null)
                    TimelineEvent(
                      title: _supplierLoadDetailTimelinePublishedTitle(l10n),
                      timestamp: _formatSupplierDateTime(context, detail.summary.publishedAt!),
                      description: _supplierLoadDetailTimelinePublishedDescription(l10n),
                    ),
                  TimelineEvent(
                    title: _supplierLoadDetailTimelineUpdatedTitle(l10n),
                    timestamp: _formatSupplierDateTime(context, detail.updatedAt),
                    description: _supplierLoadDetailTimelineUpdatedDescription(
                      l10n,
                      _localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _canCancel(LoadDetail detail) {
    final status = LoadStatus.fromDatabase(detail.summary.status);
    return status == LoadStatus.active ||
        status == LoadStatus.assignedPartial ||
        status == LoadStatus.assignedFull;
  }

  bool _canCloseFilledOutsideApp(LoadDetail detail) {
    final status = LoadStatus.fromDatabase(detail.summary.status);
    return status == LoadStatus.active ||
        status == LoadStatus.assignedPartial ||
        status == LoadStatus.assignedFull;
  }

  Future<bool?> _confirmApproveBooking(
    BuildContext context,
    Load load,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_supplierBookingApproveDialogTitle(l10n)),
        content: Text(
          _supplierBookingApproveDialogMessage(
            l10n,
            load.material,
            load.originLabel,
            load.destinationLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.chatActionCancel),
          ),
          PrimaryButton(
            label: l10n.chatActionApprove,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRejectReason(
    BuildContext context,
    LoadBookingRequest booking,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: booking.decisionReason ?? '');
    try {
      return await showDialog<String?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_supplierBookingRejectDialogTitle(l10n)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_supplierBookingRejectDialogSubtitle(l10n)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _supplierBookingRejectReasonLabel(l10n),
                  hintText: _supplierBookingRejectReasonHint(l10n),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(l10n.chatActionCancel),
            ),
            PrimaryButton(
              label: l10n.chatActionReject,
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _LoadDetailFailureBlock extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback onRetry;

  const _LoadDetailFailureBlock({
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (failure is NotFoundFailure) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: _supplierLoadDetailNotFoundTitle(l10n),
        subtitle: _supplierLoadDetailNotFoundSubtitle(l10n),
        actionLabel: l10n.commonRetry,
        onAction: () => context.go(AppRoutes.myLoadsPath),
      );
    }

    return WarningBlock(
      title: _supplierLoadDetailLoadFailureTitle(l10n),
      message: _supplierLoadDetailFailureMessage(l10n),
      action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
    );
  }
}

String _supplierLoadDetailNotFoundTitle(AppLocalizations l10n) => l10n.supplierLoadDetailNotFoundTitle;

String _supplierLoadDetailNotFoundSubtitle(AppLocalizations l10n) => l10n.supplierLoadDetailNotFoundSubtitle;

String _supplierLoadDetailLoadFailureTitle(AppLocalizations l10n) => l10n.supplierLoadDetailLoadFailureTitle;

String _supplierLoadDetailFailureMessage(AppLocalizations l10n) => l10n.supplierLoadDetailFailureMessage;

String _supplierLoadDetailScreenTitle(AppLocalizations l10n) => l10n.supplierLoadDetailScreenTitle;

String _supplierLoadDetailHeroSubtitle(AppLocalizations l10n, String loadId, String pickupDate) =>
    l10n.supplierLoadDetailHeroSubtitle(loadId, pickupDate);

String _supplierLoadDetailLinkedExecutionUnavailableTitle(AppLocalizations l10n) => l10n.supplierLoadDetailLinkedExecutionUnavailableTitle;

String _supplierLoadSupportFailureMessage(AppLocalizations l10n) => l10n.supplierLoadSupportFailureMessage;

String _supplierLoadDetailStatusAndActionsTitle(AppLocalizations l10n) => l10n.supplierLoadDetailStatusAndActionsTitle;

String _supplierLoadDetailCurrentStatus(AppLocalizations l10n, String status) => l10n.supplierLoadDetailCurrentStatus(status);

String _supplierLoadDetailActionsSubtitle(AppLocalizations l10n) => l10n.supplierLoadDetailActionsSubtitle;

String _supplierLoadDetailActionUnavailableTitle(AppLocalizations l10n) => l10n.supplierLoadDetailActionUnavailableTitle;

String _supplierLoadActionFailureMessage(AppLocalizations l10n) => l10n.supplierLoadActionFailureMessage;

String _supplierLoadDetailCancelAction(AppLocalizations l10n) => l10n.supplierLoadDetailCancelAction;

String _supplierLoadDetailCancelledSuccess(AppLocalizations l10n) => l10n.supplierLoadDetailCancelledSuccess;

String _supplierLoadCancelFailureMessage(AppLocalizations l10n) => l10n.supplierLoadCancelFailureMessage;

String _supplierLoadDetailCloseFilledOutsideAction(AppLocalizations l10n) => l10n.supplierLoadDetailCloseFilledOutsideAction;

String _supplierLoadDetailClosedFilledOutsideSuccess(AppLocalizations l10n) => l10n.supplierLoadDetailClosedFilledOutsideSuccess;

String _supplierLoadCloseFailureMessage(AppLocalizations l10n) => l10n.supplierLoadCloseFailureMessage;

String _supplierLoadDetailRouteAndScheduleTitle(AppLocalizations l10n) => l10n.supplierLoadDetailRouteAndScheduleTitle;

String _supplierLoadDetailOriginCity(AppLocalizations l10n, String value) => l10n.supplierLoadDetailOriginCity(value);

String _supplierLoadDetailOriginPoint(AppLocalizations l10n, String value) => l10n.supplierLoadDetailOriginPoint(value);

String _supplierLoadDetailDestinationCity(AppLocalizations l10n, String value) => l10n.supplierLoadDetailDestinationCity(value);

String _supplierLoadDetailDestinationPoint(AppLocalizations l10n, String value) => l10n.supplierLoadDetailDestinationPoint(value);

String _supplierLoadDetailPickupDate(AppLocalizations l10n, String value) => l10n.supplierLoadDetailPickupDate(value);

String _supplierLoadDetailDistance(AppLocalizations l10n, String value) => l10n.supplierLoadDetailDistance(value);

String _supplierLoadDetailDriveTime(AppLocalizations l10n, String value) => l10n.supplierLoadDetailDriveTime(value);

String _supplierLoadDetailRoutePreviewUnavailableTitle(AppLocalizations l10n) => l10n.supplierLoadDetailRoutePreviewUnavailableTitle;

String _supplierLoadDetailRoutePreviewUnavailableMessage(AppLocalizations l10n) => l10n.supplierLoadDetailRoutePreviewUnavailableMessage;

String _supplierLoadDetailOpenInGoogleMaps(AppLocalizations l10n) => l10n.supplierLoadDetailOpenInGoogleMaps;

String _supplierLoadDetailCargoAndRequirementsTitle(AppLocalizations l10n) => l10n.supplierLoadDetailCargoAndRequirementsTitle;

String _supplierLoadDetailMaterial(AppLocalizations l10n, String value) => l10n.supplierLoadDetailMaterial(value);

String _supplierLoadDetailWeight(AppLocalizations l10n, String value) => l10n.supplierLoadDetailWeight(value);

String _supplierLoadDetailAnyValue(AppLocalizations l10n) => l10n.supplierLoadDetailAnyValue;

String _supplierLoadDetailBodyType(AppLocalizations l10n, String value) => l10n.supplierLoadDetailBodyType(value);

String _supplierLoadDetailTyres(AppLocalizations l10n, String value) => l10n.supplierLoadDetailTyres(value);

String _supplierLoadDetailBookingAndTripLinkageTitle(AppLocalizations l10n) => l10n.supplierLoadDetailBookingAndTripLinkageTitle;

String _supplierLoadDetailBookingLinkageEmptyDescription(AppLocalizations l10n) => l10n.supplierLoadDetailBookingLinkageEmptyDescription;

String _supplierLoadDetailBookingLinkageDescription(AppLocalizations l10n) => l10n.supplierLoadDetailBookingLinkageDescription;

String _supplierLoadDetailNoBookingRequestsTitle(AppLocalizations l10n) => l10n.supplierLoadDetailNoBookingRequestsTitle;

String _supplierLoadDetailNoBookingRequestsSubtitle(AppLocalizations l10n) => l10n.supplierLoadDetailNoBookingRequestsSubtitle;

String _supplierLoadDetailLinkedTripsTitle(AppLocalizations l10n) => l10n.supplierLoadDetailLinkedTripsTitle;

String _supplierLoadDetailNoLinkedTripsTitle(AppLocalizations l10n) => l10n.supplierLoadDetailNoLinkedTripsTitle;

String _supplierLoadDetailNoLinkedTripsSubtitle(AppLocalizations l10n) => l10n.supplierLoadDetailNoLinkedTripsSubtitle;

String _supplierLoadDetailActivityTimelineTitle(AppLocalizations l10n) => l10n.supplierLoadDetailActivityTimelineTitle;

String _supplierLoadDetailTimelineCreatedTitle(AppLocalizations l10n) => l10n.supplierLoadDetailTimelineCreatedTitle;

String _supplierLoadDetailTimelineCreatedDescription(AppLocalizations l10n) => l10n.supplierLoadDetailTimelineCreatedDescription;

String _supplierLoadDetailTimelinePublishedTitle(AppLocalizations l10n) => l10n.supplierLoadDetailTimelinePublishedTitle;

String _supplierLoadDetailTimelinePublishedDescription(AppLocalizations l10n) => l10n.supplierLoadDetailTimelinePublishedDescription;

String _supplierLoadDetailTimelineUpdatedTitle(AppLocalizations l10n) => l10n.supplierLoadDetailTimelineUpdatedTitle;

String _supplierLoadDetailTimelineUpdatedDescription(AppLocalizations l10n, String status) =>
    l10n.supplierLoadDetailTimelineUpdatedDescription(status);

String _supplierBookingVerifiedLabel(AppLocalizations l10n) => l10n.supplierBookingVerifiedLabel;

String _supplierBookingRatingLabel(AppLocalizations l10n, String rating) => l10n.supplierBookingRatingLabel(rating);

String _supplierBookingTyres(AppLocalizations l10n, String tyres) => l10n.supplierBookingTyres(tyres);

String _supplierBookingSubmittedAt(AppLocalizations l10n, String truckLabel, String submittedAt) =>
    l10n.supplierBookingSubmittedAt(truckLabel, submittedAt);

String _supplierBookingDecisionRecorded(AppLocalizations l10n, String decidedAt) => l10n.supplierBookingDecisionRecorded(decidedAt);

String _supplierLinkedTripSubtitle(AppLocalizations l10n, String material, String truckerId, String truckId) =>
    l10n.supplierLinkedTripSubtitle(material, truckerId, truckId);

String _supplierBookingApprovedSuccessMessage(AppLocalizations l10n) => l10n.supplierBookingApprovedSuccessMessage;

String _supplierLoadApproveBookingFailureMessage(AppLocalizations l10n) => l10n.supplierLoadApproveBookingFailureMessage;

String _supplierBookingRejectedSuccessMessage(AppLocalizations l10n) => l10n.supplierBookingRejectedSuccessMessage;

String _supplierLoadRejectBookingFailureMessage(AppLocalizations l10n) => l10n.supplierLoadRejectBookingFailureMessage;

String _supplierBookingApproveDialogTitle(AppLocalizations l10n) => l10n.supplierBookingApproveDialogTitle;

String _supplierBookingApproveDialogMessage(
  AppLocalizations l10n,
  String material,
  String origin,
  String destination,
) =>
    l10n.supplierBookingApproveDialogMessage(material, origin, destination);

String _supplierBookingRejectDialogTitle(AppLocalizations l10n) => l10n.supplierBookingRejectDialogTitle;

String _supplierBookingRejectDialogSubtitle(AppLocalizations l10n) => l10n.supplierBookingRejectDialogSubtitle;

String _supplierBookingRejectReasonLabel(AppLocalizations l10n) => l10n.supplierBookingRejectReasonLabel;

String _supplierBookingRejectReasonHint(AppLocalizations l10n) => l10n.supplierBookingRejectReasonHint;
