import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'platform_reviewed_badge.dart';
import 'action_buttons.dart';
import 'status_components.dart';

/// Public counterparty facts safe to show before/after booking (no document images or tax IDs).
class CounterpartyTrustInfo {
  final String displayName;
  final bool isVerified;
  final double avgRating;
  final int reviewCount;
  final int? totalLoadsPosted;

  const CounterpartyTrustInfo({
    required this.displayName,
    required this.isVerified,
    this.avgRating = 0,
    this.reviewCount = 0,
    this.totalLoadsPosted,
  });
}

/// Minimal trust snapshot: platform review badge, ratings, and off-platform GSTIN guidance.
class CounterpartyTrustPacket extends StatelessWidget {
  final CounterpartyTrustInfo info;
  final bool postBooking;
  final bool onDarkBackground;

  const CounterpartyTrustPacket({
    super.key,
    required this.info,
    this.postBooking = false,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: onDarkBackground ? AppColors.inkTextPrimary : null,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: onDarkBackground ? AppColors.inkTextSecondary : theme.colorScheme.onSurfaceVariant,
    );
    final metrics = <Widget>[
      if (info.reviewCount > 0)
        StatusBadge(
          label: l10n.counterpartyTrustPacketRating(info.avgRating, info.reviewCount),
          icon: Icons.star_outline,
          palette: const StatusPalette(
            foreground: AppColors.warning,
            background: AppColors.neutralBg,
          ),
        ),
      if (info.totalLoadsPosted != null && info.totalLoadsPosted! > 0)
        StatusBadge(
          label: l10n.counterpartyTrustPacketLoadsPosted(info.totalLoadsPosted!),
          icon: Icons.inventory_2_outlined,
          palette: const StatusPalette(
            foreground: AppColors.info,
            background: AppColors.infoBg,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          postBooking ? l10n.counterpartyTrustPacketPostBookingTitle : l10n.counterpartyTrustPacketTitle,
          style: titleStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          info.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: onDarkBackground ? AppColors.inkTextPrimary : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (info.isVerified)
              const PlatformReviewedBadge(compact: true)
            else
              StatusBadge(
                label: l10n.counterpartyTrustPacketProfileReviewPending,
                icon: Icons.hourglass_top_outlined,
                palette: StatusPalette(
                  foreground: onDarkBackground ? AppColors.inkTextSecondary : AppColors.textMuted,
                  background: onDarkBackground ? AppColors.inkDeep : AppColors.neutralBg,
                ),
              ),
            ...metrics,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.counterpartyTrustPacketGstinHint,
          style: bodyStyle,
        ),
      ],
    );
  }
}

Future<void> showCounterpartyPostBookingTrustSheet({
  required BuildContext context,
  required CounterpartyTrustInfo info,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CounterpartyTrustPacket(info: info, postBooking: true),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.counterpartyChecklistPath);
                },
                child: Text(l10n.counterpartyChecklistOpenFromBookingAction),
              ),
              PrimaryButton(
                label: l10n.counterpartyTrustPacketDismissAction,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
