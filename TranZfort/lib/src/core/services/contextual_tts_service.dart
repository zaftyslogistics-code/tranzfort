import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tts_voice_model.dart';

enum ContextualTtsOutcome {
  spoken,
  muted,
  unavailable,
  skipped,
}

class ContextualTtsService {
  static const double defaultSpeechRate = 0.5;

  final Future<dynamic> Function(String language) _setLanguage;
  final Future<dynamic> Function(double rate) _setSpeechRate;
  final Future<dynamic> Function(String message) _speak;
  final Future<dynamic> Function() _stop;
  final Future<SharedPreferences> Function() _preferences;
  final Future<dynamic> _getVoices;
  final Future<dynamic> Function(Map<String, String> voice) _setVoice;
  Future<void> _pendingSpeak = Future<void>.value();
  bool _isSpeaking = false;

  ContextualTtsService({
    required Future<dynamic> Function(String language) setLanguageFn,
    required Future<dynamic> Function(double rate) setSpeechRateFn,
    required Future<dynamic> Function(String message) speakFn,
    required Future<dynamic> Function() stopFn,
    required Future<SharedPreferences> Function() preferencesFn,
    required Future<dynamic> getVoices,
    required Future<dynamic> Function(Map<String, String> voice) setVoiceFn,
  })  : _setLanguage = setLanguageFn,
        _setSpeechRate = setSpeechRateFn,
        _speak = speakFn,
        _stop = stopFn,
        _preferences = preferencesFn,
        _getVoices = getVoices,
        _setVoice = setVoiceFn;

  bool get isSpeaking => _isSpeaking;

  /// Discovers available TTS voices from the device's TTS engine.
  /// Returns a list of TtsVoice objects.
  Future<List<TtsVoice>> getVoices() async {
    try {
      final voices = await _getVoices;
      
      // Handle different return types from FlutterTts.getVoices
      if (voices is List) {
        return voices.map((voice) {
          // FlutterTts returns voices as Map<String, dynamic> with keys: name, locale
          if (voice is Map<String, dynamic>) {
            final name = voice['name'] as String? ?? '';
            final locale = voice['locale'] as String? ?? '';
            final language = locale.split('-')[0].toLowerCase();
            
            // Infer offline status from voice name (offline voices typically have "local" in the name)
            final isOffline = name.toLowerCase().contains('local');
            
            return TtsVoice(
              voiceId: name,
              name: name,
              locale: locale,
              language: language,
              isOffline: isOffline,
            );
          }
          // Fallback for non-map responses
          return TtsVoice(
            voiceId: voice.toString(),
            name: voice.toString(),
            locale: 'unknown',
            language: 'unknown',
            isOffline: false,
          );
        }).toList();
      }
      
      // If not a list, return empty
      return [];
    } catch (e) {
      // Return empty list on error rather than crashing
      return [];
    }
  }

  /// Filters voices for the given language code and prioritizes offline voices.
  /// Returns a filtered and sorted list of voices.
  /// - Filters for Hindi (hi-IN) or English (en-GB/en-US) voices
  /// - Prioritizes offline voices at the top of the list
  /// - Returns empty list if no voices match the language
  List<TtsVoice> filterVoicesForLanguage(List<TtsVoice> voices, String languageCode) {
    final filtered = voices.where((voice) {
      // Filter for the requested language
      if (languageCode == 'hi') {
        return voice.isHindi;
      } else if (languageCode == 'en') {
        return voice.isEnglish;
      }
      return false;
    }).toList();

    // Sort by offline status (offline voices first)
    filtered.sort((a, b) {
      if (a.isOffline && !b.isOffline) return -1;
      if (!a.isOffline && b.isOffline) return 1;
      return 0;
    });

    return filtered;
  }

  /// Gets the best available voice for the given language code.
  /// Prioritizes: offline voices > online voices > default voice
  /// Returns null if no voice is available for the language.
  TtsVoice? getBestVoiceForLanguage(List<TtsVoice> voices, String languageCode) {
    final filtered = filterVoicesForLanguage(voices, languageCode);
    if (filtered.isEmpty) return null;
    
    // Return the first voice (already sorted with offline first)
    return filtered.first;
  }

  /// Saves the selected voice ID for the given language code.
  /// Uses SharedPreferences for persistence across app restarts.
  Future<void> saveSelectedVoiceId(String languageCode, String voiceId) async {
    try {
      final preferences = await _preferences();
      final key = _getVoicePreferenceKey(languageCode);
      await preferences.setString(key, voiceId);
    } catch (e) {
      // Silently fail on save errors - voice selection will fall back to default
    }
  }

  /// Loads the selected voice ID for the given language code.
  /// Returns null if no voice has been selected for the language.
  Future<String?> loadSelectedVoiceId(String languageCode) async {
    try {
      final preferences = await _preferences();
      final key = _getVoicePreferenceKey(languageCode);
      return preferences.getString(key);
    } catch (e) {
      // Return null on load errors - will fall back to default voice
      return null;
    }
  }

  /// Clears the selected voice ID for the given language code.
  /// Resets to default voice selection behavior.
  Future<void> clearSelectedVoiceId(String languageCode) async {
    try {
      final preferences = await _preferences();
      final key = _getVoicePreferenceKey(languageCode);
      await preferences.remove(key);
    } catch (e) {
      // Silently fail on clear errors
    }
  }

  /// Gets the SharedPreferences key for storing voice selection for a language.
  String _getVoicePreferenceKey(String languageCode) {
    return 'tts_selected_voice_$languageCode';
  }

  Future<void> setLanguage(String languageCode) async {
    await _setLanguage(_voiceLanguage(languageCode));
  }

  Future<void> setSpeechRate(double rate) async {
    await _setSpeechRate(rate);
  }

  Future<ContextualTtsOutcome> speakSummary({
    required String languageCode,
    required String message,
  }) async {
    final sanitizedMessage = _sanitizeMessage(message);
    if (sanitizedMessage.isEmpty) {
      return ContextualTtsOutcome.skipped;
    }

    final completion = Completer<ContextualTtsOutcome>();
    _pendingSpeak = _pendingSpeak.then((_) async {
      final preferences = await _preferences();
      if (preferences.getBool('tts_muted') ?? false) {
        _isSpeaking = false;
        completion.complete(ContextualTtsOutcome.muted);
        return;
      }
      try {
        // Load persisted voice ID for the language
        final persistedVoiceId = await loadSelectedVoiceId(languageCode);
        
        // Set language
        await setLanguage(languageCode);
        
        // Set voice if persisted
        if (persistedVoiceId != null) {
          try {
            await _setVoice({'name': persistedVoiceId});
          } catch (_) {
            // Silently fail if voice is unavailable - will use default voice
          }
        }
        
        final savedRate = preferences.getDouble('tts_speech_rate');
        await setSpeechRate(savedRate ?? defaultSpeechRate);
        _isSpeaking = true;
        await _speak(sanitizedMessage);
        completion.complete(ContextualTtsOutcome.spoken);
      } catch (_) {
        completion.complete(ContextualTtsOutcome.unavailable);
      } finally {
        _isSpeaking = false;
      }
    });
    return completion.future;
  }

  String _voiceLanguage(String languageCode) {
    // Hindi -> hi-IN, all other languages -> en-GB (UK English per product direction).
    // The device TTS engine gracefully falls back to another voice
    // if the requested locale isn't installed (e.g. en-US if en-GB is missing).
    return languageCode.trim().toLowerCase() == 'hi' ? 'hi-IN' : 'en-GB';
  }

  String _sanitizeMessage(String message) {
    final withoutEmoji = message
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), ' ')
        .replaceAll(RegExp(r'[\u2600-\u27BF]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (withoutEmoji.length <= 500) {
      return withoutEmoji;
    }
    final truncated = withoutEmoji.substring(0, 500);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 0 ? truncated.substring(0, lastSpace).trimRight() : truncated.trimRight();
  }

  Future<void> stop() async {
    _isSpeaking = false;
    try {
      await _stop();
    } catch (_) {
      return;
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}

final contextualTtsServiceProvider = Provider<ContextualTtsService>((ref) {
  final tts = FlutterTts();
  final service = ContextualTtsService(
    setLanguageFn: tts.setLanguage,
    setSpeechRateFn: tts.setSpeechRate,
    speakFn: tts.speak,
    stopFn: tts.stop,
    preferencesFn: SharedPreferences.getInstance,
    getVoices: tts.getVoices,
    setVoiceFn: tts.setVoice,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
