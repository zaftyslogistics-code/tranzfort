part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Trucker: Truck Draft
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardTruck on VerificationWizardController {
  void updateTruckNumber(String value) {
    final normalized = value.toUpperCase().trim();
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(truckNumber: normalized),
      ),
      clearFieldError: 'truckNumber',
    ));
  }

  void updateTruckBodyType(String value) {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(bodyType: value),
      ),
    ));
  }

  void updateTruckTyres(int value) {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(tyres: value),
      ),
    ));
  }

  void updateTruckCapacity(String value) {
    final capacity = double.tryParse(value.trim()) ?? 0;
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(capacityTonnes: capacity),
      ),
    ));
  }

  Future<Result<void>> uploadTruckRcDocument(ImageSource source) async {
    _setState(state.copyWith(
      uploadingDocumentType: VerificationDocumentType.truckRc,
      clearError: true,
    ));

    if (_currentUserId == null) {
      final failure = UnauthorizedFailure();
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          error: failure,
        ),
        persistDraft: false,
      );
      return Failure(failure);
    }

    final result = await _uploadHelper.uploadTruckRcDocument(source: source);

    if (result.isSuccess) {
      final truck = state.draft.truck ?? TruckDraft();
      _setState(state.copyWith(
        draft: state.draft.copyWith(
          truck: truck.copyWith(rcDocumentPath: result.valueOrNull),
        ),
        clearUploadingDocumentType: true,
        clearFieldError: 'rcDocument',
      ));
    } else {
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          error: result.failureOrNull,
        ),
        persistDraft: false,
      );
    }

    return result.isSuccess ? const Success(null) : Failure(result.failureOrNull!);
  }

  Future<Result<void>> uploadTruckPhoto(ImageSource source) async {
    _setState(state.copyWith(
      uploadingDocumentType: VerificationDocumentType.truckPhoto,
      clearError: true,
    ));

    if (_currentUserId == null) {
      final failure = UnauthorizedFailure();
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          error: failure,
        ),
        persistDraft: false,
      );
      return Failure(failure);
    }

    final result = await _uploadHelper.uploadTruckPhoto(source: source);

    if (result.isSuccess) {
      final truck = state.draft.truck ?? TruckDraft();
      _setState(state.copyWith(
        draft: state.draft.copyWith(
          truck: truck.copyWith(truckPhotoPath: result.valueOrNull),
        ),
        clearUploadingDocumentType: true,
      ));
    } else {
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          error: result.failureOrNull,
        ),
        persistDraft: false,
      );
    }

    return result.isSuccess ? const Success(null) : Failure(result.failureOrNull!);
  }

  void clearTruckRc() {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(rcDocumentPath: null),
      ),
    ));
  }

  void clearTruckPhoto() {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(truckPhotoPath: null),
      ),
    ));
  }
}
