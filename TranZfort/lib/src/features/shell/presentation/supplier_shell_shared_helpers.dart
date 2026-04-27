import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/data/supplier_trip_repository.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/status_components.dart';

String formatSupplierShortDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatShortDate(value);
}

String formatSupplierDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
  return '${material.formatShortDate(value)} - $timeLabel';
}

String localizedSupplierBookingStatus(AppLocalizations l10n, String status) {
  return l10n.shellMessagesBookingStatusValue(status.trim().toLowerCase());
}

String localizedSupplierPriceType(AppLocalizations l10n, String value) {
  final normalized = switch (value.trim().toLowerCase()) {
    'fixed' => 'fixed',
    'per_ton' => 'per_ton',
    _ => 'other',
  };
  return l10n.supplierPostLoadPriceTypeValue(normalized);
}

String localizedSupplierDashboardLoadStatus(AppLocalizations l10n, String status) {
  return l10n.supplierLoadStatusValue(status.trim().toLowerCase());
}

String localizedSupplierDashboardVerificationStatus(AppLocalizations l10n, String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'verified':
      return l10n.verificationStatusVerified;
    case 'pending':
      return l10n.commonPendingLabel;
    case 'rejected':
      return l10n.verificationStatusRejected;
    case 'unverified':
    case '':
      return l10n.accountProfileStatusNeedsAttention;
    default:
      return l10n.commonUnknownLabel;
  }
}

String localizedSupplierTripStage(AppLocalizations l10n, String stage) {
  return l10n.tripStageValue(stage.trim().toLowerCase());
}

String _normalizedProofStatus(AppLocalizations l10n, {bool hasPodProof = false, bool hasLrProof = false, String stage = ''}) {
  String normalized;
  if (hasPodProof) {
    normalized = 'pod_uploaded';
  } else if (hasLrProof) {
    normalized = 'lr_uploaded';
  } else {
    normalized = switch (stage.trim().toLowerCase()) {
      'delivered' => 'awaiting_pod',
      'proof_submitted' => 'proof_submitted',
      _ => 'proof_pending',
    };
  }
  return l10n.proofStatusValue(normalized);
}

String localizedLinkedTripProofStatus(AppLocalizations l10n, LinkedTrip trip) {
  return _normalizedProofStatus(l10n, hasPodProof: trip.hasPodProof, hasLrProof: trip.hasLrProof, stage: trip.stage);
}

String localizedSupplierProofStatus(AppLocalizations l10n, SupplierTrip trip) {
  return _normalizedProofStatus(l10n, hasPodProof: trip.hasPodProof, hasLrProof: trip.hasLrProof, stage: trip.stage);
}

bool hasSuperLoadState({required bool isSuperLoad, required String superStatus}) {
  return isSuperLoad || superStatus.trim().toLowerCase() != 'none';
}

String _normalizedSuperLoadStatusValue(String superStatus, {required bool isSuperLoad}) {
  final normalized = superStatus.trim().toLowerCase();
  return switch (normalized) {
    'request_submitted' => 'request_submitted',
    'under_review' => 'under_review',
    'approved_payment_pending' => 'approved_payment_pending',
    'active' => 'active',
    'rejected' => 'rejected',
    'expired_or_closed' => 'expired_or_closed',
    _ when isSuperLoad => 'active',
    _ => 'not_requested',
  };
}

String superLoadStatusLabel(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  return l10n.supplierDashboardSuperLoadStatusValue(
    _normalizedSuperLoadStatusValue(superStatus, isSuperLoad: isSuperLoad),
  );
}

String superLoadStatusGuidance(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  return l10n.supplierDashboardSuperLoadGuidanceValue(
    _normalizedSuperLoadStatusValue(superStatus, isSuperLoad: isSuperLoad),
  );
}

String shortId(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 8) {
    return trimmed;
  }
  return trimmed.substring(0, 8);
}

class SuperLoadStatusBlock extends StatelessWidget {
  final bool isSuperLoad;
  final String superStatus;

  const SuperLoadStatusBlock({
    super.key,
    required this.isSuperLoad,
    required this.superStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!hasSuperLoadState(isSuperLoad: isSuperLoad, superStatus: superStatus)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.superLoadBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: l10n.supplierDashboardSuperLoadBadge(
              superLoadStatusLabel(l10n, superStatus, isSuperLoad: isSuperLoad),
            ),
            icon: Icons.workspace_premium_outlined,
            palette: const StatusPalette(
              foreground: AppColors.superLoadText,
              background: AppColors.superLoadBg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            superLoadStatusGuidance(l10n, superStatus, isSuperLoad: isSuperLoad),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class SupplierVerificationBannerWithAction extends StatelessWidget {
  final VerificationBanner banner;
  final String actionLabel;
  final VoidCallback onTap;

  const SupplierVerificationBannerWithAction({
    super.key,
    required this.banner,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: AppSpacing.md),
        OutlineButton(
          label: actionLabel,
          onPressed: onTap,
        ),
      ],
    );
  }
}
