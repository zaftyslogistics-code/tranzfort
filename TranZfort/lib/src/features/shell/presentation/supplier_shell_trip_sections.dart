import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_trip_repository.dart';
import '../../../features/supplier/providers/supplier_trips_provider.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/trip_list_card_tts_builder.dart';
import 'shell_components.dart';
import 'supplier_shell_shared_helpers.dart';

class SupplierTripsScreen extends ConsumerWidget {
  const SupplierTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(supplierTripsProvider);

    return ShellScrollView(
      onRefresh: () => ref.read(supplierTripsProvider.notifier).load(),
      children: [
        HeroActionCard(
          title: l10n.supplierTripsSectionTitle,
          subtitle: l10n.supplierTripsSectionSubtitle,
          compact: true,
          useDarkTheme: true,
          useInkGradient: true,
          titleIcon: Icons.alt_route_outlined,
          child: FilterChipBar(
            items: [
              FilterChipItem(
                label: l10n.commonActiveLabel,
                selected: state.selectedTab == SupplierTripsTab.active,
                onTap: () => ref.read(supplierTripsProvider.notifier).selectTab(SupplierTripsTab.active),
              ),
              FilterChipItem(
                label: l10n.commonCompletedLabel,
                selected: state.selectedTab == SupplierTripsTab.completed,
                onTap: () => ref.read(supplierTripsProvider.notifier).selectTab(SupplierTripsTab.completed),
              ),
            ],
          ),
        ),
        _SupplierTripsBody(
          state: state,
          onRetry: () => ref.read(supplierTripsProvider.notifier).load(),
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
        action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
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
            ? l10n.commonOpenMyLoadsAction
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

class _SupplierTripCard extends ConsumerWidget {
  final SupplierTrip trip;

  const _SupplierTripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = TtsLocalizations.of(context);
    final palette = statusPaletteFor(trip.stage);
    final tripPath = '${AppRoutes.tripDetailPath}/${trip.id}';
    final proofStatus = localizedSupplierProofStatus(l10n, trip);
    final stageLabel = localizedSupplierTripStage(l10n, trip.stage);
    final utterance = const TripListCardTtsBuilder().build(
      tts: ttsL10n,
      routeLabel: trip.routeLabel,
      material: trip.material,
      stageLabel: stageLabel,
      truckNumber: shortId(trip.truckId),
    );

    return StandardListCard(
      accent: palette.foreground,
      title: trip.routeLabel,
      subtitle: '${trip.material} - $proofStatus',
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
          Text(
            l10n.supplierTripsAssignedLabel(formatSupplierDateTime(context, trip.assignedAt)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierTripsTruckerTruckLabel(shortId(trip.truckerId), shortId(trip.truckId)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextActionButton(
            label: l10n.supplierTripsTrackTripAction,
            onPressed: () => context.push(tripPath),
          ),
        ],
      ),
      onTap: () => context.push(tripPath),
    );
  }
}
