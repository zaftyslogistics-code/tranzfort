import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'status_components.dart';

Future<void> showPlatformReviewedDisclaimerSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.badgeDisclaimerTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.badgeDisclaimerWhatWeAre, style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.badgeDisclaimerWhatWeAreNot, style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.badgeDisclaimerUserMustVerify, style: Theme.of(sheetContext).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    },
  );
}

/// Tappable marketplace badge for counterparty platform review (not payment/KYC guarantee).
class PlatformReviewedBadge extends StatelessWidget {
  final bool compact;

  const PlatformReviewedBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chip = StatusBadge(
      label: l10n.platformReviewedBadgeLabel,
      icon: Icons.verified_outlined,
      palette: const StatusPalette(
        foreground: AppColors.primary,
        background: AppColors.neutralBg,
      ),
    );
    if (compact) {
      return InkWell(
        onTap: () => showPlatformReviewedDisclaimerSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: chip,
      );
    }
    return InkWell(
      onTap: () => showPlatformReviewedDisclaimerSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip,
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
