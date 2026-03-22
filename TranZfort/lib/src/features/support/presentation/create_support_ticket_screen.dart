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
import '../data/support_attachment_upload_service.dart';
import '../providers/support_compose_providers.dart';
import '../providers/support_providers.dart';

class CreateSupportTicketScreen extends ConsumerStatefulWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  ConsumerState<CreateSupportTicketScreen> createState() => _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends ConsumerState<CreateSupportTicketScreen> {
  late final TextEditingController _loadIdController;
  late final TextEditingController _tripIdController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createSupportTicketProvider);
    _loadIdController = TextEditingController(text: state.relatedLoadId);
    _tripIdController = TextEditingController(text: state.relatedTripId);
    _descriptionController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _loadIdController.dispose();
    _tripIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createSupportTicketProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    _syncControllers(state);

    return DetailPageScaffold(
      title: l10n.supportCreateTicketScreenTitle,
      children: [
        HeroActionCard(
          title: l10n.supportCreateTicketHeroTitle,
          subtitle: l10n.supportCreateTicketHeroSubtitle,
          child: Text(
            l10n.supportCreateTicketHeroMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (state.failure != null)
          WarningBlock(
            title: l10n.supportCreateTicketFailureTitle,
            message: l10n.supportCreateTicketFailureMessage,
          ),
        DetailSectionCard(
          title: l10n.supportCreateTicketDetailsTitle,
          children: [
            AppDropdown<String>(
              label: l10n.supportComposeCategoryLabel,
              value: state.category,
              items: supportTicketCategories
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(_label(l10n, category)),
                      ))
                  .toList(growable: false),
              onChanged: ref.read(createSupportTicketProvider.notifier).setCategory,
              helperText: state.fieldErrors['category'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _loadIdController,
              label: l10n.supportCreateTicketRelatedLoadIdLabel,
              hintText: l10n.supportCreateTicketRelatedLoadIdHint,
              onChanged: ref.read(createSupportTicketProvider.notifier).setRelatedLoadId,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _tripIdController,
              label: l10n.supportCreateTicketRelatedTripIdLabel,
              hintText: l10n.supportCreateTicketRelatedTripIdHint,
              onChanged: ref.read(createSupportTicketProvider.notifier).setRelatedTripId,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _descriptionController,
              label: l10n.supportCreateTicketDescriptionLabel,
              hintText: l10n.supportCreateTicketDescriptionHint,
              maxLines: 6,
              errorText: state.fieldErrors['message_body'],
              onChanged: ref.read(createSupportTicketProvider.notifier).setDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.supportComposeAttachmentOptionalTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.attachmentPath.trim().isEmpty
                  ? l10n.supportComposeNoAttachment
                  : l10n.supportComposeAttachmentAttached,
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
                        : () => _pickAndUploadAttachment(context, ImageSource.camera, profile.id),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlineButton(
                    label: l10n.reportIssueChoosePhotoAction,
                    onPressed: state.isSubmitting || profile == null
                        ? null
                        : () => _pickAndUploadAttachment(context, ImageSource.gallery, profile.id),
                  ),
                ),
              ],
            ),
            if (state.attachmentPath.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: l10n.supportComposeRemoveAttachmentAction,
                  onPressed: state.isSubmitting
                      ? null
                      : () => ref.read(createSupportTicketProvider.notifier).setAttachmentPath(''),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.supportCreateTicketSubmitAction,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        final result = await ref.read(createSupportTicketProvider.notifier).submit();
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
                            message: l10n.supportCreateTicketSubmittedSuccess,
                            variant: AppSnackbarVariant.success,
                          );
                        } else {
                          AppSnackbar.show(
                            context: context,
                            message: l10n.supportCreateTicketSubmitFailureMessage,
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

  void _syncControllers(CreateSupportTicketState state) {
    if (_loadIdController.text != state.relatedLoadId) {
      _loadIdController.value = _loadIdController.value.copyWith(
        text: state.relatedLoadId,
        selection: TextSelection.collapsed(offset: state.relatedLoadId.length),
      );
    }
    if (_tripIdController.text != state.relatedTripId) {
      _tripIdController.value = _tripIdController.value.copyWith(
        text: state.relatedTripId,
        selection: TextSelection.collapsed(offset: state.relatedTripId.length),
      );
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.value = _descriptionController.value.copyWith(
        text: state.description,
        selection: TextSelection.collapsed(offset: state.description.length),
      );
    }
  }

  Future<void> _pickAndUploadAttachment(
    BuildContext context,
    ImageSource source,
    String profileId,
  ) async {
    final result = await ref.read(supportAttachmentUploadServiceProvider).pickCompressAndUploadAttachment(
          profileId: profileId,
          source: source,
        );
    if (!context.mounted) {
      return;
    }
    if (result.isSuccess) {
      final path = result.valueOrNull;
      if (path != null && path.trim().isNotEmpty) {
        ref.read(createSupportTicketProvider.notifier).setAttachmentPath(path);
        AppSnackbar.show(
          context: context,
          message: AppLocalizations.of(context).supportComposeAttachmentAddedSuccess,
          variant: AppSnackbarVariant.success,
        );
      }
      return;
    }
    AppSnackbar.show(
      context: context,
      message: AppLocalizations.of(context).supportComposeAttachmentFailureMessage,
      variant: AppSnackbarVariant.error,
    );
  }

  String _label(AppLocalizations l10n, String value) {
    return switch (value.trim().toLowerCase()) {
      'general' => l10n.supportComposeCategoryGeneral,
      'account' => l10n.supportComposeCategoryAccount,
      'load' => l10n.supportComposeCategoryLoad,
      'trip' => l10n.supportComposeCategoryTrip,
      'payment' => l10n.supportComposeCategoryPayment,
      'technical' => l10n.supportComposeCategoryTechnical,
      'other' => l10n.supportComposeCategoryOther,
      _ => l10n.supportComposeCategoryOther,
    };
  }
}
