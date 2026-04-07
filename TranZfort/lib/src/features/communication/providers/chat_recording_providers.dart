import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/voice_message_service.dart';

class VoiceRecordingState {
  final bool isRecording;
  final int elapsedSeconds;
  final AppFailure? failure;

  const VoiceRecordingState({
    required this.isRecording,
    required this.elapsedSeconds,
    required this.failure,
  });

  factory VoiceRecordingState.initial() {
    return const VoiceRecordingState(
      isRecording: false,
      elapsedSeconds: 0,
      failure: null,
    );
  }

  VoiceRecordingState copyWith({
    bool? isRecording,
    int? elapsedSeconds,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class VoiceRecordingController extends StateNotifier<VoiceRecordingState> {
  final VoiceMessageService _voiceMessageService;
  final String _conversationId;
  Timer? _recordingTimer;

  VoiceRecordingController(this._voiceMessageService, this._conversationId)
      : super(VoiceRecordingState.initial());

  Future<Result<void>> startRecording() async {
    final result = await _voiceMessageService.startRecording(
      conversationId: _conversationId,
    );
    if (result.isFailure) {
      state = state.copyWith(failure: result.failureOrNull);
      return result;
    }

    _recordingTimer?.cancel();
    state = state.copyWith(
      isRecording: true,
      elapsedSeconds: 0,
      clearFailure: true,
    );
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
    return result;
  }

  Future<Result<VoiceMessageUpload>> stopAndUpload() async {
    _recordingTimer?.cancel();
    state = state.copyWith(isRecording: false, clearFailure: true);
    final result = await _voiceMessageService.stopAndUpload(
      conversationId: _conversationId,
    );
    if (result.isFailure) {
      state = state.copyWith(
        elapsedSeconds: 0,
        failure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(
      elapsedSeconds: 0,
      clearFailure: true,
    );
    return result;
  }

  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    await _voiceMessageService.cancelRecording();
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isRecording: false,
      elapsedSeconds: 0,
      clearFailure: true,
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}

final voiceRecordingProvider = StateNotifierProvider.autoDispose
    .family<VoiceRecordingController, VoiceRecordingState, String>((ref, conversationId) {
  return VoiceRecordingController(
    ref.watch(voiceMessageServiceProvider),
    conversationId,
  );
});
