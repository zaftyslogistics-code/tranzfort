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
    
    // Determine which status to show: booking status if present, else load status
    final statusToShow = (conversation.bookingStatusLabel ?? '').trim().isNotEmpty
        ? conversation.bookingStatusLabel
        : conversation.loadStatusLabel;
    final statusLabel = statusToShow != null ? _localizedChatStatus(l10n, statusToShow) : null;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Material(
        elevation: 1,
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.inkBorder, width: 1),
          ),
          child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.primaryOnDark),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      conversation.routeLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.inkTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statusLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: StatusChip(
                        label: statusLabel,
                        palette: const StatusPalette(
                          foreground: AppColors.primaryOnDark,
                          background: AppColors.primaryChipBgDark,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: onToggleExpanded,
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.inkTextSecondary),
                    tooltip: isExpanded ? l10n.chatCollapseLoadContextTooltip : l10n.chatExpandLoadContextTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if ((conversation.loadMaterial ?? '').trim().isNotEmpty)
                      Text(
                        conversation.loadMaterial!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
                      ),
                    if (conversation.loadPriceAmount != null)
                      Text(
                        '₹${conversation.loadPriceAmount!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
                      ),
                    if ((conversation.pickupDate?.toIso8601String() ?? '').isNotEmpty)
                      Text(
                        '${conversation.pickupDate!.day}/${conversation.pickupDate!.month}/${conversation.pickupDate!.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
                      ),
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
          ),
        ),
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

class _ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isRecordingVoice;
  final int recordingElapsedSeconds;
  final VoidCallback? onSend;
  final VoidCallback? onVoiceAction;
  final VoidCallback? onVoiceLongPressStart;
  final VoidCallback? onVoiceLongPressEnd;

  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.isRecordingVoice,
    required this.recordingElapsedSeconds,
    required this.onSend,
    required this.onVoiceAction,
    this.onVoiceLongPressStart,
    this.onVoiceLongPressEnd,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  double _sendButtonScale = 1.0;

  void _scaleDown() {
    setState(() {
      _sendButtonScale = 0.9;
    });
  }

  void _scaleUp() {
    setState(() {
      _sendButtonScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          boxShadow: AppShadows.elevation1,
          border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.8))),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: TextField(
                      controller: widget.controller,
                      enabled: !widget.isSending,
                      decoration: InputDecoration(
                        hintText: l10n.chatTypeMessageHint,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: !hasText
                    ? SizedBox(
                        key: const ValueKey('mic'),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onLongPressStart: widget.onVoiceLongPressStart == null
                              ? null
                              : (_) => widget.onVoiceLongPressStart!(),
                          onLongPressEnd: widget.onVoiceLongPressEnd == null
                              ? null
                              : (_) => widget.onVoiceLongPressEnd!(),
                          child: IconButton(
                            onPressed: widget.onVoiceAction,
                            icon: Icon(widget.isRecordingVoice ? Icons.stop_circle_outlined : Icons.mic_none),
                            tooltip: widget.isRecordingVoice ? l10n.chatStopRecordingTooltip : l10n.chatVoiceRecordingTooltip,
                          ),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('send'),
                        onTapDown: (_) => _scaleDown(),
                        onTapUp: (_) => _scaleUp(),
                        onTapCancel: () => _scaleUp(),
                        child: AnimatedScale(
                          scale: _sendButtonScale,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: AppColors.heroCta,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: widget.isSending ? null : widget.onSend,
                              icon: const Icon(Icons.send, color: AppColors.textOnPrimary),
                              tooltip: l10n.chatSendAction,
                            ),
                          ),
                        ),
                      ),
              ),
              if (!hasText && widget.isRecordingVoice) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDuration(widget.recordingElapsedSeconds),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
