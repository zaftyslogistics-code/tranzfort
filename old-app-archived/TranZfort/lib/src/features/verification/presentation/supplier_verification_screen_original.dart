import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/tts_focus_field.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../providers/verification_providers.dart';

class SupplierVerificationScreen extends ConsumerStatefulWidget {
  const SupplierVerificationScreen({super.key});

  @override
  ConsumerState<SupplierVerificationScreen> createState() =>
      _SupplierVerificationScreenState();
}

class _SupplierVerificationScreenState
    extends ConsumerState<SupplierVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _tanController = TextEditingController();
  final _gstController = TextEditingController();
  final _businessLicenceController = TextEditingController();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panPhoto;
  File? _tanPhoto;
  File? _gstPhoto;
  File? _businessLicenceDoc;
  File? _profilePhoto;

  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  String? _existingPanPhotoUrl;
  String? _existingTanPhotoUrl;
  String? _existingGstPhotoUrl;
  String? _existingBusinessLicenceUrl;
  
  bool _usePan = true; // true = PAN, false = TAN
  String _verificationStatus = 'unverified';
  String? _verificationRejectionReason;
  bool _isEditMode = false;
  String? _ttsFieldGuidance;

  bool get _isVerified => _verificationStatus.toLowerCase() == 'verified';
  bool get _isLocked => _isVerified && !_isEditMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _tanController.dispose();
    _gstController.dispose();
    _businessLicenceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(File) onPicked, ImageSource source) async {
    try {
      final file = await ImagePickerUtil.pickAndCompressImage(
        context: context,
        source: source,
        crop: false,
      );
      if (file != null && mounted) {
        setState(() => onPicked(file));
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationLoadError)),
      );
    }
  }

  Future<void> _showImageSourceSheet(void Function(File) onPicked) async {
    if (_isLocked || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final sheetL10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(sheetL10n.verificationChooseImageSourceTitle),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(sheetL10n.verificationUseCamera),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(sheetL10n.verificationUseGallery),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickImage(onPicked, source);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.verificationUseGallery)));
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final hasAadhaarFront =
        _aadhaarFront != null || _existingAadhaarFrontUrl != null;
    final hasAadhaarBack =
        _aadhaarBack != null || _existingAadhaarBackUrl != null;
    final hasPan = _panPhoto != null || _existingPanPhotoUrl != null;
    final hasTan = _tanPhoto != null || _existingTanPhotoUrl != null;
    final hasBusinessLicence = _businessLicenceDoc != null || _existingBusinessLicenceUrl != null;

    // Validate mandatory documents
    if (!hasAadhaarFront || !hasAadhaarBack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationUploadMandatory)),
      );
      return;
    }

    // Validate either PAN or TAN is provided
    if (_usePan && !hasPan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationUploadMandatory)),
      );
      return;
    }
    if (!_usePan && !hasTan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationUploadMandatory)),
      );
      return;
    }

    // Validate business license
    if (!hasBusinessLicence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationUploadMandatory)),
      );
      return;
    }

    await ref
        .read(supplierVerificationProvider.notifier)
        .submitVerification(
          companyName: _companyNameController.text.trim(),
          aadhaarNumber: _aadhaarController.text.trim(),
          profilePhoto: _profilePhoto,
          aadhaarFront: _aadhaarFront,
          aadhaarBack: _aadhaarBack,
          panNumber: _usePan ? _panController.text.trim() : '',
          panPhoto: _usePan ? _panPhoto : null,
          tanNumber: !_usePan ? _tanController.text.trim() : '',
          tanPhoto: !_usePan ? _tanPhoto : null,
          gstNumber: _gstController.text.trim(),
          gstPhoto: _gstPhoto,
          businessLicenceNumber: _businessLicenceController.text.trim(),
          businessLicenceDoc: _businessLicenceDoc,
        );

    if (mounted && !ref.read(supplierVerificationProvider).hasError) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final dialogL10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 48,
            ),
            title: Text(dialogL10n.verificationSubmitSuccess),
            content: Text(dialogL10n.verificationPendingMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogL10n.tripConfirmAction),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verificationState = ref.watch(supplierVerificationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationSupplierTitle)),
      body: verificationState.when(
        data: (_) => _buildForm(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorRetry(
          message: l10n.verificationLoadError,
          onRetry: () => ref.invalidate(supplierVerificationProvider),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return ScreenScrollContainer(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TtsAnnounce(
              text: _ttsFieldGuidance ?? l10n.verificationSupplierPrompt,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.verificationSupplierPrompt,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.verificationSupplierSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  _isVerified ? Icons.check_circle : Icons.warning_amber,
                  color: _isVerified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isVerified ? l10n.dashboardVerificationStatusVerified : (_verificationRejectionReason != null ? l10n.dashboardVerificationStatusRejected : l10n.dashboardVerificationStatusPending),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (_verificationRejectionReason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _verificationRejectionReason!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_isLocked)
              _SectionCard(
                title: l10n.verificationVerifiedLockedTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.verificationVerifiedLockedBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlineButton(
                      label: l10n.verificationEditAndResubmitAction,
                      onPressed: () => setState(() => _isEditMode = true),
                    ),
                  ],
                ),
              ),
            if (_isLocked) const SizedBox(height: AppSpacing.md),
            IgnorePointer(
              ignoring: _isLocked,
              child: Opacity(
                opacity: _isLocked ? 0.55 : 1,
                child: Column(
                  children: [
                    _SectionCard(
                      title: l10n.verificationCompanyDetailsSection,
                      child: Column(
                        children: [
                          TtsFocusField(
                            labelToSpeak: l10n.verificationSupplierTtsCompanyName,
                            child: TextFormField(
                              controller: _companyNameController,
                              decoration: InputDecoration(
                                labelText: l10n.verificationCompanyNameLabel,
                              ),
                              onTap: () => setState(
                                () => _ttsFieldGuidance =
                                    l10n.verificationSupplierTtsCompanyName,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? l10n.authErrorValidation : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TtsFocusField(
                            labelToSpeak:
                                l10n.verificationSupplierTtsBusinessLicenceNumber,
                            child: TextFormField(
                              controller: _businessLicenceController,
                              decoration: InputDecoration(
                                labelText: l10n.verificationBusinessLicenceNumberLabel,
                              ),
                              onTap: () => setState(
                                () => _ttsFieldGuidance =
                                    l10n
                                        .verificationSupplierTtsBusinessLicenceNumber,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? l10n.authErrorValidation : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadBusinessLicence,
                            file: _businessLicenceDoc,
                            existingUrl: _existingBusinessLicenceUrl,
                            onPicked: (f) => _businessLicenceDoc = f,
                            ttsGuidance:
                                l10n.verificationSupplierTtsBusinessLicenceDoc,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: l10n.verificationIdentityDetailsSection,
                      child: Column(
                        children: [
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(l10n.verificationPanNumberLabel),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: const Text('TAN'),
                              ),
                            ],
                            selected: {_usePan},
                            onSelectionChanged: _isLocked ? null : (Set<bool> newSelection) {
                              setState(() {
                                _usePan = newSelection.first;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_usePan) ...[
                            TtsFocusField(
                              labelToSpeak: l10n.verificationSupplierTtsPanNumber,
                              child: TextFormField(
                                controller: _panController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: l10n.verificationPanNumberLabel,
                                  helperText: l10n.verificationPanHelper,
                                ),
                                onTap: () => setState(
                                  () => _ttsFieldGuidance =
                                      l10n.verificationSupplierTtsPanNumber,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]'),
                                  ),
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return newValue.copyWith(
                                      text: newValue.text.toUpperCase(),
                                      selection: newValue.selection,
                                    );
                                  }),
                                ],
                                validator: (v) {
                                  if (!_usePan) return null;
                                  if (v == null || v.trim().isEmpty) {
                                    return l10n.authErrorValidation;
                                  }
                                  final normalized = v.trim().toUpperCase();
                                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                                  return panRegex.hasMatch(normalized)
                                      ? null
                                      : l10n.verificationPanInvalid;
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildImagePickerRow(
                              label: l10n.verificationUploadPanCard,
                              file: _panPhoto,
                              existingUrl: _existingPanPhotoUrl,
                              onPicked: (f) => _panPhoto = f,
                              ttsGuidance: l10n.verificationSupplierTtsPanCard,
                            ),
                          ] else ...[
                            TtsFocusField(
                              labelToSpeak: l10n.verificationSupplierTtsPanNumber,
                              child: TextFormField(
                                controller: _tanController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: l10n.verificationPanNumberLabel,
                                  helperText: l10n.verificationPanHelper,
                                ),
                                onTap: () => setState(
                                  () => _ttsFieldGuidance =
                                      l10n.verificationSupplierTtsPanNumber,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]'),
                                  ),
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return newValue.copyWith(
                                      text: newValue.text.toUpperCase(),
                                      selection: newValue.selection,
                                    );
                                  }),
                                ],
                                validator: (v) {
                                  if (_usePan) return null;
                                  if (v == null || v.trim().isEmpty) {
                                    return l10n.authErrorValidation;
                                  }
                                  final normalized = v.trim().toUpperCase();
                                  final tanRegex = RegExp(r'^[A-Z]{4}[0-9]{5}[A-Z]$');
                                  return tanRegex.hasMatch(normalized)
                                      ? null
                                      : l10n.verificationPanInvalid;
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildImagePickerRow(
                              label: l10n.verificationUploadPanCard,
                              file: _tanPhoto,
                              existingUrl: _existingTanPhotoUrl,
                              onPicked: (f) => _tanPhoto = f,
                              ttsGuidance: l10n.verificationSupplierTtsPanCard,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          TtsFocusField(
                            labelToSpeak: l10n.verificationSupplierTtsAadhaarNumber,
                            child: TextFormField(
                              controller: _aadhaarController,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              decoration: InputDecoration(
                                labelText: l10n.verificationAadhaarNumberLabel,
                                helperText: l10n.verificationAadhaarHelper,
                              ),
                              onTap: () => setState(
                                () => _ttsFieldGuidance =
                                    l10n.verificationSupplierTtsAadhaarNumber,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                final normalized = (v ?? '').trim();
                                return normalized.length == 12
                                    ? null
                                    : l10n.phoneInvalidNumber;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.neutralLight),
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              children: [
                                _buildImagePickerRow(
                                  label: l10n.verificationUploadAadhaarFront,
                                  file: _aadhaarFront,
                                  existingUrl: _existingAadhaarFrontUrl,
                                  onPicked: (f) => _aadhaarFront = f,
                                  ttsGuidance:
                                      l10n.verificationSupplierTtsAadhaarFront,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _buildImagePickerRow(
                                  label: l10n.verificationUploadAadhaarBack,
                                  file: _aadhaarBack,
                                  existingUrl: _existingAadhaarBackUrl,
                                  onPicked: (f) => _aadhaarBack = f,
                                  ttsGuidance:
                                      l10n.verificationSupplierTtsAadhaarBack,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: l10n.verificationCompanyDetailsSection,
                      child: Column(
                        children: [
                          TtsFocusField(
                            labelToSpeak: l10n.verificationSupplierTtsGstNumber,
                            child: TextFormField(
                              controller: _gstController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 15,
                              decoration: InputDecoration(
                                labelText: l10n.verificationGstNumberLabel,
                              ),
                              onTap: () => setState(
                                () => _ttsFieldGuidance =
                                    l10n.verificationSupplierTtsGstNumber,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  return newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                    selection: newValue.selection,
                                  );
                                }),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final normalized = v.trim().toUpperCase();
                                final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                                return gstRegex.hasMatch(normalized)
                                    ? null
                                    : l10n.authErrorValidation;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadGstCertificate,
                            file: _gstPhoto,
                            existingUrl: _existingGstPhotoUrl,
                            onPicked: (f) => _gstPhoto = f,
                            ttsGuidance:
                                l10n.verificationSupplierTtsGstCertificate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _isEditMode
                  ? l10n.verificationEditAndResubmitAction
                  : l10n.completeVerification,
              onPressed: _isLocked ? null : _submit,
            ),
            if (_isEditMode) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.verificationReverificationNotice,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required File? file,
    required void Function(File) onPicked,
    String? existingUrl,
    String? ttsGuidance,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      onTap: () {
        if (ttsGuidance != null && ttsGuidance.isNotEmpty) {
          setState(() => _ttsFieldGuidance = ttsGuidance);
        }
        _showImageSourceSheet(onPicked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: file != null || hasExisting
                ? AppColors.primary
                : AppColors.neutralLight,
            width: file != null || hasExisting ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null || hasExisting
                  ? Icons.check_circle
                  : Icons.upload_file_outlined,
              color: file != null || hasExisting
                  ? AppColors.primary
                  : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (file != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    file,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (hasExisting)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    existingUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 24,
                        height: 24,
                        color: AppColors.neutralLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    file != null || hasExisting
                        ? file != null ? '${(file.lengthSync() / 1024).toStringAsFixed(0)} KB' : l10n.documentAttachedTapReplace
                        : l10n.documentTapUploadRequired,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.verificationImageQualityHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                (file != null || hasExisting)
                    ? l10n.retakeAction
                    : l10n.uploadAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await ref
          .read(supplierVerificationProvider.notifier)
          .loadExistingData();
      final profile =
          data['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final supplier =
          data['supplier'] as Map<String, dynamic>? ??
          const <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _companyNameController.text = (supplier['company_name'] ?? '')
            .toString();
        _aadhaarController.text = (profile['aadhaar_number'] ?? '').toString();
        _panController.text = (profile['pan_number'] ?? '').toString();
        _gstController.text = (supplier['gst_number'] ?? '').toString();
        _businessLicenceController.text =
            (supplier['business_licence_number'] ?? '').toString();

        _existingAadhaarFrontUrl =
            (profile['aadhaar_front_photo_url'] as String?)?.trim().isEmpty ==
                true
            ? null
            : profile['aadhaar_front_photo_url']?.toString();
        _existingAadhaarBackUrl =
            (profile['aadhaar_back_photo_url'] as String?)?.trim().isEmpty ==
                true
            ? null
            : profile['aadhaar_back_photo_url']?.toString();
        _existingPanPhotoUrl =
            (profile['pan_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['pan_photo_url']?.toString();
        _existingGstPhotoUrl = supplier['gst_photo_url']?.toString();
        _existingBusinessLicenceUrl = supplier['business_licence_doc_url']?.toString();

        _verificationStatus = (profile['verification_status'] ?? 'unverified')
            .toString();
        _verificationRejectionReason = profile['verification_rejection_reason']
            ?.toString();
      });
    } catch (_) {
      if (!mounted) return;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
