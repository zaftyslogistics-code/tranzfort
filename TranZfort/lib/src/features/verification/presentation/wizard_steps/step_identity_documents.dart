import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/wizard_progress_bar.dart';

class StepIdentityDocuments extends ConsumerWidget {
  const StepIdentityDocuments({super.key});

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WizardHeader(
              title: l10n.verificationWizardIdentityTitle,
              subtitle: l10n.verificationWizardIdentitySubtitle,
              currentStep: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabels: stepLabels,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Aadhaar Number
            AppTextField(
              label: l10n.verificationWizardAadhaarNumberLabel,
              hintText: '1234 5678 9012',
              keyboardType: TextInputType.number,
              initialValue: _formatAadhaar(state.draft.aadhaarNumber) ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                _AadhaarFormatter(),
              ],
              onChanged: (v) => controller.updateAadhaarNumber(v.replaceAll(' ', '')),
              errorText: state.fieldErrors['aadhaarNumber'],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Aadhaar Front
            DocumentUploadBox(
              label: l10n.verificationDocTypeAadhaarFront,
              documentPath: state.draft.aadhaarFrontPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.aadhaarFront,
              icon: Icons.document_scanner_outlined,
              onTap: () => _uploadDocument(
                context,
                controller,
                VerificationDocumentType.aadhaarFront,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.aadhaarFront),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Aadhaar Back
            DocumentUploadBox(
              label: l10n.verificationDocTypeAadhaarBack,
              documentPath: state.draft.aadhaarBackPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.aadhaarBack,
              icon: Icons.document_scanner_outlined,
              onTap: () => _uploadDocument(
                context,
                controller,
                VerificationDocumentType.aadhaarBack,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.aadhaarBack),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // PAN Number
            AppTextField(
              label: l10n.verificationWizardPanNumberLabel,
              hintText: 'ABCDE1234F',
              initialValue: state.draft.panNumber ?? '',
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: controller.updatePanNumber,
              errorText: state.fieldErrors['panNumber'],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // PAN Document
            DocumentUploadBox(
              label: l10n.verificationWizardPanDocumentLabel,
              documentPath: state.draft.panDocumentPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.pan,
              icon: Icons.credit_card_outlined,
              onTap: () => _uploadDocument(
                context,
                controller,
                VerificationDocumentType.pan,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.pan),
            ),
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

  String? _formatAadhaar(String? value) {
    if (value == null || value.isEmpty) return null;
    final digits = value.replaceAll(' ', '');
    if (digits.length <= 4) return digits;
    if (digits.length <= 8) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
  }

  Future<void> _uploadDocument(
    BuildContext context,
    VerificationWizardController controller,
    VerificationDocumentType type,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => const ImageSourcePicker(
        onSelected: _noopImageSourceSelection,
      ),
    );

    if (source == null) return;

    switch (type) {
      case VerificationDocumentType.aadhaarFront:
        await controller.uploadAadhaarFront(source);
        break;
      case VerificationDocumentType.aadhaarBack:
        await controller.uploadAadhaarBack(source);
        break;
      case VerificationDocumentType.pan:
        await controller.uploadPan(source);
        break;
      default:
        break;
    }
  }
}

void _noopImageSourceSelection(ImageSource _) {}

class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
