import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../utils/verification_status_utils.dart';

class DashboardVerificationBanner extends StatelessWidget {
  const DashboardVerificationBanner({
    super.key,
    required this.status,
    this.rejectionReason,
    this.onTap,
  });

  final String status;
  final String? rejectionReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalized = normalizeVerificationStatus(status);

    final (
      Color bg,
      Color fg,
      IconData icon,
      String message,
    ) = switch (normalized) {
      'verified' => (
        AppColors.successTint,
        AppColors.success,
        Icons.verified,
        l10n.dashboardVerificationStatusVerified,
      ),
      'pending' => (
        AppColors.warningTint,
        AppColors.warning,
        Icons.hourglass_top,
        l10n.dashboardVerificationStatusPending,
      ),
      'unverified' => (
        AppColors.warningLight,
        AppColors.warning,
        Icons.verified_user_outlined,
        l10n.dashboardVerificationStatusUnverified,
      ),
      'rejected' => (
        AppColors.errorTint,
        AppColors.error,
        Icons.error_outline,
        rejectionReason == null || rejectionReason!.isEmpty
            ? l10n.dashboardVerificationStatusRejected
            : l10n.dashboardVerificationRejectedReason(rejectionReason!),
      ),
      _ => (
        AppColors.neutralLight,
        AppColors.onSurface,
        Icons.info_outline,
        l10n.dashboardVerificationStatusUnknown,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
