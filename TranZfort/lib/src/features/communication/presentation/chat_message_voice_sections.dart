part of 'chat_screen.dart';

class _VoiceMessageContent extends StatelessWidget {
  final ChatMessage message;

  const _VoiceMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return _PlayableVoiceMessageContent(message: message);
  }
}

class _PlayableVoiceMessageContent extends ConsumerStatefulWidget {
  final ChatMessage message;

  const _PlayableVoiceMessageContent({required this.message});

  @override
  ConsumerState<_PlayableVoiceMessageContent> createState() => _PlayableVoiceMessageContentState();
}

class _PlayableVoiceMessageContentState extends ConsumerState<_PlayableVoiceMessageContent> {
  late final VoicePlaybackController _controller;
  String? _signedUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(voicePlaybackControllerFactoryProvider)();
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final durationSeconds = _payloadInt(widget.message.structuredPayload, const ['voice_duration_seconds', 'duration_seconds']);
    return ValueListenableBuilder<VoicePlaybackSnapshot>(
      valueListenable: _controller.snapshot,
      builder: (context, snapshot, _) {
        final effectiveDuration = snapshot.duration ??
            (durationSeconds == null ? null : Duration(seconds: durationSeconds));
        final totalMs = effectiveDuration?.inMilliseconds ?? 0;
        final progress = totalMs <= 0
            ? 0.0
            : (snapshot.position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.message.attachmentPath == null || widget.message.attachmentPath!.trim().isEmpty
                      ? null
                      : () => _togglePlayback(),
                  icon: Icon(
                    snapshot.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: snapshot.isPlaying ? l10n.chatPauseVoiceMessageTooltip : l10n.chatPlayVoiceMessageTooltip,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.chatVoiceMessageLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (effectiveDuration != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(_formatDuration(effectiveDuration.inSeconds), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if ((_errorMessage ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  children: List<Widget>.generate(
                    16,
                    (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 15 ? 0 : 2),
                        height: 8 + (index % 5) * 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Row(
                    children: List<Widget>.generate(
                      16,
                      (index) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index == 15 ? 0 : 2),
                          height: 8 + (index % 5) * 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (snapshot.isLoading) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        );
      },
    );
  }

  Future<void> _togglePlayback() async {
    final attachmentPath = widget.message.attachmentPath;
    if (attachmentPath == null || attachmentPath.trim().isEmpty) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _errorMessage = null;
    });
    try {
      _signedUrl ??= await ref.read(voicePlaybackServiceProvider).createSignedUrl(attachmentPath);
      if (!mounted) {
        return;
      }
      final signedUrl = _signedUrl;
      if (signedUrl == null || signedUrl.trim().isEmpty) {
        setState(() {
          _errorMessage = l10n.chatVoicePlaybackUnavailable;
        });
        return;
      }
      await _controller.togglePlayback(signedUrl);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = l10n.chatVoicePlaybackFailed;
      });
    }
  }
}
