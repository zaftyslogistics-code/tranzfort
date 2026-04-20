import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class HeroActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget child;
  final Widget? primaryAction;
  final bool compact;

  const HeroActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.primaryAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardWash,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.hero,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          ],
          Text(title, style: compact ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.titleLarge),
          if (hasSubtitle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
          child,
          if (primaryAction != null) ...[
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            primaryAction!,
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final String? helperText;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(helperText!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StandardListCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  const StandardListCard({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
            border: Border.all(color: AppColors.divider),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.card),
                      bottomLeft: Radius.circular(AppRadius.card),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          trailing!,
                        ],
                      ],
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class WarningBlock extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  const WarningBlock({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasMessage = message.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: (compact ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleMedium)?.copyWith(
                  color: AppColors.warning,
                ),
          ),
          if (hasMessage) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.superLoadText,
                  ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
