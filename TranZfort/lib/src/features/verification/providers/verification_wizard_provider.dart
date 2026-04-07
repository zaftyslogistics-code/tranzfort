import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../trucker/data/trucker_fleet_repository.dart';
import '../data/verification_document_upload_service.dart';
import '../data/verification_location_service.dart';
import '../data/verification_repository.dart';

part 'verification_wizard_state.dart';
part 'verification_wizard_draft.dart';

class VerificationWizardController extends StateNotifier<VerificationWizardState> {
  static const _draftStorageKeyPrefix = 'verification_wizard_draft_v1';

  final VerificationRepository _repository;
  final VerificationDocumentUploadService _uploadService;
  final VerificationLocationService _locationService;
  final TruckerFleetRepository? _fleetRepository;
  final String? _currentUserId;
  final AppUserRole _role;

  VerificationWizardController({
    required VerificationRepository repository,
    required VerificationDocumentUploadService uploadService,
    required VerificationLocationService locationService,
    required AppUserRole role,
    TruckerFleetRepository? fleetRepository,
    String? currentUserId,
  })  : _repository = repository,
        _uploadService = uploadService,
        _locationService = locationService,
        _fleetRepository = fleetRepository,
        _currentUserId = currentUserId,
        _role = role,
        super(VerificationWizardState.initial(role)) {
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final persistedDraft = await _loadPersistedDraft();
    if (persistedDraft != null) {
      state = state.copyWith(draft: persistedDraft);
    }

    final result = await _repository.fetchCurrentDetail();
    result.when(
      success: (detail) {
        if (detail != null) {
          final detailDraft = VerificationDraft.fromDetail(detail);
          state = state.copyWith(
            draft: persistedDraft == null ? detailDraft : detailDraft.mergeMissingFrom(state.draft),
            isLoading: false,
            verificationStatus: detail.verificationStatus.toLowerCase(),
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
    );
  }

  void nextStep() {
    if (!state.canProceed) return;
    if (state.isLastStep) return;
    
    state = state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
      clearError: true,
    );
  }

  void previousStep() {
    if (state.isFirstStep) return;
    
    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      clearError: true,
    );
  }

  void goToStep(int index) {
    if (index < 0 || index >= state.totalSteps) return;
    if (index > state.currentStepIndex + 1) return; // Can't skip ahead
    
    state = state.copyWith(
      currentStepIndex: index,
      clearError: true,
    );
  }

  // Profile Photo
  Future<Result<void>> uploadProfilePhoto(ImageSource source) async {
    state = state.copyWith(
      uploadingDocumentType: VerificationDocumentType.profilePhoto,
      clearError: true,
    );

    final result = await _pickCompressAndUpload(
      type: VerificationDocumentType.profilePhoto,
      source: source,
    );

    state = state.copyWith(clearUploadingDocumentType: true);
    return result;
  }

  void clearProfilePhoto() {
    state = state.copyWith(
      draft: state.draft.copyWith(profilePhotoPath: null),
    );
  }

  // Identity Numbers
  void updateAadhaarNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'\s'), '').trim();
    state = state.copyWith(
      draft: state.draft.copyWith(aadhaarNumber: normalized),
      clearFieldError: 'aadhaarNumber',
    );
  }

  void updatePanNumber(String value) {
    final normalized = value.toUpperCase().trim();
    state = state.copyWith(
      draft: state.draft.copyWith(panNumber: normalized),
      clearFieldError: 'panNumber',
    );
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
    state = state.copyWith(uploadingDocumentType: type, clearError: true);

    final result = await _pickCompressAndUpload(type: type, source: source);

    state = state.copyWith(clearUploadingDocumentType: true);
    return result;
  }

  void clearIdentityDoc(VerificationDocumentType type) {
    final draft = state.draft;
    switch (type) {
      case VerificationDocumentType.aadhaarFront:
        state = state.copyWith(draft: draft.copyWith(aadhaarFrontPath: null));
        break;
      case VerificationDocumentType.aadhaarBack:
        state = state.copyWith(draft: draft.copyWith(aadhaarBackPath: null));
        break;
      case VerificationDocumentType.pan:
        state = state.copyWith(draft: draft.copyWith(panDocumentPath: null));
        break;
      default:
        break;
    }
  }

  // Trucker: Truck Details
  void updateTruckNumber(String value) {
    final normalized = value.toUpperCase().trim();
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(truckNumber: normalized),
      ),
      clearFieldError: 'truckNumber',
    );
  }

  void updateTruckBodyType(String value) {
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(bodyType: value),
      ),
    );
  }

  void updateTruckTyres(int value) {
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(tyres: value),
      ),
    );
  }

  void updateTruckCapacity(String value) {
    final capacity = double.tryParse(value.trim()) ?? 0;
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(capacityTonnes: capacity),
      ),
    );
  }

  Future<Result<void>> uploadTruckRcDocument(ImageSource source) async {
    state = state.copyWith(
      uploadingDocumentType: VerificationDocumentType.truckRc,
      clearError: true,
    );

    final result = await _pickCompressAndUpload(
      type: VerificationDocumentType.truckRc,
      source: source,
    );

    if (result.isSuccess) {
      final truck = state.draft.truck ?? TruckDraft();
      state = state.copyWith(
        draft: state.draft.copyWith(
          truck: truck.copyWith(rcDocumentPath: result.valueOrNull),
        ),
        clearUploadingDocumentType: true,
      );
    } else {
      state = state.copyWith(clearUploadingDocumentType: true);
    }

    return result;
  }

  Future<Result<void>> uploadTruckPhoto(ImageSource source) async {
    state = state.copyWith(
      uploadingDocumentType: VerificationDocumentType.truckPhoto,
      clearError: true,
    );

    final result = await _pickCompressAndUpload(
      type: VerificationDocumentType.truckPhoto,
      source: source,
    );

    if (result.isSuccess) {
      final truck = state.draft.truck ?? TruckDraft();
      state = state.copyWith(
        draft: state.draft.copyWith(
          truck: truck.copyWith(truckPhotoPath: result.valueOrNull),
        ),
        clearUploadingDocumentType: true,
      );
    } else {
      state = state.copyWith(clearUploadingDocumentType: true);
    }

    return result;
  }

  void clearTruckRc() {
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(rcDocumentPath: null),
      ),
    );
  }

  void clearTruckPhoto() {
    final truck = state.draft.truck ?? TruckDraft();
    state = state.copyWith(
      draft: state.draft.copyWith(
        truck: truck.copyWith(truckPhotoPath: null),
      ),
    );
  }

  // Supplier: Business Details
  void updateCompanyName(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(companyName: value.trim()),
      clearFieldError: 'companyName',
    );
  }

  void updateBusinessLicenseNumber(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(businessLicenseNumber: value.trim()),
      clearFieldError: 'businessLicenseNumber',
    );
  }

  void updateGstNumber(String value) {
    final normalized = value.toUpperCase().trim();
    state = state.copyWith(
      draft: state.draft.copyWith(gstNumber: normalized),
    );
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
    state = state.copyWith(uploadingDocumentType: type, clearError: true);

    final result = await _pickCompressAndUpload(type: type, source: source);

    if (result.isSuccess) {
      final path = result.valueOrNull;
      if (type == VerificationDocumentType.businessLicence) {
        state = state.copyWith(
          draft: state.draft.copyWith(businessLicensePath: path),
        );
      } else {
        state = state.copyWith(
          draft: state.draft.copyWith(gstCertificatePath: path),
        );
      }
    }

    state = state.copyWith(clearUploadingDocumentType: true);
    return result;
  }

  void clearBusinessLicense() {
    state = state.copyWith(
      draft: state.draft.copyWith(businessLicensePath: null),
    );
  }

  void clearGstCertificate() {
    state = state.copyWith(
      draft: state.draft.copyWith(gstCertificatePath: null),
    );
  }

  // Supplier: Location
  Future<LocationCaptureResult> captureLocation() async {
    state = state.copyWith(isCapturingLocation: true, clearError: true);

    try {
      final location = await _locationService.captureSupplierVerificationLocation();

      if (location == null) {
        state = state.copyWith(isCapturingLocation: false);
        return LocationCaptureResult.error(LocationCaptureError.unknown);
      }

      state = state.copyWith(
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
      );

      return LocationCaptureResult.success(location);
    } on LocationServiceDisabledException {
      state = state.copyWith(isCapturingLocation: false);
      return LocationCaptureResult.error(LocationCaptureError.serviceDisabled);
    } on LocationPermissionDeniedException {
      state = state.copyWith(isCapturingLocation: false);
      return LocationCaptureResult.error(LocationCaptureError.permissionDenied);
    } on LocationPermissionDeniedForeverException {
      state = state.copyWith(isCapturingLocation: false);
      return LocationCaptureResult.error(
        LocationCaptureError.permissionDeniedForever,
      );
    } catch (_) {
      state = state.copyWith(isCapturingLocation: false);
      return LocationCaptureResult.error(LocationCaptureError.unknown);
    }
  }

  Future<void> setManualLocation({
    required String city,
    String? region,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(
      draft: state.draft.copyWith(
        location: WizardLocation(
          city: city,
          state: region,
          latitude: latitude,
          longitude: longitude,
          source: 'manual',
        ),
      ),
    );
  }

  void clearLocation() {
    state = state.copyWith(
      draft: state.draft.copyWith(location: null),
    );
  }

  // Submit
  Future<Result<String>> submit() async {
    if (!state.isLastStep) {
      return Failure(BusinessRuleFailure(message: 'Complete all steps first'));
    }

    final validationError = _validateAll();
    if (validationError != null) {
      return Failure(ValidationFailure(
        message: validationError,
        fieldErrors: state.fieldErrors,
      ));
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // Save all draft data
      final saveResult = await _saveDraftData();
      if (saveResult.isFailure) {
        state = state.copyWith(isSubmitting: false);
        return Failure(saveResult.failureOrNull!);
      }

      // Submit for review
      final submitResult = await _repository.submitForReview(
        isResubmission: state.isResubmission,
      );

      if (submitResult.isSuccess) {
        await _clearPersistedDraft();
      }

      state = state.copyWith(isSubmitting: false);
      return submitResult;
    } catch (e, stack) {
      state = state.copyWith(isSubmitting: false);
      return Failure(mapSupabaseError(e, stack));
    }
  }

  Future<Result<void>> _saveDraftData() async {
    final draft = state.draft;

    // Save identity fields
    final identityResult = await _repository.saveVerificationPacketFields(
      aadhaarNumber: draft.aadhaarNumber ?? '',
      panNumber: draft.panNumber ?? '',
      companyName: draft.companyName,
      businessLicenceNumber: draft.businessLicenseNumber,
      gstNumber: draft.gstNumber,
    );
    if (identityResult.isFailure) return identityResult;

    // Save supplier location
    if (state.isSupplier && draft.location != null) {
      final locationResult = await _repository.saveSupplierVerificationLocation(
        city: draft.location!.city,
        state: draft.location!.state,
        latitude: draft.location!.latitude,
        longitude: draft.location!.longitude,
      );
      if (locationResult.isFailure) return locationResult;
    }

    // Create truck for truckers
    if (state.isTrucker && draft.truck != null && _fleetRepository != null) {
      final truckResult = await _fleetRepository.createTruck(
        truckNumber: draft.truck!.truckNumber,
        bodyType: draft.truck!.bodyType,
        tyres: draft.truck!.tyres,
        capacityTonnes: draft.truck!.capacityTonnes,
        rcDocumentPath: draft.truck!.rcDocumentPath ?? '',
      );
      if (truckResult.isFailure) return truckResult;
    }

    return Success(null);
  }

  String? _validateAll() {
    final draft = state.draft;
    final errors = <String, String>{};

    // Step 1: Profile Photo
    if (draft.profilePhotoPath?.isEmpty ?? true) {
      errors['profilePhoto'] = 'Profile photo is required';
    }

    // Step 2: Identity
    if (draft.aadhaarNumber?.length != 12) {
      errors['aadhaarNumber'] = 'Aadhaar must be 12 digits';
    }
    if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(draft.panNumber ?? '')) {
      errors['panNumber'] = 'Invalid PAN format';
    }
    if (draft.aadhaarFrontPath?.isEmpty ?? true) {
      errors['aadhaarFront'] = 'Aadhaar front photo required';
    }
    if (draft.aadhaarBackPath?.isEmpty ?? true) {
      errors['aadhaarBack'] = 'Aadhaar back photo required';
    }
    if (draft.panDocumentPath?.isEmpty ?? true) {
      errors['panDocument'] = 'PAN photo required';
    }

    // Step 3: Role-specific
    if (state.isTrucker) {
      final truck = draft.truck;
      if (truck == null || truck.truckNumber.isEmpty) {
        errors['truckNumber'] = 'Truck number is required';
      }
      if (truck?.rcDocumentPath?.isEmpty ?? true) {
        errors['rcDocument'] = 'RC document is required';
      }
    } else {
      if (draft.companyName?.isEmpty ?? true) {
        errors['companyName'] = 'Company name is required';
      }
      if (draft.businessLicenseNumber?.isEmpty ?? true) {
        errors['businessLicenseNumber'] = 'License number is required';
      }
      if (draft.businessLicensePath?.isEmpty ?? true) {
        errors['businessLicense'] = 'License document is required';
      }
      if (draft.location == null) {
        errors['location'] = 'Verification location is required';
      }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return 'Please complete all required fields';
    }

    return null;
  }

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
      return Success(null);
    }

    // Save path to backend
    final saveResult = await _repository.saveDocumentPath(type: type, storagePath: path);
    if (saveResult.isFailure) {
      return Failure(saveResult.failureOrNull!);
    }

    return Success(path);
  }

  void setTermsAccepted(bool value) {
    state = state.copyWith(termsAccepted: value);
  }

  Future<void> saveDraft() async {
    await _persistDraft(state.draft);
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearFieldErrors: true);
  }

  String get _draftStorageKey => '$_draftStorageKeyPrefix:${_currentUserId ?? _role.name}';

  Future<void> _persistDraft(VerificationDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    if (draft.isEmpty) {
      await preferences.remove(_draftStorageKey);
      return;
    }
    await preferences.setString(_draftStorageKey, jsonEncode(draft.toJson()));
  }

  Future<VerificationDraft?> _loadPersistedDraft() async {
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

  Future<void> _clearPersistedDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftStorageKey);
  }
}

final verificationWizardProvider = StateNotifierProvider.autoDispose<
    VerificationWizardController, VerificationWizardState>((ref) {
  final role = ref.watch(currentAuthStateProvider).role;
  final repository = ref.watch(verificationRepositoryProvider);
  final uploadService = ref.watch(verificationDocumentUploadServiceProvider);
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
    locationService: locationService,
    role: role,
    fleetRepository: fleetRepo,
    currentUserId: client?.auth.currentUser?.id,
  );
});
