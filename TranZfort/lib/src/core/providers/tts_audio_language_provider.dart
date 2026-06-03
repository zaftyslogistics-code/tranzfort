import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale_providers.dart';

const ttsAudioLanguagePreferenceKey = 'tts_audio_language';

/// Spoken-language preference (`en` | `hi`). Defaults to UI [appLanguagePreferenceKey] until user overrides in Settings.
final ttsAudioLanguageProvider =
    StateNotifierProvider<TtsAudioLanguageNotifier, String>((ref) {
  return TtsAudioLanguageNotifier();
});

class TtsAudioLanguageNotifier extends StateNotifier<String> {
  TtsAudioLanguageNotifier() : super(kDefaultAppLanguageCode) {
    _load();
  }

  @visibleForTesting
  TtsAudioLanguageNotifier.test(String languageCode)
      : _loaded = true,
        _followsAppLocale = false,
        super(languageCode);

  bool _loaded = false;
  bool _followsAppLocale = true;

  bool get isLoaded => _loaded;
  bool get followsAppLocale => _followsAppLocale;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = normalizeLanguageCode(prefs.getString(ttsAudioLanguagePreferenceKey));
    if (saved != null) {
      _followsAppLocale = false;
      state = saved;
    } else {
      _followsAppLocale = true;
      // Match UI language on disk — avoid resetting to `en` after async locale sync (race).
      final appLang = normalizeLanguageCode(prefs.getString(appLanguagePreferenceKey));
      state = appLang ?? kDefaultAppLanguageCode;
    }
    _loaded = true;
  }

  /// Sync from UI locale when no explicit TTS override is stored.
  Future<void> syncFromUiLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(ttsAudioLanguagePreferenceKey)) {
      return;
    }
    _followsAppLocale = true;
    final normalized = normalizeLanguageCode(locale.languageCode);
    if (normalized != null) {
      state = normalized;
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    final normalized = normalizeLanguageCode(languageCode);
    if (normalized == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ttsAudioLanguagePreferenceKey, normalized);
    _followsAppLocale = false;
    state = normalized;
  }

  Future<void> followAppLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ttsAudioLanguagePreferenceKey);
    _followsAppLocale = true;
    final normalized = normalizeLanguageCode(locale.languageCode);
    if (normalized != null) {
      state = normalized;
    }
  }

  Future<void> clearOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ttsAudioLanguagePreferenceKey);
    _followsAppLocale = true;
    final appLang = normalizeLanguageCode(prefs.getString(appLanguagePreferenceKey));
    state = appLang ?? kDefaultAppLanguageCode;
  }

  static String? normalizeLanguageCode(String? code) {
    final raw = (code ?? '').trim().toLowerCase();
    return switch (raw) {
      'hi' || 'hi-in' || 'hi_in' => 'hi',
      'en' || 'en-gb' || 'en-us' || 'en-in' || 'en_in' => 'en',
      _ => null,
    };
  }
}

/// Resolves language for [ContextualTtsService.speakSummary].
String resolveTtsLanguageCode({
  required BuildContext context,
  required String audioLanguageCode,
}) {
  final normalized = TtsAudioLanguageNotifier.normalizeLanguageCode(audioLanguageCode);
  if (normalized != null) {
    return normalized;
  }
  return TtsAudioLanguageNotifier.normalizeLanguageCode(
        Localizations.localeOf(context).languageCode,
      ) ??
      'en';
}
