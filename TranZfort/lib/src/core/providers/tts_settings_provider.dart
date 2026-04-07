import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TTS language mode: how TTS voice language should be determined
enum TtsLanguageMode {
  /// Follow the app's selected language
  auto,

  /// Always use Hindi voice (hi-IN)
  hi,

  /// Always use English voice (en-IN)
  en,
}

/// TTS settings state
class TtsSettingsState {
  final double speechRate;
  final TtsLanguageMode languageMode;
  final bool isLoading;

  const TtsSettingsState({
    required this.speechRate,
    required this.languageMode,
    this.isLoading = false,
  });

  TtsSettingsState copyWith({
    double? speechRate,
    TtsLanguageMode? languageMode,
    bool? isLoading,
  }) {
    return TtsSettingsState(
      speechRate: speechRate ?? this.speechRate,
      languageMode: languageMode ?? this.languageMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get effective language code based on mode and app language
  String effectiveLanguageCode(String appLanguageCode) {
    return switch (languageMode) {
      TtsLanguageMode.auto => appLanguageCode,
      TtsLanguageMode.hi => 'hi',
      TtsLanguageMode.en => 'en',
    };
  }
}

/// Notifier for TTS settings
class TtsSettingsNotifier extends StateNotifier<TtsSettingsState> {
  static const String _speechRateKey = 'tts_speech_rate';
  static const String _languageModeKey = 'tts_language_mode';
  static const double defaultSpeechRate = 0.5;

  TtsSettingsNotifier()
      : super(const TtsSettingsState(
          speechRate: defaultSpeechRate,
          languageMode: TtsLanguageMode.auto,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();

    final savedRate = prefs.getDouble(_speechRateKey);
    final savedModeIndex = prefs.getInt(_languageModeKey);

    state = state.copyWith(
      speechRate: savedRate ?? defaultSpeechRate,
      languageMode: savedModeIndex != null
          ? TtsLanguageMode.values[savedModeIndex]
          : TtsLanguageMode.auto,
      isLoading: false,
    );
  }

  Future<void> setSpeechRate(double rate) async {
    // Clamp rate to valid range (0.0 - 1.0)
    final clampedRate = rate.clamp(0.0, 1.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, clampedRate);

    state = state.copyWith(speechRate: clampedRate);
  }

  Future<void> setLanguageMode(TtsLanguageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageModeKey, mode.index);

    state = state.copyWith(languageMode: mode);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_speechRateKey);
    await prefs.remove(_languageModeKey);

    state = const TtsSettingsState(
      speechRate: defaultSpeechRate,
      languageMode: TtsLanguageMode.auto,
    );
  }
}

/// Provider for TTS settings
final ttsSettingsProvider = StateNotifierProvider<TtsSettingsNotifier, TtsSettingsState>((ref) {
  return TtsSettingsNotifier();
});
