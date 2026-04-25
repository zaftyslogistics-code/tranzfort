part of 'chat_screen.dart';

class _ChatContextBanner extends StatelessWidget {
  final ConversationPreview conversation;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool canShowBookingActions;
  final bool isProcessingBookingAction;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ChatContextBanner({
    required this.conversation,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.canShowBookingActions,
    required this.isProcessingBookingAction,
    required this.onApprove,
    required this.onReject,
  });

  String _localizedChatStatus(AppLocalizations l10n, String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'active':
        return l10n.commonActiveLabel;
      case 'approved':
        return l10n.chatBookingStatusApproved;
      default:
        return l10n.commonUnknownLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: DetailSectionCard(
        title: l10n.chatLoadContextTitle,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(conversation.routeLabel, style: Theme.of(context).textTheme.titleSmall),
              ),
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                tooltip: isExpanded ? l10n.chatCollapseLoadContextTooltip : l10n.chatExpandLoadContextTooltip,
              ),
            ],
          ),
          if (isExpanded) ...[
            if ((conversation.loadMaterial ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.chatMaterialLabel(conversation.loadMaterial!)),
            ],
            if (conversation.loadPriceAmount != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.chatPriceLabel('₹${conversation.loadPriceAmount!.toStringAsFixed(0)}')),
            ],
            if ((conversation.pickupDate?.toIso8601String() ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.chatPickupLabel('${conversation.pickupDate!.day}/${conversation.pickupDate!.month}/${conversation.pickupDate!.year}')),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if ((conversation.loadStatusLabel ?? '').trim().isNotEmpty)
                  StatusChip(label: _localizedChatStatus(l10n, conversation.loadStatusLabel!)),
                if ((conversation.bookingStatusLabel ?? '').trim().isNotEmpty)
                  StatusChip(label: _localizedChatStatus(l10n, conversation.bookingStatusLabel!)),
              ],
            ),
            if (canShowBookingActions) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.chatActionApprove,
                      isLoading: isProcessingBookingAction,
                      onPressed: isProcessingBookingAction ? null : onApprove,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlineButton(
                      label: l10n.chatActionReject,
                      isLoading: isProcessingBookingAction,
                      onPressed: isProcessingBookingAction ? null : onReject,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String? _truckerChatGatingMessage(
  AppLocalizations l10n,
  AsyncValue<TruckerProfile?>? truckerProfileAsync,
  TruckerProfile? truckerProfile,
) {
  if (truckerProfileAsync == null) {
    return null;
  }
  if (truckerProfileAsync.isLoading || truckerAsyncFailure(truckerProfileAsync) != null) {
    return null;
  }
  if (truckerProfile == null || !truckerProfile.isVerified) {
    return l10n.truckerLoadDetailVerificationRequiredMessage;
  }
  if (!truckerProfile.hasApprovedTruck) {
    return l10n.truckerLoadDetailTruckApprovalRequiredMessage;
  }
  return null;
}

String _truckerChatActionLabel(AppLocalizations l10n, TruckerProfile? truckerProfile) {
  if (truckerProfile == null || !truckerProfile.isVerified) {
    return l10n.commonOpenVerificationAction;
  }
  return l10n.truckerDashboardOpenFleetAction;
}

void _openTruckerChatReadiness(BuildContext context, TruckerProfile? truckerProfile) {
  final destination = truckerProfile == null || !truckerProfile.isVerified
      ? AppRoutes.truckerVerificationPath
      : AppRoutes.fleetPath;
  context.go(destination);
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isRecordingVoice;
  final int recordingElapsedSeconds;
  final VoidCallback? onSend;
  final VoidCallback? onVoiceAction;

  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.isRecordingVoice,
    required this.recordingElapsedSeconds,
    required this.onSend,
    required this.onVoiceAction,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final hasText = controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        elevation: 8,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller,
                  hintText: l10n.chatTypeMessageHint,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (!hasText)
                SizedBox(
                  width: 64,
                  child: IconButton(
                    onPressed: onVoiceAction,
                    icon: Icon(isRecordingVoice ? Icons.stop_circle_outlined : Icons.mic_none),
                    tooltip: isRecordingVoice ? l10n.chatStopRecordingTooltip : l10n.chatVoiceRecordingTooltip,
                  ),
                )
              else
                SizedBox(
                  width: 96,
                  child: PrimaryButton(
                    label: l10n.chatSendAction,
                    isLoading: isSending,
                    onPressed: onSend,
                  ),
                ),
              if (!hasText && isRecordingVoice) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _formatDuration(recordingElapsedSeconds),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
