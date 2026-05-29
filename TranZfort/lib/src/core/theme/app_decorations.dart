import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Shared brand gradient decorations for cards and chips.
///
/// Source: docs/final-polish.md FP-0 — consume from shared widgets only.
class AppDecorations {
  AppDecorations._();

  static const double brandGradientBorderWidth = 1.2;

  static LinearGradient get brandGradient => AppColors.heroCta;

  /// Teal→orange fill for accent chips on dark surfaces (marketplace fact chips).
  static BoxDecoration brandGradientChipDecoration({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(AppRadius.chip)),
  }) {
    return BoxDecoration(
      gradient: brandGradient,
      borderRadius: borderRadius,
    );
  }

  /// Outer gradient stroke; pair with [brandGradientBorderInnerDecoration] on an inset child.
  static BoxDecoration brandGradientBorderOuter({
    BorderRadius borderRadius = BorderRadius.zero,
    double width = brandGradientBorderWidth,
  }) {
    return BoxDecoration(
      gradient: brandGradient,
      borderRadius: borderRadius,
    );
  }

  /// Inner surface inset inside [brandGradientBorderOuter] by [width].
  static BoxDecoration brandGradientBorderInner({
    required Color backgroundColor,
    BorderRadius borderRadius = BorderRadius.zero,
    double width = brandGradientBorderWidth,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: _insetRadius(borderRadius, width),
    );
  }

  /// Dark marketplace card fill (matches existing ink gradient top color).
  static BoxDecoration marketplaceCardSurface({
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.inkSurface,
          AppColors.inkMid,
        ],
      ),
      borderRadius: borderRadius,
    );
  }

  static BorderRadius _insetRadius(BorderRadius radius, double inset) {
    return BorderRadius.only(
      topLeft: Radius.circular(_inset(radius.topLeft.x, inset)),
      topRight: Radius.circular(_inset(radius.topRight.x, inset)),
      bottomLeft: Radius.circular(_inset(radius.bottomLeft.x, inset)),
      bottomRight: Radius.circular(_inset(radius.bottomRight.x, inset)),
    );
  }

  static double _inset(double value, double inset) {
    final next = value - inset;
    return next < 0 ? 0 : next;
  }
}

/// Brand teal→orange accent chip (marketplace fact labels — not load status).
class BrandAccentChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool compact;
  final bool mini;

  const BrandAccentChip({
    super.key,
    required this.label,
    this.icon,
    this.compact = true,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = mini ? 6.0 : (compact ? AppSpacing.sm : AppSpacing.md);
    final vertical = mini ? 3.0 : (compact ? AppSpacing.xs : AppSpacing.sm);
    final fontSize = mini ? 10.0 : (compact ? 11.0 : 12.0);
    final iconSize = mini ? 12.0 : (compact ? 14.0 : 16.0);
    final showIcon = !mini && icon != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: AppDecorations.brandGradientChipDecoration(
        borderRadius: BorderRadius.circular(mini ? AppRadius.iconChip : AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: iconSize, color: AppColors.textOnPrimary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
          ),
        ],
      ),
    );
  }
}

/// Gradient border wrapper for full-bleed marketplace cards.
class BrandGradientBorder extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double width;
  final Color innerColor;

  const BrandGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.width = AppDecorations.brandGradientBorderWidth,
    this.innerColor = AppColors.inkSurface,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.brandGradientBorderOuter(borderRadius: borderRadius),
      child: Padding(
        padding: EdgeInsets.all(width),
        child: DecoratedBox(
          decoration: AppDecorations.brandGradientBorderInner(
            backgroundColor: innerColor,
            borderRadius: borderRadius,
            width: width,
          ),
          child: child,
        ),
      ),
    );
  }
}
