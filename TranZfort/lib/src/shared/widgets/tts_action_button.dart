import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import '../../core/theme/app_colors.dart';

/// Voice assistant mute toggle for the app bar.
///
/// Behaviour (persistent across sessions via [ttsMutedProvider], key
/// `tts_muted`):
/// - **Unmuted (default)** → every screen auto-plays its TTS summary via
///   [TtsScreenSummaryEffect]. Icon shows a solid speaker.
/// - **Muted** → any current speech is stopped and auto-play is suppressed
///   on every screen until the user taps again to unmute. Icon shows a
///   struck-through speaker.
///
/// No replay action — unmuting simply restores auto-play for subsequent
/// screens; it does not re-speak the current screen.
class TtsActionButton extends ConsumerWidget {
  const TtsActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(ttsMutedProvider);
    final tooltip = isMuted ? 'Turn voice on' : 'Mute voice';

    return IconButton(
      tooltip: tooltip,
      onPressed: () => _handleTap(ref, isMuted),
      icon: _VoiceIcon(isMuted: isMuted),
    );
  }

  Future<void> _handleTap(WidgetRef ref, bool isMuted) async {
    final mutedNotifier = ref.read(ttsMutedProvider.notifier);
    if (isMuted) {
      // Unmute — subsequent screens will auto-play again. No replay here.
      await mutedNotifier.setMuted(false);
      return;
    }
    // Mute — stop any speech in flight and suppress auto-play everywhere.
    await ref.read(ttsPlaybackControllerProvider).stop();
    await mutedNotifier.setMuted(true);
  }
}

class _VoiceIcon extends StatelessWidget {
  final bool isMuted;

  const _VoiceIcon({required this.isMuted});

  @override
  Widget build(BuildContext context) {
    final baseColor = IconTheme.of(context).color ?? AppColors.primary;
    // Single static glyph per state — no pulsing, no replay affordance.
    return Icon(
      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      size: 26,
      color: isMuted ? baseColor.withValues(alpha: 0.6) : baseColor,
    );
  }
}
