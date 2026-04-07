import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../../../shared/widgets/scroll_to_top_fab.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../models/load_filters.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/index.dart';
import 'find_loads_controller.dart';

class FindLoadsScreen extends ConsumerStatefulWidget {
  const FindLoadsScreen({super.key});

  @override
  ConsumerState<FindLoadsScreen> createState() => _FindLoadsScreenState();
}

class _FindLoadsScreenState extends ConsumerState<FindLoadsScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  String _material = '';
  String _truckType = '';
  String _sortBy = 'newest';
  bool _mapViewEnabled = false;
  bool _filtersCollapsed = false;

  final _scrollController = ScrollController();
  late final FindLoadsController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller = FindLoadsController(
      ref: ref,
      setState: (fn) => setState(fn),
      context: context,
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldCollapse = _scrollController.position.pixels > 28;
    if (shouldCollapse != _filtersCollapsed && mounted) {
      setState(() => _filtersCollapsed = shouldCollapse);
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      ref.read(findLoadsProvider.notifier).loadMore();
    }
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 6;
    if (width < 420) return 8;
    return AppSpacing.screenPaddingH;
  }

  bool _isCompactPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  bool _isCompactHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 760;
  }

  Future<void> _search() {
    return _controller.search(
      LoadFilters(
        originCity: _originController.text.trim(),
        destinationCity: _destinationController.text.trim(),
        material: _material,
        truckType: _truckType,
        sortBy: _sortBy,
      ),
    );
  }

  Future<void> _clearFilters() async {
    await _controller.clearFilters(
      clearOrigin: () => _originController.clear(),
      clearDestination: () => _destinationController.clear(),
      setMaterial: (value) => _material = value,
      setTruckType: (value) => _truckType = value,
      setSortBy: (value) => _sortBy = value,
    );
  }

  int _activeFilterCount() {
    return _controller.calculateActiveFilterCount(
      originCity: _originController.text,
      destinationCity: _destinationController.text,
      material: _material,
      truckType: _truckType,
      sortBy: _sortBy,
    );
  }

  String _summaryText() {
    final l10n = AppLocalizations.of(context);
    return _controller.buildSummaryText(
      originCity: _originController.text,
      destinationCity: _destinationController.text,
      material: _material,
      truckType: _truckType,
      sortBy: _sortBy,
      l10n: l10n,
    );
  }

  Future<void> _openAdvancedFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FindLoadsFilterSheet(
          initialFilters: LoadFilters(
            originCity: _originController.text.trim(),
            destinationCity: _destinationController.text.trim(),
            material: _material,
            truckType: _truckType,
            sortBy: _sortBy,
          ),
          onApply: (filters) {
            setState(() {
              _originController.text = filters.originCity;
              _destinationController.text = filters.destinationCity;
              _material = filters.material;
              _truckType = filters.truckType;
              _sortBy = filters.sortBy;
            });
            _search();
          },
        );
      },
    );
  }

  Future<void> _saveCurrentSearch() async {
    await _controller.saveSearch(
      originCity: _originController.text.trim(),
      destinationCity: _destinationController.text.trim(),
      material: _material,
      truckType: _truckType,
      sortBy: _sortBy,
    );
  }

  Future<void> _applySavedSearch(Map<String, dynamic> saved) async {
    await _controller.applySavedSearch(
      saved,
      setOrigin: (value) => _originController.text = value,
      setDestination: (value) => _destinationController.text = value,
      setMaterial: (value) => _material = value,
      setTruckType: (value) => _truckType = value,
      setSortBy: (value) => _sortBy = value,
      search: _search,
    );
  }

  Future<void> _deleteSavedSearch(String id) async {
    await _controller.deleteSavedSearch(id);
  }

  Widget _buildSavedSearches(List<Map<String, dynamic>> savedSearches) {
    final l10n = AppLocalizations.of(context);
    final compactPhone = _isCompactPhone(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.findLoadsSavedSearchesLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: compactPhone ? 36 : 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: savedSearches.length,
            itemBuilder: (context, index) {
              final saved = savedSearches[index];
              final origin = (saved['origin_city'] ?? '').toString();
              final destination = (saved['dest_city'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: InputChip(
                  label: Text(
                    origin.isEmpty && destination.isEmpty
                        ? l10n.findLoadsAllRoutes
                        : '$origin → $destination',
                    style: TextStyle(
                      fontSize: compactPhone ? 11 : 12,
                    ),
                  ),
                  onPressed: () => _applySavedSearch(saved),
                  onDeleted: () => _deleteSavedSearch(saved['id'].toString()),
                  deleteIcon: Icon(
                    Icons.close,
                    size: compactPhone ? 14 : 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(findLoadsProvider);
    final savedSearches =
        ref.watch(savedSearchesProvider).valueOrNull ?? const [];
    final activeFilterCount = _activeFilterCount();
    final horizontalPadding = _horizontalPadding(context);
    final compactPhone = _isCompactPhone(context);
    final compactHeight = _isCompactHeight(context);
    final filtersCollapsed = _filtersCollapsed || compactHeight;
    final showSavedSearches = savedSearches.isNotEmpty && !compactHeight;
    final useCompactAppBarActions = MediaQuery.sizeOf(context).width < 390;

    return Scaffold(
      drawer: const AppDrawer(role: 'trucker'),
      appBar: AppBar(
        title: Text(l10n.findLoadsTitle),
        actions: [
          AppBarUtilityActions(
            ttsPreviewText: l10n.findLoadsDashboardTts,
            compact: useCompactAppBarActions,
          ),
        ],
      ),
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      bottomNavigationBar: const BottomNavBar(currentRole: 'trucker'),
      body: ScreenScrollContainer(
        scrollable: false,
        child: Column(
          children: [
            TtsAnnounce(
              text: l10n.findLoadsScreenTtsContextCount(state.results.length),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                primary: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compactPhone ? 10 : AppSpacing.screenPaddingV,
                    horizontalPadding,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: AppSpacing.normal,
                        padding: EdgeInsets.all(
                          filtersCollapsed
                              ? (compactPhone ? 10 : AppSpacing.md)
                              : (compactPhone ? 12 : AppSpacing.cardPadding),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            compactPhone ? 14 : AppSpacing.cardRadius,
                          ),
                          border: Border.all(color: AppColors.borderDefault),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.route_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _summaryText(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    maxLines: filtersCollapsed || compactPhone
                                        ? 1
                                        : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openAdvancedFiltersSheet,
                                  child: Text(l10n.editAction),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: filtersCollapsed ? 0 : AppSpacing.sm,
                            ),
                            if (!filtersCollapsed)
                              FindLoadsQuickFilters(
                                material: _material,
                                truckType: _truckType,
                                sortBy: _sortBy,
                                onMaterialChanged: (value) {
                                  setState(() => _material = value);
                                  _search();
                                },
                                onTruckTypeChanged: (value) {
                                  setState(() => _truckType = value);
                                  _search();
                                },
                                onSortChanged: (value) {
                                  setState(() => _sortBy = value);
                                  _search();
                                },
                                compact: compactPhone,
                              ),
                          ],
                        ),
                      ),
                      if (showSavedSearches) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildSavedSearches(savedSearches),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _mapViewEnabled
                                      ? Icons.map_outlined
                                      : Icons.view_list_outlined,
                                  color: AppColors.primary,
                                  size: compactPhone ? 18 : 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _mapViewEnabled
                                        ? l10n.findLoadsViewMapLabel
                                        : l10n.findLoadsViewListLabel,
                                    style: Theme.of(context).textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: compactPhone ? 176 : 220,
                                  ),
                                  child: SegmentedButton<bool>(
                                    segments: [
                                      ButtonSegment<bool>(
                                        value: false,
                                        icon: const Icon(Icons.list),
                                        label: Text(
                                          compactPhone
                                              ? ''
                                              : l10n.findLoadsViewListLabel,
                                        ),
                                      ),
                                      ButtonSegment<bool>(
                                        value: true,
                                        icon: const Icon(Icons.map),
                                        label: Text(
                                          compactPhone
                                              ? ''
                                              : l10n.findLoadsViewMapLabel,
                                        ),
                                      ),
                                    ],
                                    selected: {_mapViewEnabled},
                                    onSelectionChanged: (Set<bool> selection) {
                                      setState(() {
                                        _mapViewEnabled = selection.first;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                if (activeFilterCount > 0)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: InputChip(
                                        label: Text(
                                          l10n.findLoadsActiveFiltersSummary(
                                            activeFilterCount,
                                          ),
                                        ),
                                        onPressed: _clearFilters,
                                        deleteIcon: const Icon(Icons.clear, size: 16),
                                        onDeleted: _clearFilters,
                                      ),
                                    ),
                                  )
                                else
                                  const Spacer(),
                                const SizedBox(width: AppSpacing.sm),
                                IconButton.outlined(
                                  onPressed: _saveCurrentSearch,
                                  icon: const Icon(Icons.bookmark_border),
                                  tooltip: l10n.findLoadsSaveSearchAction,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeContentSwitcher(
                        duration: AppSpacing.normal,
                        child: state.isSearching
                            ? Column(
                                children: [
                                  SkeletonLoader.card(height: 80),
                                  const SizedBox(height: AppSpacing.sm),
                                  SkeletonLoader.card(height: 80),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (!state.isSearching) ...[
                        if (state.results.isEmpty)
                          EmptyStateView(
                            icon: Icons.local_shipping_outlined,
                            title: l10n.noLoadsFoundTitle,
                            subtitle: l10n.noLoadsFoundSubtitle,
                            cta: GradientButton(
                              onPressed: _clearFilters,
                              label: l10n.resetAction,
                            ),
                          )
                        else if (_mapViewEnabled)
                          SizedBox(
                            height: 400,
                            child: FindLoadsMapView(loads: state.results),
                          )
                        else
                          Column(
                            children: [
                              for (final load in state.results)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: RichLoadCard(
                                    load: load,
                                    backgroundColor: AppColors.gray50,
                                    borderColor: AppColors.borderDefault,
                                    onTap: () {
                                      context.push('/load-detail/${load['id']}');
                                    },
                                  ),
                                ),
                              if (state.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
