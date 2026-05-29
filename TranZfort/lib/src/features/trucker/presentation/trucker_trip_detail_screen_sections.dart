part of 'trucker_trip_detail_screen.dart';

class _TruckerTripDetailBody extends ConsumerWidget {
  final TruckerTripDetail detail;

  const _TruckerTripDetailBody({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mapsLauncher = ref.watch(mapsLauncherServiceProvider);
    final truckerProfileAsync = ref.watch(truckerProfileProvider);
    final truckerProfile = truckerProfileAsync.valueOrNull;
    final communicationBlocked = _tripChatBlockedMessage(l10n, truckerProfileAsync, truckerProfile) != null;
    final actionState = ref.watch(truckerTripActionProvider(detail.id));
    final routeSnapshot = detail.routeSnapshot;
    final nextStep = _tripNextStep(l10n, detail.stage);
    final stageAction = _tripStageAction(l10n, detail.stage);
    final lrUploadAllowed = detail.stage == 'pickup_pending' || detail.stage == 'picked_up';
    final proofUploadAllowed = detail.stage == 'delivered';
    final chatAllowed = detail.supplierId.trim().isNotEmpty && detail.truckerId.trim().isNotEmpty && detail.loadId.trim().isNotEmpty;
    final callUri = _tripDetailCallUri(detail.supplier.mobile);
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: detail.originLat,
      originLng: detail.originLng,
      destinationLat: detail.destinationLat,
      destinationLng: detail.destinationLng,
      destinationLabel: detail.destinationLabel,
    );
    final ttsL10n = TtsLocalizations.of(context);
    final tripTts = const TripDetailTtsBuilder();
    final stageLabel = _localizedTripStage(l10n, detail.stage);
    final proofLabel = _localizedProofStatus(l10n, detail);
    final overviewTts = tripTts.buildTruckerOverview(
      detail: detail,
      tts: ttsL10n,
      stageLabel: stageLabel,
      proofLabel: proofLabel,
    );
    final nextStepTts = tripTts.buildTruckerNextStep(
      tts: ttsL10n,
      stepTitle: nextStep.$1,
      stepDetail: nextStep.$2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroActionCard(
          title: detail.routeLabel,
          subtitle: l10n.truckerTripDetailHeroSubtitle(detail.truckNumber),
          useDarkTheme: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: _localizedTripStage(l10n, detail.stage),
                    icon: Icons.alt_route_outlined,
                  ),
                  StatusBadge(
                    label: _localizedProofStatus(l10n, detail),
                    icon: Icons.fact_check_outlined,
                  ),
                  StatusBadge(
                    label: _localizedVerificationStatus(l10n, detail.supplier.verificationStatus),
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.truckerTripDetailMaterialPickupSummary(
                  detail.material,
                  _tripDetailFormatDate(context, detail.pickupDate),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.commonNextStepTitle,
          ttsMessage: nextStepTts,
          children: [
            Text(nextStep.$1, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(nextStep.$2, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        if (actionState.failure != null) ...[
          const SizedBox(height: 16),
          WarningBlock(
            title: l10n.truckerTripDetailActionUnavailableTitle,
            message: l10n.truckerTripDetailActionFailureMessage,
          ),
        ],
        if (stageAction != null || lrUploadAllowed || proofUploadAllowed || chatAllowed || callUri != null || mapsUri != null) ...[
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.truckerTripDetailActionsTitle,
            children: [
              if (stageAction != null)
                GradientButton(
                  label: stageAction.$1,
                  isLoading: actionState.isSubmitting,
                  onPressed: actionState.isSubmitting
                      ? null
                      : () async {
                          final result = await ref
                              .read(truckerTripActionProvider(detail.id).notifier)
                              .advanceFromCurrentStage(detail.stage);
                          if (!context.mounted) {
                            return;
                          }
                          result.when(
                            success: (_) {
                              AppSnackbar.show(
                                context: context,
                                message: stageAction.$2,
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (failure) {
                              AppSnackbar.show(
                                context: context,
                                message: l10n.truckerTripDetailActionSubmitFailureMessage,
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        },
                ),
              if (stageAction != null && (lrUploadAllowed || proofUploadAllowed || chatAllowed || callUri != null || mapsUri != null)) const SizedBox(height: 12),
              if (lrUploadAllowed)
                OutlineButton(
                  label: detail.hasLrProof
                      ? l10n.truckerTripDetailReplaceLrUploadAction
                      : l10n.truckerTripDetailUploadLrOptionalAction,
                  onPressed: actionState.isSubmitting
                      ? null
                      : () async {
                          final source = await _showTripProofSourceSheet(
                            context: context,
                            title: l10n.truckerTripDetailUploadLrImageTitle,
                          );
                          if (!context.mounted || source == null) {
                            return;
                          }
                          final result = await ref
                              .read(truckerTripActionProvider(detail.id).notifier)
                              .uploadLrProof(currentStage: detail.stage, source: source);
                          if (!context.mounted) {
                            return;
                          }
                          result.when(
                            success: (uploaded) {
                              if (!uploaded) {
                                return;
                              }
                              AppSnackbar.show(
                                context: context,
                                message: l10n.truckerTripDetailLrUploadedSuccess,
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (failure) {
                              AppSnackbar.show(
                                context: context,
                                message: l10n.truckerTripDetailLrUploadFailureMessage,
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        },
                ),
              if (lrUploadAllowed && (proofUploadAllowed || chatAllowed || callUri != null || mapsUri != null)) const SizedBox(height: 12),
              if (proofUploadAllowed)
                PrimaryButton(
                  label: l10n.truckerTripDetailUploadPodPhotoAction,
                  isLoading: actionState.isSubmitting,
                  onPressed: actionState.isSubmitting
                      ? null
                      : () async {
                          final source = await _showTripProofSourceSheet(
                            context: context,
                            title: l10n.truckerTripDetailUploadPodPhotoTitle,
                          );
                          if (!context.mounted || source == null) {
                            return;
                          }
                          final result = await ref
                              .read(truckerTripActionProvider(detail.id).notifier)
                              .uploadPodProof(
                                currentStage: detail.stage,
                                source: source,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          result.when(
                            success: (uploaded) {
                              if (!uploaded) {
                                return;
                              }
                              AppSnackbar.show(
                                context: context,
                                message: l10n.truckerTripDetailPodUploadedSuccess,
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (failure) {
                              AppSnackbar.show(
                                context: context,
                                message: l10n.truckerTripDetailPodUploadFailureMessage,
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        },
                ),
              if (proofUploadAllowed && (chatAllowed || callUri != null || mapsUri != null)) const SizedBox(height: 12),
              if (chatAllowed)
                _TripChatButton(
                  supplierId: detail.supplierId,
                  truckerId: detail.truckerId,
                  loadId: detail.loadId,
                ),
              if (chatAllowed && (callUri != null || mapsUri != null)) const SizedBox(height: 12),
              if (callUri != null)
                OutlineButton(
                  label: l10n.truckerTripDetailCallSupplierAction,
                  onPressed: communicationBlocked
                      ? null
                      : () async {
                          await launchUrl(callUri, mode: LaunchMode.externalApplication);
                        },
                ),
              if (callUri != null && mapsUri != null) const SizedBox(height: 12),
              if (mapsUri != null)
                OutlineButton(
                  label: l10n.commonOpenInGoogleMapsAction,
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri);
                  },
                ),
              const SizedBox(height: 12),
              OutlineButton(
                label: l10n.commonReportSpamOrAbuseAction,
                onPressed: () => context.push(
                  AppRoutes.reportIssuePath,
                  extra: ReportIssueContext(
                    initialCategory: 'spam_or_scam',
                    relatedLoadId: detail.loadId,
                    relatedTripId: detail.id,
                    sourceLabel: l10n.truckerTripDetailReportSourceLabel(
                      detail.originLabel,
                      detail.destinationLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (detail.stage == 'proof_submitted' && detail.podUploadedAt != null) ...[
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.truckerTripDetailReviewCountdownTitle,
            children: [
              _ProofCountdownLabel(podUploadedAt: detail.podUploadedAt!),
              const SizedBox(height: 8),
              Text(
                l10n.truckerTripDetailReviewCountdownMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        if (detail.stage == 'disputed') ...[
          const SizedBox(height: 16),
          WarningBlock(
            title: _tripDisputeBannerTitle(l10n, detail.disputeSummary?.status),
            message: _tripDisputeBannerMessage(l10n, detail.disputeSummary),
          ),
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.truckerTripDetailDisputeStatusTitle,
            children: [
              Text(
                detail.disputeSummary == null
                    ? l10n.truckerTripDetailDisputeStateRaised
                    : l10n.truckerTripDetailDisputeCurrentStateLabel(
                        _localizedDisputeStatusLabel(l10n, detail.disputeSummary!.status),
                      ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (detail.disputeSummary != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.supplierTripDetailDisputeCategorySummary(
                    _localizedDisputeCategoryLabel(l10n, detail.disputeSummary!.category),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.truckerTripDetailDisputeLastUpdatedLabel(_tripDetailFormatDateTime(context, detail.disputeSummary!.updatedAt)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _tripDisputeStatusGuidance(l10n, detail.disputeSummary!.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _tripDisputeActionGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _tripSharedVisibilityGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _tripProofGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlineButton(
                label: l10n.commonSupportLabel,
                onPressed: () => context.push(AppRoutes.supportPath),
              ),
            ],
          ),
        ],
        if (detail.stage == 'cancelled') ...[
          const SizedBox(height: 16),
          WarningBlock(
            title: l10n.truckerTripDetailCancelledTitle,
            message: l10n.truckerTripDetailCancelledMessage,
          ),
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.truckerTripDetailCancellationSummaryTitle,
            children: [
              Text(
                l10n.truckerTripDetailCancellationCurrentState,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.truckerTripDetailRouteLabel('${detail.originLabel} to ${detail.destinationLabel}'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.truckerTripDetailMaterialLabel(detail.material),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.truckerTripDetailAssignedOnLabel(_tripDetailFormatDateTime(context, detail.assignedAt)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.truckerTripDetailCancellationFollowupMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        if (detail.stage == 'completed') ...[
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.truckerTripDetailTripSummaryTitle,
            children: [
              Text(
                l10n.truckerTripDetailTripSummaryMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(l10n.truckerTripDetailCompletedOnLabel(_tripDetailFormatDateTime(context, detail.completedAt))),
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailRouteLabel('${detail.originLabel} > ${detail.destinationLabel}')),
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailMaterialLabel(detail.material)),
            ],
          ),
          const SizedBox(height: 16),
          _CompletedTripRatingSection(detail: detail),
        ],
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.commonRouteAndScheduleTitle,
          ttsMessage: overviewTts,
          children: [
            Text(l10n.truckerTripDetailOriginLabel(detail.originLabel)),
            const SizedBox(height: 4),
            Text(l10n.truckerTripDetailDestinationLabel(detail.destinationLabel)),
            if (routeSnapshot != null) ...[
              const SizedBox(height: 12),
              Text(l10n.truckerTripDetailDistanceLabel(routeSnapshot.distanceKm.toStringAsFixed(1))),
            ],
            if (routeSnapshot != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailDriveTimeLabel(routeSnapshot.durationMinutes)),
            ],
            const SizedBox(height: 12),
            Text(l10n.truckerTripDetailAssignedLabel(_tripDetailFormatDateTime(context, detail.assignedAt))),
            if (detail.startedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailStartedLabel(_tripDetailFormatDateTime(context, detail.startedAt))),
            ],
            if (detail.deliveredAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailDeliveredLabel(_tripDetailFormatDateTime(context, detail.deliveredAt))),
            ],
            if (detail.podUploadedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailPodUploadedLabel(_tripDetailFormatDateTime(context, detail.podUploadedAt))),
            ],
            if (detail.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailCompletedLabel(_tripDetailFormatDateTime(context, detail.completedAt))),
            ],
          ],
        ),
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.truckerTripDetailTruckSupplierTitle,
          children: [
            Text(l10n.truckerTripDetailTruckNumberLabel(detail.truckNumber)),
            if ((detail.truckBodyType ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailBodyTypeLabel(l10n.truckerFleetBodyTypeOption(detail.truckBodyType!))),
            ],
            if (detail.truckTyres != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailTyresLabel('${detail.truckTyres}')),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push(AppRoutes.publicProfileLocation(detail.supplierId)),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.truckerTripDetailSupplierLabel(detail.supplier.fullName)),
                          if ((detail.supplier.companyName ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(l10n.truckerTripDetailCompanyLabel(detail.supplier.companyName!)),
                          ],
                          if ((detail.supplier.mobile ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(l10n.truckerTripDetailMobileLabel(detail.supplier.mobile!)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
