part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Supplier: Business Details
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardBusiness on VerificationWizardController {
  void updateCompanyName(String value) {
    _setState(state.copyWith(
      draft: state.draft.copyWith(companyName: value.trim()),
      clearFieldError: 'companyName',
    ));
  }

  void updateBusinessLicenseNumber(String value) {
    _setState(state.copyWith(
      draft: state.draft.copyWith(businessLicenseNumber: value.trim()),
      clearFieldError: 'businessLicenseNumber',
    ));
  }

  void updateGstNumber(String value) {
    final normalized = value.toUpperCase().trim();
    _setState(state.copyWith(
      draft: state.draft.copyWith(gstNumber: normalized),
    ));
  }

  Future<Result<void>> uploadBusinessLicense(ImageSource source) async {
    return _uploadBusinessDoc(
      type: VerificationDocumentType.businessLicence,
      source: source,
    );
  }

  Future<Result<void>> uploadGstCertificate(ImageSource source) async {
    return _uploadBusinessDoc(
      type: VerificationDocumentType.gstCertificate,
      source: source,
    );
  }

  Future<Result<void>> _uploadBusinessDoc({
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    final fieldKey = type == VerificationDocumentType.businessLicence
        ? 'businessLicense'
        : 'gstCertificate';

    _setState(
      state.copyWith(
        uploadingDocumentType: type,
        clearError: true,
        clearFieldError: fieldKey,
      ),
      persistDraft: false,
    );

    final result = await _uploadHelper.uploadBusinessDoc(type: type, source: source);
    _applyDocumentUploadResult(
      result: result,
      wizardFieldKey: fieldKey,
      applyPath: (path) {
        if (type == VerificationDocumentType.businessLicence) {
          _setState(
            state.copyWith(draft: state.draft.copyWith(businessLicensePath: path)),
            persistDraft: false,
          );
        } else {
          _setState(
            state.copyWith(draft: state.draft.copyWith(gstCertificatePath: path)),
            persistDraft: false,
          );
        }
      },
    );

    return result.isSuccess && (result.valueOrNull ?? '').trim().isNotEmpty
        ? const Success(null)
        : Failure(result.failureOrNull ?? const ValidationFailure(message: 'Document upload failed'));
  }

  void clearBusinessLicense() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(clearBusinessLicense: true),
      clearFieldError: 'businessLicense',
    ));
  }

  void clearGstCertificate() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(clearGstCertificate: true),
      clearFieldError: 'gstCertificate',
    ));
  }
}
