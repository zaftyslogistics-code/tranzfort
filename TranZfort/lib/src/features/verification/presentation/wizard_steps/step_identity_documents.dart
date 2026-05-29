import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/verification_wizard_upload_feedback.dart';
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
              label: l10n.commonAadhaarNumberLabel,
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
                ref,
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
                ref,
                controller,
                VerificationDocumentType.aadhaarBack,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.aadhaarBack),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // PAN Number
            AppTextField(
              label: l10n.commonPanNumberLabel,
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
                ref,
                controller,
                VerificationDocumentType.pan,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.pan),
            ),
            if (state.fieldErrors['aadhaarFront'] != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.fieldErrors['aadhaarFront']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
            if (state.fieldErrors['aadhaarBack'] != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.fieldErrors['aadhaarBack']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
            if (state.fieldErrors['panDocument'] != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.fieldErrors['panDocument']!,
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
    WidgetRef ref,
    VerificationWizardController controller,
    VerificationDocumentType type,
  ) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => const ImageSourcePicker(
        onSelected: _noopImageSourceSelection,
      ),
    );

    if (source == null) return;

    final Result<void> result;
    final String label;
    switch (type) {
      case VerificationDocumentType.aadhaarFront:
        result = await controller.uploadAadhaarFront(source);
        label = l10n.verificationDocTypeAadhaarFront;
        break;
      case VerificationDocumentType.aadhaarBack:
        result = await controller.uploadAadhaarBack(source);
        label = l10n.verificationDocTypeAadhaarBack;
        break;
      case VerificationDocumentType.pan:
        result = await controller.uploadPan(source);
        label = l10n.verificationWizardPanDocumentLabel;
        break;
      default:
        return;
    }

    if (!context.mounted) return;

    final updated = ref.read(verificationWizardProvider);
    final attached = switch (type) {
      VerificationDocumentType.aadhaarFront => (updated.draft.aadhaarFrontPath ?? '').isNotEmpty,
      VerificationDocumentType.aadhaarBack => (updated.draft.aadhaarBackPath ?? '').isNotEmpty,
      VerificationDocumentType.pan => (updated.draft.panDocumentPath ?? '').isNotEmpty,
      _ => false,
    };

    showVerificationWizardUploadResultSnackBar(
      context,
      result: result,
      l10n: l10n,
      documentAttached: attached,
      successMessage: l10n.verificationDocumentUploadedSuccess(label),
    );
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
