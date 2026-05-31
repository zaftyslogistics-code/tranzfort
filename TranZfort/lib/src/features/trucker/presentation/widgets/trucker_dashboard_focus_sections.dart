import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/compact_load_list_tile.dart';
import '../../../../shared/widgets/content_cards.dart';
import '../../../../shared/widgets/feedback_components.dart';
import '../../data/trucker_marketplace_repository.dart';
import '../../data/trucker_trip_repository.dart';
import '../../providers/trucker_providers.dart';

String _localizedDashboardTripStage(AppLocalizations l10n, String stage) {
  return l10n.tripStageValue(stage.trim().toLowerCase());
}

String _localizedDashboardTripProofStatus(AppLocalizations l10n, TruckerTrip trip) {
  String normalized;
  if (trip.hasPodProof) {
    normalized = 'pod_uploaded';
  } else if (trip.hasLrProof) {
    normalized = 'lr_uploaded';
  } else {
    normalized = switch (trip.stage.trim().toLowerCase()) {
      'delivered' => 'awaiting_pod',
      'proof_submitted' => 'proof_submitted',
      _ => 'proof_pending',
    };
  }
  return l10n.proofStatusValue(normalized);
}

class TruckerDashboardNextTripSection extends ConsumerWidget {
  final VoidCallback onRetry;

  const TruckerDashboardNextTripSection({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final nextTripAsync = ref.watch(truckerNextTripProvider);

    if (nextTripAsync.isLoading) {
      return const LoadingShimmer(height: 72, itemCount: 1);
    }

    if (nextTripAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardNextTripTitle,
        message: l10n.truckerDashboardLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }

    final trip = nextTripAsync.valueOrNull;
    if (trip == null) {
      return EmptyStateView(
        icon: Icons.alt_route_outlined,
        title: l10n.truckerDashboardNextTripEmptyTitle,
        subtitle: l10n.truckerDashboardNextTripEmptySubtitle,
        actionLabel: l10n.truckerDashboardSearchLoadsAction,
        onAction: () => context.go(AppRoutes.findLoadsPath),
      );
    }

    final stageLabel = _localizedDashboardTripStage(l10n, trip.stage);

    return CompactLoadListTile.fromTruckerTrip(
      routeLabel: trip.routeLabel,
      detailLine: '${trip.material} • ${_localizedDashboardTripProofStatus(l10n, trip)}',
      statusLabel: stageLabel,
      statusColor: CompactLoadListTile.statusColorForTripStage(trip.stage),
      onTap: () => context.push('${AppRoutes.tripDetailPath}/${trip.id}'),
    );
  }
}

class TruckerDashboardNearbyLoadsSection extends ConsumerWidget {
  final VoidCallback onRetry;

  const TruckerDashboardNearbyLoadsSection({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final loadsAsync = ref.watch(truckerDashboardNearbyLoadsProvider);

    if (loadsAsync.isLoading) {
      return const LoadingShimmer(height: 120, itemCount: 2);
    }

    if (loadsAsync.hasError) {
      return WarningBlock(
        title: l10n.truckerDashboardNearbyLoadsTitle,
        message: l10n.truckerDashboardLoadFailureMessage,
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
      );
    }

    final loads = loadsAsync.valueOrNull ?? const <MarketplaceLoadItem>[];
    if (loads.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_outlined,
        title: l10n.truckerDashboardNearbyLoadsEmptyTitle,
        subtitle: l10n.truckerDashboardNearbyLoadsEmptySubtitle,
        actionLabel: l10n.truckerDashboardViewAllLoadsAction,
        onAction: () => context.go(AppRoutes.findLoadsPath),
      );
    }

    return Column(
      children: [
        CompactLoadList(
          children: [
            for (final load in loads)
              CompactLoadListTile.fromMarketplaceLoad(
                load: load,
                onTap: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlineButton(
          label: l10n.truckerDashboardViewAllLoadsAction,
          onPressed: () => context.go(AppRoutes.findLoadsPath),
        ),
      ],
    );
  }
}
