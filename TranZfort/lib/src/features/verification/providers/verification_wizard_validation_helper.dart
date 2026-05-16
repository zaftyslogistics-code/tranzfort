import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import 'verification_wizard_state.dart';

/// Helper class for validation logic in the verification wizard.
/// Extracted to reduce file size of the main controller.
class VerificationWizardValidationHelper {
  final AppUserRole _role;

  VerificationWizardValidationHelper({required AppUserRole role}) : _role = role;

  /// Validates all required fields for the verification wizard.
  /// Returns an error message string if validation fails, null if all valid.
  /// Also returns a map of field-specific errors.
  ValidationResult validateAll(VerificationDraft draft, [AppLocalizations? l10n]) {
    final errors = <String, String>{};

    if (draft.profilePhotoPath?.isEmpty ?? true) {
      errors['profilePhoto'] = 'Profile photo is required';
    }

    final aadhaarError = Validators.validateAadhaar(draft.aadhaarNumber ?? '');
    if (aadhaarError != null) {
      errors['aadhaarNumber'] = aadhaarError;
    }
    final panError = Validators.validatePan(draft.panNumber ?? '');
    if (panError != null) {
      errors['panNumber'] = panError;
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

    final isTrucker = _role == AppUserRole.trucker;
    if (isTrucker) {
      final truck = draft.truck;
      if (truck == null || truck.truckNumber.isEmpty) {
        errors['truckNumber'] = 'Truck number is required';
      }
      if ((truck?.capacityTonnes ?? 0) <= 0) {
        errors['capacityTonnes'] = 'Truck capacity is required';
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
      return ValidationResult.failure(
        message: l10n?.verificationCompleteAllFields ?? 'Please complete all required fields',
        fieldErrors: errors,
      );
    }

    return ValidationResult.success();
  }
}

/// Result of validation containing either success or failure with field errors
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  factory ValidationResult.success() {
    return const ValidationResult._(isValid: true);
  }

  factory ValidationResult.failure({
    required String message,
    required Map<String, String> fieldErrors,
  }) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
      fieldErrors: fieldErrors,
    );
  }
}
