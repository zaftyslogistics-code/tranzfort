import '../../../l10n/tts_localizations.dart';
import '../../verification/providers/verification_wizard_state.dart';

class VerificationStepTtsBuilder {
  const VerificationStepTtsBuilder();

  String build({
    required WizardStep step,
    required bool isTrucker,
    required TtsLocalizations tts,
  }) {
    return switch (step) {
      WizardStep.profilePhoto => tts.ttsVerificationStepPhoto,
      WizardStep.identityDocuments => tts.ttsVerificationStepIdentity,
      WizardStep.roleSpecific =>
        isTrucker ? tts.ttsVerificationStepTruck : tts.ttsVerificationStepBusiness,
      WizardStep.reviewSubmit => tts.ttsVerificationStepReview,
    };
  }
}
