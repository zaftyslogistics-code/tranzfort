import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/tts_localizations.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../../../shared/widgets/tts_card_speaker_button.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_draft.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/verification_wizard_upload_feedback.dart';
import '../components/wizard_progress_bar.dart';

class StepIdentityDocuments extends ConsumerStatefulWidget {
  const StepIdentityDocuments({super.key});

  @override
  ConsumerState<StepIdentityDocuments> createState() => _StepIdentityDocumentsState();
}

class _StepIdentityDocumentsState extends ConsumerState<StepIdentityDocuments> {
  late final TextEditingController _aadhaarController;
  late final TextEditingController _panController;
  String? _syncedAadhaarDraft;
  String? _syncedPanDraft;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController();
    _panController = TextEditingController();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _syncControllerFromDraft({
    required TextEditingController textController,
    required String? previousDraftValue,
    required String? nextDraftValue,
    required String Function(String? value) format,
    required String Function(String value) normalize,
  }) {
    if (identical(previousDraftValue, nextDraftValue) ||
        normalize(previousDraftValue ?? '') == normalize(nextDraftValue ?? '')) {
      return;
    }

    final nextNormalized = normalize(nextDraftValue ?? '');
    if (normalize(textController.text) == nextNormalized) {
      return;
    }

    final previousNormalized = normalize(previousDraftValue ?? '');
    if (normalize(textController.text) == previousNormalized ||
        textController.text.isEmpty) {
      _setControllerText(textController, format(nextDraftValue));
    }
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncControllersWithDraft(VerificationDraft draft) {
    _syncControllerFromDraft(
      textController: _aadhaarController,
      previousDraftValue: _syncedAadhaarDraft,
      nextDraftValue: draft.aadhaarNumber,
      format: (value) => _formatAadhaar(value) ?? '',
      normalize: (value) => value.replaceAll(' ', ''),
    );
    _syncedAadhaarDraft = draft.aadhaarNumber;

    _syncControllerFromDraft(
      textController: _panController,
      previousDraftValue: _syncedPanDraft,
      nextDraftValue: draft.panNumber,
      format: (value) => value ?? '',
      normalize: (value) => value.toUpperCase(),
    );
    _syncedPanDraft = draft.panNumber;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = TtsLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final controller = ref.read(verificationWizardProvider.notifier);
    _syncControllersWithDraft(state.draft);

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

            AppTextField(
              controller: _aadhaarController,
              label: l10n.commonAadhaarNumberLabel,
              helperText: l10n.verificationFieldPurposeAadhaar,
              hintText: '1234 5678 9012',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                _AadhaarFormatter(),
              ],
              onChanged: (value) => controller.updateAadhaarNumber(value.replaceAll(' ', '')),
              errorText: state.fieldErrors['aadhaarNumber'],
              suffixIcon: TtsCardSpeakerButton(
                message: ttsL10n.ttsFieldAadhaarInputDescription,
                onDarkSurface: false,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            DocumentUploadBox(
              label: l10n.verificationDocTypeAadhaarFront,
              documentPath: state.draft.aadhaarFrontPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.aadhaarFront,
              icon: Icons.document_scanner_outlined,
              ttsMessage: ttsL10n.ttsFieldUploadAadhaarFrontPrompt,
              onTap: () => _uploadDocument(
                context,
                ref,
                controller,
                VerificationDocumentType.aadhaarFront,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.aadhaarFront),
            ),
            const SizedBox(height: AppSpacing.lg),

            DocumentUploadBox(
              label: l10n.verificationDocTypeAadhaarBack,
              documentPath: state.draft.aadhaarBackPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.aadhaarBack,
              icon: Icons.document_scanner_outlined,
              ttsMessage: ttsL10n.ttsFieldUploadAadhaarBackPrompt,
              onTap: () => _uploadDocument(
                context,
                ref,
                controller,
                VerificationDocumentType.aadhaarBack,
              ),
              onClear: () => controller.clearIdentityDoc(VerificationDocumentType.aadhaarBack),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppTextField(
              controller: _panController,
              label: l10n.commonPanNumberLabel,
              helperText: l10n.verificationFieldPurposePan,
              hintText: 'ABCDE1234F',
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: controller.updatePanNumber,
              errorText: state.fieldErrors['panNumber'],
              suffixIcon: TtsCardSpeakerButton(
                message: ttsL10n.ttsFieldPanInputDescription,
                onDarkSurface: false,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            DocumentUploadBox(
              label: l10n.verificationWizardPanDocumentLabel,
              documentPath: state.draft.panDocumentPath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.pan,
              icon: Icons.credit_card_outlined,
              ttsMessage: ttsL10n.ttsFieldUploadPanPrompt,
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
