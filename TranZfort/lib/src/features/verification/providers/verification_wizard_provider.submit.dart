part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Submit, Validation & Draft Persistence
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardSubmit on VerificationWizardController {
  Future<Result<String>> submit([AppLocalizations? l10n]) async {
    return _verificationSubmit(l10n);
  }

  void setTermsAccepted(bool value) {
    _setState(state.copyWith(termsAccepted: value), persistDraft: false);
  }

  Future<void> saveDraft() async {
    await _verificationPersistDraft(state.draft);
  }

  void clearError() {
    _setState(state.copyWith(clearError: true, clearFieldErrors: true), persistDraft: false);
  }

  // ─── Load existing data ───
  Future<void> _verificationLoadExistingData() async {
    final persistedDraft = await _verificationLoadPersistedDraft();
    if (persistedDraft != null) {
      _setState(state.copyWith(draft: persistedDraft), persistDraft: false);
    }

    final detail = _initialDetail;
    if (detail != null) {
      final detailDraft = VerificationDraft.fromDetail(detail);
      final isRejected = detail.verificationStatus.trim().toLowerCase() == 'rejected';
      _setState(
        state.copyWith(
          draft: persistedDraft == null
              ? detailDraft
              : detailDraft.mergeMissingFrom(state.draft),
          isLoading: false,
          isResubmission: isRejected,
          verificationStatus: detail.verificationStatus.toLowerCase(),
        ),
        persistDraft: false,
      );
    } else {
      _setState(state.copyWith(isLoading: false), persistDraft: false);
    }

    await _verificationHydrateTruckFromFleet();
  }

  Future<void> _verificationHydrateTruckFromFleet() async {
    final fleetRepository = _fleetRepository;
    if (!state.isTrucker || fleetRepository == null) {
      return;
    }

    final trucksResult = await fleetRepository.getMyTrucks();
    if (trucksResult.isFailure) {
      return;
    }

    final trucks = trucksResult.valueOrNull ?? const <TruckerFleetTruck>[];
    TruckerFleetTruck? fleetTruck;
    for (final t in trucks) {
      if (t.status != TruckerFleetTruckStatus.archived &&
          t.truckNumber.trim().isNotEmpty &&
          (t.rcDocumentPath ?? '').trim().isNotEmpty &&
          t.capacityTonnes > 0) {
        fleetTruck = t;
        break;
      }
    }
    if (fleetTruck == null) {
      return;
    }

    final draftTruck = state.draft.truck;
    final truckDraft = TruckDraft(
      truckNumber: (draftTruck?.truckNumber ?? '').trim().isNotEmpty
          ? draftTruck!.truckNumber
          : fleetTruck.truckNumber,
      bodyType: (draftTruck?.bodyType ?? '').trim().isNotEmpty
          ? draftTruck!.bodyType
          : fleetTruck.bodyType,
      tyres: draftTruck?.tyres ?? fleetTruck.tyres,
      capacityTonnes: (draftTruck?.capacityTonnes ?? 0) > 0
          ? draftTruck!.capacityTonnes
          : fleetTruck.capacityTonnes,
      rcDocumentPath: (draftTruck?.rcDocumentPath ?? '').trim().isNotEmpty
          ? draftTruck!.rcDocumentPath
          : fleetTruck.rcDocumentPath,
      truckPhotoPath: draftTruck?.truckPhotoPath,
    );

    _setState(
      state.copyWith(draft: state.draft.copyWith(truck: truckDraft)),
      persistDraft: false,
    );
  }

  // ─── Submit ───
  Future<Result<String>> _verificationSubmit([AppLocalizations? l10n]) async {
    if (!state.isLastStep) {
      return Failure(BusinessRuleFailure(message: 'Complete all steps first'));
    }

    final validationError = _verificationValidateAll(l10n);
    if (validationError != null) {
      final failure = ValidationFailure(
        message: validationError,
        fieldErrors: state.fieldErrors,
      );
      _setState(state.copyWith(error: failure), persistDraft: false);
      return Failure(failure);
    }

    _setState(
      state.copyWith(isSubmitting: true, clearError: true),
      persistDraft: false,
    );

    try {
      final saveResult = await _verificationSaveDraftData();
      if (saveResult.isFailure) {
        final failure = saveResult.failureOrNull!;
        _setState(
          state.copyWith(
            isSubmitting: false,
            error: failure,
            fieldErrors: {
              ...state.fieldErrors,
              ...mapRepositoryFailureToWizardFields(failure, wizardFieldKey: 'submit'),
            },
          ),
          persistDraft: false,
        );
        return Failure(failure);
      }

      final submitResult = await _repository.submitForReview(
        isResubmission: state.isResubmission,
      );

      if (submitResult.isSuccess) {
        await _verificationClearPersistedDraft();
      }

      _setState(
        state.copyWith(
          isSubmitting: false,
          error: submitResult.isFailure ? submitResult.failureOrNull : null,
        ),
        persistDraft: submitResult.isFailure,
      );
      return submitResult;
    } catch (e, stack) {
      final failure = mapSupabaseError(e, stack);
      _setState(
        state.copyWith(
          isSubmitting: false,
          error: failure,
        ),
        persistDraft: false,
      );
      return Failure(failure);
    }
  }

  // ─── Save draft data to backend ───
  Future<Result<void>> _verificationSaveDraftData() async {
    final draft = state.draft;

    final identityResult = await _repository.saveVerificationPacketFields(
      aadhaarNumber: draft.aadhaarNumber ?? '',
      panNumber: draft.panNumber ?? '',
      companyName: draft.companyName,
      businessLicenceNumber: draft.businessLicenseNumber,
      gstNumber: draft.gstNumber,
    );
    if (identityResult.isFailure) {
      return identityResult;
    }

    if (state.isSupplier && draft.location != null) {
      final locationResult = await _repository.saveSupplierVerificationLocation(
        city: draft.location!.city,
        state: draft.location!.state,
        latitude: draft.location!.latitude,
        longitude: draft.location!.longitude,
      );
      if (locationResult.isFailure) {
        return locationResult;
      }
    }

    if (state.isTrucker && draft.truck != null && _fleetRepository != null) {
      final hasReadyTruck = await _verificationFleetHasReadyTruck(draft.truck!);
      if (!hasReadyTruck) {
        final truckResult = await _fleetRepository.createTruck(
          truckNumber: draft.truck!.truckNumber,
          bodyType: draft.truck!.bodyType,
          tyres: draft.truck!.tyres,
          capacityTonnes: draft.truck!.capacityTonnes,
          rcDocumentPath: draft.truck!.rcDocumentPath ?? '',
        );
        if (truckResult.isFailure) {
          return truckResult;
        }
      }
    }

    return const Success(null);
  }

  // ─── Validation ───
  Future<bool> _verificationFleetHasReadyTruck(TruckDraft draft) async {
    final fleetRepository = _fleetRepository;
    if (fleetRepository == null) {
      return false;
    }

    final trucksResult = await fleetRepository.getMyTrucks();
    if (trucksResult.isFailure) {
      return false;
    }

    final normalizedNumber = draft.truckNumber.trim().toUpperCase();
    final trucks = trucksResult.valueOrNull ?? const <TruckerFleetTruck>[];
    return trucks.any(
      (t) =>
          t.status != TruckerFleetTruckStatus.archived &&
          t.truckNumber.trim().toUpperCase() == normalizedNumber &&
          (t.rcDocumentPath ?? '').trim().isNotEmpty &&
          t.capacityTonnes > 0,
    );
  }

  String? _verificationValidateAll([AppLocalizations? l10n]) {
    final result = _validationHelper.validateAll(
      state.draft,
      termsAccepted: state.termsAccepted,
      l10n: l10n,
    );
    if (!result.isValid) {
      _setState(state.copyWith(fieldErrors: result.fieldErrors), persistDraft: false);
      return result.errorMessage;
    }
    return null;
  }

  // ─── Draft persistence (secure storage) ───
  Future<void> _verificationPersistDraft(VerificationDraft draft) async {
    await _secureStorage.save(
      userId: _currentUserId,
      roleName: _role.name,
      draft: draft,
    );
  }

  Future<VerificationDraft?> _verificationLoadPersistedDraft() async {
    return _secureStorage.load(
      userId: _currentUserId,
      roleName: _role.name,
    );
  }

  Future<void> _verificationClearPersistedDraft() async {
    await _secureStorage.clear(
      userId: _currentUserId,
      roleName: _role.name,
    );
  }
}
