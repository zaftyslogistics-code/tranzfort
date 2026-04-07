import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/tts_focus_field.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../providers/verification_providers.dart';
import '../widgets/index.dart';
import 'supplier_verification_controller.dart';

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

  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  String? _existingPanPhotoUrl;
  String? _existingTanPhotoUrl;
  String? _existingGstPhotoUrl;
  String? _existingBusinessLicenceUrl;

  bool _usePan = true;
  bool _isEditMode = false;
  bool _isLocked = false;
  String? _verificationRejectionReason;
  String? _ttsFieldGuidance;

  late SupplierVerificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SupplierVerificationController(
      ref: ref,
      context: context,
      setState: (fn) => setState(fn),
      setTtsFieldGuidance: (guidance) => setState(() => _ttsFieldGuidance = guidance),
    );
    _loadExistingData();
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

  int _requiredDocumentCount() => 5;

  int _uploadedDocumentCount() {
    var count = 0;
    if (_businessLicenceDoc != null || _existingBusinessLicenceUrl != null) count++;
    if (_aadhaarFront != null || _existingAadhaarFrontUrl != null) count++;
    if (_aadhaarBack != null || _existingAadhaarBackUrl != null) count++;
    if (_usePan) {
      if (_panPhoto != null || _existingPanPhotoUrl != null) count++;
    } else {
      if (_tanPhoto != null || _existingTanPhotoUrl != null) count++;
    }
    if (_gstPhoto != null || _existingGstPhotoUrl != null) count++;
    return count;
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await ref
          .read(supplierVerificationProvider.notifier)
          .loadExistingData();
      final profile =
          data['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final supplier =
          data['supplier'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _companyNameController.text = (supplier['company_name'] ?? '').toString();
        _aadhaarController.text = (profile['aadhaar_number'] ?? '').toString();
        _panController.text = (profile['pan_number'] ?? '').toString();
        _tanController.text = (supplier['tan_number'] ?? '').toString();
        _gstController.text = (supplier['gst_number'] ?? '').toString();
        _businessLicenceController.text =
            (supplier['business_licence_number'] ?? '').toString();

        _existingAadhaarFrontUrl =
            (profile['aadhaar_front_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['aadhaar_front_photo_url']?.toString();
        _existingAadhaarBackUrl =
            (profile['aadhaar_back_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['aadhaar_back_photo_url']?.toString();
        _existingPanPhotoUrl =
            (profile['pan_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['pan_photo_url']?.toString();
        _existingTanPhotoUrl =
            (supplier['tan_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : supplier['tan_photo_url']?.toString();
        _existingGstPhotoUrl =
            (supplier['gst_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : supplier['gst_photo_url']?.toString();
        _existingBusinessLicenceUrl =
            (supplier['business_licence_doc_url'] as String?)?.trim().isEmpty == true
            ? null
            : supplier['business_licence_doc_url']?.toString();

        final status = (profile['verification_status'] ?? 'unverified')
            .toString()
            .toLowerCase();
        _isLocked = status == 'pending' || status == 'verified';
        _verificationRejectionReason = profile['verification_rejection_reason']
            ?.toString();

        if ((profile['pan_number'] ?? '').toString().isNotEmpty) {
          _usePan = true;
        } else if ((supplier['tan_number'] ?? '').toString().isNotEmpty) {
          _usePan = false;
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(supplierVerificationProvider.notifier)
        .submitVerification(
          companyName: _companyNameController.text.trim(),
          aadhaarNumber: _aadhaarController.text.trim(),
          panNumber: _panController.text.trim(),
          tanNumber: _tanController.text.trim(),
          gstNumber: _gstController.text.trim(),
          businessLicenceNumber: _businessLicenceController.text.trim(),
          aadhaarFront: _aadhaarFront,
          aadhaarBack: _aadhaarBack,
          panPhoto: _panPhoto,
          tanPhoto: _tanPhoto,
          gstPhoto: _gstPhoto,
          businessLicenceDoc: _businessLicenceDoc,
        );

    if (!mounted) return;

    if (!ref.read(supplierVerificationProvider).hasError) {
      final dialogL10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(dialogL10n.verificationSupplierTitle),
            content: Text(dialogL10n.verificationSubmitSuccess),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
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
    final verificationAsync = ref.watch(supplierVerificationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationSupplierTitle)),
      body: verificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorRetry(
            message: l10n.verificationLoadError,
            onRetry: () => ref.invalidate(supplierVerificationProvider),
          ),
        ),
        data: (_) {
          return ScreenScrollContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TtsAnnounce(
                    text: _ttsFieldGuidance ?? l10n.verificationSupplierTitle,
                  ),
                  if (_verificationRejectionReason != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorTint,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.dashboardVerificationRejectedReason(
                                _verificationRejectionReason!,
                              ),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_isLocked)
                    SectionCard(
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
                  Builder(
                    builder: (context) {
                      final uploaded = _uploadedDocumentCount();
                      final total = _requiredDocumentCount();
                      final progress = total == 0 ? 0.0 : uploaded / total;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.verificationSupplierTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.verificationDocumentsUploadedSummary(
                                uploaded,
                                total,
                              ),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0, 1),
                                minHeight: 8,
                                backgroundColor: AppColors.neutralLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IgnorePointer(
                    ignoring: _isLocked,
                    child: Opacity(
                      opacity: _isLocked ? 0.55 : 1,
                      child: Column(
                        children: [
                          SectionCard(
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
                                      () => _ttsFieldGuidance = l10n.verificationSupplierTtsCompanyName,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? l10n.authErrorValidation
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TtsFocusField(
                                  labelToSpeak: l10n.verificationSupplierTtsBusinessLicenceNumber,
                                  child: TextFormField(
                                    controller: _businessLicenceController,
                                    decoration: InputDecoration(
                                      labelText: l10n.verificationBusinessLicenceNumberLabel,
                                    ),
                                    onTap: () => setState(
                                      () => _ttsFieldGuidance = l10n.verificationSupplierTtsBusinessLicenceNumber,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? l10n.authErrorValidation
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DocumentUploadRow(
                                  label: l10n.verificationUploadBusinessLicence,
                                  file: _businessLicenceDoc,
                                  existingUrl: _existingBusinessLicenceUrl,
                                  onTap: () => _controller.handleDocumentTap(
                                    currentFile: _businessLicenceDoc,
                                    onFilePicked: (f) => setState(() => _businessLicenceDoc = f),
                                    ttsGuidance: l10n.verificationSupplierTtsBusinessLicenceDoc,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SectionCard(
                            title: l10n.verificationIdentityDetailsSection,
                            child: Column(
                              children: [
                                SegmentedButton<bool>(
                                  segments: [
                                    const ButtonSegment<bool>(
                                      value: true,
                                      label: Text('PAN'),
                                    ),
                                    const ButtonSegment<bool>(
                                      value: false,
                                      label: Text('TAN'),
                                    ),
                                  ],
                                  selected: {_usePan},
                                  onSelectionChanged: _isLocked ? null : (Set<bool> newSelection) {
                                    setState(() {
                                      _usePan = newSelection.first;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
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
                                        () => _ttsFieldGuidance = l10n.verificationSupplierTtsPanNumber,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                        TextInputFormatter.withFunction((oldValue, newValue) {
                                          return newValue.copyWith(
                                            text: newValue.text.toUpperCase(),
                                            selection: newValue.selection,
                                          );
                                        }),
                                      ],
                                      validator: (v) {
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
                                  DocumentUploadRow(
                                    label: l10n.verificationUploadPanCard,
                                    file: _panPhoto,
                                    existingUrl: _existingPanPhotoUrl,
                                    onTap: () => _controller.handleDocumentTap(
                                      currentFile: _panPhoto,
                                      onFilePicked: (f) => setState(() => _panPhoto = f),
                                      ttsGuidance: l10n.verificationSupplierTtsPanCard,
                                    ),
                                  ),
                                ] else ...[
                                  TtsFocusField(
                                    labelToSpeak:
                                        l10n.verificationSupplierTtsTanNumber,
                                    child: TextFormField(
                                      controller: _tanController,
                                      textCapitalization: TextCapitalization.characters,
                                      maxLength: 10,
                                      decoration: InputDecoration(
                                        labelText: l10n.verificationTanNumberLabel,
                                        helperText: l10n.verificationTanHelper,
                                      ),
                                      onTap: () => setState(
                                        () =>
                                            _ttsFieldGuidance = l10n.verificationSupplierTtsTanNumber,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                        TextInputFormatter.withFunction((oldValue, newValue) {
                                          return newValue.copyWith(
                                            text: newValue.text.toUpperCase(),
                                            selection: newValue.selection,
                                          );
                                        }),
                                      ],
                                      validator: (v) {
                                        final value = v?.trim() ?? '';
                                        if (value.isEmpty) return l10n.authErrorValidation;
                                        if (value.length != 10) {
                                          return l10n.verificationTanInvalid;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  DocumentUploadRow(
                                    label: l10n.verificationUploadTanCard,
                                    file: _tanPhoto,
                                    existingUrl: _existingTanPhotoUrl,
                                    onTap: () => _controller.handleDocumentTap(
                                      currentFile: _tanPhoto,
                                      onFilePicked: (f) => setState(() => _tanPhoto = f),
                                      ttsGuidance:
                                          l10n.verificationSupplierTtsTanCard,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
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
                                      () => _ttsFieldGuidance = l10n.verificationSupplierTtsAadhaarNumber,
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
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DocumentUploadRow(
                                        label: l10n.verificationUploadAadhaarFront,
                                        file: _aadhaarFront,
                                        existingUrl: _existingAadhaarFrontUrl,
                                        onTap: () => _controller.handleDocumentTap(
                                          currentFile: _aadhaarFront,
                                          onFilePicked: (f) => setState(() => _aadhaarFront = f),
                                          ttsGuidance: l10n.verificationSupplierTtsAadhaarFront,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: DocumentUploadRow(
                                        label: l10n.verificationUploadAadhaarBack,
                                        file: _aadhaarBack,
                                        existingUrl: _existingAadhaarBackUrl,
                                        onTap: () => _controller.handleDocumentTap(
                                          currentFile: _aadhaarBack,
                                          onFilePicked: (f) => setState(() => _aadhaarBack = f),
                                          ttsGuidance: l10n.verificationSupplierTtsAadhaarBack,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: l10n.verificationTaxDetailsSection,
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
                                      () => _ttsFieldGuidance = l10n.verificationSupplierTtsGstNumber,
                                    ),
                                    validator: (v) {
                                      final value = v?.trim() ?? '';
                                      if (value.isEmpty) return l10n.authErrorValidation;
                                      if (value.length != 15) {
                                        return l10n.verificationGstInvalid;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DocumentUploadRow(
                                  label: l10n.verificationUploadGstCertificate,
                                  file: _gstPhoto,
                                  existingUrl: _existingGstPhotoUrl,
                                  onTap: () => _controller.handleDocumentTap(
                                    currentFile: _gstPhoto,
                                    onFilePicked: (f) => setState(() => _gstPhoto = f),
                                    ttsGuidance: l10n.verificationSupplierTtsGstCertificate,
                                  ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
