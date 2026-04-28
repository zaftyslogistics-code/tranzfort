part of 'verification_wizard_provider.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

// ═══════════════════════════════════════════════════════════════════════════════
// Navigation
// ═══════════════════════════════════════════════════════════════════════════════

extension VerificationWizardNavigation on VerificationWizardController {
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
}
