import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contextual_tts_service.dart';
import 'tts_voice_model.dart';

/// State for TTS voice selection.
class TtsVoiceSelectionState {
  final List<TtsVoice> availableVoices;
  final TtsVoice? selectedHindiVoice;
  final TtsVoice? selectedEnglishVoice;
  final bool isLoading;
  final String? error;

  const TtsVoiceSelectionState({
    this.availableVoices = const [],
    this.selectedHindiVoice,
    this.selectedEnglishVoice,
    this.isLoading = false,
    this.error,
  });

  TtsVoiceSelectionState copyWith({
    List<TtsVoice>? availableVoices,
    TtsVoice? selectedHindiVoice,
    TtsVoice? selectedEnglishVoice,
    bool? isLoading,
    String? error,
  }) {
    return TtsVoiceSelectionState(
      availableVoices: availableVoices ?? this.availableVoices,
      selectedHindiVoice: selectedHindiVoice ?? this.selectedHindiVoice,
      selectedEnglishVoice: selectedEnglishVoice ?? this.selectedEnglishVoice,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for TTS voice selection state.
class TtsVoiceSelectionNotifier extends StateNotifier<TtsVoiceSelectionState> {
  final ContextualTtsService _ttsService;

  TtsVoiceSelectionNotifier(this._ttsService)
      : super(const TtsVoiceSelectionState(isLoading: true));

  /// Discovers available voices and loads persisted selections.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Discover available voices
      final voices = await _ttsService.getVoices();

      // Load persisted voice IDs
      final hindiVoiceId = await _ttsService.loadSelectedVoiceId('hi');
      final englishVoiceId = await _ttsService.loadSelectedVoiceId('en');

      // Find the selected voices from the available list
      TtsVoice? selectedHindiVoice;
      TtsVoice? selectedEnglishVoice;

      if (hindiVoiceId != null) {
        selectedHindiVoice = voices.firstWhere(
          (v) => v.voiceId == hindiVoiceId,
          orElse: () => _ttsService.getBestVoiceForLanguage(voices, 'hi')!,
        );
      } else {
        selectedHindiVoice = _ttsService.getBestVoiceForLanguage(voices, 'hi');
      }

      if (englishVoiceId != null) {
        selectedEnglishVoice = voices.firstWhere(
          (v) => v.voiceId == englishVoiceId,
          orElse: () => _ttsService.getBestVoiceForLanguage(voices, 'en')!,
        );
      } else {
        selectedEnglishVoice = _ttsService.getBestVoiceForLanguage(voices, 'en');
      }

      state = state.copyWith(
        availableVoices: voices,
        selectedHindiVoice: selectedHindiVoice,
        selectedEnglishVoice: selectedEnglishVoice,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load voices: ${e.toString()}',
      );
    }
  }

  /// Selects a voice for the given language.
  Future<void> selectVoice(String languageCode, TtsVoice voice) async {
    try {
      // Persist the selection
      await _ttsService.saveSelectedVoiceId(languageCode, voice.voiceId);

      // Update state
      if (languageCode == 'hi') {
        state = state.copyWith(selectedHindiVoice: voice);
      } else if (languageCode == 'en') {
        state = state.copyWith(selectedEnglishVoice: voice);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save voice selection: ${e.toString()}');
    }
  }

  /// Clears the voice selection for the given language.
  Future<void> clearVoiceSelection(String languageCode) async {
    try {
      await _ttsService.clearSelectedVoiceId(languageCode);

      // Reset to best available voice
      final voices = state.availableVoices;
      final bestVoice = _ttsService.getBestVoiceForLanguage(voices, languageCode);

      if (languageCode == 'hi') {
        state = state.copyWith(selectedHindiVoice: bestVoice);
      } else if (languageCode == 'en') {
        state = state.copyWith(selectedEnglishVoice: bestVoice);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear voice selection: ${e.toString()}');
    }
  }

  /// Refreshes the available voices list.
  Future<void> refreshVoices() async {
    await initialize();
  }

  /// Gets the filtered voices for a language (sorted with offline first).
  List<TtsVoice> getVoicesForLanguage(String languageCode) {
    return _ttsService.filterVoicesForLanguage(state.availableVoices, languageCode);
  }
}

/// Provider for TTS voice selection state.
final ttsVoiceSelectionProvider =
    StateNotifierProvider<TtsVoiceSelectionNotifier, TtsVoiceSelectionState>((ref) {
  final ttsService = ref.watch(contextualTtsServiceProvider);
  final notifier = TtsVoiceSelectionNotifier(ttsService);
  
  // Initialize on first use
  Future.microtask(() => notifier.initialize());
  
  return notifier;
});
