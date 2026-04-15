import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../trucker/data/truck_document_upload_service.dart';
import '../../trucker/data/trucker_fleet_repository.dart';
import '../data/verification_document_upload_service.dart';
import '../data/verification_location_service.dart';
import '../data/verification_repository.dart';
import 'verification_wizard_upload_helper.dart';
import 'verification_wizard_validation_helper.dart';

import 'verification_wizard_state.dart';

class VerificationWizardController extends StateNotifier<VerificationWizardState> {
  static const _draftStorageKeyPrefix = 'verification_wizard_draft_v1';

  final VerificationRepository _repository;
  final VerificationDocumentUploadService _uploadService;
  final TruckDocumentUploadService _truckUploadService;
  final VerificationLocationService _locationService;
  final TruckerFleetRepository? _fleetRepository;
  final String? _currentUserId;
  final AppUserRole _role;
  late final VerificationWizardUploadHelper _uploadHelper;
  late final VerificationWizardValidationHelper _validationHelper;

  VerificationWizardController({
    required VerificationRepository repository,
    required VerificationDocumentUploadService uploadService,
    required TruckDocumentUploadService truckUploadService,
    required VerificationLocationService locationService,
    required AppUserRole role,
    TruckerFleetRepository? fleetRepository,
    String? currentUserId,
  })  : _repository = repository,
        _uploadService = uploadService,
        _truckUploadService = truckUploadService,
        _locationService = locationService,
        _fleetRepository = fleetRepository,
        _currentUserId = currentUserId,
        _role = role,
        super(VerificationWizardState.initial(role)) {
    _uploadHelper = VerificationWizardUploadHelper(
      repository: _repository,
      uploadService: _uploadService,
      truckUploadService: _truckUploadService,
      currentUserId: _currentUserId,
    );
    _validationHelper = VerificationWizardValidationHelper(role: _role);
    _verificationLoadExistingData();
  }

  void _setState(VerificationWizardState newState, {bool persistDraft = true}) {
    state = newState;
    if (!persistDraft) {
      return;
    }
    unawaited(_verificationPersistDraft(state.draft));
  }

  void nextStep() {
    if (!state.canProceed) return;
    if (state.isLastStep) return;
    
    _setState(state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
      clearError: true,
    ));
  }

  void previousStep() {
    if (state.isFirstStep) return;
    
    _setState(state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      clearError: true,
    ));
  }

  void goToStep(int index) {
    if (index < 0 || index >= state.totalSteps) return;
    if (index > state.currentStepIndex + 1) return; // Can't skip ahead
    
    _setState(state.copyWith(
      currentStepIndex: index,
      clearError: true,
    ));
  }

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

  // Trucker: Truck Details
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

  // Supplier: Business Details
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

  // Supplier: Location
  Future<LocationCaptureResult> captureLocation() async {
    return _verificationCaptureLocation();
  }

  Future<void> setManualLocation({
    required String city,
    String? region,
    required double latitude,
    required double longitude,
  }) async {
    _setState(state.copyWith(
      draft: state.draft.copyWith(
        location: WizardLocation(
          city: city,
          state: region,
          latitude: latitude,
          longitude: longitude,
          source: 'manual',
        ),
      ),
    ));
  }

  void clearLocation() {
    _setState(state.copyWith(
      draft: state.draft.copyWith(location: null),
    ));
  }

  // Submit
  Future<Result<String>> submit() async {
    return _verificationSubmit();
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

  String get _draftStorageKey => '$_draftStorageKeyPrefix:${_currentUserId ?? _role.name}';

  // Helper methods from part file
  Future<void> _verificationLoadExistingData() async {
    final persistedDraft = await _verificationLoadPersistedDraft();
    if (persistedDraft != null) {
      _setState(state.copyWith(draft: persistedDraft), persistDraft: false);
    }

    final result = await _repository.fetchCurrentDetail();
    result.when(
      success: (detail) {
        if (detail != null) {
          final detailDraft = VerificationDraft.fromDetail(detail);
          _setState(
            state.copyWith(
              draft: persistedDraft == null
                  ? detailDraft
                  : detailDraft.mergeMissingFrom(state.draft),
              isLoading: false,
              verificationStatus: detail.verificationStatus.toLowerCase(),
            ),
            persistDraft: false,
          );
        } else {
          _setState(state.copyWith(isLoading: false), persistDraft: false);
        }
      },
      failure: (failure) {
        _setState(
          state.copyWith(isLoading: false, error: failure),
          persistDraft: false,
        );
      },
    );
  }

  Future<LocationCaptureResult> _verificationCaptureLocation() async {
    _setState(
      state.copyWith(isCapturingLocation: true, clearError: true),
      persistDraft: false,
    );

    try {
      final location = await _locationService.captureSupplierVerificationLocation();

      if (location == null) {
        _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
        return LocationCaptureResult.error(LocationCaptureError.unknown);
      }

      _setState(state.copyWith(
        isCapturingLocation: false,
        draft: state.draft.copyWith(
          location: WizardLocation(
            city: location.city,
            state: location.state,
            latitude: location.latitude,
            longitude: location.longitude,
            source: 'gps',
          ),
        ),
      ));

      return LocationCaptureResult.success(location);
    } on LocationServiceDisabledException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.serviceDisabled);
    } on LocationPermissionDeniedException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.permissionDenied);
    } on LocationPermissionDeniedForeverException {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.permissionDeniedForever);
    } catch (_) {
      _setState(state.copyWith(isCapturingLocation: false), persistDraft: false);
      return LocationCaptureResult.error(LocationCaptureError.unknown);
    }
  }

  Future<Result<String>> _verificationSubmit() async {
    if (!state.isLastStep) {
      return Failure(BusinessRuleFailure(message: 'Complete all steps first'));
    }

    final validationError = _verificationValidateAll();
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
        _setState(
          state.copyWith(
            isSubmitting: false,
            error: saveResult.failureOrNull,
          ),
          persistDraft: false,
        );
        return Failure(saveResult.failureOrNull!);
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

    return const Success(null);
  }

  String? _verificationValidateAll() {
    final result = _validationHelper.validateAll(state.draft);
    if (!result.isValid) {
      _setState(state.copyWith(fieldErrors: result.fieldErrors), persistDraft: false);
      return result.errorMessage;
    }
    return null;
  }

  Future<void> _verificationPersistDraft(VerificationDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    if (draft.isEmpty) {
      await preferences.remove(_draftStorageKey);
      return;
    }
    await preferences.setString(_draftStorageKey, jsonEncode(draft.toJson()));
  }

  Future<VerificationDraft?> _verificationLoadPersistedDraft() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_draftStorageKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        await preferences.remove(_draftStorageKey);
        return null;
      }
      return VerificationDraft.fromJson(decoded);
    } catch (_) {
      await preferences.remove(_draftStorageKey);
      return null;
    }
  }

  Future<void> _verificationClearPersistedDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftStorageKey);
  }
}

final verificationWizardProvider = StateNotifierProvider.autoDispose<
    VerificationWizardController, VerificationWizardState>((ref) {
  final role = ref.watch(currentAuthStateProvider).role;
  final repository = ref.watch(verificationRepositoryProvider);
  final uploadService = ref.watch(verificationDocumentUploadServiceProvider);
  final truckUploadService = ref.watch(truckDocumentUploadServiceProvider);
  final locationService = ref.watch(verificationLocationServiceProvider);
  final client = ref.watch(supabaseClientProvider);

  TruckerFleetRepository? fleetRepo;
  if (role == AppUserRole.trucker) {
    fleetRepo = TruckerFleetRepository(
      SupabaseTruckerFleetBackend(client),
      () => client?.auth.currentUser?.id,
    );
  }

  return VerificationWizardController(
    repository: repository,
    uploadService: uploadService,
    truckUploadService: truckUploadService,
    locationService: locationService,
    role: role,
    fleetRepository: fleetRepo,
    currentUserId: client?.auth.currentUser?.id,
  );
});
