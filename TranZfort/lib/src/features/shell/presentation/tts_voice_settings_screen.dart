import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tts_voice_model.dart';
import '../../../core/services/tts_voice_selection_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/tts_voice_list_item.dart';
import '../../../shared/widgets/tts_voice_test_button.dart';
import 'shell_components.dart';

/// Screen for selecting TTS voices for Hindi and English.
class TtsVoiceSettingsScreen extends ConsumerWidget {
  const TtsVoiceSettingsScreen({super.key});

  Future<void> _handleVoiceSelection(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
    TtsVoice voice,
  ) async {
    final voiceNotifier = ref.read(ttsVoiceSelectionProvider.notifier);
    
    await voiceNotifier.selectVoice(languageCode, voice);
    
    if (!context.mounted) return;
    
    final languageName = languageCode == 'hi' ? 'Hindi' : 'English';
    AppSnackbar.show(
      context: context,
      message: '$languageName voice set to "${voice.name}"',
      variant: AppSnackbarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(ttsVoiceSelectionProvider);

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
              onPressed: () => ref.read(ttsVoiceSelectionProvider.notifier).refreshVoices(),
            ),
          )
        else ...[
          _HindiVoiceSection(
            voices: ref.read(ttsVoiceSelectionProvider.notifier).getVoicesForLanguage('hi'),
            selectedVoice: voiceState.selectedHindiVoice,
            onSelectVoice: (voice) => _handleVoiceSelection(context, ref, 'hi', voice),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _EnglishVoiceSection(
            voices: ref.read(ttsVoiceSelectionProvider.notifier).getVoicesForLanguage('en'),
            selectedVoice: voiceState.selectedEnglishVoice,
            onSelectVoice: (voice) => _handleVoiceSelection(context, ref, 'en', voice),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionCard(
            title: 'Actions',
            child: SizedBox(
              width: double.infinity,
              child: OutlineButton(
                label: 'Refresh Voices',
                onPressed: () => ref.read(ttsVoiceSelectionProvider.notifier).refreshVoices(),
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
      title: AppLocalizations.of(context).ttsHindiVoice,
      child: voices.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(AppLocalizations.of(context).ttsNoHindiVoices),
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
      title: AppLocalizations.of(context).ttsEnglishVoice,
      child: voices.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(AppLocalizations.of(context).ttsNoEnglishVoices),
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
