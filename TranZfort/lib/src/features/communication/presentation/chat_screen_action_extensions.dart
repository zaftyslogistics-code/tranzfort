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
    _scrollToBottom();

    final result = await ref.read(sendMessageProvider.notifier).sendTextMessage(
          conversationId: widget.conversationId,
          text: text,
        );
    _removePendingMessage(pendingMessage.tempId);
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      AppSnackbar.show(
        context: this.context,
        message: _chatTextSendFailureMessage(),
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    final authState = ref.read(currentAuthStateProvider);
    final inboxState = ref.read(inboxProvider);
    final conversation = inboxState.conversations.where((item) => item.id == widget.conversationId).isEmpty
        ? null
        : inboxState.conversations.firstWhere((item) => item.id == widget.conversationId);
    final messageCount = ref.read(conversationMessagesProvider(widget.conversationId)).messages.length + 1;
    if (conversation != null) {
      final targetUserId = authState.role == AppUserRole.supplier ? conversation.truckerId : conversation.supplierId;
      final targetUserName = authState.role == AppUserRole.supplier ? conversation.truckerName : conversation.supplierName;
      ReviewTriggerHelper.maybeShowChatReviewPrompt(
        this.context,
        ref,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        conversationId: widget.conversationId,
        messageCount: messageCount,
      );
    }
    _scrollToBottom();
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
    final authState = ref.read(currentAuthStateProvider);
    final inboxState = ref.read(inboxProvider);
    final conversation = inboxState.conversations.where((item) => item.id == widget.conversationId).isEmpty
        ? null
        : inboxState.conversations.firstWhere((item) => item.id == widget.conversationId);
    final messageCount = ref.read(conversationMessagesProvider(widget.conversationId)).messages.length + 1;
    if (conversation != null && messageCount >= 3) {
      final targetUserId = authState.role == AppUserRole.supplier ? conversation.truckerId : conversation.supplierId;
      final targetUserName = authState.role == AppUserRole.supplier ? conversation.truckerName : conversation.supplierName;
      ReviewTriggerHelper.maybeShowChatReviewPrompt(
        this.context,
        ref,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        conversationId: widget.conversationId,
        messageCount: messageCount,
      );
    }
    _scrollToBottom();
  }

  List<_RenderedChatMessage> _buildRenderedMessages(List<ChatMessage> persistedMessages) {
    final state = this as _ChatScreenState;
    final rendered = persistedMessages
        .map((message) => _RenderedChatMessage(message: message, isSending: false))
        .toList(growable: true)
      ..addAll(
        state.pendingMessages.map(
          (pending) => _RenderedChatMessage(message: pending.message, isSending: true),
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
        );
      }
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
              PrimaryButton(
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

  void _scrollToBottom({bool force = false}) {
    final state = this as _ChatScreenState;
    if (!state.scrollController.hasClients) {
      return;
    }
    
    final position = state.scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    final threshold = 100.0;
    
    // If scrolled up more than threshold and not forcing, show pill instead of scrolling
    if (!force && (maxScroll - currentScroll) > threshold) {
      setState(() {
        state.updateShowNewMessagePill(true);
      });
      // Auto-dismiss after 3 seconds
      state.newMessagePillTimer?.cancel();
      state.updateNewMessagePillTimer(Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            state.updateShowNewMessagePill(false);
          });
        }
      }));
      return;
    }
    
    // Scroll to bottom
    state.scrollController.animateTo(
      maxScroll,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    
    // Hide pill if visible
    if (state.showNewMessagePill) {
      setState(() {
        state.updateShowNewMessagePill(false);
      });
      state.newMessagePillTimer?.cancel();
    }
  }
}
