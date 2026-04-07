import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'count_up_text.dart';

enum StatCardVariant { standard, hero }

class StatCard extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final StatCardVariant variant;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
    this.variant = StatCardVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isHero = variant == StatCardVariant.hero;
    final cardColor = isHero ? AppColors.surface : AppColors.background;
    final iconSize = isHero ? AppSpacing.iconLg : AppSpacing.iconMd;
    final iconContainerSize = isHero
        ? AppSpacing.tileLeadingSize + 4
        : AppSpacing.tileLeadingSize;
    final valueStyle = isHero
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.headlineMedium;

    final cardChild = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(
          color: isHero ? AppColors.kpiChipBorder : AppColors.neutralLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: AppSpacing.sm),
          CountUpText(
            value: value,
            style: valueStyle?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return cardChild;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: cardChild,
    );
  }
}
