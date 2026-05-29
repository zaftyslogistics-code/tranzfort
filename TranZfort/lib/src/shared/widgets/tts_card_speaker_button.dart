import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_audio_language_provider.dart';
import '../../core/providers/tts_state_provider.dart';
import '../../core/services/contextual_tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/tts_localizations.dart';

/// Per-card speaker control (manual play). Respects global mute.
class TtsCardSpeakerButton extends ConsumerWidget {
  final String message;
  final String? tooltip;

  const TtsCardSpeakerButton({
    super.key,
    required this.message,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsL10n = TtsLocalizations.of(context);
    final resolvedTooltip = tooltip ?? ttsL10n.ttsListenToLoadHint;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: resolvedTooltip,
      onPressed: () => _speak(context, ref),
      icon: Icon(
        Icons.volume_up_rounded,
        size: 22,
        color: AppColors.inkTextPrimary.withValues(alpha: 0.9),
      ),
    );
  }

  Future<void> _speak(BuildContext context, WidgetRef ref) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final languageCode = resolveTtsLanguageCode(
      context: context,
      audioLanguageCode: ref.read(ttsAudioLanguageProvider),
    );

    if (ref.read(ttsMutedProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonVoiceMuted)),
      );
      return;
    }

    await ref.read(ttsPlaybackControllerProvider).stop();

    final outcome = await ref.read(contextualTtsServiceProvider).speakSummary(
          languageCode: languageCode,
          message: normalized,
        );

    if (!context.mounted) {
      return;
    }
    if (outcome == ContextualTtsOutcome.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonVoiceUnavailable)),
      );
    }
  }
}
