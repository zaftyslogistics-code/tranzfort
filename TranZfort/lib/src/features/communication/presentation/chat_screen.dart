import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/status_components.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';
import '../../reviews/utils/review_trigger_helper.dart';
import '../../supplier/providers/load_detail_provider.dart';
import '../../support/providers/support_compose_providers.dart';
import '../../trucker/data/diesel_price_repository.dart';
import '../../trucker/data/trip_costing_service.dart';
import '../../trucker/data/trucker_profile_repository.dart';
import '../../trucker/providers/trucker_providers.dart';
import '../data/chat_repository.dart';
import '../data/voice_playback_service.dart';
import '../data/voice_message_service.dart';
import '../providers/chat_providers.dart';

part 'chat_screen_action_extensions.dart';
part 'chat_screen_helpers.dart';
part 'chat_screen_sections.dart';
part 'chat_message_sections.dart';
part 'chat_message_voice_sections.dart';
part 'chat_message_media_sections.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with _ChatScreenStateActions {
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  late final VoiceMessageService _voiceMessageService;
  int _lastRenderedMessageCount = 0;
  bool _didMarkRead = false;
  bool _isBannerExpanded = true;
  bool _isRecordingVoice = false;
  int _recordingElapsedSeconds = 0;
  bool _showNewMessagePill = false;
  bool _showScrollToBottomFab = false;
  final List<_PendingChatMessage> _pendingMessages = <_PendingChatMessage>[];
  Timer? _recordingTimer;
  Timer? _newMessagePillTimer;

  TextEditingController get messageController => _messageController;

  ScrollController get scrollController => _scrollController;

  VoiceMessageService get voiceMessageService => _voiceMessageService;

  bool get isRecordingVoice => _isRecordingVoice;

  void updateIsRecordingVoice(bool value) => _isRecordingVoice = value;

  int get recordingElapsedSeconds => _recordingElapsedSeconds;

  void updateRecordingElapsedSeconds(int value) => _recordingElapsedSeconds = value;

  List<_PendingChatMessage> get pendingMessages => _pendingMessages;

  Timer? get recordingTimer => _recordingTimer;

  void updateRecordingTimer(Timer? value) => _recordingTimer = value;

  bool get showNewMessagePill => _showNewMessagePill;

  void updateShowNewMessagePill(bool value) => _showNewMessagePill = value;

  bool get showScrollToBottomFab => _showScrollToBottomFab;

  void updateShowScrollToBottomFab(bool value) => _showScrollToBottomFab = value;

  Timer? get newMessagePillTimer => _newMessagePillTimer;

  void updateNewMessagePillTimer(Timer? value) => _newMessagePillTimer = value;

  @override
  void initState() {
    super.initState();
    _voiceMessageService = ref.read(voiceMessageServiceProvider);
    _messageController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleChatScroll);
  }

  void _handleChatScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final distance = _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    if (distance <= 160) {
      if (_showNewMessagePill || _showScrollToBottomFab) {
        setState(() {
          _showNewMessagePill = false;
          _showScrollToBottomFab = false;
        });
        _newMessagePillTimer?.cancel();
      }
      return;
    }
    if (!_showNewMessagePill && !_showScrollToBottomFab) {
      setState(() {
        _showScrollToBottomFab = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleChatScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _newMessagePillTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    ref.listen<SendMessageState>(sendMessageProvider, (previous, next) {
      final previousId = previous?.lastSentMessageId;
      final nextId = next.lastSentMessageId;
      if (nextId != null && nextId != previousId) {
        _messageController.clear();
        _scrollToBottom(force: true);
      }
      if (previous?.failure != next.failure && next.failure != null && mounted) {
        AppSnackbar.show(
          context: context,
          message: _chatTextSendFailureMessage(),
          variant: AppSnackbarVariant.error,
        );
      }
    });

    final authState = ref.watch(currentAuthStateProvider);
    final inboxState = ref.watch(inboxProvider);
    final messagesState = ref.watch(conversationMessagesProvider(widget.conversationId));
    final sendState = ref.watch(sendMessageProvider);
    final conversation = inboxState.conversations.where((item) => item.id == widget.conversationId).isEmpty
        ? null
        : inboxState.conversations.firstWhere((item) => item.id == widget.conversationId);
    final isSupplier = authState.role == AppUserRole.supplier;
    final truckerProfileAsync = isSupplier ? null : ref.watch(truckerProfileProvider);
    final truckerProfile = truckerProfileAsync?.valueOrNull;
    final truckerChatGatingMessage = _truckerChatGatingMessage(l10n, truckerProfileAsync, truckerProfile);
    final truckerChatBlocked = truckerChatGatingMessage != null;
    final loadDetailState = conversation != null && isSupplier ? ref.watch(loadDetailProvider(conversation.loadId)) : null;

    final renderedMessages = _buildRenderedMessages(messagesState.messages);
    if (_lastRenderedMessageCount != renderedMessages.length) {
      _lastRenderedMessageCount = renderedMessages.length;
      final fromSelf = renderedMessages.lastOrNull?.message.isFromCurrentUser ?? false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(force: fromSelf));
    }
    if (!_didMarkRead &&
        messagesState.hasResolvedInitialLoad &&
        !messagesState.isLoading &&
        messagesState.failure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(conversationMessagesProvider(widget.conversationId).notifier).markConversationRead();
        _didMarkRead = true;
      });
    }

    final otherPartyName = _otherPartyName(conversation, authState.role, l10n.chatTitleFallback);
    final callUri = _callUri(_otherPartyMobile(conversation, authState.role));
    final ttsSummary = [
      otherPartyName,
      if ((conversation?.routeLabel ?? '').trim().isNotEmpty) conversation!.routeLabel,
      l10n.shellMessagesTitle,
    ].join('. ');
    final canShowBookingActions = isSupplier &&
        conversation != null &&
        (conversation.bookingRequestId ?? '').trim().isNotEmpty &&
        (conversation.bookingStatusLabel ?? '').trim().toLowerCase() == 'submitted';
    final isProcessingBookingAction = (loadDetailState?.approvingBookingId ?? '') == conversation?.bookingRequestId ||
        (loadDetailState?.rejectingBookingId ?? '') == conversation?.bookingRequestId;

    return Scaffold(
      appBar: AppBar(
        leading: _otherPartyId(conversation, authState.role) != null
            ? InkWell(
                onTap: () => context.push(AppRoutes.publicProfileLocation(_otherPartyId(conversation, authState.role)!)),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: UserAvatar(
                    avatarUrl: _otherPartyAvatarUrl(conversation, authState.role),
                    userId: _otherPartyId(conversation, authState.role),
                    initials: otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : '?',
                    radius: 18,
                    fallbackColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherPartyName),
            if ((conversation?.routeLabel ?? '').trim().isNotEmpty)
              Text(
                conversation!.routeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          const TtsActionButton(),
          const LanguageToggleAction(),
          if (callUri != null)
            IconButton(
              tooltip: l10n.commonCallAction,
              onPressed: truckerChatBlocked
                  ? null
                  : () async {
                await launchUrl(callUri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.call_outlined),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mark_read') {
                await ref.read(conversationMessagesProvider(widget.conversationId).notifier).markConversationRead();
              }
              if (value == 'refresh') {
                await ref.read(inboxProvider.notifier).load();
                await ref.read(conversationMessagesProvider(widget.conversationId).notifier).load();
              }
              if (value == 'report_issue' && conversation != null && context.mounted) {
                context.go(
                  AppRoutes.reportIssuePath,
                  extra: ReportIssueContext(
                    initialCategory: 'spam_or_scam',
                    relatedLoadId: conversation.loadId,
                    relatedTripId: conversation.tripId ?? '',
                    sourceLabel: l10n.chatReportSourceLabel(conversation.routeLabel),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'mark_read',
                child: Text(l10n.chatMenuMarkConversationRead),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Text(l10n.chatMenuRefreshThread),
              ),
              PopupMenuItem<String>(
                value: 'report_issue',
                child: Text(l10n.commonReportSpamOrAbuseAction),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if ((!inboxState.hasResolvedInitialLoad || inboxState.isLoading) &&
                          conversation == null) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: LoadingShimmer(height: 88, itemCount: 4),
                        );
                      }
                      if (conversation == null) {
                        return EmptyStateView(
                          icon: Icons.chat_bubble_outline,
                          title: l10n.chatConversationUnavailableTitle,
                          subtitle: l10n.chatConversationUnavailableSubtitle,
                          actionLabel: l10n.chatBackToInboxAction,
                          onAction: () => context.go(AppRoutes.messagesPath),
                        );
                      }

                      return Column(
                        children: [
                          _ChatContextBanner(
                            conversation: conversation,
                            isExpanded: _isBannerExpanded,
                            onToggleExpanded: () {
                              setState(() {
                                _isBannerExpanded = !_isBannerExpanded;
                              });
                            },
                            canShowBookingActions: canShowBookingActions,
                            isProcessingBookingAction: isProcessingBookingAction,
                            onApprove: canShowBookingActions
                                ? () => _approveBooking(context, conversation.bookingRequestId!, conversation.loadId)
                                : null,
                            onReject: canShowBookingActions
                                ? () => _rejectBooking(context, conversation.bookingRequestId!, conversation.loadId)
                                : null,
                          ),
                          if (loadDetailState?.actionFailure != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                              child: WarningBlock(
                                title: l10n.chatBookingActionUnavailableTitle,
                                message: _chatBookingActionFailureMessage(),
                              ),
                            ),
                          Expanded(
                            child: _ChatMessagesBody(
                              scrollController: _scrollController,
                              renderedMessages: renderedMessages,
                              isLoading: messagesState.isLoading,
                              hasResolvedInitialLoad: messagesState.hasResolvedInitialLoad,
                              isLoadingOlder: messagesState.isLoadingOlder,
                              hasMoreOlderMessages: messagesState.hasMoreOlderMessages,
                              failure: messagesState.failure,
                              loadId: conversation.loadId,
                              onLoadOlder: () async {
                                await ref.read(conversationMessagesProvider(widget.conversationId).notifier).loadOlderMessages();
                              },
                              onRetry: () async {
                                await ref.read(conversationMessagesProvider(widget.conversationId).notifier).load();
                              },
                              onQuickReply: truckerChatBlocked
                                  ? null
                                  : (text) {
                                      _messageController.text = text;
                                      _messageController.selection = TextSelection.collapsed(offset: text.length);
                                    },
                              onLongPressText: truckerChatBlocked
                                  ? null
                                  : (text) => _showTextMessageActions(context, text),
                            ),
                          ),
                          if (truckerChatBlocked)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                              child: WarningBlock(
                                title: l10n.verificationChatAndCallGatingBadge,
                                message: truckerChatGatingMessage,
                                action: OutlineButton(
                                  label: _truckerChatActionLabel(l10n, truckerProfile),
                                  onPressed: () => _openTruckerChatReadiness(context, truckerProfile),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _messageController,
                  builder: (context, textValue, _) {
                    final hasText = textValue.text.trim().isNotEmpty;
                    return _ChatComposer(
                      controller: _messageController,
                      isSending: sendState.isSending,
                      isRecordingVoice: _isRecordingVoice,
                      recordingElapsedSeconds: _recordingElapsedSeconds,
                      onSend: truckerChatBlocked || !hasText
                          ? null
                          : () => _sendTextMessage(context),
                      onVoiceAction: truckerChatBlocked || hasText || sendState.isSending
                          ? null
                          : () => _toggleVoiceRecording(context),
                      onVoiceLongPressStart: truckerChatBlocked || hasText || sendState.isSending
                          ? null
                          : () => _startVoiceRecording(context),
                      onVoiceLongPressEnd: truckerChatBlocked || sendState.isSending
                          ? null
                          : () => _stopAndSendVoiceRecording(context),
                    );
                  },
                ),
              ],
            ),
            TtsScreenSummaryEffect(
              summary: ttsSummary,
              screenKey: '${AppRoutes.chatPath}/${widget.conversationId}',
            ),
            if (_showNewMessagePill)
              Positioned(
                bottom: AppSpacing.xxxl + AppSpacing.lg,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _scrollToBottom(force: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        boxShadow: AppShadows.elevation2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.chatNewMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showScrollToBottomFab && !_showNewMessagePill)
              Positioned(
                bottom: AppSpacing.xxxl + AppSpacing.lg,
                right: AppSpacing.lg,
                child: Material(
                  color: AppColors.cardSurface,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _scrollToBottom(force: true),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
