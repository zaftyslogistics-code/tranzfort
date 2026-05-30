import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_audio_language_provider.dart';
import '../../core/providers/tts_state_provider.dart';
import '../../core/services/contextual_tts_service.dart';
import '../../core/theme/app_decorations.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/tts_localizations.dart';

/// Per-card speaker control (manual play). Respects global mute.
class TtsCardSpeakerButton extends ConsumerWidget {
  final String message;
  final String? tooltip;
  final bool onDarkSurface;

  const TtsCardSpeakerButton({
    super.key,
    required this.message,
    this.tooltip,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsL10n = lookupTtsLocalizations(Localizations.localeOf(context));
    final resolvedTooltip = tooltip ?? ttsL10n.ttsListenToLoadHint;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: resolvedTooltip,
      onPressed: () => speak(context, ref, message),
      icon: Icon(
        Icons.volume_up_rounded,
        size: 22,
        color: AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface)
            .withValues(alpha: 0.9),
      ),
    );
  }

  static Future<void> speak(BuildContext context, WidgetRef ref, String message) async {
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

    ref.read(ttsLastUtteranceProvider.notifier).state = normalized;
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
