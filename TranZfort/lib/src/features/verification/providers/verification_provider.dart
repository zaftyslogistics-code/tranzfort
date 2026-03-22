import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../supplier/providers/supplier_providers.dart';
import '../../trucker/providers/trucker_providers.dart';
import '../data/verification_document_upload_service.dart';
import '../data/verification_location_service.dart';
import '../data/verification_repository.dart';

class VerificationState {
  final VerificationDetail? detail;
  final bool isLoading;
  final bool isSubmitting;
  final bool isCapturingLocation;
  final VerificationDocumentType? uploadingDocumentType;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  const VerificationState({
    required this.detail,
    required this.isLoading,
    required this.isSubmitting,
    required this.isCapturingLocation,
    required this.uploadingDocumentType,
    required this.failure,
    required this.actionFailure,
  });

  factory VerificationState.initial() {
    return const VerificationState(
      detail: null,
      isLoading: true,
      isSubmitting: false,
      isCapturingLocation: false,
      uploadingDocumentType: null,
      failure: null,
      actionFailure: null,
    );
  }

  VerificationState copyWith({
    VerificationDetail? detail,
    bool? clearDetail,
    bool? isLoading,
    bool? isSubmitting,
    bool? isCapturingLocation,
    VerificationDocumentType? uploadingDocumentType,
    bool? clearUploadingDocumentType,
    AppFailure? failure,
    bool? clearFailure,
    AppFailure? actionFailure,
    bool? clearActionFailure,
  }) {
    return VerificationState(
      detail: clearDetail == true ? null : detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCapturingLocation: isCapturingLocation ?? this.isCapturingLocation,
      uploadingDocumentType: clearUploadingDocumentType == true
          ? null
          : uploadingDocumentType ?? this.uploadingDocumentType,
      failure: clearFailure == true ? null : failure ?? this.failure,
      actionFailure: clearActionFailure == true ? null : actionFailure ?? this.actionFailure,
    );
  }
}

class VerificationController extends StateNotifier<VerificationState> {
  final void Function(VerificationDetail? detail) _invalidateRoleDependencies;
  final VerificationRepository _repository;
  final VerificationDocumentUploadService _uploadService;
  final VerificationLocationService _locationService;

  VerificationController(
    this._invalidateRoleDependencies,
    this._repository,
    this._uploadService,
    this._locationService,
  ) : super(VerificationState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true, clearActionFailure: true);
    final result = await _repository.fetchCurrentDetail();
    result.when(
      success: (detail) {
        state = state.copyWith(
          detail: detail,
          isLoading: false,
          clearFailure: true,
        );
        _invalidateRoleDependencies(detail);
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
          clearDetail: true,
        );
      },
    );
  }

  Future<Result<void>> uploadDocument({
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    final detail = state.detail;
    if (detail == null) {
      return const Failure<void>(NotFoundFailure(message: 'Verification detail is unavailable'));
    }
    if (state.uploadingDocumentType != null || state.isSubmitting || state.isCapturingLocation) {
      return const Failure<void>(BusinessRuleFailure(message: 'Another verification action is already in progress'));
    }

    state = state.copyWith(
      uploadingDocumentType: type,
      clearUploadingDocumentType: false,
      clearActionFailure: true,
    );
    final uploadResult = await _uploadService.pickCompressAndUploadDocument(
      profileId: detail.profileId,
      type: type,
      source: source,
    );
    if (uploadResult.isFailure) {
      state = state.copyWith(
        clearUploadingDocumentType: true,
        actionFailure: uploadResult.failureOrNull,
      );
      return Failure<void>(uploadResult.failureOrNull!);
    }

    final storagePath = uploadResult.valueOrNull;
    if (storagePath == null) {
      state = state.copyWith(
        clearUploadingDocumentType: true,
        clearActionFailure: true,
      );
      return const Success<void>(null);
    }

    final saveResult = await _repository.saveDocumentPath(type: type, storagePath: storagePath);
    if (saveResult.isFailure) {
      state = state.copyWith(
        clearUploadingDocumentType: true,
        actionFailure: saveResult.failureOrNull,
      );
      return saveResult;
    }

    state = state.copyWith(
      clearUploadingDocumentType: true,
      clearActionFailure: true,
    );
    await load();
    _invalidateRoleDependencies(state.detail);
    return const Success<void>(null);
  }

  Future<Result<void>> saveVerificationPacketFields({
    String? companyName,
    required String aadhaarNumber,
    required String panNumber,
    String? businessLicenceNumber,
    String? gstNumber,
  }) async {
    final detail = state.detail;
    if (detail == null) {
      return const Failure<void>(NotFoundFailure(message: 'Verification detail is unavailable'));
    }
    if (state.isSubmitting || state.uploadingDocumentType != null || state.isCapturingLocation) {
      return const Failure<void>(BusinessRuleFailure(message: 'Another verification action is already in progress'));
    }

    state = state.copyWith(clearActionFailure: true);
    final result = await _repository.saveVerificationPacketFields(
      companyName: companyName,
      aadhaarNumber: aadhaarNumber,
      panNumber: panNumber,
      businessLicenceNumber: businessLicenceNumber,
      gstNumber: gstNumber,
    );
    if (result.isFailure) {
      state = state.copyWith(actionFailure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(clearActionFailure: true);
    await load();
    _invalidateRoleDependencies(state.detail);
    return const Success<void>(null);
  }

  Future<Result<void>> captureSupplierLocation() async {
    final detail = state.detail;
    if (detail == null) {
      return const Failure<void>(NotFoundFailure(message: 'Verification detail is unavailable'));
    }
    if (!detail.isSupplier) {
      return const Failure<void>(
        BusinessRuleFailure(message: 'Verification location capture is only available for supplier verification.'),
      );
    }
    if (state.isCapturingLocation || state.isSubmitting || state.uploadingDocumentType != null) {
      return const Failure<void>(BusinessRuleFailure(message: 'Another verification action is already in progress'));
    }

    state = state.copyWith(isCapturingLocation: true, clearActionFailure: true);
    final location = await _locationService.captureSupplierVerificationLocation();
    if (location == null) {
      state = state.copyWith(
        isCapturingLocation: false,
        actionFailure: const BusinessRuleFailure(
          message: 'Unable to capture your verification location right now. Check location services and try again.',
        ),
      );
      return Failure<void>(state.actionFailure!);
    }

    final saveResult = await _repository.saveSupplierVerificationLocation(
      city: location.city,
      state: location.state,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (saveResult.isFailure) {
      state = state.copyWith(
        isCapturingLocation: false,
        actionFailure: saveResult.failureOrNull,
      );
      return saveResult;
    }

    state = state.copyWith(
      isCapturingLocation: false,
      clearActionFailure: true,
    );
    await load();
    _invalidateRoleDependencies(state.detail);
    return const Success<void>(null);
  }

  Future<Result<void>> saveManualSupplierLocation({
    required String city,
    String? state,
  }) async {
    final detail = this.state.detail;
    if (detail == null) {
      return const Failure<void>(NotFoundFailure(message: 'Verification detail is unavailable'));
    }
    if (!detail.isSupplier) {
      return const Failure<void>(
        BusinessRuleFailure(message: 'Verification location capture is only available for supplier verification.'),
      );
    }
    final manualState = (state ?? '').trim().isEmpty ? null : state?.trim();
    if (this.state.isCapturingLocation || this.state.isSubmitting || this.state.uploadingDocumentType != null) {
      return const Failure<void>(BusinessRuleFailure(message: 'Another verification action is already in progress'));
    }

    this.state = this.state.copyWith(isCapturingLocation: true, clearActionFailure: true);
    final location = await _locationService.resolveManualSupplierVerificationLocation(
      city: city,
      state: manualState,
    );
    if (location == null) {
      this.state = this.state.copyWith(
        isCapturingLocation: false,
        actionFailure: const ValidationFailure(
          message: 'Verification city is required',
          fieldErrors: {'verification_location_city': 'Verification city is required'},
        ),
      );
      return Failure<void>(this.state.actionFailure!);
    }

    final saveResult = await _repository.saveSupplierVerificationLocation(
      city: location.city,
      state: location.state,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (saveResult.isFailure) {
      this.state = this.state.copyWith(
        isCapturingLocation: false,
        actionFailure: saveResult.failureOrNull,
      );
      return saveResult;
    }

    this.state = this.state.copyWith(
      isCapturingLocation: false,
      clearActionFailure: true,
    );
    await load();
    _invalidateRoleDependencies(this.state.detail);
    return const Success<void>(null);
  }

  Future<Result<String>> submitForReview() async {
    final detail = state.detail;
    if (detail == null) {
      return const Failure<String>(NotFoundFailure(message: 'Verification detail is unavailable'));
    }
    if (state.isSubmitting || state.uploadingDocumentType != null || state.isCapturingLocation) {
      return const Failure<String>(BusinessRuleFailure(message: 'Another verification action is already in progress'));
    }
    final blockedReason = detail.submissionBlockedReason;
    if (blockedReason != null) {
      return Failure<String>(BusinessRuleFailure(message: blockedReason));
    }

    state = state.copyWith(isSubmitting: true, clearActionFailure: true);
    final result = await _repository.submitForReview(isResubmission: detail.isRejected);
    if (result.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        actionFailure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(isSubmitting: false, clearActionFailure: true);
    await load();
    _invalidateRoleDependencies(state.detail);
    return result;
  }
}

final verificationProvider = StateNotifierProvider.autoDispose<VerificationController, VerificationState>((ref) {
  return VerificationController(
    (detail) {
      if (detail?.isSupplier == true) {
        ref.invalidate(supplierProfileProvider);
        return;
      }

      if (detail?.isTrucker == true) {
        ref.invalidate(truckerProfileProvider);
        ref.invalidate(truckerDashboardProvider);
      }
    },
    ref.watch(verificationRepositoryProvider),
    ref.watch(verificationDocumentUploadServiceProvider),
    ref.watch(verificationLocationServiceProvider),
  );
});
