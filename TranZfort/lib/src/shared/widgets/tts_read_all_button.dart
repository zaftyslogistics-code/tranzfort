import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'action_buttons.dart';
import 'tts_card_speaker_button.dart';

/// Speaks a long concatenated utterance (sections combined, length-capped).
class TtsReadAllButton extends ConsumerWidget {
  final String message;

  const TtsReadAllButton({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spoken = message.trim();
    if (spoken.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlineButton(
        label: l10n.ttsReadAllSectionsAction,
        icon: const Icon(Icons.record_voice_over_outlined),
        onPressed: () => TtsCardSpeakerButton.speak(context, ref, spoken),
      ),
    );
  }
}
