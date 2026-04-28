part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Profile Photo & Identity Documents
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardIdentity on VerificationWizardController {
  // Profile Photo
  Future<Result<void>> uploadProfilePhoto(ImageSource source) async {
    _setState(state.copyWith(
      uploadingDocumentType: VerificationDocumentType.profilePhoto,
      clearError: true,
    ));

    final result = await _uploadHelper.uploadProfilePhoto(source: source);

    if (result.isSuccess) {
      _setState(state.copyWith(
        draft: state.draft.copyWith(profilePhotoPath: result.valueOrNull),
        clearUploadingDocumentType: true,
        clearFieldError: 'profilePhoto',
      ));
      return const Success(null);
    }

    _setState(state.copyWith(
      clearUploadingDocumentType: true,
      error: result.failureOrNull,
    ), persistDraft: false);
    return Failure(result.failureOrNull!);
  }

  void clearProfilePhoto() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(profilePhotoPath: null),
    ));
  }

  // Identity Numbers
  void updateAadhaarNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'\s'), '').trim();
    _setState(state.copyWith(
      draft: state.draft.copyWith(aadhaarNumber: normalized),
      clearFieldError: 'aadhaarNumber',
    ));
  }

  void updatePanNumber(String value) {
    final normalized = value.toUpperCase().trim();
    _setState(state.copyWith(
      draft: state.draft.copyWith(panNumber: normalized),
      clearFieldError: 'panNumber',
    ));
  }

  // Identity Documents
  Future<Result<void>> uploadAadhaarFront(ImageSource source) async {
    return _uploadIdentityDoc(VerificationDocumentType.aadhaarFront, source);
  }

  Future<Result<void>> uploadAadhaarBack(ImageSource source) async {
    return _uploadIdentityDoc(VerificationDocumentType.aadhaarBack, source);
  }

  Future<Result<void>> uploadPan(ImageSource source) async {
    return _uploadIdentityDoc(VerificationDocumentType.pan, source);
  }

  Future<Result<void>> _uploadIdentityDoc(VerificationDocumentType type, ImageSource source) async {
    _setState(state.copyWith(uploadingDocumentType: type, clearError: true));

    final result = await _uploadHelper.uploadIdentityDoc(type: type, source: source);

    if (result.isSuccess) {
      final path = result.valueOrNull;
      switch (type) {
        case VerificationDocumentType.aadhaarFront:
          _setState(state.copyWith(
            draft: state.draft.copyWith(aadhaarFrontPath: path),
            clearUploadingDocumentType: true,
            clearFieldError: 'aadhaarFront',
          ));
          break;
        case VerificationDocumentType.aadhaarBack:
          _setState(state.copyWith(
            draft: state.draft.copyWith(aadhaarBackPath: path),
            clearUploadingDocumentType: true,
            clearFieldError: 'aadhaarBack',
          ));
          break;
        case VerificationDocumentType.pan:
          _setState(state.copyWith(
            draft: state.draft.copyWith(panDocumentPath: path),
            clearUploadingDocumentType: true,
            clearFieldError: 'panDocument',
          ));
          break;
        default:
          _setState(state.copyWith(clearUploadingDocumentType: true));
          break;
      }
      return const Success(null);
    }

    _setState(
      state.copyWith(
        clearUploadingDocumentType: true,
        error: result.failureOrNull,
      ),
      persistDraft: false,
    );
    return Failure(result.failureOrNull!);
  }

  void clearIdentityDoc(VerificationDocumentType type) {
    final draft = state.draft;
    switch (type) {
      case VerificationDocumentType.aadhaarFront:
        _setState(state.copyWith(draft: draft.copyWith(aadhaarFrontPath: null)));
        break;
      case VerificationDocumentType.aadhaarBack:
        _setState(state.copyWith(draft: draft.copyWith(aadhaarBackPath: null)));
        break;
      case VerificationDocumentType.pan:
        _setState(state.copyWith(draft: draft.copyWith(panDocumentPath: null)));
        break;
      default:
        break;
    }
  }
}
