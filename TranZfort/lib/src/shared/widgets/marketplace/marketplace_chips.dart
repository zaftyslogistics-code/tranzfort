import 'package:flutter/material.dart';

import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';

export '../../../core/theme/app_decorations.dart' show BrandAccentChip;

/// Load info chip with primary/secondary hierarchy for marketplace cards.
///
/// Primary chips use [BrandAccentChip] (brand gradient). Secondary chips are text-only.
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
    if (level == LoadChipLevel.primary) {
      return BrandAccentChip(
        label: label,
        icon: icon,
        compact: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
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
