import 'dart:async';
import 'dart:io';
import 'dart:ui' show decodeImageFromList, Image;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/image_upload_service.dart';
import 'verification_repository.dart';

class VerificationDocumentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSizeBytes;
  final String? detectedMimeType;
  final ({int width, int height})? dimensions;

  const VerificationDocumentValidationResult.valid({
    this.fileSizeBytes,
    this.detectedMimeType,
    this.dimensions,
  })  : isValid = true,
        errorMessage = null;

  const VerificationDocumentValidationResult.invalid(this.errorMessage)
      : isValid = false,
        fileSizeBytes = null,
        detectedMimeType = null,
        dimensions = null;
}

class VerificationDocumentUploadService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int minImageWidth = 800;
  static const int minImageHeight = 600;
  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/png'];

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

  Future<VerificationDocumentValidationResult> validateDocument(XFile file, Uint8List bytes) async {
    if (bytes.length > maxFileSizeBytes) {
      return const VerificationDocumentValidationResult.invalid(
        'Document exceeds 10 MB limit. Please use a smaller image or compress it.',
      );
    }

    final mimeType = ImageUploadServiceDefaults.resolveImageMimeType(file, bytes, allowedMimeTypes: allowedMimeTypes);
    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      return const VerificationDocumentValidationResult.invalid(
        'Document must be a JPEG or PNG image. Please select a valid image file.',
      );
    }

    try {
      final decodedImage = await _decodeImageFromList(bytes);
      if (decodedImage.width < minImageWidth || decodedImage.height < minImageHeight) {
        return VerificationDocumentValidationResult.invalid(
          'Document resolution too low (${decodedImage.width}x${decodedImage.height}). '
          'Minimum required: ${minImageWidth}x$minImageHeight.',
        );
      }
      return VerificationDocumentValidationResult.valid(
        fileSizeBytes: bytes.length,
        detectedMimeType: mimeType,
        dimensions: (width: decodedImage.width, height: decodedImage.height),
      );
    } catch (_) {
      return const VerificationDocumentValidationResult.invalid(
        'Unable to read the selected image. Please try a different photo.',
      );
    }
  }

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
      final permissionFailure = await _ensureImageAccessPermission(source);
      if (permissionFailure != null) {
        return Failure<String?>(permissionFailure);
      }

      final file = await _pickImage(source);
      if (file == null) {
        return const Success<String?>(null);
      }

      final originalBytes = await _readBytes(file);
      final validation = await validateDocument(file, originalBytes);
      if (!validation.isValid) {
        return Failure<String?>(
          ValidationFailure(
            message: validation.errorMessage ?? 'Document validation failed.',
            fieldErrors: {_documentFieldKey(type): validation.errorMessage ?? 'Invalid document'},
          ),
        );
      }

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

  Future<AppFailure?> _ensureImageAccessPermission(ImageSource source) async {
    if (kIsWeb) {
      return null;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      return null;
    }

    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return null;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) {
      return null;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionFailure(
        message: source == ImageSource.camera
            ? 'Camera permission is required to take a photo. Enable it in app settings and try again.'
            : 'Photo access is required to choose an image. Enable it in app settings and try again.',
      );
    }

    return PermissionFailure(
      message: source == ImageSource.camera
          ? 'Camera permission was denied. Please allow camera access to continue.'
          : 'Photo access was denied. Please allow photo access to continue.',
    );
  }

  static Future<XFile?> _defaultPickImage(ImageSource source) async {
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

  static String _documentFieldKey(VerificationDocumentType type) {
    return switch (type) {
      VerificationDocumentType.aadhaarFront => 'aadhaar_front_document_path',
      VerificationDocumentType.aadhaarBack => 'aadhaar_back_document_path',
      VerificationDocumentType.pan => 'pan_document_path',
      VerificationDocumentType.profilePhoto => 'profile_photo_document_path',
      VerificationDocumentType.businessLicence => 'business_licence_document_path',
      VerificationDocumentType.gstCertificate => 'gst_certificate_document_path',
      VerificationDocumentType.truckRc => 'truck_rc_document_path',
      VerificationDocumentType.truckPhoto => 'truck_photo_document_path',
    };
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

  /// Wraps dart:ui decodeImageFromList callback-based API in a Future
  static Future<Image> _decodeImageFromList(Uint8List bytes) async {
    final completer = Completer<Image>();
    decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

}

final verificationDocumentUploadServiceProvider = Provider<VerificationDocumentUploadService>((ref) {
  return VerificationDocumentUploadService(ref.watch(supabaseClientProvider));
});
