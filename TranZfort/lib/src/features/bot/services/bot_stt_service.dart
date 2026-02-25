import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/error/result.dart';
import '../../../core/error/app_failure.dart';

class BotSttState {
  final bool isListening;
  final String partialTranscript;
  final AppFailureType? lastError;

  const BotSttState({
    this.isListening = false,
    this.partialTranscript = '',
    this.lastError,
  });

  BotSttState copyWith({
    bool? isListening,
    String? partialTranscript,
    AppFailureType? lastError,
    bool clearError = false,
  }) {
    return BotSttState(
      isListening: isListening ?? this.isListening,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class BotSttNotifier extends StateNotifier<BotSttState> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  BotSttNotifier() : super(const BotSttState());

  Future<Result<void>> startListening(void Function(String) onFinalResult) async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onError: (e) {
          state = state.copyWith(
            isListening: false,
            lastError: AppFailureType.unknown,
          );
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );
    }

    if (!_isInitialized) {
      state = state.copyWith(lastError: AppFailureType.forbidden);
      return const Failure(AppFailureType.forbidden, debugMessage: 'Microphone permission denied');
    }

    state = state.copyWith(isListening: true, partialTranscript: '', clearError: true);

    await _speechToText.listen(
      localeId: 'hi_IN', // Default to Hindi as per rules
      pauseFor: const Duration(seconds: 15),
      onResult: (result) {
        state = state.copyWith(partialTranscript: result.recognizedWords);
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        }
      },
    );

    return const Success(null);
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }
}

final botSttProvider = StateNotifierProvider<BotSttNotifier, BotSttState>((ref) {
  return BotSttNotifier();
});
