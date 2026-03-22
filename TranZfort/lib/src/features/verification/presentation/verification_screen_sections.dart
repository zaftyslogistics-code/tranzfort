part of 'verification_screen.dart';

class _VerificationPacketFieldsSection extends ConsumerStatefulWidget {
  final VerificationDetail detail;

  const _VerificationPacketFieldsSection({required this.detail});

  @override
  ConsumerState<_VerificationPacketFieldsSection> createState() => _VerificationPacketFieldsSectionState();
}

class _VerificationPacketFieldsSectionState extends ConsumerState<_VerificationPacketFieldsSection> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _aadhaarController;
  late final TextEditingController _panController;
  late final TextEditingController _businessLicenceController;
  late final TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.detail.companyName ?? '');
    _aadhaarController = TextEditingController(text: widget.detail.aadhaarNumber ?? '');
    _panController = TextEditingController(text: widget.detail.panNumber ?? '');
    _businessLicenceController = TextEditingController(text: widget.detail.businessLicenceNumber ?? '');
    _gstController = TextEditingController(text: widget.detail.gstNumber ?? '');
  }

  @override
  void didUpdateWidget(covariant _VerificationPacketFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _syncController(_companyNameController, widget.detail.companyName ?? '');
      _syncController(_aadhaarController, widget.detail.aadhaarNumber ?? '');
      _syncController(_panController, widget.detail.panNumber ?? '');
      _syncController(_businessLicenceController, widget.detail.businessLicenceNumber ?? '');
      _syncController(_gstController, widget.detail.gstNumber ?? '');
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _businessLicenceController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    final verificationState = ref.watch(verificationProvider);
    final actionFailure = verificationState.actionFailure;
    final fieldErrors = actionFailure is ValidationFailure
        ? (actionFailure.fieldErrors ?? const <String, String>{})
        : const <String, String>{};
    final isLocked = detail.isPending || detail.isVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.isSupplier) ...[
          AppTextField(
            controller: _companyNameController,
            label: l10n.verificationFieldCompanyName,
            errorText: fieldErrors['company_name'],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          controller: _aadhaarController,
          label: l10n.verificationFieldAadhaarNumber,
          keyboardType: TextInputType.number,
          errorText: fieldErrors['aadhaar_number'],
        ),
        if (detail.isTrucker) ...[
          const SizedBox(height: AppSpacing.sm),
          _TruckerInlineDocumentUpload(
            detail: detail,
            type: VerificationDocumentType.aadhaarFront,
            uploadingType: verificationState.uploadingDocumentType,
            isLocked: isLocked,
          ),
          const SizedBox(height: AppSpacing.xs),
          _TruckerInlineDocumentUpload(
            detail: detail,
            type: VerificationDocumentType.aadhaarBack,
            uploadingType: verificationState.uploadingDocumentType,
            isLocked: isLocked,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _panController,
          label: l10n.verificationFieldPanNumber,
          errorText: fieldErrors['pan_number'],
        ),
        if (detail.isTrucker) ...[
          const SizedBox(height: AppSpacing.sm),
          _TruckerInlineDocumentUpload(
            detail: detail,
            type: VerificationDocumentType.pan,
            uploadingType: verificationState.uploadingDocumentType,
            isLocked: isLocked,
          ),
        ],
        if (detail.isSupplier) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _businessLicenceController,
            label: l10n.verificationFieldBusinessLicenceNumber,
            errorText: fieldErrors['business_licence_number'],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _gstController,
            label: l10n.verificationFieldGstNumber,
            helperText: l10n.verificationFieldGstOptional,
            errorText: fieldErrors['gst_number'],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: l10n.verificationSavePacketAction,
            onPressed: isLocked
                ? null
                : () async {
                    final result = await ref.read(verificationProvider.notifier).saveVerificationPacketFields(
                          companyName: detail.isSupplier ? _companyNameController.text : null,
                          aadhaarNumber: _aadhaarController.text,
                          panNumber: _panController.text,
                          businessLicenceNumber: detail.isSupplier ? _businessLicenceController.text : null,
                          gstNumber: detail.isSupplier ? _gstController.text : null,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    AppSnackbar.show(
                      context: context,
                      message: result.isSuccess ? l10n.verificationSaveSuccessMessage : l10n.verificationSaveFailureMessage,
                      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                    );
                  },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isLocked
              ? (detail.isVerified
                    ? l10n.verificationLockedVerifiedGuidance
                    : l10n.verificationLockedPendingGuidance)
              : (detail.isSupplier
                    ? l10n.verificationUnlockedSupplierGuidance
                    : l10n.verificationUnlockedTruckerGuidance),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

String _localizedDocTypeLabel(AppLocalizations l10n, VerificationDocumentType type) {
  return switch (type) {
    VerificationDocumentType.aadhaarFront => l10n.verificationDocTypeAadhaarFront,
    VerificationDocumentType.aadhaarBack => l10n.verificationDocTypeAadhaarBack,
    VerificationDocumentType.pan => l10n.verificationDocTypePan,
    VerificationDocumentType.profilePhoto => l10n.verificationDocTypeProfilePhoto,
    VerificationDocumentType.businessLicence => l10n.verificationDocTypeBusinessLicence,
    VerificationDocumentType.gstCertificate => l10n.verificationDocTypeGstCertificate,
  };
}

String? _localizedSubmissionBlockedReason(AppLocalizations l10n, VerificationDetail detail) {
  if (detail.isVerified) {
    return l10n.verificationBlockedAlreadyComplete;
  }
  if (detail.isPending) {
    return l10n.verificationBlockedUnderReview;
  }
  if (!detail.hasIdentityNumbers) {
    return l10n.verificationBlockedMissingIdentity;
  }
  if (!detail.hasSupplierCompanyName) {
    return l10n.verificationBlockedMissingCompanyName;
  }
  if (!detail.hasSupplierBusinessNumbers) {
    return l10n.verificationBlockedMissingBusinessNumbers;
  }
  for (final type in detail.visibleDocuments) {
    if (detail.isDocumentRequired(type) && !detail.isDocumentUploaded(type)) {
      return l10n.verificationBlockedMissingDocument(_localizedDocTypeLabel(l10n, type));
    }
  }
  if (detail.isSupplier && !detail.hasVerificationLocation) {
    return l10n.verificationBlockedMissingLocation;
  }
  if (!detail.hasVerificationReadyTruckRequirement) {
    return l10n.verificationBlockedMissingTruck;
  }
  return null;
}

String _localizedVerificationStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return l10n.verificationStatusVerified;
    case 'pending':
      return l10n.verificationStatusPending;
    case 'rejected':
      return l10n.verificationStatusRejected;
    case 'unverified':
      return l10n.verificationStatusUnverified;
    default:
      if (status.trim().isEmpty) {
        return l10n.verificationStatusUnknown;
      }
      return l10n.verificationStatusUnknown;
  }
}

class _VerificationBannerSection extends StatelessWidget {
  final VerificationDetail detail;

  const _VerificationBannerSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (detail.isPending) {
      return VerificationBanner(
        status: VerificationBannerStatus.pending,
        title: l10n.verificationPendingBannerTitle,
        description: l10n.verificationPendingBannerDescription,
      );
    }
    if (detail.isVerified) {
      return VerificationBanner(
        status: VerificationBannerStatus.approved,
        title: l10n.verificationCompleteBannerTitle,
        description: l10n.verificationCompleteBannerDescription,
      );
    }
    if (detail.isRejected) {
      return VerificationBanner(
        status: VerificationBannerStatus.rejected,
        title: l10n.verificationNeedsAttentionBannerTitle,
        description: l10n.verificationNeedsAttentionBannerDescription,
      );
    }
    return WarningBlock(
      title: l10n.verificationNotSubmittedTitle,
      message: detail.isSupplier
          ? l10n.verificationNotSubmittedSupplierMessage
          : l10n.verificationNotSubmittedTruckerMessage,
    );
  }
}

class _TruckerInlineDocumentUpload extends ConsumerWidget {
  final VerificationDetail detail;
  final VerificationDocumentType type;
  final VerificationDocumentType? uploadingType;
  final bool isLocked;

  const _TruckerInlineDocumentUpload({
    required this.detail,
    required this.type,
    required this.uploadingType,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uploaded = detail.isDocumentUploaded(type);
    final isUploading = uploadingType == type;
    final label = _localizedDocumentTypeLabel(l10n, type);

    return Row(
      children: [
        Icon(
          uploaded ? Icons.check_circle_outline : Icons.upload_file_outlined,
          size: 18,
          color: uploaded ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            uploaded ? '$label uploaded' : '$label required',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: uploaded ? AppColors.success : AppColors.textSecondary,
                ),
          ),
        ),
        if (!isLocked)
          isUploading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: () async {
                    final source = await VerificationScreen._selectImageSource(context, label);
                    if (source == null || !context.mounted) return;
                    final result = await ref.read(verificationProvider.notifier).uploadDocument(type: type, source: source);
                    if (!context.mounted) return;
                    AppSnackbar.show(
                      context: context,
                      message: result.isSuccess
                          ? l10n.verificationDocumentUploadedSuccess(label)
                          : l10n.verificationDocumentUploadFailureMessage,
                      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                    );
                  },
                  child: Text(uploaded ? l10n.verificationReplaceDocumentAction : l10n.verificationUploadDocumentAction),
                ),
      ],
    );
  }
}

class _VerificationSubmitSection extends ConsumerWidget {
  final VerificationDetail detail;
  final VerificationState state;

  const _VerificationSubmitSection({required this.detail, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLocked = detail.isPending || detail.isVerified;

    if (isLocked) {
      return DetailSectionCard(
        title: 'Verification Status',
        children: [
          StandardListCard(
            accent: detail.isVerified ? AppColors.success : AppColors.primary,
            title: detail.isVerified ? 'Verified' : 'Under Review',
            subtitle: detail.isVerified
                ? 'Your verification has been approved. No action needed.'
                : 'Your documents are being reviewed. You will be notified once the review is complete.',
            trailing: StatusChip(
              label: _localizedVerificationStatus(l10n, detail.verificationStatus),
            ),
          ),
        ],
      );
    }

    final checks = <_ReadinessCheck>[
      _ReadinessCheck(
        label: 'Aadhaar number',
        done: (detail.aadhaarNumber ?? '').trim().isNotEmpty,
      ),
      _ReadinessCheck(
        label: 'PAN number',
        done: (detail.panNumber ?? '').trim().isNotEmpty,
      ),
      _ReadinessCheck(
        label: 'Aadhaar front photo',
        done: detail.isDocumentUploaded(VerificationDocumentType.aadhaarFront),
      ),
      _ReadinessCheck(
        label: 'Aadhaar back photo',
        done: detail.isDocumentUploaded(VerificationDocumentType.aadhaarBack),
      ),
      _ReadinessCheck(
        label: 'PAN photo',
        done: detail.isDocumentUploaded(VerificationDocumentType.pan),
      ),
      if (detail.isSupplier) ...[
        _ReadinessCheck(
          label: 'Company name',
          done: (detail.companyName ?? '').trim().isNotEmpty,
        ),
        _ReadinessCheck(
          label: 'Business licence number',
          done: (detail.businessLicenceNumber ?? '').trim().isNotEmpty,
        ),
        _ReadinessCheck(
          label: 'Business licence document',
          done: detail.isDocumentUploaded(VerificationDocumentType.businessLicence),
        ),
        _ReadinessCheck(
          label: 'Verification location',
          done: detail.hasVerificationLocation,
        ),
      ],
      if (detail.isTrucker)
        _ReadinessCheck(
          label: 'Truck with RC document',
          done: detail.hasVerificationReadyTruckRequirement,
        ),
    ];

    final allDone = checks.every((c) => c.done);
    final doneCount = checks.where((c) => c.done).length;
    final blockedReason = _localizedSubmissionBlockedReason(l10n, detail);

    return DetailSectionCard(
      title: detail.isTrucker ? 'Step 3: Submit for Verification' : 'Submit for Verification',
      children: [
        Text(
          'Complete all items below, then tap Submit to send your documents for admin review.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutralBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allDone ? Icons.check_circle : Icons.pending_outlined,
                    color: allDone ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$doneCount / ${checks.length} completed',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: allDone ? AppColors.success : AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final check in checks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        check.done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        size: 16,
                        color: check.done ? AppColors.success : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          check.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: check.done ? AppColors.textSecondary : AppColors.textPrimary,
                                decoration: check.done ? TextDecoration.lineThrough : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (blockedReason != null && !allDone) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            blockedReason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: detail.isRejected
                ? l10n.verificationResubmitForReviewAction
                : l10n.verificationSubmitForReviewAction,
            isLoading: state.isSubmitting,
            onPressed: detail.canSubmitForReview && !state.isSubmitting
                ? () async {
                    final result = await ref.read(verificationProvider.notifier).submitForReview();
                    if (!context.mounted) return;
                    AppSnackbar.show(
                      context: context,
                      message: result.isSuccess
                          ? detail.isRejected
                              ? l10n.verificationResubmittedSuccess
                              : l10n.verificationSubmittedSuccess
                          : l10n.verificationSubmitFailureMessage,
                      variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Once submitted, your details will be locked until the admin completes the review.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ReadinessCheck {
  final String label;
  final bool done;
  const _ReadinessCheck({required this.label, required this.done});
}

class TruckerInlineTruckSection extends ConsumerStatefulWidget {
  final VerificationDetail detail;

  const TruckerInlineTruckSection({super.key, required this.detail});

  @override
  ConsumerState<TruckerInlineTruckSection> createState() => _TruckerInlineTruckSectionState();
}

class _TruckerInlineTruckSectionState extends ConsumerState<TruckerInlineTruckSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    final isLocked = detail.isPending || detail.isVerified;

    return DetailSectionCard(
      title: 'Step 2: Truck Details',
      children: [
        if (detail.hasVerificationReadyTruckRequirement)
          StandardListCard(
            accent: AppColors.success,
            title: l10n.verificationReadyTruckCountLabel(detail.verificationReadyTruckCount),
            subtitle: l10n.verificationTruckReadyWithRcFooter,
            trailing: const StatusChip(label: 'Ready'),
          )
        else
          WarningBlock(
            title: l10n.verificationTruckPacketStillRequiredTitle,
            message: l10n.verificationTruckPacketStillRequiredMessage,
          ),
        if (!isLocked) ...[
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: detail.hasVerificationReadyTruckRequirement
                ? l10n.verificationOpenFleetAction
                : l10n.verificationOpenFleetAction,
            onPressed: () => context.go('${AppRoutes.fleetPath}?returnTo=verification'),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add or manage your truck with RC document from the fleet screen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
