import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

class SupportAttachmentUploadService {
  final SupabaseClient? _client;
  final DateTime Function() _now;
  final Future<XFile?> Function(ImageSource source) _pickImage;
  final Future<Uint8List> Function(XFile file) _readBytes;
  final Uint8List? Function(Uint8List bytes) _compressImage;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;
  final Future<void> Function(SupabaseClient client, String oldPath, String newPath) _moveFile;

  SupportAttachmentUploadService(
    this._client, {
    DateTime Function()? nowFn,
    Future<XFile?> Function(ImageSource source)? pickImageFn,
    Future<Uint8List> Function(XFile file)? readBytesFn,
    Uint8List? Function(Uint8List bytes)? compressImageFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
    Future<void> Function(SupabaseClient client, String oldPath, String newPath)? moveFileFn,
  })  : _now = nowFn ?? DateTime.now,
        _pickImage = pickImageFn ?? _defaultPickImage,
        _readBytes = readBytesFn ?? _defaultReadBytes,
        _compressImage = compressImageFn ?? _defaultCompressImage,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary,
        _moveFile = moveFileFn ?? _defaultMoveFile;

  Future<Result<String?>> pickCompressAndUploadAttachment({
    required String profileId,
    required ImageSource source,
    String pathSegment = 'report_issue',
  }) async {
    final normalizedProfileId = profileId.trim();
    final normalizedPathSegment = pathSegment.trim().isEmpty ? 'report_issue' : pathSegment.trim();
    if (normalizedProfileId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Profile id is required',
          fieldErrors: {'profile_id': 'Profile id is required'},
        ),
      );
    }

    try {
      final file = await _pickImage(source);
      if (file == null) {
        return const Success<String?>(null);
      }

      final originalBytes = await _readBytes(file);
      final compressedBytes = _compressImage(originalBytes);
      if (compressedBytes == null || compressedBytes.isEmpty) {
        return const Failure<String?>(
          BusinessRuleFailure(message: 'We could not prepare the evidence image. Please try another photo.'),
        );
      }

      if (_client == null) {
        return const Failure<String?>(UnauthorizedFailure());
      }

      final timestamp = _now().toUtc().millisecondsSinceEpoch;
      final storagePath = '$normalizedProfileId/$normalizedPathSegment/evidence_$timestamp.jpg';
      await _uploadBinary(_client, storagePath, compressedBytes);
      return Success<String?>(storagePath);
    } on StorageException catch (error) {
      return Failure<String?>(
        ServerFailure(
          message: error.message.trim().isEmpty
              ? 'Unable to upload the report evidence right now. Please try again.'
              : error.message.trim(),
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

  Future<Result<String>> relocateAttachment({
    required String currentPath,
    required String targetPathSegment,
  }) async {
    final normalizedCurrentPath = currentPath.trim();
    final normalizedTargetSegment = targetPathSegment.trim();
    
    if (normalizedCurrentPath.isEmpty || normalizedTargetSegment.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Both current path and target segment are required',
          fieldErrors: {'paths': 'Both current path and target segment are required'},
        ),
      );
    }

    if (_client == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final parts = normalizedCurrentPath.split('/');
    if (parts.length < 3) {
      return const Failure<String>(
        BusinessRuleFailure(message: 'Cannot relocate an attachment with an invalid path format'),
      );
    }

    final profileId = parts[0];
    final filename = parts.last;
    final newPath = '$profileId/$normalizedTargetSegment/$filename';

    try {
      await _moveFile(_client, normalizedCurrentPath, newPath);
      return Success<String>(newPath);
    } on StorageException catch (error) {
      return Failure<String>(
        ServerFailure(
          message: error.message.trim().isEmpty
              ? 'Unable to finalize the attachment right now. Please try again.'
              : error.message.trim(),
          debugInfo: error.toString(),
        ),
      );
    } on FileSystemException catch (error) {
      return Failure<String>(NetworkFailure(debugInfo: error.toString()));
    } on TimeoutException catch (error) {
      return Failure<String>(NetworkFailure(debugInfo: error.toString()));
    } catch (error) {
      return Failure<String>(UnknownFailure(debugInfo: error.toString()));
    }
  }

  static Future<XFile?> _defaultPickImage(ImageSource source) {
    return ImagePicker().pickImage(source: source);
  }

  static Future<Uint8List> _defaultReadBytes(XFile file) {
    return file.readAsBytes();
  }

  static Uint8List? _defaultCompressImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: decoded.width > 1600 ? 1600 : decoded.width)
        : img.copyResize(decoded, height: decoded.height > 1600 ? 1600 : decoded.height);

    final encoded = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(encoded);
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('support-attachments').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
  }

  static Future<void> _defaultMoveFile(
    SupabaseClient client,
    String oldPath,
    String newPath,
  ) {
    return client.storage.from('support-attachments').move(oldPath, newPath);
  }
}

final supportAttachmentUploadServiceProvider = Provider<SupportAttachmentUploadService>((ref) {
  return SupportAttachmentUploadService(ref.watch(supabaseClientProvider));
});
