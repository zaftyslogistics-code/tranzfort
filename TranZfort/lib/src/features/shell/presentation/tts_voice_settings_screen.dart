import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tts_settings_provider.dart';
import '../../../core/providers/tts_state_provider.dart';
import '../../../core/services/tts_voice_model.dart';
import '../../../core/services/tts_voice_selection_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/tts_voice_list_item.dart';
import '../../../shared/widgets/tts_voice_test_button.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';
import 'shell_components.dart';

class _SpeechRateSection extends ConsumerWidget {
  const _SpeechRateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(ttsSettingsProvider);
    return SectionCard(
      title: l10n.ttsSpeechRateTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ttsSpeechRateHelper, style: Theme.of(context).textTheme.bodySmall),
          Slider(
            value: settings.speechRate,
            min: 0.2,
            max: 1.0,
            divisions: 16,
            label: settings.speechRate.toStringAsFixed(2),
            onChanged: settings.isLoading
                ? null
                : (value) => ref.read(ttsSettingsProvider.notifier).setSpeechRate(value),
          ),
        ],
      ),
    );
  }
}

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
          _SpeechRateSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionCard(
            title: AppLocalizations.of(context).ttsVoiceSettingsActionsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlineButton(
                  label: AppLocalizations.of(context).ttsReplayLastAction,
                  icon: const Icon(Icons.replay_outlined),
                  onPressed: () {
                    final last = ref.read(ttsLastUtteranceProvider);
                    if (last == null || last.trim().isEmpty) {
                      AppSnackbar.show(
                        context: context,
                        message: AppLocalizations.of(context).ttsReplayLastEmptyMessage,
                        variant: AppSnackbarVariant.info,
                      );
                      return;
                    }
                    TtsCardSpeakerButton.speak(context, ref, last);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlineButton(
                  label: AppLocalizations.of(context).ttsVoiceSettingsRefreshVoices,
                  onPressed: () => ref.read(ttsVoiceSelectionProvider.notifier).refreshVoices(),
                ),
              ],
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
