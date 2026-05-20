import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Load info chip with primary/secondary hierarchy for marketplace cards.
class LoadInfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final LoadChipLevel level;
  final Color? accentColor;

  const LoadInfoChip({
    super.key,
    this.icon,
    required this.label,
    this.level = LoadChipLevel.primary,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accentColor ?? (level == LoadChipLevel.primary
        ? AppColors.textPrimary
        : AppColors.textSecondary);

    return Container(
      padding: level == LoadChipLevel.primary
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level == LoadChipLevel.primary
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: level == LoadChipLevel.primary
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: level == LoadChipLevel.primary ? 16 : 14,
              color: fg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.label.copyWith(
                  color: fg,
                  fontWeight: level == LoadChipLevel.primary
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 12, // Minimum 12px for decision-critical content
                ),
          ),
        ],
      ),
    );
  }
}

enum LoadChipLevel {
  primary,
  secondary,
  status,
}

/// Responsive chip layout for load cards with automatic wrapping.
class LoadChipWrap extends StatelessWidget {
  final List<Widget> chips;
  final double spacing;
  final double runSpacing;

  const LoadChipWrap({
    super.key,
    required this.chips,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}
