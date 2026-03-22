import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SttStartOutcome {
  started,
  permissionDenied,
  unavailable,
  busy,
  failed,
}

typedef SttErrorListener = void Function(String errorMessage);
typedef SttResultListener = void Function(String recognizedWords, bool isFinal);
typedef SttInitializeFn = Future<bool> Function({required SttErrorListener onError});
typedef SttListenFn = Future<void> Function({
  required SttResultListener onResult,
  required String localeId,
  required bool partialResults,
  required Duration listenFor,
  required Duration pauseFor,
});
typedef SttStopFn = Future<void> Function();
typedef SttCancelFn = Future<void> Function();
typedef SttHasPermissionFn = Future<bool> Function();
typedef SttIsListeningFn = bool Function();

class SttService {
  static const Duration defaultSilenceTimeout = Duration(seconds: 15);
  static const Duration defaultListenWindow = Duration(minutes: 1);

  final SttInitializeFn _initialize;
  final SttListenFn _listen;
  final SttStopFn _stop;
  final SttCancelFn _cancel;
  final SttHasPermissionFn _hasPermission;
  final SttIsListeningFn _engineIsListening;

  bool _isListening = false;
  String? _lastErrorMessage;

  SttService({
    required SttInitializeFn initializeFn,
    required SttListenFn listenFn,
    required SttStopFn stopFn,
    required SttCancelFn cancelFn,
    required SttHasPermissionFn hasPermissionFn,
    required SttIsListeningFn isListeningFn,
  })  : _initialize = initializeFn,
        _listen = listenFn,
        _stop = stopFn,
        _cancel = cancelFn,
        _hasPermission = hasPermissionFn,
        _engineIsListening = isListeningFn;

  bool get isListening => _isListening || _engineIsListening();

  String? get lastErrorMessage => _lastErrorMessage;

  String localeIdForLanguage(String languageCode) {
    return languageCode.trim().toLowerCase() == 'hi' ? 'hi_IN' : 'en_IN';
  }

  Future<SttStartOutcome> startListening({
    required String languageCode,
    required void Function(String text) onPartialResult,
    required void Function(String text) onFinalResult,
  }) async {
    if (isListening) {
      return SttStartOutcome.busy;
    }

    _lastErrorMessage = null;
    var sawFinalResult = false;

    try {
      final initialized = await _initialize(
        onError: (errorMessage) {
          _lastErrorMessage = errorMessage.trim();
          _isListening = false;
        },
      );
      if (!initialized) {
        return await _hasPermission() ? SttStartOutcome.unavailable : SttStartOutcome.permissionDenied;
      }

      await _listen(
        onResult: (recognizedWords, isFinal) {
          final normalized = recognizedWords.trim();
          if (normalized.isEmpty) {
            return;
          }
          if (isFinal) {
            sawFinalResult = true;
            _isListening = false;
            onFinalResult(normalized);
            return;
          }
          onPartialResult(normalized);
        },
        localeId: localeIdForLanguage(languageCode),
        partialResults: true,
        listenFor: defaultListenWindow,
        pauseFor: defaultSilenceTimeout,
      );
      _isListening = !sawFinalResult;
      return SttStartOutcome.started;
    } catch (_) {
      _isListening = false;
      return await _hasPermission() ? SttStartOutcome.failed : SttStartOutcome.permissionDenied;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    try {
      await _stop();
    } catch (_) {
      return;
    }
  }

  Future<void> cancelListening() async {
    _isListening = false;
    try {
      await _cancel();
    } catch (_) {
      return;
    }
  }

  Future<void> dispose() async {
    await cancelListening();
  }
}

final sttServiceProvider = Provider<SttService>((ref) {
  final speech = SpeechToText();
  final service = SttService(
    initializeFn: ({required onError}) async {
      return speech.initialize(
        onError: (error) => onError(error.errorMsg),
      );
    },
    listenFn: ({
      required onResult,
      required localeId,
      required partialResults,
      required listenFor,
      required pauseFor,
    }) async {
      await speech.listen(
        onResult: (result) => onResult(result.recognizedWords, result.finalResult),
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        listenOptions: SpeechListenOptions(
          partialResults: partialResults,
        ),
      );
    },
    stopFn: () async {
      await speech.stop();
    },
    cancelFn: () async {
      await speech.cancel();
    },
    hasPermissionFn: () => speech.hasPermission,
    isListeningFn: () => speech.isListening,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
