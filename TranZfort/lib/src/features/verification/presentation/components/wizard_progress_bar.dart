import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class WizardProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final double height;

  const WizardProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = (index ~/ 2);
          final isActive = stepBefore < current;
          
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? AppColors.primary : AppColors.divider,
            ),
          );
        }
        
        // Dot
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < current;
        final isCurrent = stepIndex == current;
        
        return Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent 
                ? AppColors.primary 
                : AppColors.divider,
            border: Border.all(
              color: isCurrent ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: isCompleted 
              ? Icon(
                  Icons.check, 
                  size: height * 0.6, 
                  color: Colors.white,
                )
              : null,
        );
      }),
    );
  }
}

class WizardStepLabels extends StatelessWidget {
  final int current;
  final int total;
  final List<String> labels;

  const WizardStepLabels({
    super.key,
    required this.current,
    required this.total,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(total, (index) {
        final isActive = index <= current;
        final isCurrent = index == current;
        
        return Expanded(
          child: Text(
            labels[index],
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }
}

class WizardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const WizardHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
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
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WizardProgressBar(
          current: currentStep,
          total: totalSteps,
        ),
        const SizedBox(height: 8),
        WizardStepLabels(
          current: currentStep,
          total: totalSteps,
          labels: stepLabels,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
