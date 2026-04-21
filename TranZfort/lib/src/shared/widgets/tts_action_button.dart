import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import '../../core/services/contextual_tts_service.dart';
import '../../l10n/app_localizations.dart';
import 'feedback_components.dart';

class TtsActionButton extends ConsumerWidget {
  final String? fallbackSummary;

  const TtsActionButton({
    super.key,
    this.fallbackSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaryBuilder = ref.watch(ttsScreenSummaryProvider);
    final isMuted = ref.watch(ttsMutedProvider);
    final isSpeaking = ref.watch(ttsSpeakingProvider);

    return GestureDetector(
      onLongPress: () async {
        await ref.read(ttsMutedProvider.notifier).toggleMuted();
        if (context.mounted) {
          final newMutedState = ref.read(ttsMutedProvider);
          AppSnackbar.show(
            context: context,
            message: newMutedState ? 'Voice muted — long-press speaker to unmute' : 'Voice unmuted',
            variant: AppSnackbarVariant.info,
          );
        }
      },
      child: IconButton(
        tooltip: l10n.shellTooltipVoiceAssistance,
        onPressed: () async {
          if (isMuted) {
            AppSnackbar.show(
              context: context,
              message: 'Voice is muted. Long-press speaker to unmute.',
              variant: AppSnackbarVariant.info,
            );
            return;
          }

          if (isSpeaking) {
            await ref.read(ttsPlaybackControllerProvider).stop();
            return;
          }

          final message = (summaryBuilder?.call(context) ?? fallbackSummary ?? '').trim();
          if (message.isEmpty) {
            AppSnackbar.show(
              context: context,
              message: l10n.commonVoiceUnavailable,
              variant: AppSnackbarVariant.info,
            );
            return;
          }

          final outcome = await ref.read(ttsPlaybackControllerProvider).play(
                context: context,
                message: message,
              );

          if (!context.mounted || outcome == ContextualTtsOutcome.spoken || outcome == ContextualTtsOutcome.skipped) {
            return;
          }

          AppSnackbar.show(
            context: context,
            message: outcome == ContextualTtsOutcome.muted ? l10n.commonVoiceMuted : l10n.commonVoiceUnavailable,
            variant: outcome == ContextualTtsOutcome.muted ? AppSnackbarVariant.info : AppSnackbarVariant.error,
          );
        },
        icon: Icon(
          isSpeaking
              ? Icons.stop_circle_outlined
              : (isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined),
        ),
      ),
    );
  }
}
