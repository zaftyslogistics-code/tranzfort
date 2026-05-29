import '../../../core/error/app_failure.dart';
import '../../../core/providers/app_state_providers.dart';
import '../data/verification_repository.dart';
import '../data/verification_location_service.dart';
import 'verification_wizard_draft.dart';

export 'verification_wizard_draft.dart';

/// Steps in the verification wizard flow
enum WizardStep {
  profilePhoto,
  identityDocuments,
  roleSpecific,
  reviewSubmit,
}

enum LocationCaptureError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationCaptureResult {
  final VerificationLocation? location;
  final LocationCaptureError? error;

  const LocationCaptureResult.success(this.location) : error = null;
  const LocationCaptureResult.error(this.error) : location = null;

  bool get isSuccess => location != null;
  bool get isFailure => error != null;
}

class VerificationWizardState {
  final int currentStepIndex;
  final int totalSteps;
  final WizardStep currentStep;
  final VerificationDraft draft;
  final bool isLoading;
  final bool isSubmitting;
  final bool isCapturingLocation;
  final VerificationDocumentType? uploadingDocumentType;
  final AppFailure? error;
  final Map<String, String> fieldErrors;
  final AppUserRole role;
  final bool isResubmission;
  final bool termsAccepted;
  final String verificationStatus;

  const VerificationWizardState({
    required this.currentStepIndex,
    required this.totalSteps,
    required this.currentStep,
    required this.draft,
    required this.isLoading,
    required this.isSubmitting,
    required this.isCapturingLocation,
    required this.uploadingDocumentType,
    required this.error,
    required this.fieldErrors,
    required this.role,
    required this.isResubmission,
    required this.termsAccepted,
    required this.verificationStatus,
  });

  factory VerificationWizardState.initial(AppUserRole role) {
    return VerificationWizardState(
      currentStepIndex: 0,
      totalSteps: 4,
      currentStep: WizardStep.profilePhoto,
      draft: VerificationDraft(),
      isLoading: true,
      isSubmitting: false,
      isCapturingLocation: false,
      uploadingDocumentType: null,
      error: null,
      fieldErrors: const {},
      role: role,
      isResubmission: false,
      termsAccepted: false,
      verificationStatus: 'unverified',
    );
  }

  // Computed properties
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == totalSteps - 1;
  bool get isTrucker => role == AppUserRole.trucker;
  bool get isSupplier => role == AppUserRole.supplier;
  double get progress => (currentStepIndex + 1) / totalSteps;

  bool get canProceed {
    switch (currentStep) {
      case WizardStep.profilePhoto:
        return draft.hasProfilePhoto;
      case WizardStep.identityDocuments:
        return draft.hasIdentityComplete;
      case WizardStep.roleSpecific:
        return isTrucker ? draft.hasTruckComplete : draft.hasBusinessComplete;
      case WizardStep.reviewSubmit:
        return true;
    }
  }

  bool get canGoBack => !isFirstStep;

  // Status checks
  bool get isAlreadyVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';

  VerificationWizardState copyWith({
    int? currentStepIndex,
    VerificationDraft? draft,
    bool? isLoading,
    bool? isSubmitting,
    bool? isCapturingLocation,
    VerificationDocumentType? uploadingDocumentType,
    bool? clearUploadingDocumentType,
    AppFailure? error,
    bool? clearError,
    Map<String, String>? fieldErrors,
    bool? clearFieldErrors,
    String? clearFieldError,
    bool? termsAccepted,
    bool? isResubmission,
    String? verificationStatus,
  }) {
    final newFieldErrors = <String, String>{
      if (clearFieldErrors != true && clearFieldError == null) ...this.fieldErrors,
      if (fieldErrors != null) ...fieldErrors,
    };
    if (clearFieldError != null) {
      newFieldErrors.remove(clearFieldError);
    }

    final newStepIndex = currentStepIndex ?? this.currentStepIndex;
    
    return VerificationWizardState(
      currentStepIndex: newStepIndex,
      totalSteps: totalSteps,
      currentStep: WizardStep.values[newStepIndex.clamp(0, 3)],
      draft: draft ?? this.draft,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCapturingLocation: isCapturingLocation ?? this.isCapturingLocation,
      uploadingDocumentType: clearUploadingDocumentType == true
          ? null
          : uploadingDocumentType ?? this.uploadingDocumentType,
      error: clearError == true ? null : error ?? this.error,
      fieldErrors: newFieldErrors,
      role: role,
      isResubmission: isResubmission ?? this.isResubmission,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}
