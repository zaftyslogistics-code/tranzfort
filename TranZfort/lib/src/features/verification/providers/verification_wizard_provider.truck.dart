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
    return _uploadTruckDocument(
      type: VerificationDocumentType.truckRc,
      source: source,
      fieldKey: 'rcDocument',
      applyPath: (path) {
        final truck = state.draft.truck ?? TruckDraft();
        _setState(
          state.copyWith(
            draft: state.draft.copyWith(
              truck: truck.copyWith(rcDocumentPath: path),
            ),
          ),
          persistDraft: false,
        );
      },
    );
  }

  Future<Result<void>> uploadTruckPhoto(ImageSource source) async {
    return _uploadTruckDocument(
      type: VerificationDocumentType.truckPhoto,
      source: source,
      fieldKey: 'truckPhoto',
      applyPath: (path) {
        final truck = state.draft.truck ?? TruckDraft();
        _setState(
          state.copyWith(
            draft: state.draft.copyWith(
              truck: truck.copyWith(truckPhotoPath: path),
            ),
          ),
          persistDraft: false,
        );
      },
    );
  }

  Future<Result<void>> _uploadTruckDocument({
    required VerificationDocumentType type,
    required ImageSource source,
    required String fieldKey,
    required void Function(String? path) applyPath,
  }) async {
    _setState(
      state.copyWith(
        uploadingDocumentType: type,
        clearError: true,
        clearFieldError: fieldKey,
      ),
      persistDraft: false,
    );

    if (_currentUserId == null) {
      const failure = UnauthorizedFailure();
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          error: failure,
          fieldErrors: {...state.fieldErrors, fieldKey: failure.message},
        ),
        persistDraft: false,
      );
      return const Failure(failure);
    }

    final result = type == VerificationDocumentType.truckRc
        ? await _uploadHelper.uploadTruckRcDocument(source: source)
        : await _uploadHelper.uploadTruckPhoto(source: source);

    _applyDocumentUploadResult(
      result: result,
      wizardFieldKey: fieldKey,
      applyPath: applyPath,
    );

    return result.isSuccess && (result.valueOrNull ?? '').trim().isNotEmpty
        ? const Success(null)
        : Failure(result.failureOrNull ?? const ValidationFailure(message: 'Document upload failed'));
  }

  void clearTruckRc() {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(clearRcDocument: true),
      ),
      clearFieldError: 'rcDocument',
    ));
  }

  void clearTruckPhoto() {
    final truck = state.draft.truck ?? TruckDraft();
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(clearTruckPhoto: true),
      ),
      clearFieldError: 'truckPhoto',
    ));
  }
}
