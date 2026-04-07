import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../data/trucker_city_search_service.dart';
import '../data/diesel_price_repository.dart';
import '../data/trip_costing_service.dart';
import '../data/trucker_load_detail_repository.dart';
import '../data/trucker_marketplace_repository.dart';
import '../providers/find_loads_provider.dart';
import '../providers/trucker_load_detail_provider.dart';

class TruckerFindLoadsScreen extends ConsumerStatefulWidget {
  const TruckerFindLoadsScreen({super.key});

  @override
  ConsumerState<TruckerFindLoadsScreen> createState() => _TruckerFindLoadsScreenState();
}

class _TruckerFindLoadsScreenState extends ConsumerState<TruckerFindLoadsScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late final TextEditingController _materialController;
  bool _quickAdvancedExpanded = false;
  bool _showScrollToTop = false;

  List<TruckerCitySuggestion> _originSuggestions = const <TruckerCitySuggestion>[];
  List<TruckerCitySuggestion> _destinationSuggestions = const <TruckerCitySuggestion>[];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    final filters = ref.read(findLoadsProvider).filters;
    _originController = TextEditingController(text: filters.originCity);
    _destinationController = TextEditingController(text: filters.destinationCity);
    _materialController = TextEditingController(text: filters.material);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _originController.dispose();
    _destinationController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final offset = position.pixels;
    final shouldShowScrollToTop = offset > 420;
    if (shouldShowScrollToTop != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShowScrollToTop);
    }
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(findLoadsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final state = ref.watch(findLoadsProvider);
    final filters = state.filters;
    final dieselPriceMap = ref.watch(dieselPriceMapProvider).valueOrNull ?? const <String, double>{};
    final tripCostingService = ref.watch(tripCostingServiceProvider);
    final approvedTrucks = ref.watch(truckerApprovedTrucksProvider).valueOrNull ?? const <TruckerApprovedTruck>[];

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: HeroActionCard(
                  title: l10n.shellTitleFindLoads,
                  subtitle: l10n.truckerFindLoadsHeroSubtitle,
                  compact: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              controller: _originController,
                              hintText: l10n.truckerFindLoadsOriginHint,
                              onChanged: _searchOrigin,
                              onClear: () {
                                _originController.clear();
                                _searchOrigin('');
                                _applyQuickFilters(originCity: '');
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppSearchField(
                              controller: _destinationController,
                              hintText: l10n.truckerFindLoadsDestinationHint,
                              onChanged: _searchDestination,
                              onClear: () {
                                _destinationController.clear();
                                _searchDestination('');
                                _applyQuickFilters(destinationCity: '');
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_originSuggestions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _SuggestionList(
                          suggestions: _originSuggestions,
                          onSelected: (suggestion) {
                            _originController.text = suggestion.city;
                            setState(() => _originSuggestions = const <TruckerCitySuggestion>[]);
                            _applyQuickFilters(originCity: suggestion.city);
                          },
                        ),
                      ],
                      if (_destinationSuggestions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _SuggestionList(
                          suggestions: _destinationSuggestions,
                          onSelected: (suggestion) {
                            _destinationController.text = suggestion.city;
                            setState(() => _destinationSuggestions = const <TruckerCitySuggestion>[]);
                            _applyQuickFilters(destinationCity: suggestion.city);
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      TextActionButton(
                        label: _quickAdvancedExpanded
                            ? '${l10n.truckerFindLoadsAdvancedFiltersAction} ▲'
                            : '${l10n.truckerFindLoadsAdvancedFiltersAction} ▼',
                        onPressed: () => setState(() => _quickAdvancedExpanded = !_quickAdvancedExpanded),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            AppSearchField(
                              controller: _materialController,
                              hintText: l10n.truckerFindLoadsMaterialHint,
                              onChanged: (value) => _applyQuickFilters(material: value),
                              onClear: () {
                                _materialController.clear();
                                _applyQuickFilters(material: '');
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppDropdown<MarketplaceSortOption>(
                              label: l10n.truckerFindLoadsSortByLabel,
                              value: filters.sortOption,
                              items: [
                                DropdownMenuItem(value: MarketplaceSortOption.newest, child: Text(l10n.truckerFindLoadsSortNewest)),
                                DropdownMenuItem(
                                  value: MarketplaceSortOption.priceHighToLow,
                                  child: Text(l10n.truckerFindLoadsSortPriceHighToLow),
                                ),
                                DropdownMenuItem(
                                  value: MarketplaceSortOption.priceLowToHigh,
                                  child: Text(l10n.truckerFindLoadsSortPriceLowToHigh),
                                ),
                                DropdownMenuItem(value: MarketplaceSortOption.pickupDate, child: Text(l10n.truckerFindLoadsSortPickupDate)),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(findLoadsProvider.notifier).updateFilters(filters.copyWith(sortOption: value));
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlineButton(
                              label: l10n.truckerFindLoadsAdvancedFiltersAction,
                              onPressed: () => _openAdvancedFilters(context, filters),
                            ),
                          ],
                        ),
                        crossFadeState: _quickAdvancedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: filters.hasActiveFilters ? 104 : 56,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
                  child: _FindLoadsTabsHeader(
                    state: state,
                    onReset: () {
                      _originController.clear();
                      _destinationController.clear();
                      _materialController.clear();
                      setState(() {
                        _originSuggestions = const <TruckerCitySuggestion>[];
                        _destinationSuggestions = const <TruckerCitySuggestion>[];
                      });
                      ref.read(findLoadsProvider.notifier).resetFilters();
                    },
                    onSelectAll: () => ref.read(findLoadsProvider.notifier).selectTab(FindLoadsTab.all),
                    onSelectSuperLoads: () => ref.read(findLoadsProvider.notifier).selectTab(FindLoadsTab.superLoads),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.bottomNavSafe + AppSpacing.xl,
              ),
              sliver: state.isInitialLoading
                  ? const SliverToBoxAdapter(
                      child: LoadingShimmer(height: 120, itemCount: 5),
                    )
                  : state.failure != null && state.loads.isEmpty
                      ? SliverToBoxAdapter(
                          child: WarningBlock(
                            title: l10n.truckerFindLoadsLoadFailureTitle,
                            message: l10n.truckerFindLoadsLoadFailureMessage,
                            action: OutlineButton(
                              label: l10n.commonRetry,
                              onPressed: () => ref.read(findLoadsProvider.notifier).loadInitial(),
                            ),
                          ),
                        )
                      : state.loads.isEmpty
                          ? SliverToBoxAdapter(
                              child: EmptyStateView(
                                icon: Icons.search_off_outlined,
                                title: l10n.truckerFindLoadsEmptyTitle,
                                subtitle: l10n.truckerFindLoadsEmptySubtitle,
                                actionLabel: state.filters.hasActiveFilters ? l10n.truckerFindLoadsResetFiltersAction : null,
                                onAction: state.filters.hasActiveFilters
                                    ? () {
                                        _originController.clear();
                                        _destinationController.clear();
                                        _materialController.clear();
                                        setState(() {
                                          _originSuggestions = const <TruckerCitySuggestion>[];
                                          _destinationSuggestions = const <TruckerCitySuggestion>[];
                                        });
                                        ref.read(findLoadsProvider.notifier).resetFilters();
                                      }
                                    : null,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildListDelegate([
                                for (var index = 0; index < state.loads.length; index++) ...[
                                  _MarketplaceLoadCard(
                                    load: state.loads[index],
                                    approvedTrucks: approvedTrucks,
                                    dieselPriceMap: dieselPriceMap,
                                    tripCostingService: tripCostingService,
                                  ),
                                  if (index != state.loads.length - 1) const SizedBox(height: AppSpacing.md),
                                ],
                                if (state.isLoadingMore) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  const LoadingShimmer(height: 90, itemCount: 1),
                                ],
                                if (state.failure != null && state.loads.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  WarningBlock(
                                    title: l10n.truckerFindLoadsLoadMoreFailureTitle,
                                    message: l10n.truckerFindLoadsLoadMoreFailureMessage,
                                    action: OutlineButton(
                                      label: l10n.commonRetry,
                                      onPressed: () => ref.read(findLoadsProvider.notifier).loadMore(),
                                    ),
                                  ),
                                ],
                              ]),
                            ),
            ),
          ],
        ),
        if (_showScrollToTop)
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.bottomNavSafe + AppSpacing.xl,
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
      ],
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _searchOrigin(String value) async {
    if (value.trim().length < 2) {
      setState(() => _originSuggestions = const <TruckerCitySuggestion>[]);
      return;
    }

    final suggestions = await ref.read(truckerCitySearchServiceProvider).searchCities(value);
    if (!mounted) {
      return;
    }
    setState(() => _originSuggestions = suggestions);
  }

  Future<void> _searchDestination(String value) async {
    if (value.trim().length < 2) {
      setState(() => _destinationSuggestions = const <TruckerCitySuggestion>[]);
      return;
    }

    final suggestions = await ref.read(truckerCitySearchServiceProvider).searchCities(value);
    if (!mounted) {
      return;
    }
    setState(() => _destinationSuggestions = suggestions);
  }

  void _applyQuickFilters({String? originCity, String? destinationCity, String? material}) {
    final filters = ref.read(findLoadsProvider).filters;
    ref.read(findLoadsProvider.notifier).updateFilters(
          filters.copyWith(
            originCity: originCity ?? filters.originCity,
            destinationCity: destinationCity ?? filters.destinationCity,
            material: material ?? filters.material,
          ),
        );
  }

  Future<void> _openAdvancedFilters(BuildContext context, MarketplaceSearchFilters filters) async {
    final result = await showAppBottomSheet<MarketplaceSearchFilters>(
      context: context,
      title: AppLocalizations.of(context).truckerFindLoadsAdvancedFiltersTitle,
      child: _AdvancedFiltersSheet(initialFilters: filters),
    );

    if (!mounted || result == null) {
      return;
    }

    ref.read(findLoadsProvider.notifier).updateFilters(result);
  }
}

class _FindLoadsTabsHeader extends StatelessWidget {
  final FindLoadsState state;
  final VoidCallback onReset;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectSuperLoads;

  const _FindLoadsTabsHeader({
    required this.state,
    required this.onReset,
    required this.onSelectAll,
    required this.onSelectSuperLoads,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(
                    child: _LoadFeedTabButton(
                      label: l10n.truckerFindLoadsAllLoadsTab,
                      selected: state.selectedTab == FindLoadsTab.all,
                      onTap: onSelectAll,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _LoadFeedTabButton(
                      label: l10n.truckerFindLoadsSuperLoadsTab,
                      selected: state.selectedTab == FindLoadsTab.superLoads,
                      onTap: onSelectSuperLoads,
                    ),
                  ),
                ],
              ),
            ),
            if (state.filters.hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.xs),
              _ActiveFilterSummary(
                filters: state.filters,
                resultCount: state.loads.length,
                onReset: onReset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadFeedTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LoadFeedTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.canvasWash,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

String _localizedBodyType(AppLocalizations l10n, String? bodyType) {
  final normalized = (bodyType ?? '').trim();
  switch (normalized.toLowerCase()) {
    case 'open':
      return l10n.truckerFindLoadsBodyTypeOpen;
    case 'trailer':
      return l10n.truckerFindLoadsBodyTypeTrailer;
    case 'container':
      return l10n.truckerFindLoadsBodyTypeContainer;
    case 'tanker':
      return l10n.truckerFindLoadsBodyTypeTanker;
    default:
      return normalized.isEmpty ? l10n.truckerFindLoadsAnyBodyFallback : l10n.truckerFindLoadsBodyTypeUnknown;
  }
}

String _localizedLoadStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return l10n.truckerFindLoadsStatusActive;
    case 'assigned_partial':
      return l10n.truckerFindLoadsStatusAssignedPartial;
    default:
      return l10n.truckerFindLoadsStatusUnknown;
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  final MarketplaceSearchFilters filters;
  final int resultCount;
  final VoidCallback onReset;

  const _ActiveFilterSummary({
    required this.filters,
    required this.resultCount,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final pieces = <String>[
      if (filters.originCity.trim().isNotEmpty) l10n.truckerFindLoadsSummaryFrom(filters.originCity),
      if (filters.destinationCity.trim().isNotEmpty) l10n.truckerFindLoadsSummaryTo(filters.destinationCity),
      if (filters.material.trim().isNotEmpty) filters.material,
      if (filters.truckBodyType.trim().isNotEmpty) _localizedBodyType(l10n, filters.truckBodyType),
      if (filters.tyres.isNotEmpty) l10n.truckerFindLoadsSummaryTyres(filters.tyres.join('/')),
      if (filters.minPrice != null || filters.maxPrice != null)
        l10n.truckerFindLoadsSummaryPriceRange(
          filters.minPrice?.toStringAsFixed(0) ?? '0',
          filters.maxPrice?.toStringAsFixed(0) ?? '∞',
        ),
      if (filters.superLoadsOnly) l10n.truckerFindLoadsSummarySuperLoads,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pieces.isEmpty
              ? l10n.truckerFindLoadsSummaryAllLoads(resultCount)
              : l10n.truckerFindLoadsSummaryFiltered(pieces.join(' - '), resultCount),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (filters.hasActiveFilters) ...[
          const SizedBox(height: AppSpacing.sm),
          TextActionButton(label: l10n.truckerFindLoadsResetFiltersAction, onPressed: onReset),
        ],
      ],
    );
  }
}

class _MarketplaceLoadCard extends StatelessWidget {
  final MarketplaceLoadItem load;
  final List<TruckerApprovedTruck> approvedTrucks;
  final Map<String, double> dieselPriceMap;
  final TripCostingService tripCostingService;

  const _MarketplaceLoadCard({
    required this.load,
    required this.approvedTrucks,
    required this.dieselPriceMap,
    required this.tripCostingService,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(load.status);
    final tonnes = load.weightTonnes % 1 == 0 ? load.weightTonnes.toStringAsFixed(0) : load.weightTonnes.toStringAsFixed(1);
    final dieselPrice = dieselPriceMap[(load.originState ?? '').trim().toLowerCase()];
    final routeSnapshot = load.routeSnapshot;
    final totalLoadValue = load.priceAmount * load.weightTonnes;
    final costEstimate = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: load.weightTonnes,
      dieselPricePerLitre: dieselPrice,
    );

    return StandardListCard(
      accent: palette.foreground,
      title: '${load.originCity} > ${load.destinationCity}',
      subtitle: routeSnapshot == null
          ? '${load.originLabel} - ${load.destinationLabel}'
          : '${routeSnapshot.distanceKm.toStringAsFixed(0)} km - ${_durationCompact(routeSnapshot.durationMinutes)}',
      trailing: StatusChip(label: _localizedLoadStatus(l10n, load.status)),
      onTap: () => context.go('${AppRoutes.loadDetailPath}/${load.id}'),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '₹${load.priceAmount.toStringAsFixed(0)} / T',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.subtleSurface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  _relativeAge(load.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total load value: ₹${totalLoadValue.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            costEstimate?.compactLabel ?? l10n.truckerFindLoadsTripCostUnavailable,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: costEstimate == null ? AppColors.textMuted : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _LoadMetaChip(icon: Icons.inventory_2_outlined, label: load.material),
              _LoadMetaChip(icon: Icons.scale_outlined, label: '${tonnes}T'),
              _LoadMetaChip(icon: Icons.local_shipping_outlined, label: _localizedBodyType(l10n, load.requiredBodyType)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.truckerFindLoadsPriceAdvancePickup(
              load.priceAmount.toStringAsFixed(0),
              load.advancePercentage,
              _formatDate(load.pickupDate),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextActionButton(
            label: l10n.truckerFindLoadsViewDetailsAction,
            onPressed: () => context.go('${AppRoutes.loadDetailPath}/${load.id}'),
          ),
        ],
      ),
    );
  }

  String _relativeAge(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inDays > 0) {
      return '${age.inDays}d';
    }
    if (age.inHours > 0) {
      return '${age.inHours}h';
    }
    if (age.inMinutes > 0) {
      return '${age.inMinutes}m';
    }
    return 'now';
  }

  String _durationCompact(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours <= 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LoadMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LoadMetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<TruckerCitySuggestion> suggestions;
  final ValueChanged<TruckerCitySuggestion> onSelected;

  const _SuggestionList({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < suggestions.length; index++) ...[
            ListTile(
              dense: true,
              title: Text(suggestions[index].label),
              onTap: () => onSelected(suggestions[index]),
            ),
            if (index != suggestions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final MarketplaceSearchFilters initialFilters;

  const _AdvancedFiltersSheet({required this.initialFilters});

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late String _bodyType;
  late List<int> _tyres;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _bodyType = widget.initialFilters.truckBodyType;
    _tyres = List<int>.from(widget.initialFilters.tyres);
    _minPriceController = TextEditingController(text: widget.initialFilters.minPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(text: widget.initialFilters.maxPrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          label: l10n.truckerFindLoadsTruckBodyTypeLabel,
          value: _bodyType.isEmpty ? null : _bodyType,
          items: [
            DropdownMenuItem(value: 'Open', child: Text(l10n.truckerFindLoadsBodyTypeOpen)),
            DropdownMenuItem(value: 'Trailer', child: Text(l10n.truckerFindLoadsBodyTypeTrailer)),
            DropdownMenuItem(value: 'Container', child: Text(l10n.truckerFindLoadsBodyTypeContainer)),
            DropdownMenuItem(value: 'Tanker', child: Text(l10n.truckerFindLoadsBodyTypeTanker)),
          ],
          onChanged: (value) => setState(() => _bodyType = value ?? ''),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.truckerFindLoadsTyreRequirementTitle, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tyre in const [6, 10, 12, 14, 18])
              FilterChip(
                label: Text('$tyre'),
                selected: _tyres.contains(tyre),
                onSelected: (_) {
                  setState(() {
                    if (_tyres.contains(tyre)) {
                      _tyres.remove(tyre);
                    } else {
                      _tyres.add(tyre);
                      _tyres.sort();
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _minPriceController,
          label: l10n.truckerFindLoadsMinPriceLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _maxPriceController,
          label: l10n.truckerFindLoadsMaxPriceLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.truckerFindLoadsApplyFiltersAction,
          onPressed: () {
            Navigator.of(context).pop(
              widget.initialFilters.copyWith(
                truckBodyType: _bodyType,
                tyres: _tyres,
                minPrice: double.tryParse(_minPriceController.text.trim()),
                maxPrice: double.tryParse(_maxPriceController.text.trim()),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlineButton(
          label: l10n.truckerFindLoadsResetAdvancedFiltersAction,
          onPressed: () {
            Navigator.of(context).pop(
              widget.initialFilters.copyWith(
                truckBodyType: '',
                tyres: const <int>[],
                minPrice: null,
                maxPrice: null,
              ),
            );
          },
        ),
      ],
    );
  }
}
