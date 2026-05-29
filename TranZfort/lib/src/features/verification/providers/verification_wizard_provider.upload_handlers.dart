part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension VerificationWizardUploadHandlers on VerificationWizardController {
  void _applyDocumentUploadResult({
    required Result<String?> result,
    required String wizardFieldKey,
    required void Function(String? path) applyPath,
  }) {
    if (result.isSuccess) {
      final path = result.valueOrNull;
      if ((path ?? '').trim().isEmpty) {
        _setState(
          state.copyWith(
            clearUploadingDocumentType: true,
            fieldErrors: {
              ...state.fieldErrors,
              wizardFieldKey: 'No image was selected. Please try again.',
            },
            clearError: true,
          ),
          persistDraft: false,
        );
        return;
      }

      applyPath(path);
      _setState(
        state.copyWith(
          clearUploadingDocumentType: true,
          clearError: true,
          clearFieldError: wizardFieldKey,
        ),
      );
      return;
    }

    final failure = result.failureOrNull!;
    _setState(
      state.copyWith(
        clearUploadingDocumentType: true,
        error: failure,
        fieldErrors: {
          ...state.fieldErrors,
          ...mapRepositoryFailureToWizardFields(failure, wizardFieldKey: wizardFieldKey),
        },
      ),
      persistDraft: false,
    );
  }

}
