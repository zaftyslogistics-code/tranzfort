import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../communication/data/chat_repository.dart';
import '../../../features/shell/presentation/shell_components.dart';
import '../../support/providers/support_compose_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../data/diesel_price_repository.dart';
import '../data/trip_costing_service.dart';
import '../data/trucker_load_detail_repository.dart';
import '../data/trucker_load_share_service.dart';
import '../data/trucker_profile_repository.dart';
import '../providers/trucker_load_detail_provider.dart';
import '../providers/trucker_providers.dart';

part 'trucker_load_detail_sections.dart';

class TruckerLoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const TruckerLoadDetailScreen({
    super.key,
    required this.loadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerLoadDetailProvider(loadId));
    final detail = state.detail;
    final profileAsync = ref.watch(truckerProfileProvider);
    final profile = profileAsync.valueOrNull;
    final dieselPriceMap = ref.watch(dieselPriceMapProvider).valueOrNull ?? const <String, double>{};
    final tripCostingService = ref.watch(tripCostingServiceProvider);
    final shareService = ref.watch(truckerLoadShareServiceProvider);

    return DetailPageScaffold(
      title: l10n.truckerLoadDetailTitle,
      children: [
        if (state.isLoading) const LoadingShimmer(height: 120, itemCount: 4),
        if (!state.isLoading && state.failure != null && detail == null)
          _TruckerLoadDetailFailureBlock(
            failure: state.failure!,
            onRetry: () => ref.read(truckerLoadDetailProvider(loadId).notifier).load(),
          ),
        if (!state.isLoading && detail != null) ...[
          _TruckerLoadDetailBody(
            loadId: loadId,
            detail: detail,
            state: state,
            profile: profile,
            dieselPriceMap: dieselPriceMap,
            tripCostingService: tripCostingService,
            shareService: shareService,
          ),
        ],
      ],
    );
  }
}

String _localizedBookingRequestStatus(AppLocalizations l10n, String status) {
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

String _loadSupportFailureMessage(AppLocalizations l10n) {
  return l10n.truckerLoadDetailSupportFailureMessage;
}

String _loadActionFailureMessage(AppLocalizations l10n) {
  return l10n.truckerLoadDetailActionFailureMessage;
}

String _bookingSubmitFailureMessage(AppLocalizations l10n) {
  return l10n.truckerLoadDetailBookingSubmitFailureMessage;
}

String _localizedLoadDetailStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return l10n.truckerLoadDetailStatusActive;
    case 'assigned_partial':
      return l10n.truckerLoadDetailStatusAssignedPartial;
    default:
      return l10n.truckerLoadDetailStatusUnknown;
  }
}

String _localizedLoadPriceType(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'fixed':
      return l10n.supplierPostLoadPriceTypeFixed;
    case 'negotiable':
      return l10n.supplierPostLoadPriceTypeNegotiable;
    default:
      return l10n.supplierPostLoadPriceTypeUnknown;
  }
}
