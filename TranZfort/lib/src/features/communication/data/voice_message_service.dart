import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';

// C-006: Error codes for localization (UI should map these to AppLocalizations)
class VoiceMessageErrorCodes {
  static const String conversationIdRequired = 'chat.voice_conversation_id_required';
  static const String recordingAlreadyInProgress = 'chat.voice_recording_already_in_progress';
  static const String microphonePermissionRequired = 'chat.voice_microphone_permission_required';
  static const String noActiveRecording = 'chat.voice_no_active_recording';
}

class VoiceMessageUpload {
  final String messageId;
  final String attachmentPath;
  final int durationSeconds;

  const VoiceMessageUpload({
    required this.messageId,
    required this.attachmentPath,
    required this.durationSeconds,
  });
}

class VoiceMessageService {
  final SupabaseClient? _client;
  final AudioRecorder Function() _recorderFactory;
  final Future<Uint8List> Function(String path) _readBytes;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;
  final Future<void> Function(String path) _deleteFile;
  final DateTime Function() _now;
  final String Function() _newId;

  AudioRecorder? _recorder;
  String? _activeConversationId;
  String? _activeFilePath;
  DateTime? _startedAt;

  VoiceMessageService(
    this._client, {
    AudioRecorder Function()? recorderFactory,
    Future<Uint8List> Function(String path)? readBytesFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
    Future<void> Function(String path)? deleteFileFn,
    DateTime Function()? nowFn,
    String Function()? newIdFn,
  })  : _recorderFactory = recorderFactory ?? AudioRecorder.new,
        _readBytes = readBytesFn ?? _defaultReadBytes,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary,
        _deleteFile = deleteFileFn ?? _defaultDeleteFile,
        _now = nowFn ?? DateTime.now,
        _newId = newIdFn ?? (() => const Uuid().v4());

  Future<Result<void>> startRecording({required String conversationId}) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to VoiceMessageErrorCodes.conversationIdRequired in UI layer
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }
    if (_activeConversationId != null) {
      return const Failure<void>(
        // TODO: Map to VoiceMessageErrorCodes.recordingAlreadyInProgress in UI layer
        BusinessRuleFailure(message: 'A voice recording is already in progress.'),
      );
    }

    final recorder = _recorderFactory();
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        await recorder.dispose();
        return const Failure<void>(
          // TODO: Map to VoiceMessageErrorCodes.microphonePermissionRequired in UI layer
          PermissionFailure(message: 'Microphone permission is required to record a voice message.'),
        );
      }

      final tempFilePath = '${Directory.systemTemp.path}${Platform.pathSeparator}${_newId()}.m4a';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: tempFilePath,
      );
      _recorder = recorder;
      _activeConversationId = normalizedConversationId;
      _activeFilePath = tempFilePath;
      _startedAt = _now();
      return const Success<void>(null);
    } catch (error) {
      await recorder.dispose();
      return Failure<void>(_mapRecordingError(error));
    }
  }

  Future<Result<VoiceMessageUpload>> stopAndUpload({required String conversationId}) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) {
      return const Failure<VoiceMessageUpload>(
        ValidationFailure(
          // TODO: Map to VoiceMessageErrorCodes.conversationIdRequired in UI layer
          message: 'Conversation id is required',
          fieldErrors: {'conversation_id': 'Conversation id is required'},
        ),
      );
    }
    if (_activeConversationId != normalizedConversationId || _recorder == null || _startedAt == null) {
      return const Failure<VoiceMessageUpload>(
        // TODO: Map to VoiceMessageErrorCodes.noActiveRecording in UI layer
        BusinessRuleFailure(message: 'No active voice recording is available for this conversation.'),
      );
    }
    if (_client == null) {
      await cancelRecording();
      return const Failure<VoiceMessageUpload>(UnauthorizedFailure());
    }

    final recorder = _recorder!;
    final startedAt = _startedAt!;
    try {
      final filePath = await recorder.stop() ?? _activeFilePath;
      final durationSeconds = _now().difference(startedAt).inSeconds;
      if (durationSeconds <= 0) {
        await _cleanup();
        return const Failure<VoiceMessageUpload>(
          BusinessRuleFailure(message: 'Voice recording was too short. Please try again.'),
        );
      }
      if (durationSeconds > 120) {
        await _cleanup(pathOverride: filePath);
        return const Failure<VoiceMessageUpload>(
          BusinessRuleFailure(message: 'Voice message cannot exceed 2 minutes.'),
        );
      }
      if (filePath == null || filePath.trim().isEmpty) {
        await _cleanup();
        return const Failure<VoiceMessageUpload>(UnknownFailure(message: 'Recorded audio file is unavailable.'));
      }

      final bytes = await _readBytes(filePath);
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        await _cleanup(pathOverride: filePath);
        return const Failure<VoiceMessageUpload>(
          BusinessRuleFailure(message: 'Voice message cannot exceed 5MB.'),
        );
      }

      final messageId = _newId();
      final storagePath = '$normalizedConversationId/$messageId.m4a';
      await _uploadBinary(_client, storagePath, bytes);
      await _cleanup(pathOverride: filePath);
      return Success<VoiceMessageUpload>(
        VoiceMessageUpload(
          messageId: messageId,
          attachmentPath: storagePath,
          durationSeconds: durationSeconds,
        ),
      );
    } catch (error) {
      await _cleanup();
      return Failure<VoiceMessageUpload>(_mapRecordingError(error));
    }
  }

  Future<void> cancelRecording() async {
    final recorder = _recorder;
    if (recorder != null) {
      try {
        await recorder.cancel();
      } catch (e) {
        AppLogger.warning('Failed to cancel voice recorder', scope: 'voice', error: e);
      }
    }
    await _cleanup();
  }

  Future<void> _cleanup({String? pathOverride}) async {
    final filePath = pathOverride ?? _activeFilePath;
    final recorder = _recorder;
    _recorder = null;
    _activeConversationId = null;
    _activeFilePath = null;
    _startedAt = null;

    if (recorder != null) {
      try {
        await recorder.dispose();
      } catch (e) {
        AppLogger.warning('Failed to dispose voice recorder', scope: 'voice', error: e);
      }
    }
    if (filePath != null && filePath.trim().isNotEmpty) {
      try {
        await _deleteFile(filePath);
      } catch (e) {
        AppLogger.warning('Failed to delete voice file', scope: 'voice', error: e);
      }
    }
  }

  AppFailure _mapRecordingError(Object error) {
    if (error is StorageException) {
      return ServerFailure(
        message: error.message.trim().isEmpty ? 'Unable to upload voice message right now. Please try again.' : error.message.trim(),
        debugInfo: error.toString(),
      );
    }
    if (error is FileSystemException || error is TimeoutException) {
      return NetworkFailure(debugInfo: error.toString());
    }
    return UnknownFailure(debugInfo: error.toString());
  }

  static Future<Uint8List> _defaultReadBytes(String path) {
    return File(path).readAsBytes();
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('communication-media').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/mp4',
            upsert: true,
          ),
        );
  }

  static Future<void> _defaultDeleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final voiceMessageServiceProvider = Provider<VoiceMessageService>((ref) {
  return VoiceMessageService(ref.watch(supabaseClientProvider));
});
