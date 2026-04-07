import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

class TtsService {
  static const _ttsEnabledKey = 'tts_enabled';
  static const _languageKey = 'app_language';
  static const _ttsSpeedKey = 'tts_speed';
  static const _ttsLanguageModeKey = 'tts_language_mode';

  final FlutterTts _flutterTts = FlutterTts();
  String _lastLanguage = '';

  TtsService() {
    _initTts();
  }

  String _localeForAppLanguage(String appLanguage) {
    return appLanguage == 'hi' ? 'hi-IN' : 'en-IN';
  }

  Future<String> _targetLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_ttsLanguageModeKey) ?? 'auto';
    if (mode == 'hi') {
      return 'hi-IN';
    }
    if (mode == 'en') {
      return 'en-IN';
    }
    final appLanguage = prefs.getString(_languageKey) ?? 'hi';
    return _localeForAppLanguage(appLanguage);
  }

  Future<double> _targetSpeedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getDouble(_ttsSpeedKey) ?? 0.5;
    return raw.clamp(0.3, 0.8);
  }

  Future<void> _applyLanguage(String targetLanguage) async {
    if (_lastLanguage == targetLanguage) {
      return;
    }

    await _flutterTts.setLanguage(targetLanguage);
    await _setPreferredVoiceForLanguage(targetLanguage);
    _lastLanguage = targetLanguage;
  }

  Future<void> _initTts() async {
    final initialLanguage = await _targetLanguageFromPrefs();
    await _applyLanguage(initialLanguage);
    await _flutterTts.setSpeechRate(await _targetSpeedFromPrefs());
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _setPreferredVoiceForLanguage(String languageTag) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is! List) {
        return;
      }

      final languagePrefix = languageTag.substring(0, 2).toLowerCase();

      Map<dynamic, dynamic>? pickVoice(bool femaleOnly) {
        for (final voice in voices) {
          if (voice is! Map) {
            continue;
          }
          final locale = (voice['locale'] ?? '').toString().toLowerCase();
          if (!locale.startsWith(languagePrefix)) {
            continue;
          }

          final name = (voice['name'] ?? '').toString().toLowerCase();
          final gender = (voice['gender'] ?? '').toString().toLowerCase();
          final isFemale =
              gender.contains('female') || name.contains('female');
          if (femaleOnly && !isFemale) {
            continue;
          }
          return voice;
        }
        return null;
      }

      final selected = pickVoice(true) ?? pickVoice(false);
      if (selected != null) {
        await _flutterTts.setVoice(Map<String, String>.from(selected));
      }
    } catch (_) {
      // Keep language-only fallback if a specific voice cannot be selected.
    }
  }

  Future<void> speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_ttsEnabledKey) ?? true;
    if (!enabled) {
      return;
    }

    final targetLanguage = await _targetLanguageFromPrefs();
    final speed = await _targetSpeedFromPrefs();
    await _applyLanguage(targetLanguage);
    await _flutterTts.setSpeechRate(speed);

    await _flutterTts.stop();

    final cleanText = text
        .replaceAll(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
          '',
        )
        .trim();
    if (cleanText.isEmpty) {
      return;
    }

    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> previewVoice(String sampleText) async {
    await speak(sampleText);
  }
}
