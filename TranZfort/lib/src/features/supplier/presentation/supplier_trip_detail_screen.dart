import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/shell/presentation/shell_components.dart';
import '../../support/providers/support_compose_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/status_components.dart';
import '../data/supplier_trip_repository.dart';
import '../providers/supplier_trip_action_provider.dart';
import '../providers/supplier_trip_detail_provider.dart';
import '../providers/supplier_trip_rating_provider.dart';

class SupplierTripDetailScreen extends ConsumerWidget {
  final String tripId;

  const SupplierTripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(supplierTripDetailProvider(tripId));
    final detail = state.detail;

    return DetailPageScaffold(
      title: l10n.supplierTripDetailTitle,
      children: [
        if (state.isLoading) const LoadingShimmer(height: 120, itemCount: 4),
        if (!state.isLoading && state.failure is NotFoundFailure && detail == null)
          EmptyStateView(
            icon: Icons.alt_route_outlined,
            title: l10n.supplierTripDetailNotFoundTitle,
            subtitle: l10n.supplierTripDetailNotFoundSubtitle,
            actionLabel: l10n.supplierTripDetailBackToTripsAction,
            onAction: () => context.go(AppRoutes.supplierTripsPath),
          ),
        if (!state.isLoading && state.failure != null && detail == null)
          WarningBlock(
            title: l10n.supplierTripDetailLoadFailureTitle,
            message: l10n.supplierTripDetailLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.read(supplierTripDetailProvider(tripId).notifier).load(),
            ),
          ),
        if (!state.isLoading && detail != null) _SupplierTripDetailBody(detail: detail),
      ],
    );
  }
}

String _localizedSupplierTripVerificationStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return l10n.supplierTripDetailVerificationStatusVerified;
    case 'pending':
      return l10n.supplierTripDetailVerificationStatusPending;
    case 'rejected':
      return l10n.supplierTripDetailVerificationStatusRejected;
    default:
      return l10n.supplierTripDetailVerificationStatusUnknown;
  }
}

String _localizedSupplierTripStage(AppLocalizations l10n, String stage) {
  switch (stage.trim().toLowerCase()) {
    case 'assigned':
      return l10n.supplierTripDetailStageAssigned;
    case 'pickup_pending':
      return l10n.supplierTripDetailStagePickupPending;
    case 'picked_up':
      return l10n.supplierTripDetailStagePickedUp;
    case 'in_transit':
      return l10n.supplierTripDetailStageInTransit;
    case 'delivered':
      return l10n.supplierTripDetailStageDelivered;
    case 'proof_submitted':
      return l10n.supplierTripDetailStageProofSubmitted;
    case 'completed':
      return l10n.supplierTripDetailStageCompleted;
    case 'disputed':
      return l10n.supplierTripDetailStageDisputed;
    case 'cancelled':
      return l10n.supplierTripDetailStageCancelled;
    default:
      return l10n.supplierTripDetailStageUnknown;
  }
}

class _CompletedTripRatingSection extends ConsumerStatefulWidget {
  final SupplierTripDetail detail;

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
    final ratingState = ref.watch(supplierTripRatingProvider(widget.detail.loadId));

    if (!_didSeedComment && !ratingState.isLoading) {
      _commentController.text = ratingState.commentDraft;
      _didSeedComment = true;
    }

    return DetailSectionCard(
      title: l10n.supplierTripDetailRatingSectionTitle,
      children: [
        if (ratingState.isLoading)
          const LoadingShimmer(height: 72, itemCount: 1)
        else if (ratingState.hasSubmittedRating) ...[
          Text(
            l10n.supplierTripDetailRatingAlreadySubmitted,
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
            l10n.supplierTripDetailRatingSubmittedOn(
              _formatSubmittedDate(context, ratingState.submittedRating!.createdAt),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          Text(
            l10n.supplierTripDetailRatingPrompt,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _RatingStars(
            selectedScore: ratingState.selectedScore,
            enabled: !ratingState.isSubmitting,
            onSelected: (value) {
              ref.read(supplierTripRatingProvider(widget.detail.loadId).notifier).setSelectedScore(value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _commentController,
            label: l10n.supplierTripDetailCommentLabel,
            hintText: l10n.supplierTripDetailCommentHint,
            maxLines: 3,
            onChanged: (value) {
              ref.read(supplierTripRatingProvider(widget.detail.loadId).notifier).setCommentDraft(value);
            },
          ),
          if (ratingState.failure != null) ...[
            const SizedBox(height: 12),
            WarningBlock(
              title: l10n.supplierTripDetailRatingUnavailableTitle,
              message: l10n.supplierTripDetailRatingFailureMessage,
            ),
          ],
          const SizedBox(height: 12),
          GradientButton(
            label: l10n.supplierTripDetailSubmitRatingAction,
            isLoading: ratingState.isSubmitting,
            onPressed: ratingState.isSubmitting
                ? null
                : () async {
                    final result = await ref.read(supplierTripRatingProvider(widget.detail.loadId).notifier).submit();
                    if (!context.mounted) {
                      return;
                    }
                    result.when(
                      success: (_) {
                        AppSnackbar.show(
                          context: context,
                          message: l10n.supplierTripDetailRatingSubmittedSuccess,
                          variant: AppSnackbarVariant.success,
                        );
                      },
                      failure: (failure) {
                        AppSnackbar.show(
                          context: context,
                          message: l10n.supplierTripDetailRatingSubmitFailureMessage,
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
            tooltip: l10n.supplierTripDetailRatingStarTooltip(index, index == 1 ? '' : 's'),
          ),
      ],
    );
  }
}

class _SupplierTripDetailBody extends ConsumerWidget {
  final SupplierTripDetail detail;

  const _SupplierTripDetailBody({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(supplierTripActionProvider(detail.id));
    final confirmAllowed = detail.stage == 'proof_submitted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroActionCard(
          title: detail.routeLabel,
          subtitle: l10n.supplierTripDetailHeroSubtitle(detail.id, detail.truckNumber),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: _localizedSupplierTripStage(l10n, detail.stage),
                    icon: Icons.alt_route_outlined,
                  ),
                  StatusBadge(
                    label: _localizedSupplierTripVerificationStatus(l10n, detail.trucker.verificationStatus),
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.supplierTripDetailMaterialTruckerSummary(detail.material, detail.trucker.fullName),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.supplierTripDetailNextStepTitle,
          children: [
            Text(_nextStep(l10n, detail.stage).$1, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(_nextStep(l10n, detail.stage).$2, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        if (detail.stage == 'disputed') ...[
          const SizedBox(height: 16),
          WarningBlock(
            title: _disputeBannerTitle(l10n, detail.disputeSummary?.status),
            message: _disputeBannerMessage(l10n, detail.disputeSummary),
          ),
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.supplierTripDetailDisputeStatusTitle,
            children: [
              Text(
                detail.disputeSummary == null
                    ? l10n.supplierTripDetailDisputeStateRaised
                    : l10n.supplierTripDetailDisputeCategorySummary(
                        _localizedDisputeCategoryLabel(l10n, detail.disputeSummary!.category),
                      ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (detail.disputeSummary != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.supplierTripDetailDisputeCurrentStateLabel(
                    _localizedDisputeStatusLabel(l10n, detail.disputeSummary!.status),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.supplierTripDetailDisputeLastUpdatedLabel(_formatDateTime(context, detail.disputeSummary!.updatedAt)),
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
                _actionGuidance(l10n, detail.disputeSummary?.status),
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
        if (actionState.failure != null) ...[
          const SizedBox(height: 16),
          WarningBlock(
            title: l10n.supplierTripDetailActionUnavailableTitle,
            message: l10n.supplierTripDetailActionFailureMessage,
          ),
        ],
        if (detail.podSignedUrl != null || detail.lrSignedUrl != null) ...[
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.supplierTripDetailProofDocumentsTitle,
            children: [
              if (detail.podSignedUrl != null) ...[
                Text(l10n.supplierTripDetailPodPhotoTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openImagePreview(context, detail.podSignedUrl!, l10n.supplierTripDetailPodPhotoTitle),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        detail.podSignedUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Text(l10n.supplierTripDetailPreviewUnavailable),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlineButton(
                  label: l10n.supplierTripDetailOpenPodPhotoAction,
                  onPressed: () => _openImagePreview(context, detail.podSignedUrl!, l10n.supplierTripDetailPodPhotoTitle),
                ),
              ],
              if (detail.podSignedUrl != null && detail.lrSignedUrl != null) const SizedBox(height: 12),
              if (detail.lrSignedUrl != null)
                OutlineButton(
                  label: l10n.supplierTripDetailOpenLrDocumentAction,
                  onPressed: () => _openImagePreview(context, detail.lrSignedUrl!, l10n.supplierTripDetailOpenLrDocumentAction),
                ),
            ],
          ),
        ],
        if (confirmAllowed) ...[
          const SizedBox(height: 16),
          DetailSectionCard(
            title: l10n.supplierTripDetailActionsTitle,
            children: [
              GradientButton(
                label: l10n.supplierTripDetailConfirmDeliveryAction,
                isLoading: actionState.isSubmitting,
                onPressed: actionState.isSubmitting
                    ? null
                    : () async {
                        final result = await ref
                            .read(supplierTripActionProvider(detail.id).notifier)
                            .confirmDelivery();
                        if (!context.mounted) {
                          return;
                        }
                        result.when(
                          success: (_) {
                            AppSnackbar.show(
                              context: context,
                              message: l10n.supplierTripDetailConfirmDeliverySuccess,
                              variant: AppSnackbarVariant.success,
                            );
                          },
                          failure: (failure) {
                            AppSnackbar.show(
                              context: context,
                              message: l10n.supplierTripDetailActionSubmitFailureMessage,
                              variant: AppSnackbarVariant.error,
                            );
                          },
                        );
                      },
              ),
              const SizedBox(height: 12),
              OutlineButton(
                label: l10n.supplierTripDetailDisputePodAction,
                isLoading: actionState.isSubmitting && actionState.pendingStage == 'disputed',
                onPressed: actionState.isSubmitting
                    ? null
                    : () => context.go('${AppRoutes.raiseDisputePath}/${detail.id}'),
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
                    sourceLabel: l10n.supplierTripDetailReportSourceLabel(detail.routeLabel),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (detail.stage == 'completed') ...[
          const SizedBox(height: 16),
          _CompletedTripRatingSection(detail: detail),
        ],
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.supplierTripDetailRouteScheduleTitle,
          children: [
            Text(l10n.supplierTripDetailOriginLabel(detail.originLabel)),
            const SizedBox(height: 4),
            Text(l10n.supplierTripDetailDestinationLabel(detail.destinationLabel)),
            if (detail.routeDistanceKm != null) ...[
              const SizedBox(height: 12),
              Text(l10n.supplierTripDetailDistanceLabel(detail.routeDistanceKm!.toStringAsFixed(1))),
            ],
            if (detail.routeDurationMinutes != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailDriveTimeLabel(detail.routeDurationMinutes!)),
            ],
            if (detail.pickupDate != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailPickupDateLabel(_formatDate(context, detail.pickupDate))),
            ],
            const SizedBox(height: 12),
            Text(l10n.supplierTripDetailAssignedLabel(_formatDateTime(context, detail.assignedAt))),
            if (detail.deliveredAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailDeliveredLabel(_formatDateTime(context, detail.deliveredAt))),
            ],
            if (detail.podUploadedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailPodUploadedLabel(_formatDateTime(context, detail.podUploadedAt))),
            ],
            if (detail.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailCompletedLabel(_formatDateTime(context, detail.completedAt))),
            ],
          ],
        ),
        const SizedBox(height: 16),
        DetailSectionCard(
          title: l10n.supplierTripDetailTruckerTruckTitle,
          children: [
            Text(l10n.supplierTripDetailTruckerLabel(detail.trucker.fullName)),
            const SizedBox(height: 4),
            Text(l10n.supplierTripDetailTruckNumberLabel(detail.truckNumber)),
            if ((detail.truckBodyType ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailBodyTypeLabel(l10n.truckerFleetBodyTypeOption(detail.truckBodyType!))),
            ],
            if (detail.truckTyres != null) ...[
              const SizedBox(height: 4),
              Text(l10n.supplierTripDetailTyresLabel('${detail.truckTyres}')),
            ],
          ],
        ),
      ],
    );
  }

  (String, String) _nextStep(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'proof_submitted' => (
          l10n.supplierTripDetailNextStepReviewTitle,
          l10n.supplierTripDetailNextStepReviewMessage,
        ),
      'completed' => (
          l10n.supplierTripDetailNextStepCompletedTitle,
          l10n.supplierTripDetailNextStepCompletedMessage,
        ),
      'disputed' => (
          l10n.supplierTripDetailNextStepDisputedTitle,
          l10n.supplierTripDetailNextStepDisputedMessage,
        ),
      _ => (
          l10n.supplierTripDetailNextStepDefaultTitle,
          l10n.supplierTripDetailNextStepDefaultMessage,
        ),
    };
  }

  Future<void> _openImagePreview(BuildContext context, String imageUrl, String title) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          height: 200,
                          child: Center(child: Text(l10n.supplierTripDetailPreviewUnavailable)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    final l10n = AppLocalizations.of(context);
    if (date == null) {
      return l10n.supplierTripDetailPending;
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatDateTime(BuildContext context, DateTime? date) {
    final l10n = AppLocalizations.of(context);
    if (date == null) {
      return l10n.supplierTripDetailPending;
    }
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: true,
    );
    return '${_formatDate(context, date)} - $time';
  }

  String _disputeStatusGuidance(AppLocalizations l10n, String value) {
    return switch (value.trim().toLowerCase()) {
      'open' => l10n.supplierTripDetailDisputeStatusGuidanceOpen,
      'in_progress' => l10n.supplierTripDetailDisputeStatusGuidanceInProgress,
      'waiting_for_user' => l10n.supplierTripDetailDisputeStatusGuidanceWaitingForUser,
      'resolved' || 'closed' => l10n.supplierTripDetailDisputeStatusGuidanceResolved,
      _ => l10n.supplierTripDetailDisputeStatusGuidanceDefault,
    };
  }

  String _disputeBannerTitle(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'waiting_for_user' => l10n.supplierTripDetailDisputeBannerWaitingTitle,
      'resolved' || 'closed' => l10n.supplierTripDetailDisputeBannerClosedTitle,
      _ => l10n.supplierTripDetailDisputeBannerInProgressTitle,
    };
  }

  String _disputeBannerMessage(AppLocalizations l10n, SupplierTripDisputeSummary? disputeSummary) {
    if (disputeSummary == null) {
      return l10n.supplierTripDetailDisputeBannerNoSummaryMessage;
    }
    final category = _localizedDisputeCategoryLabel(l10n, disputeSummary.category);
    return switch (disputeSummary.status.trim().toLowerCase()) {
      'waiting_for_user' => l10n.supplierTripDetailDisputeBannerWaitingMessage(category),
      'resolved' || 'closed' => l10n.supplierTripDetailDisputeBannerClosedMessage(category),
      _ => l10n.supplierTripDetailDisputeBannerInProgressMessage(
          category,
          _localizedDisputeStatusLabel(l10n, disputeSummary.status),
        ),
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
      'trip_dispute' => l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryTripDispute),
      'loaded_quantity_mismatch' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryLoadedQuantityMismatch),
      'unloaded_quantity_mismatch' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryUnloadedQuantityMismatch),
      'document_mismatch' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDocumentMismatch),
      'non_payment' => l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryNonPayment),
      'fake_payout_proof' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryFakePayoutProof),
      'delay_or_no_show' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDelayOrNoShow),
      'damage_or_shortage' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDamageOrShortage),
      'abusive_behavior' =>
          l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryAbusiveBehavior),
      'spam_or_scam' => l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategorySpamOrScam),
      'other' => l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
      _ => l10n.supplierTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
    };
  }

  String _sharedVisibilityGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.supplierTripDetailSharedVisibilityClosed,
      _ => l10n.supplierTripDetailSharedVisibilityInProgress,
    };
  }

  String _actionGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.supplierTripDetailActionGuidanceClosed,
      _ => l10n.supplierTripDetailActionGuidanceInProgress,
    };
  }

  String _proofGuidance(AppLocalizations l10n, String? status) {
    return switch ((status ?? '').trim().toLowerCase()) {
      'resolved' || 'closed' => l10n.supplierTripDetailProofGuidanceClosed,
      _ => l10n.supplierTripDetailProofGuidanceInProgress,
    };
  }
}
