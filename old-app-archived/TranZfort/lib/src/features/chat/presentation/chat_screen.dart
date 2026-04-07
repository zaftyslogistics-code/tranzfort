import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../core/error/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/config/maps_config.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/tts_service.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/index.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlayingVoice = false;
  String? _playingVoiceMessageId;

  late ChatController _chatController;
  late VoiceRecordingController _voiceController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      ref: ref,
      context: context,
      setState: (fn) => setState(fn),
      messageController: _messageController,
      scrollController: _scrollController,
      conversationId: widget.conversationId,
    );
    _voiceController = VoiceRecordingController(
      setState: (fn) => setState(fn),
      recorder: _recorder,
      audioPlayer: _audioPlayer,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    await _chatController.sendMessage();
  }

  Future<void> _sendLocation() async {
    await _chatController.sendLocation();
  }

  Future<void> _bookFromConversation() async {
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(chatSendProvider.notifier)
        .bookFromConversation(widget.conversationId);
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatBookingRequestSentFromChat)),
        );
        await ref.read(ttsServiceProvider).speak(l10n.loadBookTtsSuccess);
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatCouldNotBookFromChat)),
        );
        await ref.read(ttsServiceProvider).speak(l10n.loadBookTtsFailure);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final duration = await _getAudioDuration(path);
        await _chatController.sendVoiceNote(path, duration);
      }
    } else {
      await _recorder.start(const RecordConfig(), path: 'temp_voice.m4a');
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<int> _getAudioDuration(String path) async {
    try {
      final duration = await _audioPlayer.setFilePath(path);
      return duration?.inSeconds ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _playVoiceMessage(String url, String messageId) async {
    if (_isPlayingVoice && _playingVoiceMessageId == messageId) {
      await _voiceController.stopVoice(
        setPlayingMessageId: (id) => setState(() => _playingVoiceMessageId = id),
        setIsPlaying: (playing) => setState(() => _isPlayingVoice = playing),
      );
    } else {
      await _voiceController.playVoice(
        url,
        messageId,
        setPlayingMessageId: (id) => setState(() => _playingVoiceMessageId = id),
        setIsPlaying: (playing) => setState(() => _isPlayingVoice = playing),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final conversationAsync = ref.watch(
      conversationDetailProvider(widget.conversationId),
    );
    final sendState = ref.watch(chatSendProvider);
    final currentUser = ref.watch(authSessionProvider).value?.session?.user.id;
    final mapsConfig = ref.watch(mapsConfigProvider);
    final load = conversationAsync.value?['load'] as Map<String, dynamic>?;
    final conversationTitle = load == null
        ? l10n.chatTitle
        : '${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}';
    final conversationSubtitle = (load?['material'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversationTitle),
            if (conversationSubtitle.isNotEmpty)
              Text(
                conversationSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(l10n.chatFailedLoadMessages),
              ),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return Center(child: Text(l10n.chatNoMessagesYet));
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    AppSpacing.screenPaddingV,
                    AppSpacing.screenPaddingH,
                    AppSpacing.screenPaddingV,
                  ),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == currentUser;
                    final createdAt = DateTime.tryParse(
                      (message['created_at'] ?? '').toString(),
                    );
                    final isRead = message['is_read'] == true;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.chatSender
                              : AppColors.chatReceiver,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppSpacing.cardRadius),
                            topRight: const Radius.circular(AppSpacing.cardRadius),
                            bottomLeft: Radius.circular(
                              isMe ? AppSpacing.cardRadius : AppSpacing.xs,
                            ),
                            bottomRight: Radius.circular(
                              isMe ? AppSpacing.xs : AppSpacing.cardRadius,
                            ),
                          ),
                          border: isMe
                              ? null
                              : Border.all(color: AppColors.neutralLight),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            _buildMessageContent(
                              message,
                              mapsConfig,
                              isMe: isMe,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (createdAt != null)
                                  Text(
                                    TimeOfDay.fromDateTime(
                                      createdAt.toLocal(),
                                    ).format(context),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textTertiary,
                                          fontSize: 10,
                                        ),
                                  ),
                                if (isMe) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    isRead ? Icons.done_all : Icons.check,
                                    size: AppSpacing.iconXs,
                                    color: isRead
                                        ? AppColors.brandTeal
                                        : AppColors.textTertiary,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(l10n, sendState),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    Map<String, dynamic> message,
    MapsConfig mapsConfig, {
    required bool isMe,
  }) {
    final l10n = AppLocalizations.of(context);
    final type = (message['message_type'] ?? 'text').toString();
    final content = (message['text_content'] ?? '').toString();
    final payload =
        (message['payload'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    switch (type) {
      case 'voice':
        final duration = (message['voice_duration_seconds'] as num?)?.toInt() ?? 0;
        return VoiceMessageCard(
          isPlaying: _isPlayingVoice &&
              _playingVoiceMessageId == message['id'],
          durationSeconds: duration,
          onPressed: () => _playVoiceMessage(
            (message['voice_url'] ?? '').toString(),
            message['id'],
          ),
        );

      case 'map_card':
        final coords = CoordinateUtils.parseLatLng(
          payload['lat'],
          payload['lng'],
        );
        if (coords != null) {
          return MapMessageCard(
            title: content.isNotEmpty
                ? content
                : l10n.chatMapCardTitleLocationShared,
            subtitle: l10n.chatMapLatLng(
              coords.lat.toStringAsFixed(4),
              coords.lng.toStringAsFixed(4),
            ),
            lat: coords.lat,
            lng: coords.lng,
            onOpenMap: () => _chatController.openMap(coords.lat, coords.lng),
            mapsConfig: mapsConfig,
          );
        }
        return Text(
          l10n.chatMapCoordinatesUnavailable,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isMe ? AppColors.onSurface : AppColors.textSecondary,
          ),
        );

      case 'truck_card':
        return BookingActionCard(
          description: content.isNotEmpty
              ? content
              : l10n.chatBookingActionDescription,
          ctaLabel: (payload['label'] ?? l10n.chatBookThisLoad).toString(),
          onPressed: _bookFromConversation,
        );

      default:
        return Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
          ),
        );
    }
  }

  Widget _buildMessageInput(AppLocalizations l10n, AsyncValue<void> sendState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.neutralLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: sendState.isLoading ? null : _sendLocation,
              icon: const Icon(Icons.location_on_outlined),
              tooltip: l10n.chatAttachShareLocation,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: l10n.chatTypeMessageHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.composerRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return CircleAvatar(
                  radius: AppSpacing.minTouchTarget / 2,
                  backgroundColor: _isRecording
                      ? AppColors.error
                      : AppColors.primary,
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: sendState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            hasText
                                ? Icons.send
                                : (_isRecording ? Icons.stop : Icons.mic),
                            color: Colors.white,
                          ),
                    onPressed: sendState.isLoading
                        ? null
                        : (hasText ? _sendMessage : _toggleRecording),
                    tooltip: hasText
                        ? l10n.chatSendMessageTooltip
                        : (_isRecording
                              ? l10n.chatStopRecordingTooltip
                              : l10n.chatStartRecordingTooltip),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
