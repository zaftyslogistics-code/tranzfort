import 'package:flutter/material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/verification_repository.dart';

/// Maps repository / upload-service field keys to wizard UI keys.
String wizardFieldKeyForDocument(VerificationDocumentType type) {
  return switch (type) {
    VerificationDocumentType.profilePhoto => 'profilePhoto',
    VerificationDocumentType.aadhaarFront => 'aadhaarFront',
    VerificationDocumentType.aadhaarBack => 'aadhaarBack',
    VerificationDocumentType.pan => 'panDocument',
    VerificationDocumentType.businessLicence => 'businessLicense',
    VerificationDocumentType.gstCertificate => 'gstCertificate',
    VerificationDocumentType.truckRc => 'rcDocument',
    VerificationDocumentType.truckPhoto => 'truckPhoto',
  };
}

Map<String, String> wizardFieldErrorsFromFailure(
  AppFailure failure, {
  String? primaryFieldKey,
}) {
  if (failure is ValidationFailure) {
    final mapped = <String, String>{};
    for (final entry in failure.fieldErrors?.entries ?? const <MapEntry<String, String>>[]) {
      final wizardKey = _mapRepositoryFieldKey(entry.key);
      if (wizardKey != null && entry.value.trim().isNotEmpty) {
        mapped[wizardKey] = entry.value.trim();
      }
    }
    if (mapped.isEmpty && primaryFieldKey != null && failure.message.trim().isNotEmpty) {
      mapped[primaryFieldKey] = failure.message.trim();
    }
    return mapped;
  }

  if (primaryFieldKey != null && failure.message.trim().isNotEmpty) {
    return {primaryFieldKey: failure.message.trim()};
  }
  return const {};
}

String? _mapRepositoryFieldKey(String key) {
  return switch (key) {
    'profile_photo_document_path' || 'profilePhoto' => 'profilePhoto',
    'aadhaar_front_document_path' || 'aadhaarFront' => 'aadhaarFront',
    'aadhaar_back_document_path' || 'aadhaarBack' => 'aadhaarBack',
    'pan_document_path' || 'panDocument' => 'panDocument',
    'business_licence_document_path' || 'businessLicense' => 'businessLicense',
    'gst_certificate_document_path' || 'gstCertificate' => 'gstCertificate',
    'truck_rc_document_path' || 'rcDocument' => 'rcDocument',
    'truck_photo_document_path' || 'truckPhoto' => 'truckPhoto',
    'aadhaar_number' => 'aadhaarNumber',
    'pan_number' => 'panNumber',
    _ => null,
  };
}

String verificationWizardUploadErrorMessage(AppFailure error, AppLocalizations l10n) {
  final trimmed = error.message.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  if (error is ValidationFailure) {
    return l10n.verificationWizardValidationError;
  }
  if (error is UnauthorizedFailure) {
    return l10n.verificationWizardUnauthorizedError;
  }
  return l10n.verificationWizardUnknownError;
}

void showVerificationWizardUploadSnackBar(
  BuildContext context, {
  required bool succeeded,
  required String message,
}) {
  if (!context.mounted || message.trim().isEmpty) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: succeeded ? null : Theme.of(context).colorScheme.error,
      ),
    );
}

void showVerificationWizardUploadResultSnackBar(
  BuildContext context, {
  required Result<void> result,
  required AppLocalizations l10n,
  required bool documentAttached,
  required String successMessage,
  String cancelledMessage = 'No image was selected. Please try again.',
}) {
  if (!context.mounted) {
    return;
  }

  if (result.isSuccess && documentAttached) {
    showVerificationWizardUploadSnackBar(
      context,
      succeeded: true,
      message: successMessage,
    );
    return;
  }

  if (result.isSuccess && !documentAttached) {
    showVerificationWizardUploadSnackBar(
      context,
      succeeded: false,
      message: cancelledMessage,
    );
    return;
  }

  final failure = result.failureOrNull;
  if (failure != null) {
    showVerificationWizardUploadSnackBar(
      context,
      succeeded: false,
      message: verificationWizardUploadErrorMessage(failure, l10n),
    );
  }
}

class VerificationWizardUploadErrorBanner extends StatelessWidget {
  final AppFailure? error;

  const VerificationWizardUploadErrorBanner({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        verificationWizardUploadErrorMessage(error!, l10n),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
