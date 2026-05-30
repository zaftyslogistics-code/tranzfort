import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/tts_localizations.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../../../shared/widgets/tts_card_speaker_button.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_provider.dart';
import '../../providers/verification_wizard_state.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/verification_wizard_upload_feedback.dart';
import '../components/wizard_progress_bar.dart';

class StepTruckDetails extends ConsumerWidget {
  const StepTruckDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = TtsLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final controller = ref.read(verificationWizardProvider.notifier);
    final truck = state.draft.truck ?? TruckDraft();

    final List<String> stepLabels = [
      l10n.verificationWizardStepPhoto,
      l10n.verificationWizardStepIdentity,
      l10n.verificationWizardStepTruck,
      l10n.verificationWizardStepReview,
    ];

    return StepContainer(
      stepIndex: state.currentStepIndex,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WizardHeader(
              title: l10n.commonTruckDetailsLabel,
              subtitle: l10n.verificationWizardTruckSubtitle,
              currentStep: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabels: stepLabels,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Info banner
            _InfoBanner(message: l10n.verificationWizardTruckInfo),
            const SizedBox(height: AppSpacing.lg),
            
            // Truck Number
            AppTextField(
              label: l10n.commonTruckNumberLabel,
              hintText: 'MH01AB1234',
              initialValue: truck.truckNumber,
              onChanged: controller.updateTruckNumber,
              errorText: state.fieldErrors['truckNumber'],
              suffixIcon: TtsCardSpeakerButton(
                message: ttsL10n.ttsFieldTruckNumberInputDescription,
                onDarkSurface: false,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Body Type
            _SpeakableDropdownField(
              label: l10n.verificationWizardBodyTypeLabel,
              ttsMessage: ttsL10n.ttsFieldTruckBodyTypeDescription,
              child: AppDropdown<String>(
                value: truck.bodyType,
                items: [
                  'open',
                  'closed',
                  'container',
                  'flatbed',
                  'tanker',
                  'refrigerated',
                ].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(_getBodyTypeLabel(l10n, type)),
                )).toList(),
                onChanged: (v) => controller.updateTruckBodyType(v!),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Tyres
            _SpeakableDropdownField(
              label: l10n.verificationWizardTyresLabel,
              ttsMessage: ttsL10n.ttsFieldTruckTyresDescription,
              child: AppDropdown<int>(
                value: truck.tyres,
                items: [6, 10, 12, 14, 16, 18, 22].map((count) => DropdownMenuItem(
                  value: count,
                  child: Text('$count ${l10n.verificationWizardTyresLabel.toLowerCase()}'),
                )).toList(),
                onChanged: (v) => controller.updateTruckTyres(v!),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Capacity
            AppTextField(
              label: l10n.verificationWizardCapacityLabel,
              hintText: l10n.verificationWizardCapacityHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              initialValue: truck.capacityTonnes > 0 ? truck.capacityTonnes.toString() : '',
              onChanged: controller.updateTruckCapacity,
              errorText: state.fieldErrors['capacityTonnes'],
              suffixIcon: TtsCardSpeakerButton(
                message: ttsL10n.ttsFieldTruckCapacityInputDescription,
                onDarkSurface: false,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // RC Document (Required)
            DocumentUploadBox(
              label: l10n.verificationWizardRcDocumentLabel,
              subtitle: l10n.verificationWizardRequiredForVerification,
              documentPath: truck.rcDocumentPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.truckRc,
              icon: Icons.description_outlined,
              ttsMessage: ttsL10n.ttsFieldUploadRcPrompt,
              onTap: () => _uploadRc(context, ref, controller),
              onClear: controller.clearTruckRc,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Truck Photo (Optional)
            DocumentUploadBox(
              label: l10n.verificationWizardTruckPhotoLabel,
              subtitle: l10n.verificationWizardTruckPhotoHint,
              documentPath: truck.truckPhotoPath,
              isRequired: false,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.truckPhoto,
              icon: Icons.local_shipping_outlined,
              ttsMessage: ttsL10n.ttsFieldUploadTruckPhotoPrompt,
              onTap: () => _uploadPhoto(context, ref, controller),
              onClear: controller.clearTruckPhoto,
            ),
            if (state.fieldErrors['rcDocument'] != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.fieldErrors['rcDocument']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
            VerificationWizardUploadErrorBanner(error: state.error),
            const SizedBox(height: AppSpacing.xl),
            
            StepActions(
              onBack: controller.previousStep,
              onContinue: state.canProceed ? controller.nextStep : null,
              isContinueEnabled: state.canProceed,
              isLoading: state.isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadRc(BuildContext context, WidgetRef ref, VerificationWizardController controller) async {
    final l10n = AppLocalizations.of(context);
    final source = await _showImageSourcePicker(context);
    if (source == null) return;

    final result = await controller.uploadTruckRcDocument(source);
    if (!context.mounted) return;

    final updated = ref.read(verificationWizardProvider);
    showVerificationWizardUploadResultSnackBar(
      context,
      result: result,
      l10n: l10n,
      documentAttached: (updated.draft.truck?.rcDocumentPath ?? '').isNotEmpty,
      successMessage: l10n.verificationWizardReviewRcUploaded,
    );
  }

  Future<void> _uploadPhoto(BuildContext context, WidgetRef ref, VerificationWizardController controller) async {
    final l10n = AppLocalizations.of(context);
    final source = await _showImageSourcePicker(context);
    if (source == null) return;

    final result = await controller.uploadTruckPhoto(source);
    if (!context.mounted) return;

    final updated = ref.read(verificationWizardProvider);
    showVerificationWizardUploadResultSnackBar(
      context,
      result: result,
      l10n: l10n,
      documentAttached: (updated.draft.truck?.truckPhotoPath ?? '').isNotEmpty,
      successMessage: l10n.verificationWizardReviewTruckPhotoUploaded,
    );
  }

  Future<ImageSource?> _showImageSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => const ImageSourcePicker(
        onSelected: _noopImageSourceSelection,
      ),
    );
  }

  String _getBodyTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'open' => 'Open',
      'closed' => 'Closed',
      'container' => 'Container',
      'flatbed' => 'Flatbed',
      'tanker' => 'Tanker',
      'refrigerated' => 'Refrigerated',
      _ => type,
    };
  }

}

void _noopImageSourceSelection(ImageSource _) {}

class _SpeakableDropdownField extends StatelessWidget {
  final String label;
  final String ttsMessage;
  final Widget child;

  const _SpeakableDropdownField({
    required this.label,
    required this.ttsMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            TtsCardSpeakerButton(
              message: ttsMessage,
              onDarkSurface: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.info,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
