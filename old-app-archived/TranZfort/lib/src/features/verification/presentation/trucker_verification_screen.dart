import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_logger.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/dashboard_verification_banner.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/tts_focus_field.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../../../shared/utils/verification_status_utils.dart';
import '../providers/verification_providers.dart';

class TruckerVerificationScreen extends ConsumerStatefulWidget {
  const TruckerVerificationScreen({super.key});

  @override
  ConsumerState<TruckerVerificationScreen> createState() =>
      _TruckerVerificationScreenState();
}

class _TruckerVerificationScreenState
    extends ConsumerState<TruckerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _dlController = TextEditingController();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panPhoto;
  File? _dlFrontPhoto;
  File? _dlBackPhoto;
  File? _profilePhoto;

  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  String? _existingPanPhotoUrl;
  String? _existingDlFrontUrl;
  String? _existingDlBackUrl;
  String? _existingProfilePhotoUrl;
  String _verificationStatus = 'unverified';
  String? _verificationRejectionReason;
  bool _isEditMode = false;
  String? _ttsFieldGuidance;
  DateTime? _dlExpiryDate;

  bool get _isVerified => _verificationStatus.toLowerCase() == 'verified';
  bool get _isLocked => _isVerified && !_isEditMode;

  int _uploadedDocumentCount() {
    var count = 0;
    if (_profilePhoto != null || _existingProfilePhotoUrl != null) count++;
    if (_aadhaarFront != null || _existingAadhaarFrontUrl != null) count++;
    if (_aadhaarBack != null || _existingAadhaarBackUrl != null) count++;
    if (_panPhoto != null || _existingPanPhotoUrl != null) count++;
    if (_dlFrontPhoto != null || _existingDlFrontUrl != null) count++;
    if (_dlBackPhoto != null || _existingDlBackUrl != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  Future<void> _pickDlExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dlExpiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) {
      setState(() => _dlExpiryDate = selected);
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _dlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
    void Function(File file) onPicked,
    ImageSource source,
  ) async {
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

  Future<void> _showImageSourceSheet(void Function(File file) onPicked) async {
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

    final hasCompleteTruck = await ref
        .read(truckerVerificationProvider.notifier)
        .hasAtLeastOneCompleteTruck();
    if (!hasCompleteTruck) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationTruckRequiredMessage),
          action: SnackBarAction(
            label: l10n.findLoadsAddTruck,
            onPressed: () => context.push('/my-fleet/add'),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;

    final hasAadhaarFront =
        _aadhaarFront != null || _existingAadhaarFrontUrl != null;
    final hasAadhaarBack =
        _aadhaarBack != null || _existingAadhaarBackUrl != null;
    final hasPan = _panPhoto != null || _existingPanPhotoUrl != null;
    final hasDlFront = _dlFrontPhoto != null || _existingDlFrontUrl != null;
    final hasDlBack = _dlBackPhoto != null || _existingDlBackUrl != null;
    final hasProfilePhoto =
        _profilePhoto != null || _existingProfilePhotoUrl != null;

    if (!hasAadhaarFront ||
        !hasAadhaarBack ||
        !hasPan ||
        !hasDlFront ||
        !hasDlBack ||
        !hasProfilePhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationUploadMandatory)),
      );
      return;
    }

    await ref
        .read(truckerVerificationProvider.notifier)
        .submitVerification(
          aadhaarNumber: _aadhaarController.text.trim(),
          profilePhoto: _profilePhoto,
          aadhaarFront: _aadhaarFront,
          aadhaarBack: _aadhaarBack,
          panNumber: _panController.text.trim(),
          panPhoto: _panPhoto,
          dlNumber: _dlController.text.trim(),
          dlExpiryDate: _dlExpiryDate,
          dlFrontPhoto: _dlFrontPhoto,
          dlBackPhoto: _dlBackPhoto,
        );

    if (mounted && !ref.read(truckerVerificationProvider).hasError) {
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
    final verificationState = ref.watch(truckerVerificationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationTruckerTitle)),
      body: verificationState.when(
        data: (_) => _buildForm(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorRetry(
          message: l10n.verificationLoadError,
          onRetry: () => ref.invalidate(truckerVerificationProvider),
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
              text: _ttsFieldGuidance ?? l10n.verificationTruckerPrompt,
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
                    l10n.verificationTruckerPrompt,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.verificationTruckerSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardVerificationBanner(
              status: _verificationStatus,
              rejectionReason: _verificationRejectionReason,
            ),
            const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                const totalDocuments = 6;
                final uploaded = _uploadedDocumentCount();
                final progress = uploaded / totalDocuments;
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
                        l10n.verificationTruckerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.verificationDocumentsUploadedSummary(
                          uploaded,
                          totalDocuments,
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
                          valueColor: const AlwaysStoppedAnimation(
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
                      title: l10n.verificationIdentityDetailsSection,
                      child: Column(
                        children: [
                          _buildImagePickerRow(
                            label: l10n.verificationProfilePhotoLabel,
                            file: _profilePhoto,
                            existingUrl: _existingProfilePhotoUrl,
                            onPicked: (f) => _profilePhoto = f,
                            ttsGuidance: l10n.verificationTruckerTtsProfilePhoto,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TtsFocusField(
                            labelToSpeak: l10n.verificationTruckerTtsAadhaarNumber,
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
                                    l10n.verificationTruckerTtsAadhaarNumber,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final normalized = (v ?? '').trim();
                                return normalized.length == 12
                                    ? null
                                    : l10n.phoneInvalidNumber;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadAadhaarFront,
                            file: _aadhaarFront,
                            existingUrl: _existingAadhaarFrontUrl,
                            onPicked: (f) => _aadhaarFront = f,
                            ttsGuidance:
                                l10n.verificationTruckerTtsAadhaarFront,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadAadhaarBack,
                            file: _aadhaarBack,
                            existingUrl: _existingAadhaarBackUrl,
                            onPicked: (f) => _aadhaarBack = f,
                            ttsGuidance:
                                l10n.verificationTruckerTtsAadhaarBack,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TtsFocusField(
                            labelToSpeak: l10n.verificationTruckerTtsPanNumber,
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
                                    l10n.verificationTruckerTtsPanNumber,
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
                          const SizedBox(height: AppSpacing.md),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadPanCard,
                            file: _panPhoto,
                            existingUrl: _existingPanPhotoUrl,
                            onPicked: (f) => _panPhoto = f,
                            ttsGuidance: l10n.verificationTruckerTtsPanCard,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: l10n.verificationDrivingLicenseSection,
                      child: Column(
                        children: [
                          TtsFocusField(
                            labelToSpeak: l10n.verificationTruckerTtsDlNumber,
                            child: TextFormField(
                              controller: _dlController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 16,
                              decoration: InputDecoration(
                                labelText: l10n.verificationDlNumberLabel,
                                helperText: l10n.verificationDlHelper,
                              ),
                              onTap: () => setState(
                                () => _ttsFieldGuidance =
                                    l10n.verificationTruckerTtsDlNumber,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9-]'),
                                ),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  return newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                    selection: newValue.selection,
                                  );
                                }),
                              ],
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.authErrorValidation
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.verificationDlExpiryDateLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            readOnly: true,
                            onTap: _pickDlExpiryDate,
                            decoration: InputDecoration(
                              labelText: l10n.verificationDlExpiryDateLabel,
                              hintText: l10n.verificationSelectDateAction,
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                            controller: TextEditingController(
                              text: _dlExpiryDate == null
                                  ? ''
                                  : '${_dlExpiryDate!.day.toString().padLeft(2, '0')}/${_dlExpiryDate!.month.toString().padLeft(2, '0')}/${_dlExpiryDate!.year}',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadDlFront,
                            file: _dlFrontPhoto,
                            existingUrl: _existingDlFrontUrl,
                            onPicked: (f) => _dlFrontPhoto = f,
                            ttsGuidance: l10n.verificationTruckerTtsDlFront,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildImagePickerRow(
                            label: l10n.verificationUploadDlBack,
                            file: _dlBackPhoto,
                            existingUrl: _existingDlBackUrl,
                            onPicked: (f) => _dlBackPhoto = f,
                            ttsGuidance: l10n.verificationTruckerTtsDlBack,
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
    required void Function(File file) onPicked,
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
                ? AppColors.success
                : AppColors.neutralLight,
            width: file != null || hasExisting ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            if (file != null || hasExisting) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : Image.network(
                          existingUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.neutralLight,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(
              file != null || hasExisting
                  ? Icons.check_circle
                  : Icons.upload_file_outlined,
              color: file != null || hasExisting
                  ? AppColors.success
                  : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
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
                        ? l10n.documentAttachedTapReplace
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
            Text(
              (file != null || hasExisting)
                  ? l10n.retakeAction
                  : l10n.uploadAction,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await ref
          .read(truckerVerificationProvider.notifier)
          .loadExistingData();
      final profile =
          data['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final trucker =
          data['trucker'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      ErrorLogger.logDebug(
        'Trucker verification data loaded',
        context: {
          'module': 'trucker_verification',
          'profileId': profile['id'],
          'role': profile['user_role_type'],
          'rawVerificationStatus': profile['verification_status'],
          'normalizedVerificationStatus': normalizeVerificationStatus(
            profile['verification_status'],
          ),
          'hasDlNumber': (trucker['dl_number'] ?? '').toString().trim().isNotEmpty,
          'hasDlFront': (trucker['dl_front_photo_url'] ?? '')
              .toString()
              .trim()
              .isNotEmpty,
          'hasDlBack': (trucker['dl_back_photo_url'] ?? '')
              .toString()
              .trim()
              .isNotEmpty,
        },
      );

      if (!mounted) return;

      setState(() {
        _aadhaarController.text = (profile['aadhaar_number'] ?? '').toString();
        _panController.text = (profile['pan_number'] ?? '').toString();
        _dlController.text = (trucker['dl_number'] ?? '').toString();
        final dlExpiryRaw = (trucker['dl_expiry_date'] ?? '').toString();
        _dlExpiryDate = DateTime.tryParse(dlExpiryRaw);

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
        _existingProfilePhotoUrl =
            (profile['avatar_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['avatar_url']?.toString();
        _existingDlFrontUrl =
            (trucker['dl_front_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : trucker['dl_front_photo_url']?.toString();
        _existingDlBackUrl =
            (trucker['dl_back_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : trucker['dl_back_photo_url']?.toString();

        _verificationStatus = normalizeVerificationStatus(
          profile['verification_status'],
        );
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
