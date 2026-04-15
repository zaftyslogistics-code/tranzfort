import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../trucker/data/truck_document_upload_service.dart';
import '../data/verification_document_upload_service.dart';
import '../data/verification_repository.dart';

/// Helper class to handle document uploads for the verification wizard.
/// Extracted from VerificationWizardController to reduce file size.
class VerificationWizardUploadHelper {
  final VerificationRepository _repository;
  final VerificationDocumentUploadService _uploadService;
  final TruckDocumentUploadService _truckUploadService;
  final String? _currentUserId;

  VerificationWizardUploadHelper({
    required VerificationRepository repository,
    required VerificationDocumentUploadService uploadService,
    required TruckDocumentUploadService truckUploadService,
    required String? currentUserId,
  })  : _repository = repository,
        _uploadService = uploadService,
        _truckUploadService = truckUploadService,
        _currentUserId = currentUserId;

  /// Upload identity document (Aadhaar front/back, PAN)
  Future<Result<String?>> uploadIdentityDoc({
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    return _pickCompressAndUpload(type: type, source: source);
  }

  /// Upload truck RC document
  Future<Result<String?>> uploadTruckRcDocument({
    required ImageSource source,
  }) async {
    if (_currentUserId == null) {
      return Failure(UnauthorizedFailure());
    }

    return _truckUploadService.pickCompressAndUploadRcDocument(
      ownerId: _currentUserId,
      truckId: 'draft-truck',
      source: source,
    );
  }

  /// Upload truck photo
  Future<Result<String?>> uploadTruckPhoto({
    required ImageSource source,
  }) async {
    if (_currentUserId == null) {
      return Failure(UnauthorizedFailure());
    }

    return _truckUploadService.pickCompressAndUploadTruckPhoto(
      ownerId: _currentUserId,
      truckId: 'draft-truck',
      source: source,
    );
  }

  /// Upload business document (license or GST certificate)
  Future<Result<String?>> uploadBusinessDoc({
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    return _pickCompressAndUpload(type: type, source: source);
  }

  /// Upload profile photo
  Future<Result<String?>> uploadProfilePhoto({
    required ImageSource source,
  }) async {
    return _pickCompressAndUpload(
      type: VerificationDocumentType.profilePhoto,
      source: source,
    );
  }

  /// Core upload method that handles pick, compress, and upload
  Future<Result<String?>> _pickCompressAndUpload({
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    if (_currentUserId == null) {
      return Failure(UnauthorizedFailure());
    }

    final uploadResult = await _uploadService.pickCompressAndUploadDocument(
      profileId: _currentUserId,
      type: type,
      source: source,
    );

    if (uploadResult.isFailure) {
      return Failure(uploadResult.failureOrNull!);
    }

    final path = uploadResult.valueOrNull;
    if (path == null) {
      return const Success(null);
    }

    // Truck documents don't need to be saved to repository separately
    if (type == VerificationDocumentType.truckRc ||
        type == VerificationDocumentType.truckPhoto) {
      return Success(path);
    }

    // Save document path to repository for other document types
    final saveResult = await _repository.saveDocumentPath(type: type, storagePath: path);
    if (saveResult.isFailure) {
      return Failure(saveResult.failureOrNull!);
    }

    return Success(path);
  }
}
