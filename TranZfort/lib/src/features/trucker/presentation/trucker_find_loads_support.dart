part of 'trucker_find_loads_screen.dart';

/// Pinned legacy filter: one body-type row (chip + vertical padding).
const double _pinnedFilterSingleRowHeight = 40.0;

/// Pinned legacy filter: body-type row + tyre row.
const double _pinnedFilterWithTyreRowHeight = 74.0;

/// Full-bleed ink filter band (tabs). Load cards stay edge-to-edge below.
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

String _legacyBodyTypeForPinnedFilter(MarketplaceSearchFilters filters) {
  final body = filters.truckBodyType.trim().toLowerCase();
  if (body.isNotEmpty && LoadBodyTypes.filterChipTypes.contains(body)) {
    return body;
  }
  final category = filters.vehicleCategoryCode.trim().toLowerCase();
  if (category.isEmpty || !isPinnedFindLoadsVehicleCategory(category)) {
    return '';
  }
  return mapVehicleCategoryCodeToLegacyBodyType(category);
}

MarketplaceSearchFilters _filtersAfterPinnedBodyType(
  MarketplaceSearchFilters filters,
  String bodyType,
) {
  final normalized = bodyType.trim().toLowerCase();
  if (normalized.isEmpty) {
    return filters.copyWith(
      truckBodyType: '',
      vehicleCategoryCode: '',
      bodyStyleCodes: const <String>[],
      configurationCodes: const <String>[],
      tyres: const <int>[],
    );
  }
  return filters.copyWith(
    truckBodyType: normalized,
    vehicleCategoryCode: '',
    bodyStyleCodes: const <String>[],
    configurationCodes: const <String>[],
    tyres: const <int>[],
  );
}

MarketplaceSearchFilters _filtersAfterPinnedTyreToggle(
  MarketplaceSearchFilters filters,
  int count,
) {
  final tyres = List<int>.from(filters.tyres);
  if (tyres.contains(count)) {
    tyres.remove(count);
  } else {
    tyres.add(count);
  }
  tyres.sort();
  return filters.copyWith(tyres: tyres);
}

int _findLoadsAdvancedFilterBadgeCount(MarketplaceSearchFilters filters) {
  var count = 0;
  if (filters.material.trim().isNotEmpty) {
    count += 1;
  }
  if (filters.sortOption != MarketplaceSortOption.newest) {
    count += 1;
  }
  if (filters.minPrice != null || filters.maxPrice != null) {
    count += 1;
  }
  if (filters.bodyStyleCodes.isNotEmpty || filters.configurationCodes.isNotEmpty) {
    count += 1;
  }
  final category = filters.vehicleCategoryCode.trim().toLowerCase();
  if (category.isNotEmpty && extendedFindLoadsVehicleCategoryCodes.contains(category)) {
    count += 1;
  }
  return count;
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

class _LegacyPinnedVehicleFilterBar extends StatelessWidget {
  final MarketplaceSearchFilters filters;
  final ValueChanged<MarketplaceSearchFilters> onFiltersChanged;

  const _LegacyPinnedVehicleFilterBar({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.inkBorder.withValues(alpha: 0.8)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
        child: MarketplaceFilterBar(
          selectedBodyType: _legacyBodyTypeForPinnedFilter(filters),
          selectedTyres: filters.tyres,
          onDarkSurface: true,
          onBodyTypeChanged: (bodyType) {
            onFiltersChanged(_filtersAfterPinnedBodyType(filters, bodyType));
          },
          onTyreToggled: (count) {
            onFiltersChanged(_filtersAfterPinnedTyreToggle(filters, count));
          },
        ),
      ),
    );
  }
}

class _PinnedVehicleFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool showTyreRow;

  _PinnedVehicleFilterHeaderDelegate({
    required this.child,
    required this.showTyreRow,
  });

  @override
  double get minExtent => showTyreRow ? _pinnedFilterWithTyreRowHeight : _pinnedFilterSingleRowHeight;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.inkSurface,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedVehicleFilterHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || showTyreRow != oldDelegate.showTyreRow;
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

class _AdvancedSearchSheet extends StatefulWidget {
  final MarketplaceSearchFilters initialFilters;
  final VehicleCatalog? catalog;

  const _AdvancedSearchSheet({
    required this.initialFilters,
    required this.catalog,
  });

  @override
  State<_AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<_AdvancedSearchSheet> {
  late TextEditingController _materialController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late MarketplaceSortOption _sortOption;
  late VehicleRequirementSelection _vehicleSelection;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _materialController = TextEditingController(text: filters.material);
    _minPriceController = TextEditingController(text: filters.minPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(text: filters.maxPrice?.toStringAsFixed(0) ?? '');
    _sortOption = filters.sortOption;
    _vehicleSelection = VehicleRequirementSelection(
      categoryCode: _initialAdvancedCategory(filters),
      bodyStyleCodes: filters.bodyStyleCodes,
      configurationCodes: filters.configurationCodes,
    );
  }

  String _initialAdvancedCategory(MarketplaceSearchFilters filters) {
    final code = filters.vehicleCategoryCode.trim().toLowerCase();
    if (extendedFindLoadsVehicleCategoryCodes.contains(code)) {
      return code;
    }
    return '';
  }

  @override
  void dispose() {
    _materialController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  List<VehicleCategoryCatalogItem> _extendedCategories(VehicleCatalog catalog) {
    return catalog.categories
        .where((item) => extendedFindLoadsVehicleCategoryCodes.contains(item.code.trim().toLowerCase()))
        .toList(growable: false);
  }

  void _selectExtendedCategory(String code) {
    setState(() {
      if (_vehicleSelection.categoryCode == code) {
        _vehicleSelection = const VehicleRequirementSelection(
          categoryCode: '',
          bodyStyleCodes: <String>[],
          configurationCodes: <String>[],
        );
      } else {
        _vehicleSelection = VehicleRequirementSelection(
          categoryCode: code,
          bodyStyleCodes: const <String>[],
          configurationCodes: const <String>[],
        );
      }
    });
  }

  MarketplaceSearchFilters _buildResult() {
    final catalog = widget.catalog;
    var next = widget.initialFilters.copyWith(
      material: _materialController.text.trim(),
      sortOption: _sortOption,
      minPrice: double.tryParse(_minPriceController.text.trim()),
      maxPrice: double.tryParse(_maxPriceController.text.trim()),
    );

    final category = _vehicleSelection.categoryCode.trim();
    if (category.isEmpty) {
      return next;
    }

    if (catalog == null) {
      return next.copyWith(
        vehicleCategoryCode: category,
        bodyStyleCodes: _vehicleSelection.bodyStyleCodes,
        configurationCodes: _vehicleSelection.configurationCodes,
      );
    }

    final legacy = resolveVehicleRequirementLegacyFields(
      selection: _vehicleSelection,
      catalog: catalog,
    );
    return next.copyWith(
      vehicleCategoryCode: category,
      bodyStyleCodes: _vehicleSelection.bodyStyleCodes,
      configurationCodes: _vehicleSelection.configurationCodes,
      truckBodyType: legacy.bodyType,
      tyres: legacy.selectedTyres.toList(growable: false)..sort(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalog = widget.catalog;
    final extendedCategories = catalog == null ? const <VehicleCategoryCatalogItem>[] : _extendedCategories(catalog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSearchField(
          controller: _materialController,
          hintText: l10n.truckerFindLoadsMaterialHint,
          onDarkSurface: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppDropdown<MarketplaceSortOption>(
          label: l10n.truckerFindLoadsSortByLabel,
          value: _sortOption,
          onDarkSurface: true,
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
              setState(() => _sortOption = value);
            }
          },
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
        if (extendedCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'More vehicle types',
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.inkTextPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in extendedCategories) ...[
                  VehicleCategoryInkChip(
                    label: category.nameEn,
                    icon: vehicleCategoryIcon(category.code),
                    selected: _vehicleSelection.categoryCode == category.code,
                    onTap: () => _selectExtendedCategory(category.code),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ],
        if (catalog != null && _vehicleSelection.categoryCode.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          VehicleCatalogSelectorSheet(
            catalog: catalog,
            initialSelection: _vehicleSelection,
            onDarkSurface: true,
            lockCategorySelection: true,
            embedInParentSheet: true,
            hideSheetActions: true,
            onChanged: (selection) => setState(() => _vehicleSelection = selection),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.truckerFindLoadsApplyFiltersAction,
          onPressed: () => Navigator.of(context).pop(_buildResult()),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlineButton(
          label: l10n.truckerFindLoadsResetAdvancedFiltersAction,
          onPressed: () {
            final pinnedVehicle = isPinnedFindLoadsVehicleCategory(widget.initialFilters.vehicleCategoryCode);
            Navigator.of(context).pop(
              widget.initialFilters.copyWith(
                material: '',
                sortOption: MarketplaceSortOption.newest,
                minPrice: null,
                maxPrice: null,
                vehicleCategoryCode: pinnedVehicle ? widget.initialFilters.vehicleCategoryCode : '',
                bodyStyleCodes: pinnedVehicle ? widget.initialFilters.bodyStyleCodes : const <String>[],
                configurationCodes: pinnedVehicle ? widget.initialFilters.configurationCodes : const <String>[],
                truckBodyType: pinnedVehicle ? widget.initialFilters.truckBodyType : '',
                tyres: pinnedVehicle ? widget.initialFilters.tyres : const <int>[],
              ),
            );
          },
        ),
      ],
    );
  }
}
