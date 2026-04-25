part of 'chat_screen.dart';

class _ChatMessagesBody extends StatelessWidget {
  final ScrollController scrollController;
  final List<_RenderedChatMessage> renderedMessages;
  final bool isLoading;
  final AppFailure? failure;
  final String? loadId;

  const _ChatMessagesBody({
    required this.scrollController,
    required this.renderedMessages,
    required this.isLoading,
    required this.failure,
    required this.loadId,
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

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemBuilder: (context, index) => _ChatMessageBubble(
        message: renderedMessages[index].message,
        isSending: renderedMessages[index].isSending,
        loadId: loadId,
      ),
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemCount: renderedMessages.length,
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSending;
  final String? loadId;

  const _ChatMessageBubble({
    required this.message,
    this.isSending = false,
    this.loadId,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (message.type == ChatMessageType.system) {
      return Center(
        child: Text(
          message.textBody ?? l10n.commonSystemUpdateLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final alignment = message.isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final background = message.isFromCurrentUser ? AppColors.infoBg : Theme.of(context).colorScheme.surfaceContainerLow;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: _ChatMessageContent(message: message, loadId: loadId),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isSending ? l10n.chatSendingLabel : _formatTimestamp(message.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RenderedChatMessage {
  final ChatMessage message;
  final bool isSending;

  const _RenderedChatMessage({
    required this.message,
    required this.isSending,
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
