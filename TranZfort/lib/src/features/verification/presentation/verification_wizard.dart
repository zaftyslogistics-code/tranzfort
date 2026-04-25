import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../providers/verification_wizard_provider.dart';
import '../providers/verification_wizard_state.dart';
import 'wizard_steps/step_business_details.dart';
import 'wizard_steps/step_identity_documents.dart';
import 'wizard_steps/step_profile_photo.dart';
import 'wizard_steps/step_review_submit.dart';
import 'wizard_steps/step_truck_details.dart';

class VerificationWizard extends ConsumerStatefulWidget {
  const VerificationWizard({super.key});

  @override
  ConsumerState<VerificationWizard> createState() => _VerificationWizardState();
}

class _VerificationWizardState extends ConsumerState<VerificationWizard> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationWizardProvider);
    final l10n = AppLocalizations.of(context);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.draft.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.verificationLoadFailureTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.verificationLoadFailureMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.commonRetryAction,
                  onPressed: () => ref.invalidate(verificationWizardProvider),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Already verified - show success
    if (state.isAlreadyVerified) {
      return const _AlreadyVerifiedView();
    }

    // Pending - show status
    if (state.isPending) {
      return const _PendingStatusView();
    }

    return PopScope(
      canPop: state.currentStepIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (state.currentStepIndex > 0) {
          final shouldPop = await _showBackDialog(context, ref, state);
          if (shouldPop && mounted) {
            ref.read(verificationWizardProvider.notifier).previousStep();
          }
        } else {
          // On first step, show exit dialog
          final navigator = Navigator.of(context);
          final shouldExit = await _showExitDialog(context, ref);
          if (shouldExit && mounted) {
            navigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.verificationTitle),
          leading: state.currentStepIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => ref.read(verificationWizardProvider.notifier).previousStep(),
                )
              : null,
          actions: [
            // Exit button with save draft dialog
            TextButton(
              onPressed: () => _showExitDialog(context, ref),
              child: Text(l10n.verificationWizardSaveAndExitAction),
            ),
          ],
        ),
        body: SafeArea(
          child: _buildStepContent(state),
        ),
      ),
    );
  }

  Widget _buildStepContent(VerificationWizardState state) {
    switch (state.currentStep) {
      case WizardStep.profilePhoto:
        return const StepProfilePhoto();
      case WizardStep.identityDocuments:
        return const StepIdentityDocuments();
      case WizardStep.roleSpecific:
        return state.isTrucker
            ? const StepTruckDetails()
            : const StepBusinessDetails();
      case WizardStep.reviewSubmit:
        return const StepReviewSubmit();
    }
  }

  Future<bool> _showBackDialog(BuildContext context, WidgetRef ref, VerificationWizardState state) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go Back?'),
        content: const Text('You will lose your progress on this step. Do you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showExitDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.verificationWizardExitTitle),
        content: Text(l10n.verificationWizardExitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.verificationWizardExitAction),
          ),
          PrimaryButton(
            onPressed: () async {
              await ref.read(verificationWizardProvider.notifier).saveDraft();
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            label: l10n.verificationWizardSaveAndExitAction,
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      context.go(AppRoutes.dashboardPath);
    }
    return shouldExit ?? false;
  }
}

class _AlreadyVerifiedView extends StatelessWidget {
  const _AlreadyVerifiedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 80, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.verificationCompleteBannerTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.verificationCompleteBannerDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.commonDashboardLabel,
              onPressed: () => context.go(AppRoutes.dashboardPath),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingStatusView extends StatelessWidget {
  const _PendingStatusView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 80,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.commonVerificationPendingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.verificationPendingBannerDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PendingTimeline(),
              const SizedBox(height: AppSpacing.lg),
              OutlineButton(
                label: l10n.commonDashboardLabel,
                onPressed: () => context.go(AppRoutes.dashboardPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _TimelineItem(
          icon: Icons.check_circle,
          isComplete: true,
          title: l10n.verificationTimelinePacketSubmittedTitle,
        ),
        _TimelineConnector(),
        _TimelineItem(
          icon: Icons.rate_review,
          isComplete: false,
          isActive: true,
          title: l10n.verificationTimelineReviewInProgressTitle,
        ),
        _TimelineConnector(),
        _TimelineItem(
          icon: Icons.notifications,
          isComplete: false,
          title: l10n.verificationTimelineNotifiedTitle,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final bool isComplete;
  final bool isActive;
  final String title;

  const _TimelineItem({
    required this.icon,
    required this.isComplete,
    this.isActive = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isComplete) {
      color = AppColors.success;
    } else if (isActive) {
      color = AppColors.primary;
    } else {
      color = AppColors.textMuted;
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isComplete ? AppColors.success : Colors.transparent,
            border: Border.all(color: color),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isComplete ? Colors.white : color, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w500 : null,
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      width: 2,
      height: 24,
      color: AppColors.divider,
    );
  }
}
