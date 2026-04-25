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
                        ReviewTriggerHelper.showTripCompletedReviewPrompt(
                          context,
                          ref,
                          targetUserId: widget.detail.supplierId,
                          targetUserName: widget.detail.supplier.companyName?.trim().isNotEmpty == true
                              ? widget.detail.supplier.companyName!
                              : widget.detail.supplier.fullName,
                          tripId: widget.detail.id,
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
      return l10n.verificationStatusVerified;
    case 'pending':
      return l10n.commonPendingLabel;
    case 'rejected':
      return l10n.verificationStatusRejected;
    default:
      return l10n.commonUnknownLabel;
  }
}

String _localizedTripStage(AppLocalizations l10n, String stage) {
  return l10n.tripStageValue(stage.trim().toLowerCase());
}

String _localizedProofStatus(AppLocalizations l10n, TruckerTripDetail detail) {
  String normalized;
  if (detail.hasPodProof) {
    normalized = 'pod_uploaded';
  } else if (detail.hasLrProof) {
    normalized = 'lr_uploaded';
  } else {
    normalized = switch (detail.stage.trim().toLowerCase()) {
      'delivered' => 'awaiting_pod',
      'proof_submitted' => 'proof_submitted',
      _ => 'proof_pending',
    };
  }
  return l10n.proofStatusValue(normalized);
}
