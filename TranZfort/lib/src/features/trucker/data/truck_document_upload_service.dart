import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/image_upload_service.dart';

class TruckDocumentUploadService {
  final SupabaseClient? _client;
  final Future<XFile?> Function(ImageSource source) _pickImage;
  final Future<Uint8List> Function(XFile file) _readBytes;
  final Uint8List? Function(Uint8List bytes) _compressImage;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;

  TruckDocumentUploadService(
    this._client, {
    Future<XFile?> Function(ImageSource source)? pickImageFn,
    Future<Uint8List> Function(XFile file)? readBytesFn,
    Uint8List? Function(Uint8List bytes)? compressImageFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
  })  : _pickImage = pickImageFn ?? ImageUploadServiceDefaults.pickImage,
        _readBytes = readBytesFn ?? ImageUploadServiceDefaults.readBytes,
        _compressImage = compressImageFn ?? ImageUploadServiceDefaults.compressImage,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary;

  Future<Result<String?>> pickCompressAndUploadRcDocument({
    required String ownerId,
    required String truckId,
    required ImageSource source,
  }) async {
    final normalizedOwnerId = ownerId.trim();
    final normalizedTruckId = truckId.trim();
    if (normalizedOwnerId.isEmpty || normalizedTruckId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Truck identity is required',
          fieldErrors: {
            'owner_id': 'Owner id is required',
            'truck_id': 'Truck id is required',
          },
        ),
      );
    }

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final storagePath = '$normalizedOwnerId/$normalizedTruckId/rc/rc_$timestamp.jpg';
    return ImageUploadWorkflow.pickCompressAndUpload(
      client: _client,
      source: source,
      pickImage: _pickImage,
      readBytes: _readBytes,
      compressImage: _compressImage,
      uploadBinary: _uploadBinary,
      storagePath: storagePath,
      invalidImageMessage: 'We could not prepare the RC image. Please try another photo.',
      storageFailureFallbackMessage: 'Unable to upload the RC document right now.',
    );
  }

  Future<Result<String?>> pickCompressAndUploadTruckPhoto({
    required String ownerId,
    required String truckId,
    required ImageSource source,
  }) async {
    final normalizedOwnerId = ownerId.trim();
    final normalizedTruckId = truckId.trim();
    if (normalizedOwnerId.isEmpty || normalizedTruckId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Truck identity is required',
          fieldErrors: {
            'owner_id': 'Owner id is required',
            'truck_id': 'Truck id is required',
          },
        ),
      );
    }

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final storagePath = '$normalizedOwnerId/$normalizedTruckId/photo/truck_photo_$timestamp.jpg';
    return ImageUploadWorkflow.pickCompressAndUpload(
      client: _client,
      source: source,
      pickImage: _pickImage,
      readBytes: _readBytes,
      compressImage: _compressImage,
      uploadBinary: _uploadBinary,
      storagePath: storagePath,
      invalidImageMessage: 'We could not prepare the truck photo. Please try another photo.',
      storageFailureFallbackMessage: 'Unable to upload the truck photo right now.',
    );
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('truck-documents').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
  }
}

final truckDocumentUploadServiceProvider = Provider<TruckDocumentUploadService>((ref) {
  return TruckDocumentUploadService(ref.watch(supabaseClientProvider));
});
