import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/data/supplier_profile_repository.dart';
import '../../../features/supplier/providers/my_loads_provider.dart';
import '../../../features/supplier/providers/supplier_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import 'supplier_shell_shared_helpers.dart';

class SupplierMyLoadsScreen extends ConsumerWidget {
  const SupplierMyLoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(myLoadsProvider);
    final supplierProfileAsync = ref.watch(supplierProfileProvider);
    final supplierProfile = supplierProfileAsync.valueOrNull;
    final profileResolved = !supplierProfileAsync.isLoading && !supplierProfileAsync.hasError && supplierProfile != null;
    final canPostLoads = _supplierCanPostLoads(supplierProfile);

    return RefreshIndicator(
      onRefresh: () => ref.read(myLoadsProvider.notifier).loadInitial(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.sectionGap,
            ),
            sliver: SliverToBoxAdapter(
              child: DetailSectionCard(
                title: l10n.supplierMyLoadsTitle,
                children: [
                  Text(
                    l10n.supplierMyLoadsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilterChipBar(
                    items: [
                      FilterChipItem(
                        label: l10n.commonActiveLabel,
                        selected: state.selectedTab == MyLoadsTab.active,
                        onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.active),
                      ),
                      FilterChipItem(
                        label: l10n.commonCompletedLabel,
                        selected: state.selectedTab == MyLoadsTab.completed,
                        onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.completed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ..._buildMyLoadsSlivers(
            context,
            state: state,
            canPostLoads: canPostLoads,
            hasResolvedSupplierProfile: profileResolved,
            onRetry: () => ref.read(myLoadsProvider.notifier).loadInitial(),
            onLoadMore: () => ref.read(myLoadsProvider.notifier).loadMore(),
          ),
        ],
      ),
    );
  }

  bool _supplierCanPostLoads(SupplierProfile? profile) {
    return profile?.canAccessWorkspace == true;
  }
}

List<Widget> _buildMyLoadsSlivers(
  BuildContext context, {
  required MyLoadsState state,
  required bool canPostLoads,
  required bool hasResolvedSupplierProfile,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
}) {
  final l10n = AppLocalizations.of(context);
  if (state.isInitialLoading) {
    return const <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: LoadingShimmer(height: 110, itemCount: 4),
        ),
      ),
    ];
  }

  if (state.failure != null && state.loads.isEmpty) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: WarningBlock(
            title: l10n.supplierMyLoadsLoadFailureTitle,
            message: l10n.supplierMyLoadsFailureMessage,
            action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
          ),
        ),
      ),
    ];
  }

  if (state.loads.isEmpty) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: state.selectedTab == MyLoadsTab.active
                ? l10n.supplierMyLoadsEmptyActiveTitle
                : l10n.supplierMyLoadsEmptyCompletedTitle,
            subtitle: state.selectedTab == MyLoadsTab.active
                ? l10n.supplierMyLoadsEmptyActiveSubtitle
                : l10n.supplierMyLoadsEmptyCompletedSubtitle,
            actionLabel: state.selectedTab == MyLoadsTab.active
                ? (!hasResolvedSupplierProfile
                      ? l10n.commonSupportLabel
                      : canPostLoads
                      ? l10n.commonPostLoadAction
                      : l10n.supplierCompleteVerification)
                : l10n.supplierMyLoadsOpenActiveLoads,
            onAction: () => context.go(
              state.selectedTab == MyLoadsTab.active
                  ? (!hasResolvedSupplierProfile
                        ? AppRoutes.supportPath
                        : canPostLoads
                        ? AppRoutes.postLoadPath
                        : AppRoutes.supplierVerificationPath)
                  : AppRoutes.myLoadsPath,
            ),
          ),
        ),
      ),
    ];
  }

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == state.loads.length - 1 ? 0 : AppSpacing.md),
            child: _SupplierLoadListCard(load: state.loads[index]),
          );
        }, childCount: state.loads.length),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.bottomNavSafe + AppSpacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            if (state.failure != null)
              WarningBlock(
                title: l10n.supplierMyLoadsMoreUnavailableTitle,
                message: l10n.supplierMyLoadsPaginationFailureMessage,
                action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
              ),
            if (state.failure != null && state.hasMore) const SizedBox(height: AppSpacing.md),
            if (state.hasMore)
              OutlineButton(
                label: state.isLoadingMore ? l10n.supplierMyLoadsLoadingMore : l10n.supplierMyLoadsLoadMore,
                onPressed: state.isLoadingMore ? null : onLoadMore,
              ),
          ],
        ),
      ),
    ),
  ];
}

class _SupplierLoadListCard extends StatelessWidget {
  final Load load;

  const _SupplierLoadListCard({required this.load});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(load.status);
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);

    return StandardListCard(
      accent: palette.foreground,
      title: '${load.originLabel} to ${load.destinationLabel}',
      subtitle: '${load.material} - ${tonnes}T - ₹${load.priceAmount.toStringAsFixed(0)}',
      trailing: StatusChip(label: localizedSupplierDashboardLoadStatus(l10n, load.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierLoadCardPickupDate(formatSupplierShortDate(context, load.pickupDate)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierLoadCardTrucks('${load.trucksBooked}', '${load.trucksNeeded}'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hasSuperLoadState(isSuperLoad: load.isSuperLoad, superStatus: load.superStatus)) ...[
            const SizedBox(height: AppSpacing.sm),
            SuperLoadStatusBlock(
              isSuperLoad: load.isSuperLoad,
              superStatus: load.superStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextActionButton(
            label: _primaryActionLabel(context, load.status),
            onPressed: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
          ),
        ],
      ),
      onTap: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
    );
  }

  String _primaryActionLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'assigned_full':
      case 'assigned_partial':
      case 'in_transit':
        return l10n.supplierLoadCardTrackLoad;
      case 'completed':
      case 'filled_outside_app':
        return l10n.supplierLoadCardViewHistory;
      default:
        return l10n.commonViewDetailsAction;
    }
  }
}
