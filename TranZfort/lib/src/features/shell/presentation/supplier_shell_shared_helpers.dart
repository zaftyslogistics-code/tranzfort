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
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return l10n.shellMessagesBookingStatusSubmitted;
    case 'approved':
      return l10n.shellMessagesBookingStatusApproved;
    case 'rejected':
      return l10n.shellMessagesBookingStatusRejected;
    case 'pending':
      return l10n.shellMessagesBookingStatusPending;
    default:
      return l10n.shellMessagesBookingStatusUnknown;
  }
}

String localizedSupplierPriceType(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'fixed':
      return l10n.supplierPostLoadPriceTypeFixed;
    case 'per_ton':
    case 'negotiable':
      return l10n.supplierPostLoadPriceTypeNegotiable;
    default:
      return l10n.supplierPostLoadPriceTypeUnknown;
  }
}

String localizedSupplierDashboardLoadStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return l10n.supplierDashboardLoadStatusActive;
    case 'assigned_partial':
      return l10n.supplierLoadStatusAssignedPartial;
    case 'assigned_full':
      return l10n.supplierLoadStatusAssignedFull;
    case 'in_transit':
      return l10n.supplierLoadStatusInTransit;
    case 'completed':
      return l10n.supplierLoadStatusCompleted;
    case 'filled_outside_app':
      return l10n.supplierLoadStatusFilledOutsideApp;
    case 'cancelled':
      return l10n.supplierLoadStatusCancelled;
    case 'expired':
      return l10n.supplierLoadStatusExpired;
    case 'deactivated':
      return l10n.supplierLoadStatusDeactivated;
    default:
      return l10n.supplierLoadStatusUnknown;
  }
}

String localizedSupplierDashboardVerificationStatus(AppLocalizations l10n, String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'verified':
      return l10n.supplierDashboardVerificationStatusVerified;
    case 'pending':
      return l10n.supplierDashboardVerificationStatusPending;
    case 'rejected':
      return l10n.supplierDashboardVerificationStatusRejected;
    case 'unverified':
    case '':
      return l10n.accountProfileStatusNeedsAttention;
    default:
      return l10n.supplierDashboardVerificationStatusUnknown;
  }
}

String localizedSupplierTripStage(AppLocalizations l10n, String stage) {
  switch (stage.trim().toLowerCase()) {
    case 'assigned':
      return l10n.supplierTripDetailStageAssigned;
    case 'pickup_pending':
      return l10n.supplierTripDetailStagePickupPending;
    case 'picked_up':
      return l10n.supplierTripDetailStagePickedUp;
    case 'in_transit':
      return l10n.supplierTripDetailStageInTransit;
    case 'delivered':
      return l10n.supplierTripDetailStageDelivered;
    case 'proof_submitted':
      return l10n.supplierTripDetailStageProofSubmitted;
    case 'completed':
      return l10n.supplierTripDetailStageCompleted;
    case 'disputed':
      return l10n.supplierTripDetailStageDisputed;
    case 'cancelled':
      return l10n.supplierTripDetailStageCancelled;
    default:
      return l10n.supplierTripDetailStageUnknown;
  }
}

String localizedLinkedTripProofStatus(AppLocalizations l10n, LinkedTrip trip) {
  if (trip.hasPodProof) {
    return l10n.truckerTripDetailProofStatusPodUploaded;
  }
  if (trip.hasLrProof) {
    return l10n.truckerTripDetailProofStatusLrUploaded;
  }
  switch (trip.stage.trim().toLowerCase()) {
    case 'delivered':
      return l10n.truckerTripDetailProofStatusAwaitingPod;
    case 'proof_submitted':
      return l10n.truckerTripDetailProofStatusProofSubmitted;
    default:
      return l10n.truckerTripDetailProofStatusProofPending;
  }
}

String localizedSupplierProofStatus(AppLocalizations l10n, SupplierTrip trip) {
  if (trip.hasPodProof) {
    return l10n.truckerTripDetailProofStatusPodUploaded;
  }
  if (trip.hasLrProof) {
    return l10n.truckerTripDetailProofStatusLrUploaded;
  }
  switch (trip.stage.trim().toLowerCase()) {
    case 'delivered':
      return l10n.truckerTripDetailProofStatusAwaitingPod;
    case 'proof_submitted':
      return l10n.truckerTripDetailProofStatusProofSubmitted;
    default:
      return l10n.truckerTripDetailProofStatusProofPending;
  }
}

bool hasSuperLoadState({required bool isSuperLoad, required String superStatus}) {
  return isSuperLoad || superStatus.trim().toLowerCase() != 'none';
}

String superLoadStatusLabel(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  final normalized = superStatus.trim().toLowerCase();
  return switch (normalized) {
    'request_submitted' => l10n.supplierDashboardSuperLoadStatusRequestSubmitted,
    'under_review' => l10n.supplierDashboardSuperLoadStatusUnderReview,
    'approved_payment_pending' => l10n.supplierDashboardSuperLoadStatusApproved,
    'active' => l10n.supplierDashboardSuperLoadStatusActive,
    'rejected' => l10n.supplierDashboardSuperLoadStatusRejected,
    'expired_or_closed' => l10n.supplierDashboardSuperLoadStatusExpiredOrClosed,
    _ when isSuperLoad => l10n.supplierDashboardSuperLoadStatusActive,
    _ => l10n.supplierDashboardSuperLoadStatusNotActive,
  };
}

String superLoadStatusGuidance(AppLocalizations l10n, String superStatus, {required bool isSuperLoad}) {
  final normalized = superStatus.trim().toLowerCase();
  return switch (normalized) {
    'request_submitted' => l10n.supplierDashboardSuperLoadGuidanceRequestSubmitted,
    'under_review' => l10n.supplierDashboardSuperLoadGuidanceUnderReview,
    'approved_payment_pending' => l10n.supplierDashboardSuperLoadGuidanceApproved,
    'active' => l10n.supplierDashboardSuperLoadGuidanceActive,
    'rejected' => l10n.supplierDashboardSuperLoadGuidanceRejected,
    'expired_or_closed' => l10n.supplierDashboardSuperLoadGuidanceExpiredOrClosed,
    _ when isSuperLoad => l10n.supplierDashboardSuperLoadGuidanceActive,
    _ => l10n.supplierDashboardSuperLoadGuidanceNotActive,
  };
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
