part of 'trucker_trip_detail_screen.dart';

class _CompletedTripRatingSection extends ConsumerStatefulWidget {
  final TruckerTripDetail detail;

  const _CompletedTripRatingSection({required this.detail});

  @override
  ConsumerState<_CompletedTripRatingSection> createState() => _CompletedTripRatingSectionState();
}

class _CompletedTripRatingSectionState extends ConsumerState<_CompletedTripRatingSection> {
  late final TextEditingController _commentController;
  bool _didSeedComment = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratingState = ref.watch(truckerTripRatingProvider(widget.detail.loadId));

    if (!_didSeedComment && !ratingState.isLoading) {
      _commentController.text = ratingState.commentDraft;
      _didSeedComment = true;
    }

    return DetailSectionCard(
      title: l10n.truckerTripDetailRatingSectionTitle,
      children: [
        if (ratingState.isLoading)
          const LoadingShimmer(height: 72, itemCount: 1)
        else if (ratingState.hasSubmittedRating) ...[
          Text(
            l10n.truckerTripDetailRatingAlreadySubmitted,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _RatingStars(
            selectedScore: ratingState.submittedRating!.score,
            enabled: false,
            onSelected: (_) {},
          ),
          if ((ratingState.submittedRating!.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(ratingState.submittedRating!.comment!),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.truckerTripDetailRatingSubmittedOn(
              _formatSubmittedDate(context, ratingState.submittedRating!.createdAt),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          Text(
            l10n.truckerTripDetailRatingPrompt,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _RatingStars(
            selectedScore: ratingState.selectedScore,
            enabled: !ratingState.isSubmitting,
            onSelected: (value) {
              ref.read(truckerTripRatingProvider(widget.detail.loadId).notifier).setSelectedScore(value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _commentController,
            label: l10n.truckerTripDetailCommentLabel,
            hintText: l10n.truckerTripDetailCommentHint,
            maxLines: 3,
            onChanged: (value) {
              ref.read(truckerTripRatingProvider(widget.detail.loadId).notifier).setCommentDraft(value);
            },
          ),
          if (ratingState.failure != null) ...[
            const SizedBox(height: 12),
            WarningBlock(
              title: l10n.truckerTripDetailRatingUnavailableTitle,
              message: l10n.truckerTripDetailRatingFailureMessage,
            ),
          ],
          const SizedBox(height: 12),
          GradientButton(
            label: l10n.truckerTripDetailSubmitRatingAction,
            isLoading: ratingState.isSubmitting,
            onPressed: ratingState.isSubmitting
                ? null
                : () async {
                    final result = await ref.read(truckerTripRatingProvider(widget.detail.loadId).notifier).submit();
                    if (!context.mounted) {
                      return;
                    }
                    result.when(
                      success: (_) {
                        AppSnackbar.show(
                          context: context,
                          message: l10n.truckerTripDetailRatingSubmittedSuccess,
                          variant: AppSnackbarVariant.success,
                        );
                      },
                      failure: (failure) {
                        AppSnackbar.show(
                          context: context,
                          message: l10n.truckerTripDetailRatingSubmitFailureMessage,
                          variant: AppSnackbarVariant.error,
                        );
                      },
                    );
                  },
          ),
        ],
      ],
    );
  }

  String _formatSubmittedDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }
}

class _RatingStars extends StatelessWidget {
  final int selectedScore;
  final bool enabled;
  final ValueChanged<int> onSelected;

  const _RatingStars({
    required this.selectedScore,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (var index = 1; index <= 5; index++)
          IconButton(
            onPressed: enabled ? () => onSelected(index) : null,
            icon: Icon(
              index <= selectedScore ? Icons.star_rounded : Icons.star_border_rounded,
              color: index <= selectedScore ? Colors.amber : Theme.of(context).colorScheme.outline,
            ),
            tooltip: l10n.truckerTripDetailRatingStarTooltip(index, index == 1 ? '' : 's'),
          ),
      ],
    );
  }
}

class _ProofCountdownLabel extends StatelessWidget {
  final DateTime podUploadedAt;

  const _ProofCountdownLabel({required this.podUploadedAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<DateTime>(
      initialData: DateTime.now(),
      stream: Stream<DateTime>.periodic(
        const Duration(minutes: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final remaining = podUploadedAt.add(const Duration(hours: 48)).difference(now);
        final message = remaining.isNegative
            ? l10n.truckerTripDetailAutoCompleteDueNow
            : l10n.truckerTripDetailAutoCompleteIn(_formatDuration(l10n, remaining));
        return Text(
          message,
          style: Theme.of(context).textTheme.titleSmall,
        );
      },
    );
  }

  static String _formatDuration(AppLocalizations l10n, Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return l10n.truckerTripDetailAutoCompleteDuration(hours, minutes);
  }
}

String _localizedVerificationStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return l10n.truckerTripDetailVerificationStatusVerified;
    case 'pending':
      return l10n.truckerTripDetailVerificationStatusPending;
    case 'rejected':
      return l10n.truckerTripDetailVerificationStatusRejected;
    default:
      return l10n.truckerTripDetailVerificationStatusUnknown;
  }
}

String _localizedTripStage(AppLocalizations l10n, String stage) {
  switch (stage.trim().toLowerCase()) {
    case 'assigned':
      return l10n.truckerTripDetailStageAssigned;
    case 'pickup_pending':
      return l10n.truckerTripDetailStagePickupPending;
    case 'picked_up':
      return l10n.truckerTripDetailStagePickedUp;
    case 'in_transit':
      return l10n.truckerTripDetailStageInTransit;
    case 'delivered':
      return l10n.truckerTripDetailStageDelivered;
    case 'proof_submitted':
      return l10n.truckerTripDetailStageProofSubmitted;
    case 'completed':
      return l10n.truckerTripDetailStageCompleted;
    case 'disputed':
      return l10n.truckerTripDetailStageDisputed;
    case 'cancelled':
      return l10n.truckerTripDetailStageCancelled;
    default:
      return l10n.truckerTripsStageUnknown;
  }
}

String _localizedProofStatus(AppLocalizations l10n, TruckerTripDetail detail) {
  if (detail.hasPodProof) {
    return l10n.truckerTripDetailProofStatusPodUploaded;
  }
  if (detail.hasLrProof) {
    return l10n.truckerTripDetailProofStatusLrUploaded;
  }
  switch (detail.stage.trim().toLowerCase()) {
    case 'delivered':
      return l10n.truckerTripDetailProofStatusAwaitingPod;
    case 'proof_submitted':
      return l10n.truckerTripDetailProofStatusProofSubmitted;
    default:
      return l10n.truckerTripDetailProofStatusProofPending;
  }
}

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
    final nextStep = _nextStep(l10n, detail.stage);
    final stageAction = _stageAction(l10n, detail.stage);
    final lrUploadAllowed = detail.stage == 'pickup_pending' || detail.stage == 'picked_up';
    final proofUploadAllowed = detail.stage == 'delivered';
    final chatAllowed = detail.supplierId.trim().isNotEmpty && detail.truckerId.trim().isNotEmpty && detail.loadId.trim().isNotEmpty;
    final callUri = _callUri(detail.supplier.mobile);
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: detail.originLat,
      originLng: detail.originLng,
      destinationLat: detail.destinationLat,
      destinationLng: detail.destinationLng,
      destinationLabel: detail.destinationLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroActionCard(
          title: detail.routeLabel,
          subtitle: l10n.truckerTripDetailHeroSubtitle(detail.id, detail.truckNumber),
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
                  _formatDate(context, detail.pickupDate),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.truckerTripDetailNextStepTitle,
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
                          final source = await _showProofSourceSheet(
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
                          final source = await _showProofSourceSheet(
                            context: context,
                            title: l10n.truckerTripDetailUploadPodPhotoTitle,
                          );
                          if (!context.mounted || source == null) {
                            return;
                          }
                          final result = await ref
                              .read(truckerTripActionProvider(detail.id).notifier)
                              .uploadPodProof(source);
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
                  label: l10n.truckerTripDetailOpenInGoogleMapsAction,
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri);
                  },
                ),
              const SizedBox(height: 12),
              OutlineButton(
                label: l10n.chatMenuReportSpamOrAbuse,
                onPressed: () => context.go(
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
            title: _disputeBannerTitle(l10n, detail.disputeSummary?.status),
            message: _disputeBannerMessage(l10n, detail.disputeSummary),
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
                  l10n.truckerTripDetailDisputeLastUpdatedLabel(
                    _formatDateTime(context, detail.disputeSummary!.updatedAt),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _disputeStatusGuidance(l10n, detail.disputeSummary!.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _disputeActionGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _sharedVisibilityGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _proofGuidance(l10n, detail.disputeSummary?.status),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlineButton(
                label: l10n.navSupport,
                onPressed: () => context.go(AppRoutes.supportPath),
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
                l10n.truckerTripDetailRouteLabel('${detail.originLabel} → ${detail.destinationLabel}'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.truckerTripDetailMaterialLabel(detail.material),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.truckerTripDetailAssignedOnLabel(_formatDateTime(context, detail.assignedAt)),
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
              Text(l10n.truckerTripDetailCompletedOnLabel(_formatDateTime(context, detail.completedAt))),
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailRouteLabel('${detail.originLabel} → ${detail.destinationLabel}')),
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailMaterialLabel(detail.material)),
            ],
          ),
          const SizedBox(height: 16),
          _CompletedTripRatingSection(detail: detail),
        ],
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.truckerTripDetailRouteScheduleTitle,
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
            Text(l10n.truckerTripDetailAssignedLabel(_formatDateTime(context, detail.assignedAt))),
            if (detail.startedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailStartedLabel(_formatDateTime(context, detail.startedAt))),
            ],
            if (detail.deliveredAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailDeliveredLabel(_formatDateTime(context, detail.deliveredAt))),
            ],
            if (detail.podUploadedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailPodUploadedLabel(_formatDateTime(context, detail.podUploadedAt))),
            ],
            if (detail.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.truckerTripDetailCompletedLabel(_formatDateTime(context, detail.completedAt))),
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
      ],
    );
  }

  Uri? _callUri(String? mobile) {
    final normalized = (mobile ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return Uri(scheme: 'tel', path: normalized);
  }

  Future<ImageSource?> _showProofSourceSheet({
    required BuildContext context,
    required String title,
  }) {
    final l10n = AppLocalizations.of(context);
    return showAppBottomSheet<ImageSource>(
      context: context,
      title: title,
      child: Column(
        children: [
          PrimaryButton(
            label: l10n.truckerTripDetailTakePhotoAction,
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          OutlineButton(
            label: l10n.truckerTripDetailChooseFromGalleryAction,
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  (String, String)? _stageAction(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'assigned' => (
          l10n.truckerTripDetailHeadToPickupAction,
          l10n.truckerTripDetailHeadToPickupSuccess,
        ),
      'pickup_pending' => (
          l10n.truckerTripDetailCargoLoadedAction,
          l10n.truckerTripDetailCargoLoadedSuccess,
        ),
      'picked_up' => (
          l10n.truckerTripDetailStartTripAction,
          l10n.truckerTripDetailStartTripSuccess,
        ),
      'in_transit' => (
          l10n.truckerTripDetailMarkDeliveredAction,
          l10n.truckerTripDetailMarkDeliveredSuccess,
        ),
      _ => null,
    };
  }

  (String, String) _nextStep(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'assigned' => (
          l10n.truckerTripDetailNextStepAssignedTitle,
          l10n.truckerTripDetailNextStepAssignedMessage,
        ),
      'pickup_pending' => (
          l10n.truckerTripDetailNextStepPickupPendingTitle,
          l10n.truckerTripDetailNextStepPickupPendingMessage,
        ),
      'picked_up' => (
          l10n.truckerTripDetailNextStepPickedUpTitle,
          l10n.truckerTripDetailNextStepPickedUpMessage,
        ),
      'in_transit' => (
          l10n.truckerTripDetailNextStepInTransitTitle,
          l10n.truckerTripDetailNextStepInTransitMessage,
        ),
      'delivered' => (
          l10n.truckerTripDetailNextStepDeliveredTitle,
          l10n.truckerTripDetailNextStepDeliveredMessage,
        ),
      'proof_submitted' => (
          l10n.truckerTripDetailNextStepProofSubmittedTitle,
          l10n.truckerTripDetailNextStepProofSubmittedMessage,
        ),
      'completed' => (
          l10n.truckerTripDetailNextStepCompletedTitle,
          l10n.truckerTripDetailNextStepCompletedMessage,
        ),
      'disputed' => (
          l10n.truckerTripDetailNextStepDisputedTitle,
          l10n.truckerTripDetailNextStepDisputedMessage,
        ),
      'cancelled' => (
          l10n.truckerTripDetailNextStepCancelledTitle,
          l10n.truckerTripDetailNextStepCancelledMessage,
        ),
      _ => (
          l10n.truckerTripDetailNextStepDefaultTitle,
          l10n.truckerTripDetailNextStepDefaultMessage,
        ),
    };
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return '-';
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatDateTime(BuildContext context, DateTime? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null) {
      return l10n.truckerTripDetailPending;
    }
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: true,
    );
    return '${_formatDate(context, value)} • $time';
  }

  String _disputeStatusGuidance(AppLocalizations l10n, String value) {
    return switch (value.trim().toLowerCase()) {
      'open' => l10n.truckerTripDetailDisputeStatusGuidanceOpen,
      'in_progress' => l10n.truckerTripDetailDisputeStatusGuidanceInProgress,
      'waiting_for_user' => l10n.truckerTripDetailDisputeStatusGuidanceWaitingForUser,
      'resolved' || 'closed' => l10n.truckerTripDetailDisputeStatusGuidanceResolved,
      _ => l10n.truckerTripDetailDisputeStatusGuidanceDefault,
    };
  }

  String _disputeBannerTitle(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'waiting_for_user' => l10n.truckerTripDetailDisputeBannerWaitingTitle,
      'resolved' || 'closed' => l10n.truckerTripDetailDisputeBannerClosedTitle,
      _ => l10n.truckerTripDetailDisputeBannerInProgressTitle,
    };
  }

  String _disputeBannerMessage(AppLocalizations l10n, TruckerTripDisputeSummary? disputeSummary) {
    if (disputeSummary == null) {
      return l10n.truckerTripDetailDisputeBannerNoSummaryMessage;
    }
    final category = _localizedDisputeCategoryLabel(l10n, disputeSummary.category);
    return switch (disputeSummary.status.trim().toLowerCase()) {
      'waiting_for_user' => l10n.truckerTripDetailDisputeBannerWaitingMessage(category),
      'resolved' || 'closed' => l10n.truckerTripDetailDisputeBannerClosedMessage(category),
      _ => l10n.truckerTripDetailDisputeBannerInProgressMessage(category),
    };
  }

  String _localizedDisputeStatusLabel(AppLocalizations l10n, String status) {
    return switch (status.trim().toLowerCase()) {
      'open' => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusOpen),
      'in_progress' => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusInProgress),
      'waiting_for_user' => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusWaitingForYou),
      'resolved' => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusResolved),
      'closed' => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusClosed),
      _ => l10n.supplierTripDetailDisputeStatusLabel(l10n.supportTicketStatusUnknown),
    };
  }

  String _localizedDisputeCategoryLabel(AppLocalizations l10n, String category) {
    return switch (category.trim().toLowerCase()) {
      'trip_dispute' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryTripDispute),
      'loaded_quantity_mismatch' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryLoadedQuantityMismatch),
      'unloaded_quantity_mismatch' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryUnloadedQuantityMismatch),
      'document_mismatch' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDocumentMismatch),
      'non_payment' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryNonPayment),
      'fake_payout_proof' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryFakePayoutProof),
      'delay_or_no_show' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDelayOrNoShow),
      'damage_or_shortage' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDamageOrShortage),
      'abusive_behavior' =>
          l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryAbusiveBehavior),
      'spam_or_scam' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategorySpamOrScam),
      'other' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
      _ => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
    };
  }

  String _disputeActionGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.truckerTripDetailDisputeActionGuidanceClosed,
      _ => l10n.truckerTripDetailDisputeActionGuidanceInProgress,
    };
  }

  String _sharedVisibilityGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.truckerTripDetailSharedVisibilityClosed,
      _ => l10n.truckerTripDetailSharedVisibilityInProgress,
    };
  }

  String _proofGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.truckerTripDetailProofGuidanceClosed,
      _ => l10n.truckerTripDetailProofGuidanceInProgress,
    };
  }
}

class _TripChatButton extends ConsumerStatefulWidget {
  final String supplierId;
  final String truckerId;
  final String loadId;

  const _TripChatButton({
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
  });

  @override
  ConsumerState<_TripChatButton> createState() => _TripChatButtonState();
}

class _TripChatButtonState extends ConsumerState<_TripChatButton> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final truckerProfileAsync = ref.watch(truckerProfileProvider);
    final truckerProfile = truckerProfileAsync.valueOrNull;
    final chatBlockedMessage = _tripChatBlockedMessage(l10n, truckerProfileAsync, truckerProfile);
    final chatBlocked = chatBlockedMessage != null;
    final showOpenVerification = !truckerProfileAsync.isLoading && truckerAsyncFailure(truckerProfileAsync) == null && (truckerProfile == null || !truckerProfile.isVerified);
    final showOpenFleet = !showOpenVerification && truckerProfile != null && !truckerProfile.hasApprovedTruck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineButton(
          label: l10n.truckerChatSupplierAction,
          isLoading: _isStarting,
          onPressed: _isStarting || chatBlocked
              ? null
              : () async {
                  setState(() {
                    _isStarting = true;
                  });
                  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
                        supplierId: widget.supplierId,
                        truckerId: widget.truckerId,
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
                        message: l10n.truckerTripChatStartFailureMessage,
                        variant: AppSnackbarVariant.error,
                      );
                    },
                  );
                },
        ),
        if (chatBlockedMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            chatBlockedMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (showOpenVerification) ...[
            const SizedBox(height: 8),
            TextActionButton(
              label: l10n.truckerDashboardOpenVerificationAction,
              onPressed: () => context.go(AppRoutes.truckerVerificationPath),
            ),
          ] else if (showOpenFleet) ...[
            const SizedBox(height: 8),
            TextActionButton(
              label: l10n.truckerDashboardOpenFleetAction,
              onPressed: () => context.go(AppRoutes.fleetPath),
            ),
          ],
        ],
      ],
    );
  }
}

String? _tripChatBlockedMessage(
  AppLocalizations l10n,
  AsyncValue<TruckerProfile?> truckerProfileAsync,
  TruckerProfile? truckerProfile,
) {
  if (truckerProfileAsync.isLoading) {
    return l10n.truckerLoadDetailProfileLoadingMessage;
  }
  if (truckerAsyncFailure(truckerProfileAsync) != null) {
    return l10n.truckerLoadDetailProfileLoadingMessage;
  }
  if (truckerProfile == null || !truckerProfile.isVerified) {
    return l10n.truckerLoadDetailVerificationRequiredMessage;
  }
  if (!truckerProfile.hasApprovedTruck) {
    return l10n.truckerLoadDetailTruckApprovalRequiredMessage;
  }
  return null;
}
