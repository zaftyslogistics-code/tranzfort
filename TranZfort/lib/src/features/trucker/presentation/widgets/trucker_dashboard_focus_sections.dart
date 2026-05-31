import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/content_cards.dart';
import '../../../../shared/widgets/feedback_components.dart';
import '../../../../shared/widgets/status_components.dart';
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

String _formatDashboardTripDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
}

String _localizedDashboardTripTimeContext(BuildContext context, AppLocalizations l10n, TruckerTrip trip) {
  if (trip.completedAt != null && trip.stage == 'completed') {
    return l10n.truckerTripsTimeContextCompleted(_formatDashboardTripDate(context, trip.completedAt!));
  }
  if (trip.podUploadedAt != null && trip.stage == 'proof_submitted') {
    return l10n.truckerTripsTimeContextPodUploaded(_formatDashboardTripDate(context, trip.podUploadedAt!));
  }
  if (trip.deliveredAt != null && trip.stage == 'delivered') {
    return l10n.truckerTripsTimeContextDelivered(_formatDashboardTripDate(context, trip.deliveredAt!));
  }
  return l10n.truckerTripsTimeContextAssigned(_formatDashboardTripDate(context, trip.assignedAt));
}

class TruckerDashboardNextTripSection extends ConsumerWidget {
  final VoidCallback onRetry;

  const TruckerDashboardNextTripSection({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final nextTripAsync = ref.watch(truckerNextTripProvider);

    if (nextTripAsync.isLoading) {
      return const LoadingShimmer(height: 120, itemCount: 1);
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

    final palette = statusPaletteFor(trip.stage);
    final stageLabel = _localizedDashboardTripStage(l10n, trip.stage);

    return StandardListCard(
      accent: palette.foreground,
      title: trip.routeLabel,
      subtitle: '${trip.material} - ${_localizedDashboardTripProofStatus(l10n, trip)}',
      trailing: StatusChip(label: stageLabel),
      footer: Text(
        _localizedDashboardTripTimeContext(context, l10n, trip),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
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
      return const LoadingShimmer(height: 180, itemCount: 2);
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
        for (var index = 0; index < loads.length; index++) ...[
          _DashboardNearbyLoadCard(load: loads[index]),
          if (index != loads.length - 1) const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.md),
        OutlineButton(
          label: l10n.truckerDashboardViewAllLoadsAction,
          onPressed: () => context.go(AppRoutes.findLoadsPath),
        ),
      ],
    );
  }
}

class _DashboardNearbyLoadCard extends StatelessWidget {
  final MarketplaceLoadItem load;

  const _DashboardNearbyLoadCard({required this.load});

  @override
  Widget build(BuildContext context) {
    final rateLabel = load.priceType.trim().toLowerCase() == 'per_ton'
        ? '₹${load.priceAmount.toStringAsFixed(0)}/ton'
        : '₹${load.priceAmount.toStringAsFixed(0)} fixed';

    final AppLocalizations l10n = AppLocalizations.of(context);
    final trucksLabel = load.trucksNeeded > 1
        ? ' · ${l10n.supplierDashboardTrucksBooked(load.trucksBooked, load.trucksNeeded)}'
        : '';

    return StandardListCard(
      accent: load.isSuperLoad ? AppColors.secondary : AppColors.primary,
      title: '${load.originCity} → ${load.destinationCity}',
      subtitle: '${load.material} · $rateLabel$trucksLabel',
      trailing: load.isSuperLoad ? const StatusChip(label: 'Super') : null,
      onTap: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
    );
  }
}
