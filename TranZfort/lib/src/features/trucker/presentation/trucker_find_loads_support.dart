part of 'trucker_find_loads_screen.dart';

/// Pinned header height: truck-type row (+ tyre row when Open).
double _pinnedTruckFilterHeight(MarketplaceSearchFilters filters) {
  var height = 56.0;
  if (filters.truckBodyType.trim().toLowerCase() == 'open') {
    height += 36.0;
  }
  return height;
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
        child: SizedBox(
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
        child: MarketplaceFilterBar(
          selectedBodyType: filters.truckBodyType,
          selectedTyres: filters.tyres,
          onBodyTypeChanged: onBodyTypeChanged,
          onTyreToggled: onTyreToggled,
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
      child: SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.center,
          child: child,
        ),
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
