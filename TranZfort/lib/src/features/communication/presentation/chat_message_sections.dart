part of 'chat_screen.dart';

class _ChatMessagesBody extends StatelessWidget {
  final ScrollController scrollController;
  final List<_RenderedChatMessage> renderedMessages;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasMoreOlderMessages;
  final AppFailure? failure;
  final String? loadId;
  final VoidCallback? onLoadOlder;

  const _ChatMessagesBody({
    required this.scrollController,
    required this.renderedMessages,
    required this.isLoading,
    this.isLoadingOlder = false,
    this.hasMoreOlderMessages = false,
    required this.failure,
    required this.loadId,
    this.onLoadOlder,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingShimmer(height: 72, itemCount: 5),
      );
    }

    if (failure != null && renderedMessages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: WarningBlock(
          title: l10n.chatMessagesLoadFailureTitle,
          message: l10n.chatMessagesLoadFailureMessage,
        ),
      );
    }

    if (renderedMessages.isEmpty) {
      return EmptyStateView(
        icon: Icons.chat_bubble_outline,
        title: l10n.chatNoMessagesTitle,
        subtitle: l10n.chatNoMessagesSubtitle,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemCount: renderedMessages.length + (hasMoreOlderMessages || isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMoreOlderMessages || isLoadingOlder) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: Center(
                child: isLoadingOlder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: onLoadOlder,
                        child: Text(
                          'Load older messages',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
              ),
            );
          }
          index -= 1;
        }
        final rendered = renderedMessages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rendered.showDateDivider && rendered.dateLabel != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    rendered.dateLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _ChatMessageBubble(
              message: rendered.message,
              isSending: rendered.isSending,
              showTimestamp: rendered.showTimestamp,
              loadId: loadId,
            ),
            if (index < renderedMessages.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSending;
  final bool showTimestamp;
  final String? loadId;

  const _ChatMessageBubble({
    required this.message,
    this.isSending = false,
    this.showTimestamp = true,
    this.loadId,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (message.type == ChatMessageType.system) {
      return Center(
        child: Text(
          message.textBody ?? l10n.commonSystemUpdateLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    final alignment = message.isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final background = message.isFromCurrentUser ? AppColors.primaryChipBg : AppColors.subtleSurface;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        AnimatedOpacity(
          opacity: isSending ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.only(
              left: message.isFromCurrentUser ? AppSpacing.md : 0,
              right: message.isFromCurrentUser ? 0 : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.inkBorder.withValues(alpha: message.isFromCurrentUser ? 0.15 : 0.10),
                width: 1,
              ),
            ),
            child: _ChatMessageContent(message: message, loadId: loadId),
          ),
        ),
        if (showTimestamp) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSending ? l10n.chatSendingLabel : _formatTimestamp(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (message.isFromCurrentUser) ...[
                const SizedBox(width: AppSpacing.xs),
                if (isSending)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? AppColors.primary : AppColors.textMuted,
                  ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _RenderedChatMessage {
  final ChatMessage message;
  final bool isSending;
  final bool showTimestamp;
  final bool showDateDivider;
  final String? dateLabel;

  const _RenderedChatMessage({
    required this.message,
    required this.isSending,
    this.showTimestamp = true,
    this.showDateDivider = false,
    this.dateLabel,
  });
}

class _PendingChatMessage {
  final String tempId;
  final ChatMessage message;

  const _PendingChatMessage({
    required this.tempId,
    required this.message,
  });
}
