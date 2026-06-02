import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import '../../core/services/contextual_tts_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/tts_localizations.dart';
import 'tts_listen_icon.dart';

/// Per-card play/listen control (manual tap only). Uses [TtsPlaybackController.listenToggle].
class TtsCardSpeakerButton extends ConsumerWidget {
  final String message;
  final String? playbackKey;
  final String? tooltip;
  final bool onDarkSurface;

  const TtsCardSpeakerButton({
    super.key,
    required this.message,
    this.playbackKey,
    this.tooltip,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = lookupTtsLocalizations(Localizations.localeOf(context));
    final normalized = message.trim();
    final playback = ref.read(ttsPlaybackControllerProvider);
    final normalizedKey = (playbackKey ?? '').trim();
    final effectivePlaybackKey =
        normalizedKey.isEmpty ? normalized : normalizedKey;
    final isPlaying = playback.isPlayingMessage(
      normalized,
      playbackKey: effectivePlaybackKey,
    );
    final resolvedTooltip = tooltip ??
        (isPlaying ? l10n.commonStopListening : ttsL10n.ttsListenToLoadHint);

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: resolvedTooltip,
      onPressed: normalized.isEmpty
          ? null
          : () => speak(
                context,
                ref,
                message,
                playbackKey: effectivePlaybackKey,
              ),
      icon: TtsListenIcon(
        message: normalized,
        playbackKey: effectivePlaybackKey,
        onDarkSurface: onDarkSurface,
      ),
    );
  }

  static Future<ContextualTtsOutcome> speak(
    BuildContext context,
    WidgetRef ref,
    String message,
    {String? playbackKey}
  ) async {
    if (!context.mounted) {
      return ContextualTtsOutcome.skipped;
    }

    final outcome = await ref.read(ttsPlaybackControllerProvider).listenToggle(
          context: context,
          message: message,
          playbackKey: playbackKey,
        );

    if (!context.mounted) {
      return outcome;
    }
    if (outcome == ContextualTtsOutcome.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonVoiceUnavailable)),
      );
    }
    return outcome;
  }
}
