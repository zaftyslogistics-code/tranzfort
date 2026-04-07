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
import 'verification_repository.dart';

class VerificationDocumentUploadService {
  final SupabaseClient? _client;
  final Future<XFile?> Function(ImageSource source) _pickImage;
  final Future<Uint8List> Function(XFile file) _readBytes;
  final Uint8List? Function(Uint8List bytes) _compressImage;
  final Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes) _uploadBinary;

  VerificationDocumentUploadService(
    this._client, {
    Future<XFile?> Function(ImageSource source)? pickImageFn,
    Future<Uint8List> Function(XFile file)? readBytesFn,
    Uint8List? Function(Uint8List bytes)? compressImageFn,
    Future<void> Function(SupabaseClient client, String storagePath, Uint8List bytes)? uploadBinaryFn,
  })  : _pickImage = pickImageFn ?? _defaultPickImage,
        _readBytes = readBytesFn ?? _defaultReadBytes,
        _compressImage = compressImageFn ?? _defaultCompressImage,
        _uploadBinary = uploadBinaryFn ?? _defaultUploadBinary;

  Future<Result<String?>> pickCompressAndUploadDocument({
    required String profileId,
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    final normalizedProfileId = profileId.trim();
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
        return Failure<String?>(
          BusinessRuleFailure(message: 'We could not prepare the ${type.label.toLowerCase()} image. Please try another photo.'),
        );
      }

      if (_client == null) {
        return const Failure<String?>(UnauthorizedFailure());
      }

      final storagePath = '$normalizedProfileId/${_documentFolder(type)}/${_documentFilename(type)}';
      await _uploadBinary(_client, storagePath, compressedBytes);
      return Success<String?>(storagePath);
    } on StorageException catch (error) {
      return Failure<String?>(
        ServerFailure(
          message: error.message.trim().isEmpty
              ? 'Unable to upload the verification document right now. Please try again.'
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
        ? img.copyResize(decoded, width: decoded.width > 1200 ? 1200 : decoded.width)
        : img.copyResize(decoded, height: decoded.height > 1200 ? 1200 : decoded.height);

    final encoded = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(encoded);
  }

  static Future<void> _defaultUploadBinary(
    SupabaseClient client,
    String storagePath,
    Uint8List bytes,
  ) {
    return client.storage.from('verification-documents').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
  }

  static String _documentFolder(VerificationDocumentType type) {
    return switch (type) {
      VerificationDocumentType.aadhaarFront => 'aadhaar_front',
      VerificationDocumentType.aadhaarBack => 'aadhaar_back',
      VerificationDocumentType.pan => 'pan',
      VerificationDocumentType.profilePhoto => 'profile_photo',
      VerificationDocumentType.businessLicence => 'business_licence',
      VerificationDocumentType.gstCertificate => 'gst_certificate',
      VerificationDocumentType.truckRc => 'truck_rc',
      VerificationDocumentType.truckPhoto => 'truck_photo',
    };
  }

  static String _documentFilename(VerificationDocumentType type) {
    return switch (type) {
      VerificationDocumentType.aadhaarFront => 'aadhaar_front.jpg',
      VerificationDocumentType.aadhaarBack => 'aadhaar_back.jpg',
      VerificationDocumentType.pan => 'pan.jpg',
      VerificationDocumentType.profilePhoto => 'profile_photo.jpg',
      VerificationDocumentType.businessLicence => 'business_licence.jpg',
      VerificationDocumentType.gstCertificate => 'gst_certificate.jpg',
      VerificationDocumentType.truckRc => 'truck_rc.jpg',
      VerificationDocumentType.truckPhoto => 'truck_photo.jpg',
    };
  }
}

final verificationDocumentUploadServiceProvider = Provider<VerificationDocumentUploadService>((ref) {
  return VerificationDocumentUploadService(ref.watch(supabaseClientProvider));
});
