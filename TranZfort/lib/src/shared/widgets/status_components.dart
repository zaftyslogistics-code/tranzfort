import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class StatusPalette {
  final Color foreground;
  final Color background;

  const StatusPalette({
    required this.foreground,
    required this.background,
  });
}

StatusPalette statusPaletteFor(String status) {
  final normalized = status.trim().toLowerCase();

  switch (normalized) {
    case 'verified':
    case 'approved':
    case 'completed':
    case 'resolved':
    case 'active':
    case 'success':
      return const StatusPalette(
        foreground: AppColors.success,
        background: AppColors.successBg,
      );
    case 'pending':
    case 'submitted':
    case 'under_review':
    case 'warning':
    case 'assigned_partial':
      return const StatusPalette(
        foreground: AppColors.warning,
        background: AppColors.warningBg,
      );
    case 'rejected':
    case 'cancelled':
    case 'deactivated':
    case 'error':
    case 'banned':
      return const StatusPalette(
        foreground: AppColors.error,
        background: AppColors.errorBg,
      );
    case 'info':
    case 'in_transit':
    case 'open':
    case 'unread':
      return const StatusPalette(
        foreground: AppColors.info,
        background: AppColors.infoBg,
      );
    default:
      return const StatusPalette(
        foreground: AppColors.neutral,
        background: AppColors.neutralBg,
      );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final bool showDot;
  final StatusPalette? palette;

  const StatusChip({
    super.key,
    required this.label,
    this.showDot = true,
    this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPalette = palette ?? statusPaletteFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: resolvedPalette.background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: resolvedPalette.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: resolvedPalette.foreground,
                ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final StatusPalette? palette;

  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPalette = palette ?? statusPaletteFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: resolvedPalette.background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: resolvedPalette.foreground),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: resolvedPalette.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
