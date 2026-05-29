import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../shell/presentation/shell_components.dart';
import '../providers/support_compose_providers.dart';
import '../providers/support_providers.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  final ReportIssueContext contextData;

  const ReportIssueScreen({
    super.key,
    required this.contextData,
  });

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(reportIssueProvider(widget.contextData));
    _descriptionController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(reportIssueProvider(widget.contextData));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    _syncController(state);

    return DetailPageScaffold(
      title: l10n.reportIssueTitle,
      children: [
        HeroActionCard(
          title: l10n.reportIssueHeroTitle,
          subtitle: l10n.reportIssueHeroSubtitle,
          child: Text(
            l10n.reportIssueHeroMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (state.failure != null)
          WarningBlock(
            title: l10n.reportIssueSubmissionUnavailableTitle,
            message: l10n.reportIssueFailureMessage,
          ),
        DetailSectionCard(
          title: l10n.reportIssueLinkedContextTitle,
          children: [
            Text(l10n.reportIssueSourceLabel(widget.contextData.sourceLabel)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.contextData.relatedLoadId.trim().isEmpty
                  ? '${l10n.reportIssueRelatedLoadLabel}: ${l10n.reportIssueNotLinked}'
                  : l10n.reportIssueRelatedLoadLabel,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.contextData.relatedTripId.trim().isEmpty
                  ? '${l10n.reportIssueRelatedTripLabel}: ${l10n.reportIssueNotLinked}'
                  : l10n.reportIssueRelatedTripLabel,
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.reportIssueDetailsTitle,
          children: [
            AppDropdown<String>(
              label: l10n.reportIssueTypeLabel,
              value: state.category,
              items: reportIssueCategories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(_categoryLabel(l10n, category)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: ref.read(reportIssueProvider(widget.contextData).notifier).setCategory,
              helperText: _fieldErrorText(l10n, state.fieldErrors['category']),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _descriptionController,
              label: l10n.reportIssueWhatHappenedLabel,
              hintText: l10n.reportIssueWhatHappenedHint,
              maxLines: 6,
              errorText: _fieldErrorText(l10n, state.fieldErrors['message_body']),
              onChanged: ref.read(reportIssueProvider(widget.contextData).notifier).setDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.reportIssueHelpfulDetailsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _categoryGuidance(l10n, state.category),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _reportPrompts(l10n, state.category)
                  .map(
                    (prompt) => ActionChip(
                      label: Text(prompt),
                      onPressed: state.isSubmitting ? null : () => _appendDescriptionPrompt(prompt),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.reportIssueEvidenceOptionalTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.attachments.isEmpty
                  ? l10n.reportIssueNoEvidenceAttached
                  : l10n.reportIssueEvidenceAttached,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: l10n.reportIssueUseCameraAction,
                    onPressed: state.isSubmitting || profile == null
                        ? null
                        : () => _pickAndUploadEvidence(context, ImageSource.camera, profile.id),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlineButton(
                    label: l10n.reportIssueChoosePhotoAction,
                    onPressed: state.isSubmitting || profile == null
                        ? null
                        : () => _pickAndUploadEvidence(context, ImageSource.gallery, profile.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.reportIssueSubmitAction,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final result = await ref.read(reportIssueProvider(widget.contextData).notifier).submit();
                        if (!context.mounted) {
                          return;
                        }
                        if (result.isSuccess) {
                          await ref.read(supportTicketsProvider.notifier).load();
                          if (!context.mounted) {
                            return;
                          }
                          context.go(AppRoutes.supportPath, extra: result.valueOrNull);
                          AppSnackbar.show(
                            context: context,
                            message: l10n.reportIssueSubmittedSuccess,
                            variant: AppSnackbarVariant.success,
                          );
                        } else {
                          AppSnackbar.show(
                            context: context,
                            message: l10n.reportIssueSubmitFailureMessage,
                            variant: AppSnackbarVariant.error,
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncController(ReportIssueState state) {
    if (_descriptionController.text != state.description) {
      _descriptionController.value = _descriptionController.value.copyWith(
        text: state.description,
        selection: TextSelection.collapsed(offset: state.description.length),
      );
    }
  }

  void _appendDescriptionPrompt(String prompt) {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      return;
    }
    final currentText = _descriptionController.text.trimRight();
    if (currentText.contains(normalizedPrompt)) {
      _descriptionController.selection = TextSelection.collapsed(offset: _descriptionController.text.length);
      return;
    }
    final nextText = currentText.isEmpty ? '$normalizedPrompt ' : '$currentText\n$normalizedPrompt ';
    ref.read(reportIssueProvider(widget.contextData).notifier).setDescription(nextText);
  }

  Future<void> _pickAndUploadEvidence(
    BuildContext context,
    ImageSource source,
    String profileId,
  ) async {
    // Attachments can be added after ticket is created via reply
    AppSnackbar.show(
      context: context,
      message: 'Please add attachments after creating the ticket',
      variant: AppSnackbarVariant.info,
    );
  }

  String? _fieldErrorText(AppLocalizations l10n, String? code) {
    return switch (code) {
      reportIssueInvalidCategoryCode => l10n.reportIssueInvalidCategoryMessage,
      reportIssueDescriptionTooShortCode => l10n.reportIssueDescriptionTooShortMessage,
      reportIssueAttachmentRequiredCode => l10n.reportIssueAttachmentRequiredMessage,
      _ => code,
    };
  }

  List<String> _reportPrompts(AppLocalizations l10n, String category) {
    return [
      ...switch (category.trim().toLowerCase()) {
        'non_payment' => <String>[
            l10n.supplierRaiseDisputePromptAmountStillUnpaid,
            l10n.supplierRaiseDisputePromptPaymentDueDateOrMilestone,
            l10n.supplierRaiseDisputePromptOtherPaymentProofNotAttached,
          ],
        'fake_payout_proof' => <String>[
            l10n.supplierRaiseDisputePromptWhyPayoutProofLooksFake,
            l10n.supplierRaiseDisputePromptWhatPaymentStatusShouldBe,
            l10n.supplierRaiseDisputePromptOtherProofOrChatContextNotAttached,
          ],
        'abusive_behavior' => <String>[
            l10n.supplierRaiseDisputePromptWhatHappenedDuringIncident,
            l10n.supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred,
            l10n.supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded,
          ],
        _ => <String>[
            l10n.supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred,
            l10n.supplierRaiseDisputePromptWhatMisleadingClaimWasMade,
            l10n.supplierRaiseDisputePromptOtherProofOrChatContextNotAttached,
          ],
      },
    ].whereType<String>().where((prompt) => prompt.trim().isNotEmpty).toList(growable: false);
  }

  String _categoryLabel(AppLocalizations l10n, String category) {
    return switch (category.trim().toLowerCase()) {
      'spam_or_scam' => l10n.reportIssueCategorySpamOrScam,
      'abusive_behavior' => l10n.reportIssueCategoryAbusiveBehavior,
      'fake_payout_proof' => l10n.reportIssueCategoryFakePayoutProof,
      'non_payment' => l10n.reportIssueCategoryNonPayment,
      _ => category.trim().replaceAll('_', ' '),
    };
  }

  String _categoryGuidance(AppLocalizations l10n, String category) {
    return switch (category.trim().toLowerCase()) {
      'spam_or_scam' => l10n.reportIssueCategoryGuidanceSpamOrScam,
      'abusive_behavior' => l10n.reportIssueCategoryGuidanceAbusiveBehavior,
      'fake_payout_proof' => l10n.reportIssueCategoryGuidanceFakePayoutProof,
      'non_payment' => l10n.reportIssueCategoryGuidanceNonPayment,
      _ => l10n.reportIssueCategoryGuidanceSpamOrScam,
    };
  }
}
