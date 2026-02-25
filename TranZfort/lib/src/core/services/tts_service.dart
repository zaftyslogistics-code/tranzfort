import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

class TtsService {
  static const _ttsEnabledKey = 'tts_enabled';

  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('hi-IN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_ttsEnabledKey) ?? true;
    if (!enabled) {
      return;
    }

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
}
