import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';

class StepContainer extends StatelessWidget {
  final Widget child;
  final int stepIndex;
  final EdgeInsets padding;

  const StepContainer({
    super.key,
    required this.child,
    required this.stepIndex,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(stepIndex),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class StepActions extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String? continueLabel;
  final String? backLabel;
  final bool isLoading;
  final bool isContinueEnabled;

  const StepActions({
    super.key,
    this.onBack,
    this.onContinue,
    this.continueLabel,
    this.backLabel,
    this.isLoading = false,
    this.isContinueEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: continueLabel ?? l10n.onboardingSaveAndContinue,
          onPressed: isContinueEnabled && !isLoading ? onContinue : null,
          isLoading: isLoading,
        ),
        if (onBack != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: backLabel ?? 'Back',
            onPressed: isLoading ? null : onBack,
          ),
        ],
      ],
    );
  }
}

class StepErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const StepErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}
