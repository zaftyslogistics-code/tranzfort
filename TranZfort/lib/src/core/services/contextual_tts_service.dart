import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> _pendingSpeak = Future<void>.value();
  bool _isSpeaking = false;

  ContextualTtsService({
    required Future<dynamic> Function(String language) setLanguageFn,
    required Future<dynamic> Function(double rate) setSpeechRateFn,
    required Future<dynamic> Function(String message) speakFn,
    required Future<dynamic> Function() stopFn,
    required Future<SharedPreferences> Function() preferencesFn,
  })  : _setLanguage = setLanguageFn,
        _setSpeechRate = setSpeechRateFn,
        _speak = speakFn,
        _stop = stopFn,
        _preferences = preferencesFn;

  bool get isSpeaking => _isSpeaking;

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
        await setLanguage(languageCode);
        await setSpeechRate(defaultSpeechRate);
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
    return languageCode.trim().toLowerCase() == 'hi' ? 'hi-IN' : 'en-IN';
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
    return withoutEmoji.substring(0, 500).trimRight();
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
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
