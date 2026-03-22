part of 'supplier_shell_screens.dart';

String _localizedSupplierProofStatus(AppLocalizations l10n, SupplierTrip trip) {
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

String _localizedSupplierTripStage(AppLocalizations l10n, String stage) {
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

class SupplierTripsScreen extends ConsumerWidget {
  const SupplierTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(supplierTripsProvider);

    return ShellScrollView(
      children: [
        DetailSectionCard(
          title: l10n.supplierTripsSectionTitle,
          children: [
            Text(
              l10n.supplierTripsSectionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilterChipBar(
              items: [
                FilterChipItem(
                  label: l10n.supplierTripsTabActive,
                  selected: state.selectedTab == SupplierTripsTab.active,
                  onTap: () => ref.read(supplierTripsProvider.notifier).selectTab(SupplierTripsTab.active),
                ),
                FilterChipItem(
                  label: l10n.supplierTripsTabCompleted,
                  selected: state.selectedTab == SupplierTripsTab.completed,
                  onTap: () => ref.read(supplierTripsProvider.notifier).selectTab(SupplierTripsTab.completed),
                ),
              ],
            ),
          ],
        ),
        _SupplierTripsBody(
          state: state,
          onRetry: () => ref.read(supplierTripsProvider.notifier).load(),
        ),
      ],
    );
  }
}

class SupplierTripDetailStubScreen extends StatelessWidget {
  final String tripId;

  const SupplierTripDetailStubScreen({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DetailPageScaffold(
      title: l10n.supplierTripDetailStubScreenTitle,
      children: [
        DetailSectionCard(
          title: l10n.supplierTripDetailStubCardTitle,
          children: [
            Text(l10n.supplierTripDetailStubReference(tripId), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.supplierTripDetailStubMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _SupplierTripsBody extends StatelessWidget {
  final SupplierTripsState state;
  final VoidCallback onRetry;

  const _SupplierTripsBody({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return const LoadingShimmer(height: 110, itemCount: 4);
    }

    if (state.failure != null && state.trips.isEmpty) {
      return WarningBlock(
        title: l10n.supplierTripsLoadFailureTitle,
        message: l10n.supplierTripsLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
      );
    }

    if (state.trips.isEmpty) {
      return EmptyStateView(
        icon: Icons.alt_route_outlined,
        title: state.selectedTab == SupplierTripsTab.active
            ? l10n.supplierTripsEmptyActiveTitle
            : l10n.supplierTripsEmptyCompletedTitle,
        subtitle: state.selectedTab == SupplierTripsTab.active
            ? l10n.supplierTripsEmptyActiveSubtitle
            : l10n.supplierTripsEmptyCompletedSubtitle,
        actionLabel: state.selectedTab == SupplierTripsTab.active
            ? l10n.supplierTripsEmptyActiveAction
            : l10n.supplierTripsEmptyCompletedAction,
        onAction: () => context.go(
          state.selectedTab == SupplierTripsTab.active ? AppRoutes.myLoadsPath : AppRoutes.supplierTripsPath,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < state.trips.length; index++) ...[
          _SupplierTripCard(trip: state.trips[index]),
          if (index != state.trips.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SupplierTripCard extends StatelessWidget {
  final SupplierTrip trip;

  const _SupplierTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(trip.stage);
    final tripPath = '${AppRoutes.tripDetailPath}/${trip.id}';
    final proofStatus = _localizedSupplierProofStatus(l10n, trip);

    return StandardListCard(
      accent: palette.foreground,
      title: trip.routeLabel,
      subtitle: '${trip.material} • $proofStatus',
      trailing: StatusChip(label: _localizedSupplierTripStage(l10n, trip.stage)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierTripsAssignedLabel(_formatSupplierDateTime(context, trip.assignedAt)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierTripsTruckerTruckLabel(_shortId(trip.truckerId), _shortId(trip.truckId)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextActionButton(
            label: l10n.supplierTripsTrackTripAction,
            onPressed: () => context.go(tripPath),
          ),
        ],
      ),
      onTap: () => context.go(tripPath),
    );
  }
}
