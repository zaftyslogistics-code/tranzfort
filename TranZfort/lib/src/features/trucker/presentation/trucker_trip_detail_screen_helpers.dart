part of 'trucker_trip_detail_screen.dart';

Uri? _tripDetailCallUri(String? mobile) {
  final normalized = (mobile ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return Uri(scheme: 'tel', path: normalized);
}

Future<ImageSource?> _showTripProofSourceSheet({
  required BuildContext context,
  required String title,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<ImageSource>(
    context: context,
    title: title,
    child: Column(
      children: [
        PrimaryButton(
          label: l10n.commonTakePhotoAction,
          onPressed: () => Navigator.of(context).pop(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        OutlineButton(
          label: l10n.commonChooseFromGalleryAction,
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
      ],
    ),
  );
}

(String, String)? _tripStageAction(AppLocalizations l10n, String stage) {
  return switch (stage) {
    'assigned' => (
        l10n.truckerTripDetailHeadToPickupAction,
        l10n.truckerTripDetailHeadToPickupSuccess,
      ),
    'pickup_pending' => (
        l10n.truckerTripDetailCargoLoadedAction,
        l10n.truckerTripDetailCargoLoadedSuccess,
      ),
    'picked_up' => (
        l10n.truckerTripDetailStartTripAction,
        l10n.truckerTripDetailStartTripSuccess,
      ),
    'in_transit' => (
        l10n.truckerTripDetailMarkDeliveredAction,
        l10n.truckerTripDetailMarkDeliveredSuccess,
      ),
    _ => null,
  };
}

(String, String) _tripNextStep(AppLocalizations l10n, String stage) {
  return switch (stage) {
    'assigned' => (
        l10n.truckerTripDetailNextStepAssignedTitle,
        l10n.truckerTripDetailNextStepAssignedMessage,
      ),
    'pickup_pending' => (
        l10n.truckerTripDetailNextStepPickupPendingTitle,
        l10n.truckerTripDetailNextStepPickupPendingMessage,
      ),
    'picked_up' => (
        l10n.truckerTripDetailNextStepPickedUpTitle,
        l10n.truckerTripDetailNextStepPickedUpMessage,
      ),
    'in_transit' => (
        l10n.truckerTripDetailNextStepInTransitTitle,
        l10n.truckerTripDetailNextStepInTransitMessage,
      ),
    'delivered' => (
        l10n.truckerTripDetailNextStepDeliveredTitle,
        l10n.truckerTripDetailNextStepDeliveredMessage,
      ),
    'proof_submitted' => (
        l10n.truckerTripDetailNextStepProofSubmittedTitle,
        l10n.truckerTripDetailNextStepProofSubmittedMessage,
      ),
    'completed' => (
        l10n.truckerTripDetailNextStepCompletedTitle,
        l10n.truckerTripDetailNextStepCompletedMessage,
      ),
    'disputed' => (
        l10n.commonDisputeInProgressTitle,
        l10n.truckerTripDetailNextStepDisputedMessage,
      ),
    'cancelled' => (
        l10n.truckerTripDetailNextStepCancelledTitle,
        l10n.truckerTripDetailNextStepCancelledMessage,
      ),
    _ => (
        l10n.truckerTripDetailNextStepDefaultTitle,
        l10n.truckerTripDetailNextStepDefaultMessage,
      ),
  };
}

String _tripDetailFormatDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return '-';
  }
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _tripDetailFormatDateTime(BuildContext context, DateTime? value) {
  final l10n = AppLocalizations.of(context);
  if (value == null) {
    return l10n.commonPendingLabel;
  }
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: true,
  );
  return '${_tripDetailFormatDate(context, value)} - $time';
}

String _tripDisputeStatusGuidance(AppLocalizations l10n, String value) {
  return switch (value.trim().toLowerCase()) {
    'open' => l10n.truckerTripDetailDisputeStatusGuidanceOpen,
    'in_progress' => l10n.truckerTripDetailDisputeStatusGuidanceInProgress,
    'waiting_for_user' => l10n.truckerTripDetailDisputeStatusGuidanceWaitingForUser,
    'resolved' || 'closed' => l10n.truckerTripDetailDisputeStatusGuidanceResolved,
    _ => l10n.truckerTripDetailDisputeStatusGuidanceDefault,
  };
}

String _tripDisputeBannerTitle(AppLocalizations l10n, String? status) {
  return switch ((status ?? '').trim().toLowerCase()) {
    'waiting_for_user' => l10n.truckerTripDetailDisputeBannerWaitingTitle,
    'resolved' || 'closed' => l10n.commonDisputeReviewClosedTitle,
    _ => l10n.commonDisputeInProgressTitle,
  };
}

String _tripDisputeBannerMessage(
  AppLocalizations l10n,
  TruckerTripDisputeSummary? disputeSummary,
) {
  if (disputeSummary == null) {
    return l10n.truckerTripDetailDisputeBannerNoSummaryMessage;
  }
  final category = _localizedDisputeCategoryLabel(l10n, disputeSummary.category);
  return switch (disputeSummary.status.trim().toLowerCase()) {
    'waiting_for_user' => l10n.truckerTripDetailDisputeBannerWaitingMessage(category),
    'resolved' || 'closed' => l10n.truckerTripDetailDisputeBannerClosedMessage(category),
    _ => l10n.truckerTripDetailDisputeBannerInProgressMessage(category),
  };
}

String _localizedDisputeStatusLabel(AppLocalizations l10n, String status) {
  return l10n.supplierTripDetailDisputeStatusLabel(
    l10n.supportTicketStatusValue(status.trim().toLowerCase()),
  );
}

String _localizedDisputeCategoryLabel(AppLocalizations l10n, String category) {
  return switch (category.trim().toLowerCase()) {
    'trip_dispute' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryTripDispute),
    'loaded_quantity_mismatch' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryLoadedQuantityMismatch),
    'unloaded_quantity_mismatch' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryUnloadedQuantityMismatch),
    'document_mismatch' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDocumentMismatch),
    'non_payment' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryNonPayment),
    'fake_payout_proof' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryFakePayoutProof),
    'delay_or_no_show' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDelayOrNoShow),
    'damage_or_shortage' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryDamageOrShortage),
    'abusive_behavior' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryAbusiveBehavior),
    'spam_or_scam' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategorySpamOrScam),
    'other' => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
    _ => l10n.truckerTripDetailDisputeCategoryLabel(l10n.supportDisputeCategoryOther),
  };
}

String _tripDisputeActionGuidance(AppLocalizations l10n, String? status) {
  return switch ((status ?? '').trim().toLowerCase()) {
    'resolved' || 'closed' => l10n.truckerTripDetailDisputeActionGuidanceClosed,
    _ => l10n.truckerTripDetailDisputeActionGuidanceInProgress,
  };
}

String _tripSharedVisibilityGuidance(AppLocalizations l10n, String? status) {
  return switch ((status ?? '').trim().toLowerCase()) {
    'resolved' || 'closed' => l10n.truckerTripDetailSharedVisibilityClosed,
    _ => l10n.truckerTripDetailSharedVisibilityInProgress,
  };
}

String _tripProofGuidance(AppLocalizations l10n, String? status) {
  return switch ((status ?? '').trim().toLowerCase()) {
    'resolved' || 'closed' => l10n.truckerTripDetailProofGuidanceClosed,
    _ => l10n.truckerTripDetailProofGuidanceInProgress,
  };
}
