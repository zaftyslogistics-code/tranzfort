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
import '../../../shared/widgets/tts_card_speaker_button.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/trip_list_card_tts_builder.dart';
import '../data/trucker_trip_repository.dart';
import '../providers/trucker_trips_provider.dart';

class TruckerTripsScreen extends ConsumerWidget {
  const TruckerTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerTripsProvider);

    return ShellScrollView(
      onRefresh: () => ref.read(truckerTripsProvider.notifier).load(),
      children: [
        HeroActionCard(
          title: l10n.truckerTripsTitle,
          subtitle: l10n.truckerTripsSubtitle,
          compact: true,
          useDarkTheme: true,
          useInkGradient: true,
          titleIcon: Icons.alt_route_outlined,
          child: FilterChipBar(
            items: [
              FilterChipItem(
                label: l10n.commonActiveLabel,
                selected: state.selectedTab == TruckerTripsTab.active,
                onTap: () => ref.read(truckerTripsProvider.notifier).selectTab(TruckerTripsTab.active),
              ),
              FilterChipItem(
                label: l10n.commonCompletedLabel,
                selected: state.selectedTab == TruckerTripsTab.completed,
                onTap: () => ref.read(truckerTripsProvider.notifier).selectTab(TruckerTripsTab.completed),
              ),
            ],
          ),
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
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
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
  return l10n.tripStageValue(stage.trim().toLowerCase());
}

String _localizedTruckerTripsProofStatus(AppLocalizations l10n, TruckerTrip trip) {
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

class _TruckerTripCard extends ConsumerWidget {
  final TruckerTrip trip;

  const _TruckerTripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ttsL10n = lookupTtsLocalizations(Localizations.localeOf(context));
    final palette = statusPaletteFor(trip.stage);
    final stageLabel = _localizedTruckerTripsStage(l10n, trip.stage);
    final utterance = const TripListCardTtsBuilder().build(
      tts: ttsL10n,
      routeLabel: trip.routeLabel,
      material: trip.material,
      stageLabel: stageLabel,
      truckNumber: trip.truckNumber,
    );

    return StandardListCard(
      accent: palette.foreground,
      title: trip.routeLabel,
      subtitle: '${trip.material} - ${_localizedTruckerTripsProofStatus(l10n, trip)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TtsCardSpeakerButton(message: utterance),
          const SizedBox(width: 4),
          StatusChip(label: stageLabel),
        ],
      ),
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
          Text(
            _localizedTruckerTripsTimeContext(context, l10n, trip),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.truckerTripsTruckLabel(trip.truckNumber),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      onTap: () => context.push('${AppRoutes.tripDetailPath}/${trip.id}'),
    );
  }
}
