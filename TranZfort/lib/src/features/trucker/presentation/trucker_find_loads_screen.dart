import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/marketplace_load_card.dart';
import '../../communication/data/chat_repository.dart';
import '../data/trucker_city_search_service.dart';
import '../data/diesel_price_repository.dart';
import '../data/trip_costing_service.dart';
import '../data/trucker_marketplace_repository.dart';
import '../providers/find_loads_provider.dart';
import '../providers/trucker_providers.dart';

part 'trucker_find_loads_support.dart';
part 'trucker_find_loads_actions.dart';

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
                  // Keep the hero tight when collapsed; only show the longer
                  // helper copy when the user expands the advanced section.
                  subtitle: _quickAdvancedExpanded ? l10n.truckerFindLoadsHeroSubtitle : '',
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
                height: filters.hasActiveFilters ? 132 : 56,
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
                              label: l10n.commonRetryAction,
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
                                  MarketplaceLoadCard(
                                    load: state.loads[index],
                                    tripCostingService: tripCostingService,
                                    dieselPrice: dieselPriceMap[(state.loads[index].originState ?? '').trim().toLowerCase()],
                                    supplierInitial: state.loads[index].supplierName?.trim().isNotEmpty == true
                                        ? state.loads[index].supplierName!.substring(0, 1).toUpperCase()
                                        : null,
                                    supplierAvatarUrl: state.loads[index].supplierAvatarUrl,
                                    onSupplierTap: () => context.push(AppRoutes.publicProfileLocation(state.loads[index].supplierId)),
                                    onViewDetails: () => context.push('${AppRoutes.loadDetailPath}/${state.loads[index].id}'),
                                    onChat: () => _startChatFromFeedAction(context, ref, state.loads[index]),
                                    onCall: () => _callSupplierFromFeedAction(context, ref, state.loads[index]),
                                  ),
                                  if (index != state.loads.length - 1) const SizedBox(height: AppSpacing.lg),
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
                                      label: l10n.commonRetryAction,
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
