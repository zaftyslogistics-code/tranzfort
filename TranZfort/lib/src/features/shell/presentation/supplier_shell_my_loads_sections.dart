part of 'supplier_shell_screens.dart';

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
      child: ShellScrollView(
        children: [
          DetailSectionCard(
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
                    label: l10n.supplierMyLoadsTabActive,
                    selected: state.selectedTab == MyLoadsTab.active,
                    onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.active),
                  ),
                  FilterChipItem(
                    label: l10n.supplierMyLoadsTabCompleted,
                    selected: state.selectedTab == MyLoadsTab.completed,
                    onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.completed),
                  ),
                ],
              ),
            ],
          ),
          _MyLoadsBody(
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

class _MyLoadsBody extends StatelessWidget {
  final MyLoadsState state;
  final bool canPostLoads;
  final bool hasResolvedSupplierProfile;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  const _MyLoadsBody({
    required this.state,
    required this.canPostLoads,
    required this.hasResolvedSupplierProfile,
    required this.onRetry,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.isInitialLoading) {
      return const LoadingShimmer(height: 110, itemCount: 4);
    }

    if (state.failure != null && state.loads.isEmpty) {
      return WarningBlock(
        title: l10n.supplierMyLoadsLoadFailureTitle,
        message: l10n.supplierMyLoadsFailureMessage,
        action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
      );
    }

    if (state.loads.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: state.selectedTab == MyLoadsTab.active
            ? l10n.supplierMyLoadsEmptyActiveTitle
            : l10n.supplierMyLoadsEmptyCompletedTitle,
        subtitle: state.selectedTab == MyLoadsTab.active
            ? l10n.supplierMyLoadsEmptyActiveSubtitle
            : l10n.supplierMyLoadsEmptyCompletedSubtitle,
        actionLabel: state.selectedTab == MyLoadsTab.active
            ? (!hasResolvedSupplierProfile
                  ? l10n.navSupport
                  : canPostLoads
                  ? l10n.supplierDashboardPostLoadAction
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
      );
    }

    return Column(
      children: [
        for (var index = 0; index < state.loads.length; index++) ...[
          _SupplierLoadListCard(load: state.loads[index]),
          if (index != state.loads.length - 1) const SizedBox(height: AppSpacing.md),
        ],
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          WarningBlock(
            title: l10n.supplierMyLoadsMoreUnavailableTitle,
            message: l10n.supplierMyLoadsPaginationFailureMessage,
            action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
          ),
        ],
        if (state.hasMore) ...[
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: state.isLoadingMore ? l10n.supplierMyLoadsLoadingMore : l10n.supplierMyLoadsLoadMore,
            onPressed: state.isLoadingMore ? null : onLoadMore,
          ),
        ],
      ],
    );
  }
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
      title: '${load.originLabel} → ${load.destinationLabel}',
      subtitle: '${load.material} • ${tonnes}T • ₹${load.priceAmount.toStringAsFixed(0)}',
      trailing: StatusChip(label: _localizedSupplierDashboardLoadStatus(l10n, load.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supplierLoadCardPickupDate(_formatSupplierShortDate(context, load.pickupDate)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierLoadCardTrucks('${load.trucksBooked}', '${load.trucksNeeded}'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_hasSuperLoadState(isSuperLoad: load.isSuperLoad, superStatus: load.superStatus)) ...[
            const SizedBox(height: AppSpacing.sm),
            _SuperLoadStatusBlock(
              isSuperLoad: load.isSuperLoad,
              superStatus: load.superStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextActionButton(
            label: _primaryActionLabel(context, load.status),
            onPressed: () => context.go('${AppRoutes.loadDetailPath}/${load.id}'),
          ),
        ],
      ),
      onTap: () => context.go('${AppRoutes.loadDetailPath}/${load.id}'),
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
        return l10n.supplierLoadCardViewDetails;
    }
  }
}
