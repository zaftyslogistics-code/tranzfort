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
    _setState(state.copyWith(uploadingDocumentType: type, clearError: true));

    final result = await _uploadHelper.uploadBusinessDoc(type: type, source: source);

    if (result.isSuccess) {
      final path = result.valueOrNull;
      if (type == VerificationDocumentType.businessLicence) {
        _setState(state.copyWith(
          draft: state.draft.copyWith(businessLicensePath: path),
        ));
      } else {
        _setState(state.copyWith(
          draft: state.draft.copyWith(gstCertificatePath: path),
        ));
      }
    } else {
      _setState(
        state.copyWith(error: result.failureOrNull),
        persistDraft: false,
      );
    }

    _setState(
      state.copyWith(clearUploadingDocumentType: true),
      persistDraft: result.isSuccess,
    );
    return result.isSuccess ? const Success(null) : Failure(result.failureOrNull!);
  }

  void clearBusinessLicense() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(businessLicensePath: null),
    ));
  }

  void clearGstCertificate() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(gstCertificatePath: null),
    ));
  }
}
