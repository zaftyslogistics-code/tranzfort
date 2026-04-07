import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../data/support_attachment_upload_service.dart';
import '../providers/support_compose_providers.dart';
import '../providers/support_providers.dart';

class SupportReplyComposer extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportReplyComposer({
    super.key,
    required this.ticketId,
  });

  @override
  ConsumerState<SupportReplyComposer> createState() => _SupportReplyComposerState();
}

class _SupportReplyComposerState extends ConsumerState<SupportReplyComposer> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(supportReplyProvider(widget.ticketId));
    _messageController = TextEditingController(text: state.messageBody);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(supportReplyProvider(widget.ticketId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    _syncController(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.failure != null) ...[
          WarningBlock(
            title: l10n.supportReplyFailureTitle,
            message: l10n.supportReplyFailureMessage,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          controller: _messageController,
          label: l10n.supportReplyLabel,
          hintText: l10n.supportReplyHint,
          maxLines: 4,
          errorText: _fieldErrorText(l10n, state.fieldErrors['message_body']),
          onChanged: ref.read(supportReplyProvider(widget.ticketId).notifier).setMessageBody,
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
                  : () => ref.read(supportReplyProvider(widget.ticketId).notifier).setAttachmentPath(''),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: l10n.supportReplySendAction,
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting
                ? null
                : () async {
                    final result = await ref.read(supportReplyProvider(widget.ticketId).notifier).submit();
                    if (!context.mounted) {
                      return;
                    }
                    if (result.isSuccess) {
                      ref.invalidate(supportTicketDetailProvider(widget.ticketId));
                      await ref.read(supportTicketsProvider.notifier).load();
                      if (!context.mounted) {
                        return;
                      }
                    }
                    AppSnackbar.show(
                      context: context,
                      message: result.isSuccess
                          ? l10n.supportReplySentSuccess
                          : l10n.supportReplySubmitFailureMessage,
                      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                    );
                  },
          ),
        ),
      ],
    );
  }

  void _syncController(SupportReplyState state) {
    if (_messageController.text != state.messageBody) {
      _messageController.value = _messageController.value.copyWith(
        text: state.messageBody,
        selection: TextSelection.collapsed(offset: state.messageBody.length),
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
          pathSegment: 'support_ticket/${widget.ticketId}',
        );
    if (!context.mounted) {
      return;
    }
    if (result.isSuccess) {
      final path = result.valueOrNull;
      if (path != null && path.trim().isNotEmpty) {
        ref.read(supportReplyProvider(widget.ticketId).notifier).setAttachmentPath(path);
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

  String? _fieldErrorText(AppLocalizations l10n, String? code) {
    return switch (code) {
      supportReplyMessageTooShortCode => l10n.supportReplyMessageTooShortMessage,
      _ => code,
    };
  }
}
