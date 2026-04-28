import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/image_upload_service.dart';

class RcDocumentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSizeBytes;
  final String? detectedMimeType;
  final ({int width, int height})? dimensions;

  const RcDocumentValidationResult.valid({
    this.fileSizeBytes,
    this.detectedMimeType,
    this.dimensions,
  })  : isValid = true,
        errorMessage = null;

  const RcDocumentValidationResult.invalid(this.errorMessage)
      : isValid = false,
        fileSizeBytes = null,
        detectedMimeType = null,
        dimensions = null;
}

class TruckDocumentUploadService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int minImageWidth = 800;
  static const int minImageHeight = 600;
  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/png'];
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

  Future<RcDocumentValidationResult> validateRcDocument(XFile file, Uint8List bytes) async {
    if (bytes.length > maxFileSizeBytes) {
      return const RcDocumentValidationResult.invalid(
        'RC document exceeds 10 MB limit. Please use a smaller image or compress it.',
      );
    }

    final mimeType = file.mimeType;
    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      return const RcDocumentValidationResult.invalid(
        'RC document must be a JPEG or PNG image. Please select a valid image file.',
      );
    }

    try {
      final decodedImage = await decodeImageFromList(bytes);
      if (decodedImage.width < minImageWidth || decodedImage.height < minImageHeight) {
        return RcDocumentValidationResult.invalid(
          'RC document resolution too low (${decodedImage.width}x${decodedImage.height}). '
          'Minimum required: ${minImageWidth}x$minImageHeight.',
        );
      }
      return RcDocumentValidationResult.valid(
        fileSizeBytes: bytes.length,
        detectedMimeType: mimeType,
        dimensions: (width: decodedImage.width, height: decodedImage.height),
      );
    } catch (_) {
      return const RcDocumentValidationResult.invalid(
        'Unable to read the selected image. Please try a different photo.',
      );
    }
  }

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

    final picked = await _pickImage(source);
    if (picked == null) {
      return const Success<String?>(null);
    }

    final originalBytes = await _readBytes(picked);
    final validation = await validateRcDocument(picked, originalBytes);
    if (!validation.isValid) {
      return Failure<String?>(
        ValidationFailure(
          message: validation.errorMessage ?? 'RC document validation failed.',
          fieldErrors: {'rc_document_path': validation.errorMessage ?? 'Invalid document'},
        ),
      );
    }

    final compressedBytes = _compressImage(originalBytes);
    if (compressedBytes == null || compressedBytes.isEmpty) {
      return const Failure<String?>(
        BusinessRuleFailure(message: 'We could not prepare the RC image. Please try another photo.'),
      );
    }

    if (_client == null) {
      return const Failure<String?>(UnauthorizedFailure());
    }

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final storagePath = '$normalizedOwnerId/$normalizedTruckId/rc/rc_$timestamp.jpg';

    try {
      await _uploadBinary(_client!, storagePath, compressedBytes);
      return Success<String?>(storagePath);
    } on StorageException catch (error) {
      return Failure<String?>(
        ServerFailure(
          message: error.message.trim().isEmpty ? 'Unable to upload the RC document right now.' : error.message.trim(),
          debugInfo: error.toString(),
        ),
      );
    } on FileSystemException catch (error) {
      return Failure<String?>(NetworkFailure(debugInfo: error.toString()));
    } on TimeoutException catch (error) {
      return Failure<String?>(NetworkFailure(debugInfo: error.toString()));
    } catch (error) {
      return Failure<String?>(UnknownFailure(debugInfo: error.toString()));
    }
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
