part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Profile Photo & Identity Documents
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardIdentity on VerificationWizardController {
  Future<Result<void>> uploadProfilePhoto(ImageSource source) async {
    _setState(
      state.copyWith(
        uploadingDocumentType: VerificationDocumentType.profilePhoto,
        clearError: true,
        clearFieldError: 'profilePhoto',
      ),
      persistDraft: false,
    );

    final result = await _uploadHelper.uploadProfilePhoto(source: source);
    _applyDocumentUploadResult(
      result: result,
      wizardFieldKey: 'profilePhoto',
      applyPath: (path) => _setState(
        state.copyWith(draft: state.draft.copyWith(profilePhotoPath: path)),
        persistDraft: false,
      ),
    );

    return result.isSuccess && (result.valueOrNull ?? '').trim().isNotEmpty
        ? const Success(null)
        : Failure(result.failureOrNull ?? const ValidationFailure(message: 'Profile photo upload failed'));
  }

  void clearProfilePhoto() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(clearProfilePhoto: true),
      clearFieldError: 'profilePhoto',
    ));
  }

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
    final fieldKey = switch (type) {
      VerificationDocumentType.aadhaarFront => 'aadhaarFront',
      VerificationDocumentType.aadhaarBack => 'aadhaarBack',
      VerificationDocumentType.pan => 'panDocument',
      _ => 'document',
    };

    _setState(
      state.copyWith(
        uploadingDocumentType: type,
        clearError: true,
        clearFieldError: fieldKey,
      ),
      persistDraft: false,
    );

    final result = await _uploadHelper.uploadIdentityDoc(type: type, source: source);
    _applyDocumentUploadResult(
      result: result,
      wizardFieldKey: fieldKey,
      applyPath: (path) {
        switch (type) {
          case VerificationDocumentType.aadhaarFront:
            _setState(
              state.copyWith(draft: state.draft.copyWith(aadhaarFrontPath: path)),
              persistDraft: false,
            );
            break;
          case VerificationDocumentType.aadhaarBack:
            _setState(
              state.copyWith(draft: state.draft.copyWith(aadhaarBackPath: path)),
              persistDraft: false,
            );
            break;
          case VerificationDocumentType.pan:
            _setState(
              state.copyWith(draft: state.draft.copyWith(panDocumentPath: path)),
              persistDraft: false,
            );
            break;
          default:
            break;
        }
      },
    );

    return result.isSuccess && (result.valueOrNull ?? '').trim().isNotEmpty
        ? const Success(null)
        : Failure(result.failureOrNull ?? const ValidationFailure(message: 'Document upload failed'));
  }

  void clearIdentityDoc(VerificationDocumentType type) {
    final draft = state.draft;
    switch (type) {
      case VerificationDocumentType.aadhaarFront:
        _setState(state.copyWith(
          draft: draft.copyWith(clearAadhaarFront: true),
          clearFieldError: 'aadhaarFront',
        ));
        break;
      case VerificationDocumentType.aadhaarBack:
        _setState(state.copyWith(
          draft: draft.copyWith(clearAadhaarBack: true),
          clearFieldError: 'aadhaarBack',
        ));
        break;
      case VerificationDocumentType.pan:
        _setState(state.copyWith(
          draft: draft.copyWith(clearPanDocument: true),
          clearFieldError: 'panDocument',
        ));
        break;
      default:
        break;
    }
  }
}
