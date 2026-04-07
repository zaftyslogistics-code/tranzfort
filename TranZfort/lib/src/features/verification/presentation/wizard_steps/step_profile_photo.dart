import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/feedback_components.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/wizard_progress_bar.dart';

class StepProfilePhoto extends ConsumerWidget {
  const StepProfilePhoto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final controller = ref.read(verificationWizardProvider.notifier);
    
    final List<String> stepLabels = [
      l10n.verificationWizardStepPhoto,
      l10n.verificationWizardStepIdentity,
      state.isTrucker ? l10n.verificationWizardStepTruck : l10n.verificationWizardStepBusiness,
      l10n.verificationWizardStepReview,
    ];

    return StepContainer(
      stepIndex: state.currentStepIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardHeader(
            title: l10n.verificationWizardProfileTitle,
            subtitle: l10n.verificationWizardProfileSubtitle,
            currentStep: state.currentStepIndex,
            totalSteps: state.totalSteps,
            stepLabels: stepLabels,
          ),
          const SizedBox(height: AppSpacing.xl),
          DocumentUploadBox(
            label: l10n.verificationDocTypeProfilePhoto,
            subtitle: l10n.verificationWizardProfileHint,
            documentPath: state.draft.profilePhotoPath,
            isRequired: true,
            isUploading: state.uploadingDocumentType == VerificationDocumentType.profilePhoto,
            icon: Icons.person_outline,
            onTap: () => _showImageSourcePicker(context, controller),
            onClear: controller.clearProfilePhoto,
            qualityChecks: const [
              QualityCheck(label: 'Face detected', passed: true),
              QualityCheck(label: 'Good lighting', passed: true),
            ],
          ),
          if (state.fieldErrors['profilePhoto'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.fieldErrors['profilePhoto']!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          StepActions(
            onContinue: state.canProceed ? controller.nextStep : null,
            isContinueEnabled: state.canProceed,
            isLoading: state.isSubmitting,
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourcePicker(
    BuildContext context,
    VerificationWizardController controller,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => ImageSourcePicker(
        onSelected: (s) => Navigator.pop(context, s),
      ),
    );

    if (source != null) {
      await controller.uploadProfilePhoto(source);
    }
  }
}
