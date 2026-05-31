part of 'trucker_find_loads_screen.dart';

/// Pinned header height: body-type row (+ tyre row when a specific type is selected).
/// Heights include ink card padding; +20% vs original 44 / 78 for tyre row breathing room.
double _pinnedTruckFilterHeight(MarketplaceSearchFilters filters) {
  if (filters.truckBodyType.trim().isEmpty) {
    return 44.0;
  }
  return 80.0;
}

/// Full-bleed ink filter band (tabs + truck filters). Load cards stay edge-to-edge below.
Widget _marketplaceBleedFrame({required Widget child}) {
  return DecoratedBox(
    decoration: AppDecorations.brandGradientBorderOuter(),
    child: Padding(
      padding: const EdgeInsets.all(AppDecorations.brandGradientBorderWidth),
      child: DecoratedBox(
        decoration: AppDecorations.inkHeroCard(borderRadius: BorderRadius.zero),
        child: child,
      ),
    ),
  );
}

class _FindLoadsFeedTabs extends StatelessWidget {
  final FindLoadsState state;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectSuperLoads;

  const _FindLoadsFeedTabs({
    required this.state,
    required this.onSelectAll,
    required this.onSelectSuperLoads,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _marketplaceBleedFrame(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: InkSegmentTabBar(
          items: [
            FilterChipItem(
              label: l10n.truckerFindLoadsAllLoadsTab,
              selected: state.selectedTab == FindLoadsTab.all,
              onTap: onSelectAll,
            ),
            FilterChipItem(
              label: l10n.truckerFindLoadsSuperLoadsTab,
              selected: state.selectedTab == FindLoadsTab.superLoads,
              onTap: onSelectSuperLoads,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedTruckFilterBar extends StatelessWidget {
  final MarketplaceSearchFilters filters;
  final ValueChanged<String> onBodyTypeChanged;
  final ValueChanged<int> onTyreToggled;

  const _PinnedTruckFilterBar({
    required this.filters,
    required this.onBodyTypeChanged,
    required this.onTyreToggled,
  });

  @override
  Widget build(BuildContext context) {
    return _marketplaceBleedFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          4,
          AppSpacing.lg,
          0,
        ),
        child: MarketplaceFilterBar(
          selectedBodyType: filters.truckBodyType,
          selectedTyres: filters.tyres,
          onDarkSurface: true,
          onBodyTypeChanged: onBodyTypeChanged,
          onTyreToggled: onTyreToggled,
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
    return ColoredBox(
      color: AppColors.inkSurface,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
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
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
