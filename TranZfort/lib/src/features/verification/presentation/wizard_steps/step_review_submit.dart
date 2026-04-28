import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../providers/verification_wizard_provider.dart';
import '../components/step_container.dart';
import '../components/wizard_progress_bar.dart';

class StepReviewSubmit extends ConsumerWidget {
  const StepReviewSubmit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final controller = ref.read(verificationWizardProvider.notifier);
    final draft = state.draft;

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
              title: l10n.verificationWizardReviewTitle,
              subtitle: l10n.verificationWizardReviewSubtitle,
              currentStep: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabels: stepLabels,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Checklist
            _ReviewSection(
              icon: Icons.person,
              title: l10n.commonProfileLabel,
              isComplete: draft.hasProfilePhoto,
              details: draft.hasProfilePhoto
                  ? [l10n.verificationWizardReviewProfileUploaded]
                  : [l10n.verificationWizardReviewProfileMissing],
            ),
            _ReviewSection(
              icon: Icons.badge_outlined,
              title: l10n.verificationWizardReviewIdentity,
              isComplete: draft.hasIdentityComplete,
              details: [
                '${l10n.commonAadhaarNumberLabel}: ${draft.aadhaarNumber ?? '-'}',
                '${l10n.commonPanNumberLabel}: ${draft.panNumber ?? '-'}',
                if (draft.hasIdentityComplete)
                  l10n.verificationWizardReviewDocumentsUploaded,
              ],
            ),
            if (state.isTrucker)
              _ReviewSection(
                icon: Icons.local_shipping,
                title: l10n.verificationWizardReviewTruck,
                isComplete: draft.hasTruckComplete,
                details: [
                  '${l10n.commonTruckNumberLabel}: ${draft.truck?.truckNumber ?? '-'}',
                  if (draft.truck?.rcDocumentPath != null)
                    l10n.verificationWizardReviewRcUploaded,
                  if (draft.truck?.truckPhotoPath != null)
                    l10n.verificationWizardReviewTruckPhotoUploaded,
                ],
              ),
            if (state.isSupplier)
              _ReviewSection(
                icon: Icons.business,
                title: l10n.verificationWizardReviewBusiness,
                isComplete: draft.hasBusinessComplete,
                details: [
                  '${l10n.commonCompanyNameLabel}: ${draft.companyName ?? '-'}',
                  '${l10n.verificationWizardReviewLicenseNumber}: ${draft.businessLicenseNumber ?? '-'}',
                  if (draft.gstNumber?.isNotEmpty ?? false)
                    '${l10n.commonGstNumberLabel}: ${draft.gstNumber}',
                  '${l10n.verificationWizardReviewLocation}: ${draft.location?.city ?? '-'}',
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Terms checkbox
            _TermsCheckbox(
              isChecked: state.termsAccepted,
              onChanged: (v) => controller.setTermsAccepted(v ?? false),
              error: state.fieldErrors['terms'],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Error display
            if (state.error != null)
              Text(
                _getErrorMessage(state.error!, l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Submit button
            PrimaryButton(
              label: state.isResubmission
                  ? l10n.verificationResubmitForReviewAction
                  : l10n.verificationSubmitForReviewAction,
              onPressed: state.canProceed && !state.isSubmitting
                  ? () => _submit(context, ref)
                  : null,
              isLoading: state.isSubmitting,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                l10n.verificationWizardReviewTimelineMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Back button
            OutlineButton(
              label: l10n.verificationWizardBackAction,
              onPressed: state.isSubmitting ? null : controller.previousStep,
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(AppFailure error, AppLocalizations l10n) {
    if (error is BusinessRuleFailure) {
      return error.message;
    }
    if (error is ValidationFailure) {
      return l10n.verificationWizardValidationError;
    }
    if (error is UnauthorizedFailure) {
      return l10n.verificationWizardUnauthorizedError;
    }
    return l10n.verificationWizardUnknownError;
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(verificationWizardProvider.notifier).submit();

    if (!context.mounted) return;

    result.when(
      success: (caseId) {
        final verificationState = ref.read(verificationWizardProvider);
        final role = verificationState.isSupplier ? 'supplier' : (verificationState.isTrucker ? 'trucker' : null);
        context.go(AppRoutes.homeForRole(role));
      },
      failure: (error) {
      },
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isComplete;
  final List<String> details;

  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.isComplete,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isComplete ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                isComplete ? Icons.check_circle : Icons.error_outline,
                color: isComplete ? AppColors.success : AppColors.warning,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 2),
            child: Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final String? error;

  const _TermsCheckbox({
    required this.isChecked,
    required this.onChanged,
    this.error,
  });

  @override
  State<_TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<_TermsCheckbox> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.isChecked,
              onChanged: widget.onChanged,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onChanged(!widget.isChecked),
                child: Text(
                  AppLocalizations.of(context).verificationWizardTermsText,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              widget.error!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
