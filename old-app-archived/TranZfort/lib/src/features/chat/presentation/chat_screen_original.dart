import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/maps_config.dart';
import '../../../core/error/result.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/utils/ist_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startVoiceRecording() async {
    final l10n = AppLocalizations.of(context);
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatMicrophonePermissionRequired)),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/voice_${widget.conversationId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    if (!mounted) return;

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopAndSendVoice() async {
    final l10n = AppLocalizations.of(context);
    final path = await _recorder.stop();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
    });

    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatVoiceRecordingEmpty)),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatCouldNotReadRecordedFile)),
      );
      return;
    }

    final success = await ref
        .read(chatSendProvider.notifier)
        .sendVoice(
          conversationId: widget.conversationId,
          audioFile: file,
          durationSeconds: 0,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.chatVoiceMessageSent : l10n.chatVoiceMessageSendFailed,
        ),
      ),
    );
  }

  Future<void> _toggleVoiceMessagePlayback(Map<String, dynamic> msg) async {
    final l10n = AppLocalizations.of(context);
    final messageId = (msg['id'] ?? '').toString();
    if (messageId.isEmpty) return;

    if (_isPlayingVoice && _playingVoiceMessageId == messageId) {
      await _audioPlayer.stop();
      if (!mounted) return;
      setState(() {
        _isPlayingVoice = false;
        _playingVoiceMessageId = null;
      });
      return;
    }

    final voicePath = (msg['voice_url'] ?? '').toString();
    if (voicePath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatVoiceFileUnavailable)));
      return;
    }

    String playbackUrl = voicePath;
    if (!voicePath.startsWith('http://') && !voicePath.startsWith('https://')) {
      final signedResult = await ref
          .read(chatStorageServiceProvider)
          .createSignedUrl(bucketName: 'voice-messages', filePath: voicePath);

      switch (signedResult) {
        case Success(data: final url):
          playbackUrl = url;
        case Failure():
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatUnablePlayVoiceMessage)),
          );
          return;
      }
    }

    await _audioPlayer.stop();
    await _audioPlayer.setUrl(playbackUrl);
    await _audioPlayer.play();

    if (!mounted) return;
    setState(() {
      _isPlayingVoice = true;
      _playingVoiceMessageId = messageId;
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed ||
          state.playing == false) {
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceMessageId = null;
        });
      }
    });
  }

  Future<void> _sendMapCard() async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(chatSendProvider.notifier)
        .sendMapCard(widget.conversationId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.chatLocationShared : l10n.chatCouldNotShareLocation,
        ),
      ),
    );
  }

  Future<void> _sendBookingActionCard() async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(chatSendProvider.notifier)
        .sendBookingAction(widget.conversationId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.chatBookingActionShared
              : l10n.chatCouldNotShareBookingAction,
        ),
      ),
    );
  }

  Future<void> _bookFromConversation() async {
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(chatSendProvider.notifier)
        .bookFromConversation(widget.conversationId);
    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatBookingRequestSentFromChat)),
        );
        await ref.read(ttsServiceProvider).speak(l10n.loadBookTtsSuccess);
      case Failure(debugMessage: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? l10n.chatCouldNotBookFromChat)),
        );
        await ref.read(ttsServiceProvider).speak(l10n.loadBookTtsFailure);
    }
  }

  Future<void> _openMapFromPayload(Map<String, dynamic> payload) async {
    final parsed = CoordinateUtils.parseLatLng(payload['lat'], payload['lng']);
    if (parsed == null) return;
    final lat = parsed.lat;
    final lng = parsed.lng;

    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(navUri)) {
      await launchUrl(navUri);
      return;
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showAttachMenu() async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l10n.chatAttachShareLocation),
                onTap: () => Navigator.of(context).pop('map_card'),
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(l10n.chatAttachShareBookingAction),
                onTap: () => Navigator.of(context).pop('booking_action'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'map_card':
        await _sendMapCard();
      case 'booking_action':
        await _sendBookingActionCard();
    }
  }

  Widget _buildMessageBody(Map<String, dynamic> msg, bool isMe) {
    final l10n = AppLocalizations.of(context);
    final type = (msg['message_type'] ?? 'text').toString();
    final content = (msg['text_content'] ?? '').toString();
    final payload = (msg['payload'] as Map<String, dynamic>?) ?? const {};

    if (type == 'voice') {
      final messageId = (msg['id'] ?? '').toString();
      final isPlaying = _isPlayingVoice && _playingVoiceMessageId == messageId;
      final durationSeconds =
          (msg['voice_duration_seconds'] as num?)?.toInt() ?? 0;
      return _VoiceMessageCard(
        isPlaying: isPlaying,
        durationSeconds: durationSeconds,
        onPressed: () => _toggleVoiceMessagePlayback(msg),
      );
    }

    if (type == 'map_card') {
      final parsed = CoordinateUtils.parseLatLng(payload['lat'], payload['lng']);
      final lat = parsed?.lat;
      final lng = parsed?.lng;
      return _MapMessageCard(
        title: content.isNotEmpty ? content : l10n.chatMapCardTitleLocationShared,
        lat: lat,
        lng: lng,
        subtitle: lat != null && lng != null
            ? l10n.chatMapLatLng(
                lat.toStringAsFixed(4),
                lng.toStringAsFixed(4),
              )
            : l10n.chatMapCoordinatesUnavailable,
        onOpenMap: lat != null && lng != null
            ? () => _openMapFromPayload(payload)
            : null,
        mapsConfig: MapsConfig.fromEnvironment(),
      );
    }

    if (type == 'truck_card' && payload['action'] == 'book_load') {
      final label = (payload['label'] ?? l10n.chatBookThisLoad).toString();
      return _BookingActionCard(
        description: content.isNotEmpty
            ? content
            : l10n.chatBookingActionDescription,
        ctaLabel: label,
        onPressed: _bookFromConversation,
      );
    }

    return Text(
      content,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
    );
  }

  Future<void> _sendText() async {
    final l10n = AppLocalizations.of(context);
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI updates are handled by the stream mostly,
    // but clearing the input immediately feels responsive.
    _messageController.clear();

    final success = await ref
        .read(chatSendProvider.notifier)
        .sendText(widget.conversationId, text);

    if (success && mounted) {
      _scrollToBottom();
    } else if (mounted) {
      // Restore if failed (rudimentary retry UX)
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatFailedSendMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversationId),
    );
    final conversationAsync = ref.watch(
      conversationDetailProvider(widget.conversationId),
    );
    final sendState = ref.watch(chatSendProvider);
    final userId = ref.watch(authSessionProvider).value?.session?.user.id;

    final conversationTitle = conversationAsync.value == null
        ? l10n.chatTitle
        : '${conversationAsync.value?['load']?['origin_city'] ?? '-'} → ${conversationAsync.value?['load']?['dest_city'] ?? '-'}';

    return Scaffold(
      appBar: AppBar(title: Text(conversationTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
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
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == userId;
                      final type = msg['message_type'] ?? 'text';
                      final content = msg['text_content'] ?? '';
                      final createdAt = DateTime.tryParse(
                        (msg['created_at'] ?? '').toString(),
                      );
                      final isRead = msg['is_read'] == true;

                      if (type == 'system') {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutralLight.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                            child: Text(
                              content,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.neutral),
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                              topLeft: const Radius.circular(
                                AppSpacing.cardRadius,
                              ),
                              topRight: const Radius.circular(
                                AppSpacing.cardRadius,
                              ),
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
                              _buildMessageBody(msg, isMe),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (createdAt != null)
                                    Text(
                                      IstTime.formatTime(createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.neutral,
                                            fontSize: 10,
                                          ),
                                    ),
                                  if (isMe) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      isRead ? Icons.done_all : Icons.check,
                                      size: AppSpacing.iconXs,
                                      color: isRead
                                          ? AppColors.brandTealLight
                                          : AppColors.neutral,
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.chatFailedLoadMessages)),
              ),
            ),
            Container(
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: AppColors.neutral,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    tooltip: l10n.chatAttach,
                    onPressed: _showAttachMenu,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: l10n.chatTypeMessageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.composerRadius,
                          ),
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
                      onSubmitted: (_) => _sendText(),
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
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  hasText
                                      ? Icons.send
                                      : (_isRecording ? Icons.stop : Icons.mic),
                                  color: Colors.white,
                                ),
                          onPressed: hasText
                              ? _sendText
                              : (_isRecording
                                    ? _stopAndSendVoice
                                    : _startVoiceRecording),
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
          ],
        ),
      ),
    );
  }
}

class _VoiceMessageCard extends StatelessWidget {
  final bool isPlaying;
  final int durationSeconds;
  final VoidCallback onPressed;

  const _VoiceMessageCard({
    required this.isPlaying,
    required this.durationSeconds,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationLabel =
        durationSeconds > 0 ? '${durationSeconds}s' : l10n.chatVoiceLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoiceWaveformBars(isPlaying: isPlaying),
          const SizedBox(width: AppSpacing.xs),
          Text(durationLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          OutlineButton(
            label: isPlaying ? l10n.chatStopAction : l10n.chatPlayAction,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _VoiceWaveformBars extends StatefulWidget {
  final bool isPlaying;

  const _VoiceWaveformBars({required this.isPlaying});

  @override
  State<_VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<_VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceWaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final phase = (_controller.value * math.pi * 2) + (index * 0.9);
              final active = widget.isPlaying;
              final height = active ? (4 + (math.sin(phase).abs() * 8)) : 4.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MapMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;
  final VoidCallback? onOpenMap;
  final MapsConfig mapsConfig;

  const _MapMessageCard({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lng,
    this.onOpenMap,
    required this.mapsConfig,
  });

  String? _buildStaticMapUrl() {
    if (lat == null || lng == null) {
      return null;
    }
    if (mapsConfig.hasApiKey) {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=13&size=600x260&maptype=roadmap&markers=color:red%7C$lat,$lng&key=${mapsConfig.apiKey}';
    }
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=11&size=600x260&markers=$lat,$lng,red-pushpin';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lat != null && lng != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: Image.network(
                  _buildStaticMapUrl()!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                        size: AppSpacing.iconLg,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (onOpenMap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlineButton(label: l10n.chatOpenMap, onPressed: onOpenMap),
          ],
        ],
      ),
    );
  }
}

class _BookingActionCard extends StatelessWidget {
  final String description;
  final String ctaLabel;
  final VoidCallback onPressed;

  const _BookingActionCard({
    required this.description,
    required this.ctaLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(label: ctaLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}
