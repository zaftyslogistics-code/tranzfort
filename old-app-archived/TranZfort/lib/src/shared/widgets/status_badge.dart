import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.neutral(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.background,
      textColor: AppColors.neutral,
    );
  }

  factory StatusBadge.fromTripStage(BuildContext context, String stage) {
    final l10n = AppLocalizations.of(context);
    return switch (stage) {
      'completed' => StatusBadge(
        label: l10n.tripStageCompleted,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      ),
      'in_transit' => StatusBadge(
        label: l10n.tripStageInTransit,
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      ),
      'at_pickup' => StatusBadge(
        label: l10n.tripStageAtPickup,
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      ),
      'delivered' => StatusBadge(
        label: l10n.tripStageDelivered,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      ),
      'pod_uploaded' => StatusBadge(
        label: l10n.tripStagePodUploaded,
        backgroundColor: AppColors.infoTint,
        textColor: AppColors.info,
      ),
      _ => StatusBadge.neutral(l10n.tripStageUnknown),
    };
  }

  factory StatusBadge.fromVerificationStatus(
    BuildContext context,
    String status,
  ) {
    final l10n = AppLocalizations.of(context);
    return switch (status) {
      'verified' => StatusBadge(
        label: l10n.dashboardVerificationStatusVerified,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      ),
      'rejected' => StatusBadge(
        label: l10n.dashboardVerificationStatusRejected,
        backgroundColor: AppColors.errorTint,
        textColor: AppColors.error,
      ),
      'pending' => StatusBadge(
        label: l10n.dashboardVerificationStatusPending,
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      ),
      _ => StatusBadge.neutral(status),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.statusBadgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconXs, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
