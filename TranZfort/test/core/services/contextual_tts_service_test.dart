import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';

import 'dart:async';

void main() {
  test('contextual TTS returns muted when device voice guidance is muted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'tts_muted': true});
    var speakCalls = 0;
    final service = ContextualTtsService(
      setLanguageFn: (_) async {},
      setSpeechRateFn: (_) async {},
      speakFn: (_) async {
        speakCalls += 1;
      },
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    final outcome = await service.speakSummary(
      languageCode: 'en',
      message: 'Settings summary',
    );

    expect(outcome, ContextualTtsOutcome.muted);
    expect(speakCalls, 0);
  });

  test('contextual TTS sanitizes emoji and selects Hindi voice code', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    String? selectedLanguage;
    double? selectedRate;
    String? spokenMessage;
    final service = ContextualTtsService(
      setLanguageFn: (value) async {
        selectedLanguage = value;
      },
      setSpeechRateFn: (value) async {
        selectedRate = value;
      },
      speakFn: (value) async {
        spokenMessage = value;
      },
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    final outcome = await service.speakSummary(
      languageCode: 'hi',
      message: 'Namaste 🚚 driver summary',
    );

    expect(outcome, ContextualTtsOutcome.spoken);
    expect(selectedLanguage, 'hi-IN');
    expect(selectedRate, ContextualTtsService.defaultSpeechRate);
    expect(spokenMessage, 'Namaste driver summary');
  });

  test('contextual TTS public language helper normalizes supported voice codes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final selectedLanguages = <String>[];
    final service = ContextualTtsService(
      setLanguageFn: (value) async {
        selectedLanguages.add(value);
      },
      setSpeechRateFn: (_) async {},
      speakFn: (_) async {},
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    await service.setLanguage('hi');
    await service.setLanguage('en');
    await service.setLanguage('unknown');

    expect(selectedLanguages, <String>['hi-IN', 'en-IN', 'en-IN']);
  });

  test('contextual TTS truncates long summaries to 500 characters', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    String? spokenMessage;
    final service = ContextualTtsService(
      setLanguageFn: (_) async {},
      setSpeechRateFn: (_) async {},
      speakFn: (value) async {
        spokenMessage = value;
      },
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    final message = 'a' * 550;
    final outcome = await service.speakSummary(
      languageCode: 'en',
      message: message,
    );

    expect(outcome, ContextualTtsOutcome.spoken);
    expect(spokenMessage, isNotNull);
    expect(spokenMessage!.length, 500);
  });

  test('contextual TTS serializes overlapping speak requests', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final completions = <Completer<void>>[];
    final spokenMessages = <String>[];
    final service = ContextualTtsService(
      setLanguageFn: (_) async {},
      setSpeechRateFn: (_) async {},
      speakFn: (value) async {
        spokenMessages.add(value);
        final completer = Completer<void>();
        completions.add(completer);
        await completer.future;
      },
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    final firstFuture = service.speakSummary(languageCode: 'en', message: 'First summary');
    final secondFuture = service.speakSummary(languageCode: 'en', message: 'Second summary');

    await Future<void>.delayed(Duration.zero);
    expect(spokenMessages, ['First summary']);

    completions.first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(spokenMessages, ['First summary', 'Second summary']);

    completions.last.complete();
    expect(await firstFuture, ContextualTtsOutcome.spoken);
    expect(await secondFuture, ContextualTtsOutcome.spoken);
  });

  test('contextual TTS exposes speaking state while an utterance is active', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final completer = Completer<void>();
    late ContextualTtsService service;
    service = ContextualTtsService(
      setLanguageFn: (_) async {},
      setSpeechRateFn: (_) async {},
      speakFn: (_) async {
        expect(service.isSpeaking, isTrue);
        await completer.future;
      },
      stopFn: () async {},
      preferencesFn: () => SharedPreferences.getInstance(),
      getVoices: Future.value,
      setVoiceFn: (_) async {},
    );

    final speakFuture = service.speakSummary(languageCode: 'en', message: 'Active summary');
    await Future<void>.delayed(Duration.zero);

    expect(service.isSpeaking, isTrue);

    completer.complete();
    await speakFuture;

    expect(service.isSpeaking, isFalse);
  });
}
