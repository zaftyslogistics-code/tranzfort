import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import '../../core/theme/app_decorations.dart';

/// Play/stop icon for a specific [message] utterance (IMP Jun 2026).
class TtsListenIcon extends ConsumerWidget {
  final String message;
  final String? playbackKey;
  final double size;
  final Color? color;
  final bool onDarkSurface;

  const TtsListenIcon({
    super.key,
    required this.message,
    this.playbackKey,
    this.size = 22,
    this.color,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ttsSpeakingProvider);
    ref.watch(ttsLastUtteranceProvider);
    ref.watch(ttsActivePlaybackKeyProvider);
    ref.watch(ttsMutedProvider);

    final controller = ref.read(ttsPlaybackControllerProvider);
    final isActive = controller.isPlayingMessage(
      message,
      playbackKey: playbackKey,
    );
    final isMuted = ref.read(ttsMutedProvider);
    final resolvedColor = color ??
        AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface)
            .withValues(alpha: isMuted ? 0.55 : 0.9);

    final ringColor = resolvedColor.withValues(alpha: isActive ? 0.16 : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
          key: ValueKey<bool>(isActive),
          size: size,
          color: resolvedColor,
        ),
      ),
    );
  }
}
