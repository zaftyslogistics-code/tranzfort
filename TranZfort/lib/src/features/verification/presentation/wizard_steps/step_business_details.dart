import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../data/verification_repository.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/city_search_sheet.dart';
import '../components/document_upload_box.dart';
import '../components/step_container.dart';
import '../components/wizard_progress_bar.dart';

class StepBusinessDetails extends ConsumerWidget {
  const StepBusinessDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final controller = ref.read(verificationWizardProvider.notifier);
    final draft = state.draft;

    final List<String> stepLabels = [
      l10n.verificationWizardStepPhoto,
      l10n.verificationWizardStepIdentity,
      l10n.verificationWizardStepBusiness,
      l10n.verificationWizardStepReview,
    ];

    return StepContainer(
      stepIndex: state.currentStepIndex,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WizardHeader(
              title: l10n.verificationWizardBusinessTitle,
              subtitle: l10n.verificationWizardBusinessSubtitle,
              currentStep: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabels: stepLabels,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Company Name
            AppTextField(
              label: l10n.verificationWizardCompanyNameLabel,
              hintText: l10n.verificationWizardCompanyNameHint,
              controller: TextEditingController(text: draft.companyName ?? ''),
              onChanged: controller.updateCompanyName,
              errorText: state.fieldErrors['companyName'],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // License Number
            AppTextField(
              label: l10n.verificationWizardLicenseNumberLabel,
              hintText: l10n.verificationWizardLicenseNumberHint,
              controller: TextEditingController(text: draft.businessLicenseNumber ?? ''),
              onChanged: controller.updateBusinessLicenseNumber,
              errorText: state.fieldErrors['businessLicenseNumber'],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // License Document
            DocumentUploadBox(
              label: l10n.verificationWizardLicenseDocumentLabel,
              documentPath: draft.businessLicensePath,
              isRequired: true,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.businessLicence,
              icon: Icons.business_center_outlined,
              onTap: () => _uploadDocument(
                context,
                controller,
                VerificationDocumentType.businessLicence,
              ),
              onClear: controller.clearBusinessLicense,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // GST (Optional) - Expandable
            _OptionalGstSection(
              gstNumber: draft.gstNumber,
              gstPath: draft.gstCertificatePath,
              isUploading: state.uploadingDocumentType == VerificationDocumentType.gstCertificate,
              onGstNumberChanged: controller.updateGstNumber,
              onUpload: () => _uploadDocument(
                context,
                controller,
                VerificationDocumentType.gstCertificate,
              ),
              onClear: controller.clearGstCertificate,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Verification Location
            _LocationSection(
              location: draft.location,
              isCapturing: state.isCapturingLocation,
              onCapture: () => _handleLocationCapture(context, ref),
              onManualEntry: () => _showManualLocationDialog(context, ref),
              onClear: controller.clearLocation,
              fieldError: state.fieldErrors['location'],
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

  Future<void> _uploadDocument(
    BuildContext context,
    VerificationWizardController controller,
    VerificationDocumentType type,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => ImageSourcePicker(
        onSelected: (s) => Navigator.pop(context, s),
      ),
    );

    if (source == null) return;

    if (type == VerificationDocumentType.businessLicence) {
      await controller.uploadBusinessLicense(source);
    } else {
      await controller.uploadGstCertificate(source);
    }
  }

  Future<void> _handleLocationCapture(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(verificationWizardProvider.notifier);
    final result = await controller.captureLocation();

    if (!context.mounted) return;

    if (result.error == LocationCaptureError.serviceDisabled) {
      final shouldOpenSettings = await _showGpsDisabledDialog(context);
      if (shouldOpenSettings) {
        await Geolocator.openLocationSettings();
        // Retry after user returns
        _handleLocationCapture(context, ref);
      }
    } else if (result.error == LocationCaptureError.permissionDeniedForever) {
      final shouldOpenSettings = await _showPermissionDeniedDialog(context);
      if (shouldOpenSettings) {
        await Geolocator.openAppSettings();
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture location. Please try again.')),
      );
    }
  }

  Future<bool> _showGpsDisabledDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.verificationWizardLocationServicesOffTitle),
            content: Text(l10n.verificationWizardLocationServicesOffMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              PrimaryButton(
                onPressed: () => Navigator.pop(context, true),
                label: l10n.verificationWizardOpenSettingsAction,
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showPermissionDeniedDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.verificationWizardLocationPermissionTitle),
            content: Text(l10n.verificationWizardLocationPermissionMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              PrimaryButton(
                onPressed: () => Navigator.pop(context, true),
                label: l10n.verificationWizardOpenSettingsAction,
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showManualLocationDialog(BuildContext context, WidgetRef ref) {
    // Uses city search autocomplete component
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySearchSheet(
        onCitySelected: (city) {
          Navigator.pop(context);
          ref.read(verificationWizardProvider.notifier).setManualLocation(
            city: city.city,
            region: city.state,
            latitude: city.lat ?? 0,
            longitude: city.lng ?? 0,
          );
        },
      ),
    );
  }
}

class _OptionalGstSection extends StatefulWidget {
  final String? gstNumber;
  final String? gstPath;
  final bool isUploading;
  final ValueChanged<String> onGstNumberChanged;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  const _OptionalGstSection({
    required this.gstNumber,
    required this.gstPath,
    required this.isUploading,
    required this.onGstNumberChanged,
    required this.onUpload,
    required this.onClear,
  });

  @override
  State<_OptionalGstSection> createState() => _OptionalGstSectionState();
}

class _OptionalGstSectionState extends State<_OptionalGstSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasData = (widget.gstNumber?.isNotEmpty ?? false) || 
                    (widget.gstPath?.isNotEmpty ?? false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.verificationWizardGstDetailsTitle),
            subtitle: Text(
              hasData ? l10n.verificationWizardGstDetailsAdded : l10n.verificationWizardGstOptional,
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  AppTextField(
                    label: l10n.verificationWizardGstNumberLabel,
                    hintText: '22AAAAA0000A1Z5',
                    controller: TextEditingController(text: widget.gstNumber ?? ''),
                    onChanged: widget.onGstNumberChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DocumentUploadBox(
                    label: l10n.verificationWizardGstCertificateLabel,
                    documentPath: widget.gstPath,
                    isRequired: false,
                    isUploading: widget.isUploading,
                    icon: Icons.receipt_outlined,
                    onTap: widget.onUpload,
                    onClear: widget.onClear,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final WizardLocation? location;
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onManualEntry;
  final VoidCallback onClear;
  final String? fieldError;

  const _LocationSection({
    required this.location,
    required this.isCapturing,
    required this.onCapture,
    required this.onManualEntry,
    required this.onClear,
    this.fieldError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = location != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).verificationLocationTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hasLocation ? AppColors.successBg : AppColors.neutralBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLocation ? AppColors.success : AppColors.divider,
            ),
          ),
          child: isCapturing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              : hasLocation
                  ? _LocationDisplay(
                      location: location!,
                      onClear: onClear,
                    )
                  : _LocationEmpty(
                      onCapture: onCapture,
                      onManualEntry: onManualEntry,
                    ),
        ),
        if (fieldError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            fieldError!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationDisplay extends StatelessWidget {
  final WizardLocation location;
  final VoidCallback onClear;

  const _LocationDisplay({
    required this.location,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: AppColors.success, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${location.city}, ${location.state ?? ''}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClear,
              color: AppColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          location.source == 'gps'
              ? l10n.verificationWizardCapturedViaGps
              : l10n.verificationWizardAddedManually,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LocationEmpty extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onManualEntry;

  const _LocationEmpty({
    required this.onCapture,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 48,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppLocalizations.of(context).verificationLocationRequiredMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            PrimaryButton(
              label: AppLocalizations.of(context).verificationCaptureLocationAction,
              onPressed: onCapture,
            ),
            OutlineButton(
              label: AppLocalizations.of(context).verificationManualLocationAction,
              onPressed: onManualEntry,
            ),
          ],
        ),
      ],
    );
  }
}
