import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import '../../core/services/contextual_tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'tts_listen_icon.dart';

/// App-bar control: tap to play/stop the current screen summary; long-press to turn voice off.
///
/// Does not auto-play on navigation ([TtsScreenSummaryEffect.autoPlay] is false).
class TtsActionButton extends ConsumerWidget {
  const TtsActionButton({super.key});
  static const _screenPlaybackKey = 'tts:screen-summary';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(ttsSpeakingProvider);
    ref.watch(ttsLastUtteranceProvider);
    ref.watch(ttsMutedProvider);

    final playback = ref.read(ttsPlaybackControllerProvider);
    final isMuted = ref.read(ttsMutedProvider);
    final summary = playback.screenSummaryFor(context);
    final isPlayingScreen = summary != null &&
        playback.isPlayingMessage(
          summary,
          playbackKey: _screenPlaybackKey,
        );

    final tooltip = isMuted
        ? l10n.commonTurnVoiceOn
        : isPlayingScreen
            ? l10n.commonStopListening
            : l10n.commonHearSummary;

    return IconButton(
      tooltip: tooltip,
      onPressed: () => _onTap(context, ref, summary),
      onLongPress: () => _onLongPress(ref),
      icon: summary == null
          ? Icon(
              isMuted ? Icons.volume_off_rounded : Icons.play_circle_outline,
              size: 26,
              color: _iconColor(context, isMuted: isMuted),
            )
          : TtsListenIcon(
              message: summary,
              playbackKey: _screenPlaybackKey,
              size: 26,
              color: _iconColor(context, isMuted: isMuted),
              onDarkSurface: false,
            ),
    );
  }

  Color _iconColor(BuildContext context, {required bool isMuted}) {
    final base = IconTheme.of(context).color ?? AppColors.primary;
    return isMuted ? base.withValues(alpha: 0.55) : base;
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, String? summary) async {
    final playback = ref.read(ttsPlaybackControllerProvider);
    if (summary == null) {
      if (ref.read(ttsMutedProvider)) {
        await ref.read(ttsMutedProvider.notifier).setMuted(false);
      }
      return;
    }

    final outcome = await playback.listenToggle(
      context: context,
      message: summary,
      playbackKey: _screenPlaybackKey,
    );
    if (!context.mounted) {
      return;
    }
    if (outcome == ContextualTtsOutcome.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonVoiceUnavailable)),
      );
    }
  }

  Future<void> _onLongPress(WidgetRef ref) async {
    await ref.read(ttsPlaybackControllerProvider).stop();
    await ref.read(ttsMutedProvider.notifier).setMuted(true);
  }
}
