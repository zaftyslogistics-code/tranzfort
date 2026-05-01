import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/image_upload_service.dart';

class TripProofUploadService {
  final SupabaseClient? _client;
  final Future<XFile?> Function(ImageSource source) _pickImage;
  final Future<Uint8List> Function(XFile file) _readBytes;
  final Uint8List? Function(Uint8List bytes) _compressImage;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;

  TripProofUploadService(
    this._client, {
    Future<XFile?> Function(ImageSource source)? pickImageFn,
    Future<Uint8List> Function(XFile file)? readBytesFn,
    Uint8List? Function(Uint8List bytes)? compressImageFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
  })  : _pickImage = pickImageFn ?? ImageUploadServiceDefaults.pickImage,
        _readBytes = readBytesFn ?? ImageUploadServiceDefaults.readBytes,
        _compressImage = compressImageFn ?? ImageUploadServiceDefaults.compressImage,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary;

  Future<Result<String?>> pickCompressAndUploadPod({
    required String tripId,
    required ImageSource source,
    bool enableAutoCompletion = true,
  }) async {
    final uploadResult = await _pickCompressAndUploadProof(
      tripId: tripId,
      source: source,
      storageFilename: 'pod.jpg',
      invalidImageMessage: 'We could not prepare the POD image. Please try another photo.',
    );

    // Enable auto-completion after successful POD upload
    if (uploadResult.isSuccess && enableAutoCompletion) {
      await _enableTripAutoCompletion(tripId);
    }

    return uploadResult;
  }

  Future<Result<String?>> pickCompressAndUploadLr({
    required String tripId,
    required ImageSource source,
  }) async {
    return _pickCompressAndUploadProof(
      tripId: tripId,
      source: source,
      storageFilename: 'lr.jpg',
      invalidImageMessage: 'We could not prepare the LR image. Please try another photo.',
    );
  }

  Future<Result<String?>> _pickCompressAndUploadProof({
    required String tripId,
    required ImageSource source,
    required String storageFilename,
    required String invalidImageMessage,
  }) async {
    final normalizedTripId = tripId.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }

    final storagePath = '$normalizedTripId/$storageFilename';
    return ImageUploadWorkflow.pickCompressAndUpload(
      client: _client,
      source: source,
      pickImage: _pickImage,
      readBytes: _readBytes,
      compressImage: _compressImage,
      uploadBinary: _uploadBinary,
      storagePath: storagePath,
      invalidImageMessage: invalidImageMessage,
      storageFailureFallbackMessage: 'Unable to upload proof right now. Please try again.',
    );
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('trip-proof-documents').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
  }

  /// Enable auto-completion for a trip after POD upload
  Future<void> _enableTripAutoCompletion(String tripId) async {
    if (_client == null) return;

    try {
      await _client.rpc(
        'enable_trip_auto_completion',
        params: <String, dynamic>{
          'p_trip_id': tripId.trim(),
          'p_completion_window_hours': 24, // 24-hour default
        },
      );
    } catch (e) {
      // Log error but don't fail the upload if auto-completion fails
      // Auto-completion is a nice-to-have feature
      AppLogger.warning('Failed to enable auto-completion for trip $tripId', error: e);
    }
  }
}

final tripProofUploadServiceProvider = Provider<TripProofUploadService>((ref) {
  return TripProofUploadService(ref.watch(supabaseClientProvider));
});
