import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/shell/presentation/shell_components.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/status_components.dart';
import '../../support/providers/support_providers.dart';
import '../../support/data/support_attachment_upload_service.dart';
import '../providers/supplier_trip_action_provider.dart';
import '../providers/supplier_trip_detail_provider.dart';

class RaiseDisputeScreen extends ConsumerStatefulWidget {
  final String tripId;

  const RaiseDisputeScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  late final TextEditingController _reasonController;
  String _selectedCategory = 'document_mismatch';
  String _attachmentPath = '';
  String? _categoryError;
  String? _reasonError;

  // Track initial values for unsaved changes detection
  late final String _initialCategory;
  late final String _initialAttachmentPath;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _initialCategory = 'document_mismatch';
    _initialAttachmentPath = '';
  }

  bool _hasUnsavedChanges() {
    return _reasonController.text.trim().isNotEmpty ||
        _selectedCategory != _initialCategory ||
        _attachmentPath != _initialAttachmentPath;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Dispute?'),
        content: const Text('You have unsaved dispute details. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tripState = ref.watch(supplierTripDetailProvider(widget.tripId));
    final actionState = ref.watch(supplierTripActionProvider(widget.tripId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final detail = tripState.detail;
    final localizedStage = detail == null ? '' : _localizedSupplierTripStage(l10n, detail.stage);
    final canSubmit = detail != null && detail.stage == 'proof_submitted' && !actionState.isSubmitting;

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final navigator = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Reset form to initial values when discarding changes
            setState(() {
              _reasonController.clear();
              _selectedCategory = _initialCategory;
              _attachmentPath = _initialAttachmentPath;
            });
            // Navigate back
            navigator.pop();
          }
        }
      },
      child: DetailPageScaffold(
        title: l10n.supplierRaiseDisputeTitle,
        children: [
        if (tripState.isLoading)
          const LoadingShimmer(height: 120, itemCount: 2)
        else if (tripState.failure is NotFoundFailure && detail == null)
          EmptyStateView(
            icon: Icons.alt_route_outlined,
            title: l10n.supplierTripDetailNotFoundTitle,
            subtitle: l10n.supplierTripDetailNotFoundSubtitle,
            actionLabel: l10n.supplierTripDetailBackToTripsAction,
            onAction: () => context.go(AppRoutes.supplierTripsPath),
          )
        else if (tripState.failure != null && detail == null)
          WarningBlock(
            title: l10n.supplierRaiseDisputeTripUnavailableTitle,
            message: l10n.supplierRaiseDisputeTripLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.read(supplierTripDetailProvider(widget.tripId).notifier).load(),
            ),
          )
        else if (detail != null) ...[
          HeroActionCard(
            title: l10n.supplierRaiseDisputeHeroTitle,
            subtitle: l10n.supplierRaiseDisputeHeroSubtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusBadge(
                      label: localizedStage,
                      icon: Icons.alt_route_outlined,
                    ),
                    StatusBadge(
                      label: l10n.supplierRaiseDisputeTripBadge,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.supplierRaiseDisputeHeroSummary(detail.routeLabel, detail.material),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.supplierRaiseDisputeHeroGuidance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (tripState.failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            WarningBlock(
              title: l10n.supplierRaiseDisputePartialContextUnavailableTitle,
              message: l10n.supplierRaiseDisputeTripContextFailureMessage,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DetailSectionCard(
            title: l10n.supplierRaiseDisputeSummaryTitle,
            children: [
              Text(l10n.supplierRaiseDisputeTripRouteLabel(detail.routeLabel)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierRaiseDisputeTruckLabel(detail.truckNumber)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierRaiseDisputeTruckerLabel(detail.trucker.fullName)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierRaiseDisputeCurrentStageLabel(localizedStage)),
              if (detail.stage != 'proof_submitted') ...[
                const SizedBox(height: AppSpacing.md),
                WarningBlock(
                  title: l10n.supplierRaiseDisputeSubmissionBlockedTitle,
                  message: l10n.supplierRaiseDisputeSubmissionBlockedMessage,
                  action: OutlineButton(
                    label: l10n.navSupport,
                    onPressed: () => context.push(AppRoutes.supportPath),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (actionState.failure != null)
            WarningBlock(
              title: l10n.supplierRaiseDisputeSubmissionUnavailableTitle,
              message: l10n.supplierRaiseDisputeSubmitFailureMessage,
            ),
          DetailSectionCard(
            title: l10n.supplierRaiseDisputeProblemTitle,
            children: [
              AppDropdown<String>(
                label: l10n.supplierRaiseDisputeCategoryLabel,
                value: _selectedCategory,
                items: supplierTripDisputeCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(l10n.supplierTripDetailDisputeCategoryLabel(category)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                    _categoryError = null;
                  });
                },
                helperText: _categoryError,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _reasonController,
                label: l10n.supplierRaiseDisputeReasonLabel,
                hintText: l10n.supplierRaiseDisputeReasonHint,
                maxLines: 6,
                errorText: _reasonError,
                onChanged: (_) {
                  if (_reasonError != null) {
                    setState(() {
                      _reasonError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supplierRaiseDisputeHelpfulDetailsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.supplierRaiseDisputeHelpfulDetailsMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _reasonPrompts(l10n, _selectedCategory)
                    .map(
                      (prompt) => ActionChip(
                        label: Text(prompt),
                        onPressed: actionState.isSubmitting ? null : () => _appendReasonPrompt(prompt),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supplierRaiseDisputeEvidenceOptionalTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _attachmentPath.trim().isEmpty
                    ? l10n.supplierRaiseDisputeNoEvidenceAttached
                    : l10n.supplierRaiseDisputeEvidenceAttached,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _evidenceGuidance(l10n, _selectedCategory),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _bestImageGuidance(l10n, _selectedCategory),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.supplierRaiseDisputeVisibleToOtherPartyMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._evidenceChecklist(l10n, _selectedCategory).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '- $item',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlineButton(
                      label: l10n.supplierRaiseDisputeUseCameraAction,
                      onPressed: actionState.isSubmitting || profile == null
                          ? null
                          : () => _pickAndUploadAttachment(context, ImageSource.camera, profile.id),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlineButton(
                      label: l10n.supplierRaiseDisputeChoosePhotoAction,
                      onPressed: actionState.isSubmitting || profile == null
                          ? null
                          : () => _pickAndUploadAttachment(context, ImageSource.gallery, profile.id),
                    ),
                  ),
                ],
              ),
              if (_attachmentPath.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlineButton(
                    label: l10n.supplierRaiseDisputeRemoveEvidenceAction,
                    onPressed: actionState.isSubmitting
                        ? null
                        : () => setState(() {
                              _attachmentPath = '';
                            }),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: l10n.supplierRaiseDisputeSubmitAction,
                  isLoading: actionState.isSubmitting && actionState.pendingStage == 'disputed',
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          final reason = _reasonController.text.trim();
                          if (!supplierTripDisputeCategories.contains(_selectedCategory)) {
                            setState(() {
                              _categoryError = l10n.supplierRaiseDisputeCategoryError;
                            });
                            return;
                          }
                          if (reason.length < 10) {
                            setState(() {
                              _reasonError = l10n.supplierRaiseDisputeReasonError;
                            });
                            return;
                          }

                          final result = await ref.read(supplierTripActionProvider(widget.tripId).notifier).raiseDispute(
                                category: _selectedCategory,
                                reason: reason,
                                attachmentPath: _attachmentPath.trim().isEmpty ? null : _attachmentPath.trim(),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          result.when(
                            success: (ticketId) {
                              ref.read(supportTicketsProvider.notifier).load();
                              context.push(AppRoutes.supportPath, extra: ticketId);
                              AppSnackbar.show(
                                context: context,
                                message: l10n.supplierRaiseDisputeSubmittedSuccess,
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (failure) {
                              AppSnackbar.show(
                                context: context,
                                message: l10n.supplierRaiseDisputeSubmitFailureMessage,
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ],
      ),
    );
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

  Future<void> _pickAndUploadAttachment(
    BuildContext context,
    ImageSource source,
    String userId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(supportAttachmentUploadServiceProvider).pickCompressAndUploadAttachment(
          profileId: userId,
          source: source,
          pathSegment: 'trip_dispute',
        );
    if (!context.mounted) {
      return;
    }
    if (result.isSuccess) {
      final path = result.valueOrNull;
      if (path != null && path.trim().isNotEmpty) {
        setState(() {
          _attachmentPath = path;
        });
        AppSnackbar.show(
          context: context,
          message: l10n.supplierRaiseDisputeAttachmentAttachedSuccess,
          variant: AppSnackbarVariant.success,
        );
      }
      return;
    }
    AppSnackbar.show(
      context: context,
      message: l10n.supplierRaiseDisputeAttachmentFailureMessage,
      variant: AppSnackbarVariant.error,
    );
  }

  void _appendReasonPrompt(String prompt) {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      return;
    }

    final currentText = _reasonController.text.trimRight();
    if (currentText.contains(normalizedPrompt)) {
      _reasonController.selection = TextSelection.collapsed(offset: _reasonController.text.length);
      return;
    }

    final nextText = currentText.isEmpty
        ? '$normalizedPrompt '
        : '$currentText\n$normalizedPrompt ';
    _reasonController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    if (_reasonError != null) {
      setState(() {
        _reasonError = null;
      });
    } else {
      setState(() {});
    }
  }

  String _evidenceGuidance(AppLocalizations l10n, String category) {
    return switch (category) {
      'loaded_quantity_mismatch' => l10n.supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch,
      'unloaded_quantity_mismatch' => l10n.supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch,
      'document_mismatch' => l10n.supplierRaiseDisputeEvidenceGuidanceDocumentMismatch,
      'non_payment' => l10n.supplierRaiseDisputeEvidenceGuidanceNonPayment,
      'fake_payout_proof' => l10n.supplierRaiseDisputeEvidenceGuidanceFakePayoutProof,
      'delay_or_no_show' => l10n.supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow,
      'damage_or_shortage' => l10n.supplierRaiseDisputeEvidenceGuidanceDamageOrShortage,
      'abusive_behavior' => l10n.supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior,
      'spam_or_scam' => l10n.supplierRaiseDisputeEvidenceGuidanceSpamOrScam,
      'other' => l10n.supplierRaiseDisputeEvidenceGuidanceOther,
      _ => l10n.supplierRaiseDisputeEvidenceGuidanceFallback,
    };
  }

  String _bestImageGuidance(AppLocalizations l10n, String category) {
    return switch (category) {
      'loaded_quantity_mismatch' ||
      'unloaded_quantity_mismatch' ||
      'document_mismatch' => l10n.supplierRaiseDisputeBestImageGuidanceDocumentCategory,
      'fake_payout_proof' || 'non_payment' => l10n.supplierRaiseDisputeBestImageGuidancePaymentCategory,
      'delay_or_no_show' || 'abusive_behavior' || 'spam_or_scam' => l10n.supplierRaiseDisputeBestImageGuidanceTimelineCategory,
      'damage_or_shortage' => l10n.supplierRaiseDisputeBestImageGuidanceDamageCategory,
      'other' => l10n.supplierRaiseDisputeBestImageGuidanceOther,
      _ => l10n.supplierRaiseDisputeBestImageGuidanceFallback,
    };
  }

  List<String> _reasonPrompts(AppLocalizations l10n, String category) {
    return switch (category) {
      'loaded_quantity_mismatch' => [
        l10n.supplierRaiseDisputePromptDispatchQuantityShownOnProof,
        l10n.supplierRaiseDisputePromptQuantityActuallyChallenged,
        l10n.supplierRaiseDisputePromptOtherLoadingProofNotAttached,
      ],
      'unloaded_quantity_mismatch' => [
        l10n.supplierRaiseDisputePromptQuantityReceivedAtUnloading,
        l10n.supplierRaiseDisputePromptQuantityExpectedFromDispatchProof,
        l10n.supplierRaiseDisputePromptExtraUnloadProofNotAttached,
      ],
      'document_mismatch' => [
        l10n.supplierRaiseDisputePromptDocumentFieldDoesNotMatch,
        l10n.supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe,
        l10n.supplierRaiseDisputePromptOtherRelatedDocumentNotAttached,
      ],
      'non_payment' => [
        l10n.supplierRaiseDisputePromptAmountStillUnpaid,
        l10n.supplierRaiseDisputePromptPaymentDueDateOrMilestone,
        l10n.supplierRaiseDisputePromptOtherPaymentProofNotAttached,
      ],
      'fake_payout_proof' => [
        l10n.supplierRaiseDisputePromptWhyPayoutProofLooksFake,
        l10n.supplierRaiseDisputePromptWhatPaymentStatusShouldBe,
        l10n.supplierRaiseDisputePromptOtherProofOrChatContextNotAttached,
      ],
      'delay_or_no_show' => [
        l10n.supplierRaiseDisputePromptExpectedReportingOrArrivalTime,
        l10n.supplierRaiseDisputePromptActualDelayOrNoShowOutcome,
        l10n.supplierRaiseDisputePromptOtherTimingProofNotAttached,
      ],
      'damage_or_shortage' => [
        l10n.supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage,
        l10n.supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed,
        l10n.supplierRaiseDisputePromptOtherSupportingProofNotAttached,
      ],
      'abusive_behavior' => [
        l10n.supplierRaiseDisputePromptWhatHappenedDuringIncident,
        l10n.supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred,
        l10n.supplierRaiseDisputePromptOtherSupportingProofNotAttached,
      ],
      'spam_or_scam' => [
        l10n.supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred,
        l10n.supplierRaiseDisputePromptWhatMisleadingClaimWasMade,
        l10n.supplierRaiseDisputePromptOtherSupportingProofNotAttached,
      ],
      'other' => [
        l10n.supplierRaiseDisputePromptMainIssueSupportShouldReview,
        l10n.supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded,
        l10n.supplierRaiseDisputePromptOtherSupportingProofNotAttached,
      ],
      _ => [
        l10n.supplierRaiseDisputePromptMainIssueSupportShouldReview,
        l10n.supplierRaiseDisputePromptStrongestMissingProofNotAttached,
      ],
    };
  }

  List<String> _evidenceChecklist(AppLocalizations l10n, String category) {
    return switch (category) {
      'loaded_quantity_mismatch' => [
        l10n.supplierRaiseDisputeChecklistLoadedReadableQuantity,
        l10n.supplierRaiseDisputeChecklistLoadedPreferBilty,
        l10n.supplierRaiseDisputeChecklistLoadedUseWrittenReason,
      ],
      'unloaded_quantity_mismatch' => [
        l10n.supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity,
        l10n.supplierRaiseDisputeChecklistUnloadedPreferWeighbridge,
        l10n.supplierRaiseDisputeChecklistUnloadedUseWrittenReason,
      ],
      'document_mismatch' => [
        l10n.supplierRaiseDisputeChecklistDocumentReadableFields,
        l10n.supplierRaiseDisputeChecklistDocumentPreferSpecificPage,
        l10n.supplierRaiseDisputeChecklistDocumentUseWrittenReason,
      ],
      'non_payment' => [
        l10n.supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot,
        l10n.supplierRaiseDisputeChecklistPaymentUseWrittenReason,
        l10n.supplierRaiseDisputeChecklistPaymentUploadStrongestFirst,
      ],
      'fake_payout_proof' => [
        l10n.supplierRaiseDisputeChecklistFakePreferScreenshot,
        l10n.supplierRaiseDisputeChecklistFakeUseWrittenReason,
        l10n.supplierRaiseDisputeChecklistFakeSummarizeChatContext,
      ],
      'delay_or_no_show' => [
        l10n.supplierRaiseDisputeChecklistDelayChooseClearestTiming,
        l10n.supplierRaiseDisputeChecklistDelayUseWrittenReason,
        l10n.supplierRaiseDisputeChecklistDelayKeepFocusedImage,
      ],
      'damage_or_shortage' => [
        l10n.supplierRaiseDisputeChecklistDamageChooseImage,
        l10n.supplierRaiseDisputeChecklistDamageKeepAffectedGoods,
        l10n.supplierRaiseDisputeChecklistDamageUseWrittenReason,
      ],
      'abusive_behavior' => [
        l10n.supplierRaiseDisputeChecklistAbusiveUploadIfSafe,
        l10n.supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot,
        l10n.supplierRaiseDisputeChecklistAbusiveUseWrittenReason,
      ],
      'spam_or_scam' => [
        l10n.supplierRaiseDisputeChecklistSpamChooseScreenshot,
        l10n.supplierRaiseDisputeChecklistSpamPreferStrongestProof,
        l10n.supplierRaiseDisputeChecklistSpamUseWrittenReason,
      ],
      'other' => [
        l10n.supplierRaiseDisputeChecklistOtherChooseStrongestImage,
        l10n.supplierRaiseDisputeChecklistOtherKeepIssueReadable,
        l10n.supplierRaiseDisputeChecklistOtherUseWrittenReason,
      ],
      _ => [
        l10n.supplierRaiseDisputeChecklistFallbackChooseClearestImage,
        l10n.supplierRaiseDisputeChecklistFallbackKeepReadableProof,
        l10n.supplierRaiseDisputeChecklistFallbackUseWrittenReason,
      ],
    };
  }
}
