part of 'chat_screen.dart';

const double _kChatEdgePadding = 8;
const double _kChatBubbleScreenWidthRatio = 0.76;
const double _kChatBubbleMaxWidth = 420;
const double _kChatBubbleCorner = 18;
const double _kChatBubbleTailCorner = 6;
const double _kChatGroupGap = 4;
const double _kChatSenderGap = 10;
const double _kChatListBottomPadding = 16;

bool _canGroupChatMessages(ChatMessage current, ChatMessage other) {
  if (current.type == ChatMessageType.system || other.type == ChatMessageType.system) {
    return false;
  }
  return current.isFromCurrentUser == other.isFromCurrentUser;
}

BorderRadius _chatBubbleBorderRadius({
  required bool isFromCurrentUser,
  required bool isFirstInGroup,
  required bool isLastInGroup,
}) {
  final topLeft = isFromCurrentUser
      ? _kChatBubbleCorner
      : (isFirstInGroup ? _kChatBubbleCorner : _kChatBubbleTailCorner);
  final topRight = isFromCurrentUser
      ? (isFirstInGroup ? _kChatBubbleCorner : _kChatBubbleTailCorner)
      : _kChatBubbleCorner;
  final bottomLeft = isFromCurrentUser
      ? _kChatBubbleCorner
      : (isLastInGroup ? _kChatBubbleTailCorner : _kChatBubbleCorner);
  final bottomRight = isFromCurrentUser
      ? (isLastInGroup ? _kChatBubbleTailCorner : _kChatBubbleCorner)
      : _kChatBubbleCorner;

  return BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomLeft: Radius.circular(bottomLeft),
    bottomRight: Radius.circular(bottomRight),
  );
}

class _ChatLaneScope extends StatelessWidget {
  final Widget child;

  const _ChatLaneScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kChatEdgePadding),
      child: child,
    );
  }
}

double _chatBubbleMaxWidth(BuildContext context) {
  final contentWidth = MediaQuery.sizeOf(context).width - (_kChatEdgePadding * 2);
  return (contentWidth * _kChatBubbleScreenWidthRatio).clamp(0.0, _kChatBubbleMaxWidth);
}

class _ChatMessagesBody extends StatelessWidget {
  final ScrollController scrollController;
  final List<_RenderedChatMessage> renderedMessages;
  final bool isLoading;
  final bool hasResolvedInitialLoad;
  final bool isLoadingOlder;
  final bool hasMoreOlderMessages;
  final AppFailure? failure;
  final String? loadId;
  final VoidCallback? onLoadOlder;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onQuickReply;
  final ValueChanged<String>? onLongPressText;

  const _ChatMessagesBody({
    required this.scrollController,
    required this.renderedMessages,
    required this.isLoading,
    required this.hasResolvedInitialLoad,
    this.isLoadingOlder = false,
    this.hasMoreOlderMessages = false,
    required this.failure,
    required this.loadId,
    this.onLoadOlder,
    this.onRetry,
    this.onQuickReply,
    this.onLongPressText,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!hasResolvedInitialLoad || isLoading) {
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
          action: onRetry == null
              ? null
              : OutlineButton(
                  label: l10n.chatMessagesRetryAction,
                  onPressed: onRetry,
                ),
        ),
      );
    }

    if (renderedMessages.isEmpty) {
      return Center(
        child: _ChatLaneScope(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyStateView(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.chatNoMessagesTitle,
                  subtitle: l10n.chatNoMessagesSubtitle,
                ),
                if (onQuickReply != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ChatQuickReplyChip(
                        label: l10n.chatQuickReplyAvailable,
                        onTap: () => onQuickReply!(l10n.chatQuickReplyAvailable),
                      ),
                      _ChatQuickReplyChip(
                        label: l10n.chatQuickReplyCallMe,
                        onTap: () => onQuickReply!(l10n.chatQuickReplyCallMe),
                      ),
                      _ChatQuickReplyChip(
                        label: l10n.chatQuickReplyShareTruck,
                        onTap: () => onQuickReply!(l10n.chatQuickReplyShareTruck),
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

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(_kChatEdgePadding, 0, _kChatEdgePadding, _kChatListBottomPadding),
      itemCount: renderedMessages.length + (hasMoreOlderMessages || isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMoreOlderMessages || isLoadingOlder) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
              child: _ChatLaneScope(
                child: Center(
                  child: isLoadingOlder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Material(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          child: InkWell(
                            onTap: onLoadOlder,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                l10n.chatLoadOlderMessages,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            );
          }
          index -= 1;
        }
        final rendered = renderedMessages[index];
        final bottomGap = index < renderedMessages.length - 1
            ? (rendered.isLastInGroup ? _kChatSenderGap : _kChatGroupGap)
            : 0.0;

        return Column(
          children: [
            if (rendered.showDateDivider && rendered.dateLabel != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                child: _ChatLaneScope(
                  child: Center(
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
                ),
              ),
            ],
            _ChatMessageBubble(
              message: rendered.message,
              isSending: rendered.isSending,
              showTimestamp: rendered.showTimestamp,
              isFirstInGroup: rendered.isFirstInGroup,
              isLastInGroup: rendered.isLastInGroup,
              loadId: loadId,
              onLongPressText: rendered.message.type == ChatMessageType.text &&
                      (rendered.message.textBody ?? '').trim().isNotEmpty &&
                      onLongPressText != null
                  ? () => onLongPressText!(rendered.message.textBody!.trim())
                  : null,
            ),
            if (bottomGap > 0) SizedBox(height: bottomGap),
          ],
        );
      },
    );
  }
}

class _ChatQuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChatQuickReplyChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSending;
  final bool showTimestamp;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String? loadId;
  final VoidCallback? onLongPressText;

  const _ChatMessageBubble({
    required this.message,
    this.isSending = false,
    this.showTimestamp = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.loadId,
    this.onLongPressText,
  });

  bool get _usesCompactTextPadding =>
      message.type == ChatMessageType.text && (message.textBody ?? '').trim().isNotEmpty;

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

    final background = message.isFromCurrentUser ? AppColors.primaryChipBg : AppColors.subtleSurface;
    final borderRadius = _chatBubbleBorderRadius(
      isFromCurrentUser: message.isFromCurrentUser,
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
    );

    return Align(
      alignment: message.isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: isSending ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _chatBubbleMaxWidth(context)),
              child: _buildBubbleContent(background, borderRadius),
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
      ),
    );
  }

  Widget _buildBubbleContent(Color background, BorderRadius borderRadius) {
    Widget bubble = Container(
      padding: _usesCompactTextPadding
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.inkBorder.withValues(alpha: message.isFromCurrentUser ? 0.15 : 0.10),
          width: 1,
        ),
      ),
      child: _ChatMessageContent(message: message, loadId: loadId),
    );

    if (onLongPressText != null) {
      bubble = GestureDetector(onLongPress: onLongPressText, child: bubble);
    }

    return bubble;
  }
}

class _RenderedChatMessage {
  final ChatMessage message;
  final bool isSending;
  final bool showTimestamp;
  final bool showDateDivider;
  final String? dateLabel;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _RenderedChatMessage({
    required this.message,
    required this.isSending,
    this.showTimestamp = true,
    this.showDateDivider = false,
    this.dateLabel,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
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
