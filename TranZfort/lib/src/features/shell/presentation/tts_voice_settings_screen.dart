import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tts_voice_model.dart';
import '../../../core/services/tts_voice_selection_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/tts_voice_list_item.dart';
import '../../../shared/widgets/tts_voice_test_button.dart';
import 'shell_components.dart';

/// Screen for selecting TTS voices for Hindi and English.
class TtsVoiceSettingsScreen extends ConsumerWidget {
  const TtsVoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(ttsVoiceSelectionProvider);
    final voiceNotifier = ref.read(ttsVoiceSelectionProvider.notifier);

    return DetailPageScaffold(
      title: 'Voice Settings',
      ttsSummary: 'Voice settings screen. Select preferred voices for Hindi and English text-to-speech.',
      children: [
        if (voiceState.isLoading)
          const LoadingShimmer(height: 200, itemCount: 2)
        else if (voiceState.error != null)
          WarningBlock(
            title: 'Failed to load voices',
            message: voiceState.error!,
            action: OutlineButton(
              label: 'Retry',
              onPressed: () => voiceNotifier.refreshVoices(),
            ),
          )
        else ...[
          _HindiVoiceSection(
            voices: voiceNotifier.getVoicesForLanguage('hi'),
            selectedVoice: voiceState.selectedHindiVoice,
            onSelectVoice: (voice) => voiceNotifier.selectVoice('hi', voice),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _EnglishVoiceSection(
            voices: voiceNotifier.getVoicesForLanguage('en'),
            selectedVoice: voiceState.selectedEnglishVoice,
            onSelectVoice: (voice) => voiceNotifier.selectVoice('en', voice),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionCard(
            title: 'Actions',
            child: SizedBox(
              width: double.infinity,
              child: OutlineButton(
                label: 'Refresh Voices',
                onPressed: () => voiceNotifier.refreshVoices(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HindiVoiceSection extends StatelessWidget {
  final List<TtsVoice> voices;
  final TtsVoice? selectedVoice;
  final Function(TtsVoice) onSelectVoice;

  const _HindiVoiceSection({
    required this.voices,
    required this.selectedVoice,
    required this.onSelectVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Hindi Voice',
      child: voices.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('No Hindi voices available on this device.'),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: voices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final voice = voices[index];
                final isSelected = voice == selectedVoice;
                return Row(
                  children: [
                    Expanded(
                      child: TtsVoiceListItem(
                        voice: voice,
                        isSelected: isSelected,
                        onTap: () => onSelectVoice(voice),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TtsVoiceTestButton(
                      voice: voice,
                      languageCode: 'hi',
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _EnglishVoiceSection extends StatelessWidget {
  final List<TtsVoice> voices;
  final TtsVoice? selectedVoice;
  final Function(TtsVoice) onSelectVoice;

  const _EnglishVoiceSection({
    required this.voices,
    required this.selectedVoice,
    required this.onSelectVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'English Voice',
      child: voices.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('No English voices available on this device.'),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: voices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final voice = voices[index];
                final isSelected = voice == selectedVoice;
                return Row(
                  children: [
                    Expanded(
                      child: TtsVoiceListItem(
                        voice: voice,
                        isSelected: isSelected,
                        onTap: () => onSelectVoice(voice),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TtsVoiceTestButton(
                      voice: voice,
                      languageCode: 'en',
                    ),
                  ],
                );
              },
            ),
    );
  }
}
