part of 'chat_screen.dart';

mixin _ChatScreenStateActions on ConsumerState<ChatScreen> {
  Future<void> _sendTextMessage(BuildContext context) async {
    final state = this as _ChatScreenState;
    final text = state.messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final pendingId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = _PendingChatMessage(
      tempId: pendingId,
      message: ChatMessage(
        id: pendingId,
        conversationId: widget.conversationId,
        senderProfileId: ref.read(currentAuthStateProvider).hasSession ? 'me' : null,
        type: ChatMessageType.text,
        textBody: text,
        attachmentPath: null,
        structuredPayload: null,
        isRead: false,
        readAt: null,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      ),
    );
    state.setState(() {
      state.pendingMessages.add(pendingMessage);
    });
    _scrollToBottom(force: true);

    final result = await ref.read(sendMessageProvider.notifier).sendTextMessage(
          conversationId: widget.conversationId,
          text: text,
        );
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      _removePendingMessage(pendingMessage.tempId);
      AppSnackbar.show(
        context: this.context,
        message: _chatTextSendFailureMessage(),
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final sentMessageId = result.valueOrNull;
    if (sentMessageId != null) {
      _confirmPendingMessage(pendingMessage.tempId, sentMessageId, messagesState: ref.read(conversationMessagesProvider(widget.conversationId)).messages);
    }
  }

  Future<void> _toggleVoiceRecording(BuildContext context) async {
    final state = this as _ChatScreenState;
    if (state.isRecordingVoice) {
      await _stopAndSendVoiceRecording(context);
      return;
    }
    await _startVoiceRecording(context);
  }

  Future<void> _startVoiceRecording(BuildContext context) async {
    final state = this as _ChatScreenState;
    final result = await state.voiceMessageService.startRecording(
          conversationId: widget.conversationId,
        );
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      AppSnackbar.show(
        context: this.context,
        message: _chatVoiceStartFailureMessage(),
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    state.setState(() {
      state.updateIsRecordingVoice(true);
      state.updateRecordingElapsedSeconds(0);
    });
    state.recordingTimer?.cancel();
    state.updateRecordingTimer(Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      state.setState(() {
        state.updateRecordingElapsedSeconds(state.recordingElapsedSeconds + 1);
      });
    }));
  }

  Future<void> _stopAndSendVoiceRecording(BuildContext context) async {
    final state = this as _ChatScreenState;
    state.recordingTimer?.cancel();
    state.setState(() {
      state.updateIsRecordingVoice(false);
    });
    final uploadResult = await state.voiceMessageService.stopAndUpload(
          conversationId: widget.conversationId,
        );
    if (!mounted) {
      return;
    }
    if (uploadResult.isFailure) {
      state.setState(() {
        state.updateRecordingElapsedSeconds(0);
      });
      AppSnackbar.show(
        context: this.context,
        message: _chatVoiceUploadFailureMessage(),
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final upload = uploadResult.valueOrNull!;
    final sendResult = await ref.read(sendMessageProvider.notifier).sendVoiceMessage(
          conversationId: widget.conversationId,
          messageId: upload.messageId,
          attachmentPath: upload.attachmentPath,
          structuredPayload: {
            'voice_duration_seconds': upload.durationSeconds,
          },
        );
    if (!mounted) {
      return;
    }
    state.setState(() {
      state.updateRecordingElapsedSeconds(0);
    });
    if (sendResult.isFailure) {
      AppSnackbar.show(
        context: this.context,
        message: _chatVoiceSendFailureMessage(),
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    _scrollToBottom(force: true);
  }

  Future<void> _showTextMessageActions(BuildContext context, String text) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l10n.chatCopyMessageAction),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.of(sheetContext).pop();
                  AppSnackbar.show(
                    context: context,
                    message: l10n.chatMessageCopiedToast,
                    variant: AppSnackbarVariant.success,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<_RenderedChatMessage> _buildRenderedMessages(List<ChatMessage> persistedMessages) {
    final state = this as _ChatScreenState;
    final persistedIds = persistedMessages.map((message) => message.id).toSet();
    final rendered = persistedMessages
        .map((message) => _RenderedChatMessage(message: message, isSending: false))
        .toList(growable: true)
      ..addAll(
        state.pendingMessages
            .where((pending) => !_pendingMessageResolved(pending, persistedMessages, persistedIds))
            .map(
              (pending) => _RenderedChatMessage(
                message: pending.message,
                isSending: pending.confirmedMessageId == null,
              ),
            ),
      )
      ..sort((a, b) => a.message.createdAt.compareTo(b.message.createdAt));

    // Compute grouping metadata
    for (var i = 0; i < rendered.length; i++) {
      final current = rendered[i];
      final prev = i > 0 ? rendered[i - 1] : null;

      // Check for day change - show date divider
      if (prev == null ||
          prev.message.createdAt.day != current.message.createdAt.day ||
          prev.message.createdAt.month != current.message.createdAt.month ||
          prev.message.createdAt.year != current.message.createdAt.year) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final messageDate = DateTime(
          current.message.createdAt.year,
          current.message.createdAt.month,
          current.message.createdAt.day,
        );
        
        String? dateLabel;
        final l10n = AppLocalizations.of(context);
        if (messageDate == today) {
          dateLabel = l10n.chatToday;
        } else {
          final yesterday = today.subtract(const Duration(days: 1));
          if (messageDate == yesterday) {
            dateLabel = l10n.chatYesterday;
          } else {
            dateLabel = '${current.message.createdAt.day}/${current.message.createdAt.month}/${current.message.createdAt.year}';
          }
        }

        rendered[i] = _RenderedChatMessage(
          message: current.message,
          isSending: current.isSending,
          showTimestamp: current.showTimestamp,
          showDateDivider: true,
          dateLabel: dateLabel,
          isFirstInGroup: current.isFirstInGroup,
          isLastInGroup: current.isLastInGroup,
        );
      }
    }

    for (var i = 0; i < rendered.length; i++) {
      final current = rendered[i];
      final prev = i > 0 ? rendered[i - 1] : null;
      final next = i < rendered.length - 1 ? rendered[i + 1] : null;
      final groupsWithPrev = prev != null && _canGroupChatMessages(prev.message, current.message);
      final groupsWithNext = next != null && _canGroupChatMessages(current.message, next.message);

      rendered[i] = _RenderedChatMessage(
        message: current.message,
        isSending: current.isSending,
        showDateDivider: current.showDateDivider,
        dateLabel: current.dateLabel,
        isFirstInGroup: !groupsWithPrev,
        isLastInGroup: !groupsWithNext,
        showTimestamp: !groupsWithNext || current.isSending,
      );
    }

    return rendered;
  }

  void _removePendingMessage(String tempId) {
    final state = this as _ChatScreenState;
    if (!mounted) {
      return;
    }
    state.setState(() {
      state.pendingMessages.removeWhere((pending) => pending.tempId == tempId);
    });
  }

  void _confirmPendingMessage(
    String tempId,
    String confirmedMessageId, {
    required List<ChatMessage> messagesState,
  }) {
    final state = this as _ChatScreenState;
    if (!mounted) {
      return;
    }

    if (messagesState.any((message) => message.id == confirmedMessageId)) {
      _removePendingMessage(tempId);
      return;
    }

    state.setState(() {
      final index = state.pendingMessages.indexWhere((pending) => pending.tempId == tempId);
      if (index == -1) {
        return;
      }
      state.pendingMessages[index] = state.pendingMessages[index].copyWithConfirmedId(confirmedMessageId);
    });
  }

  void _schedulePendingMessagePrune(List<ChatMessage> persistedMessages) {
    final state = this as _ChatScreenState;
    if (state.pendingMessages.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _pruneResolvedPendingMessages(persistedMessages);
    });
  }

  void _pruneResolvedPendingMessages(List<ChatMessage> persistedMessages) {
    final state = this as _ChatScreenState;
    if (state.pendingMessages.isEmpty) {
      return;
    }

    final persistedIds = persistedMessages.map((message) => message.id).toSet();
    final resolvedTempIds = state.pendingMessages
        .where((pending) => _pendingMessageResolved(pending, persistedMessages, persistedIds))
        .map((pending) => pending.tempId)
        .toList(growable: false);

    if (resolvedTempIds.isEmpty) {
      return;
    }

    state.setState(() {
      state.pendingMessages.removeWhere((pending) => resolvedTempIds.contains(pending.tempId));
    });
  }

  bool _pendingMessageResolved(
    _PendingChatMessage pending,
    List<ChatMessage> persistedMessages,
    Set<String> persistedIds,
  ) {
    final confirmedId = pending.confirmedMessageId;
    if (confirmedId != null && persistedIds.contains(confirmedId)) {
      return true;
    }

    final pendingText = (pending.message.textBody ?? '').trim();
    if (pendingText.isEmpty) {
      return false;
    }

    return persistedMessages.any((message) {
      if (!message.isFromCurrentUser) {
        return false;
      }
      if ((message.textBody ?? '').trim() != pendingText) {
        return false;
      }
      return message.createdAt.difference(pending.message.createdAt).inSeconds.abs() <= 120;
    });
  }

  Future<void> _approveBooking(BuildContext context, String bookingId, String loadId) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.chatApproveBookingDialogTitle),
            content: Text(l10n.chatApproveBookingDialogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancelAction),
              ),
              PrimaryButton(
                label: l10n.chatActionApprove,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    final result = await ref.read(loadDetailProvider(loadId).notifier).approveBookingRequest(bookingId);
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      await ref.read(inboxProvider.notifier).load();
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context: this.context,
        message: l10n.chatBookingApprovedSuccess,
        variant: AppSnackbarVariant.success,
      );
      return;
    }
    AppSnackbar.show(
      context: this.context,
      message: _chatApproveBookingFailureMessage(),
      variant: AppSnackbarVariant.error,
    );
  }

  Future<void> _rejectBooking(BuildContext context, String bookingId, String loadId) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.chatRejectBookingDialogTitle),
            content: Text(l10n.chatRejectBookingDialogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancelAction),
              ),
              DestructiveButton(
                label: l10n.chatActionReject,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    final result = await ref.read(loadDetailProvider(loadId).notifier).rejectBookingRequest(bookingId);
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      await ref.read(inboxProvider.notifier).load();
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        context: this.context,
        message: l10n.chatBookingRejectedSuccess,
        variant: AppSnackbarVariant.success,
      );
      return;
    }
    AppSnackbar.show(
      context: this.context,
      message: _chatRejectBookingFailureMessage(),
      variant: AppSnackbarVariant.error,
    );
  }

  String _chatTextSendFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatTextSendFailureMessage;
  }

  String _chatVoiceStartFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatVoiceStartFailureMessage;
  }

  String _chatVoiceUploadFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatVoiceUploadFailureMessage;
  }

  String _chatVoiceSendFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatVoiceSendFailureMessage;
  }

  String _chatApproveBookingFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatApproveBookingFailureMessage;
  }

  String _chatRejectBookingFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatRejectBookingFailureMessage;
  }

  String _chatBookingActionFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.chatBookingActionFailureMessage;
  }

  void _scrollToBottom({bool force = false, bool jump = false}) {
    final state = this as _ChatScreenState;

    void performScroll({bool allowRetry = true}) {
      if (!state.mounted || !state.scrollController.hasClients) {
        return;
      }

      final position = state.scrollController.position;
      final maxScroll = position.maxScrollExtent;
      final distance = maxScroll - position.pixels;
      const threshold = 160.0;

      if (!force && distance > threshold) {
        if (!state.showNewMessagePill && !state.showScrollToBottomFab) {
          state.setState(() {
            state.updateShowNewMessagePill(true);
            state.updateShowScrollToBottomFab(false);
          });
        }
        state.newMessagePillTimer?.cancel();
        return;
      }

      if (jump || distance <= 1) {
        state.scrollController.jumpTo(maxScroll);
        if (allowRetry && jump && maxScroll <= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => performScroll(allowRetry: false));
        }
      } else {
        state.scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }

      if (state.showNewMessagePill || state.showScrollToBottomFab) {
        state.setState(() {
          state.updateShowNewMessagePill(false);
          state.updateShowScrollToBottomFab(false);
        });
        state.newMessagePillTimer?.cancel();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => performScroll());
  }
}
