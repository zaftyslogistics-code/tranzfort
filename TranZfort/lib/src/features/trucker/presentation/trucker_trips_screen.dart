import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/shell/presentation/shell_components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../data/trucker_trip_repository.dart';
import '../providers/trucker_trips_provider.dart';

class TruckerTripsScreen extends ConsumerWidget {
  const TruckerTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerTripsProvider);

    return ShellScrollView(
      children: [
        DetailSectionCard(
          title: l10n.truckerTripsTitle,
          children: [
            Text(
              l10n.truckerTripsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilterChipBar(
              items: [
                FilterChipItem(
                  label: l10n.truckerTripsTabActive,
                  selected: state.selectedTab == TruckerTripsTab.active,
                  onTap: () => ref.read(truckerTripsProvider.notifier).selectTab(TruckerTripsTab.active),
                ),
                FilterChipItem(
                  label: l10n.truckerTripsTabCompleted,
                  selected: state.selectedTab == TruckerTripsTab.completed,
                  onTap: () => ref.read(truckerTripsProvider.notifier).selectTab(TruckerTripsTab.completed),
                ),
              ],
            ),
          ],
        ),
        _TruckerTripsBody(
          state: state,
          onRetry: () => ref.read(truckerTripsProvider.notifier).load(),
        ),
      ],
    );
  }
}

class _TruckerTripsBody extends StatelessWidget {
  final TruckerTripsState state;
  final VoidCallback onRetry;

  const _TruckerTripsBody({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return const LoadingShimmer(height: 110, itemCount: 4);
    }

    if (state.failure != null && state.trips.isEmpty) {
      return WarningBlock(
        title: l10n.truckerTripsLoadFailureTitle,
        message: l10n.truckerTripsLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
      );
    }

    if (state.trips.isEmpty) {
      return EmptyStateView(
        icon: Icons.alt_route_outlined,
        title: state.selectedTab == TruckerTripsTab.active
            ? l10n.truckerTripsEmptyActiveTitle
            : l10n.truckerTripsEmptyCompletedTitle,
        subtitle: state.selectedTab == TruckerTripsTab.active
            ? l10n.truckerTripsEmptyActiveSubtitle
            : l10n.truckerTripsEmptyCompletedSubtitle,
        actionLabel: state.selectedTab == TruckerTripsTab.active
            ? l10n.truckerTripsEmptyActiveAction
            : l10n.truckerTripsEmptyCompletedAction,
        onAction: () => context.go(
          state.selectedTab == TruckerTripsTab.active ? AppRoutes.findLoadsPath : AppRoutes.tripsPath,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < state.trips.length; index++) ...[
          _TruckerTripCard(trip: state.trips[index]),
          if (index != state.trips.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

}

String _localizedTruckerTripsStage(AppLocalizations l10n, String stage) {
  switch (stage.trim().toLowerCase()) {
    case 'assigned':
      return l10n.truckerTripsStageAssigned;
    case 'pickup_pending':
      return l10n.truckerTripsStagePickupPending;
    case 'picked_up':
      return l10n.truckerTripsStagePickedUp;
    case 'in_transit':
      return l10n.truckerTripsStageInTransit;
    case 'delivered':
      return l10n.truckerTripsStageDelivered;
    case 'proof_submitted':
      return l10n.truckerTripsStageProofSubmitted;
    case 'completed':
      return l10n.truckerTripsStageCompleted;
    case 'disputed':
      return l10n.truckerTripsStageDisputed;
    case 'cancelled':
      return l10n.truckerTripsStageCancelled;
    default:
      return l10n.truckerTripsStageUnknown;
  }
}

String _localizedTruckerTripsProofStatus(AppLocalizations l10n, TruckerTrip trip) {
  if (trip.hasPodProof) {
    return l10n.truckerTripsProofStatusPodUploaded;
  }
  if (trip.hasLrProof) {
    return l10n.truckerTripsProofStatusLrUploaded;
  }
  switch (trip.stage.trim().toLowerCase()) {
    case 'delivered':
      return l10n.truckerTripsProofStatusAwaitingPod;
    case 'proof_submitted':
      return l10n.truckerTripsProofStatusProofSubmitted;
    default:
      return l10n.truckerTripsProofStatusProofPending;
  }
}

String _formatTruckerTripsDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
}

String _localizedTruckerTripsTimeContext(BuildContext context, AppLocalizations l10n, TruckerTrip trip) {
  if (trip.completedAt != null && trip.stage == 'completed') {
    return l10n.truckerTripsTimeContextCompleted(_formatTruckerTripsDate(context, trip.completedAt!));
  }
  if (trip.podUploadedAt != null && trip.stage == 'proof_submitted') {
    return l10n.truckerTripsTimeContextPodUploaded(_formatTruckerTripsDate(context, trip.podUploadedAt!));
  }
  if (trip.deliveredAt != null && trip.stage == 'delivered') {
    return l10n.truckerTripsTimeContextDelivered(_formatTruckerTripsDate(context, trip.deliveredAt!));
  }
  return l10n.truckerTripsTimeContextAssigned(_formatTruckerTripsDate(context, trip.assignedAt));
}

class _TruckerTripCard extends StatelessWidget {
  final TruckerTrip trip;

  const _TruckerTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(trip.stage);

    return StandardListCard(
      accent: palette.foreground,
      title: trip.routeLabel,
      subtitle: '${trip.material} - ${_localizedTruckerTripsProofStatus(l10n, trip)}',
      trailing: StatusChip(label: _localizedTruckerTripsStage(l10n, trip.stage)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: trip.progressValue,
              minHeight: 6,
              backgroundColor: AppColors.neutralBg,
              valueColor: AlwaysStoppedAnimation<Color>(palette.foreground),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_localizedTruckerTripsTimeContext(context, l10n, trip), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.truckerTripsTruckLabel(trip.truckNumber), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      onTap: () => context.push('${AppRoutes.tripDetailPath}/${trip.id}'),
    );
  }
}
