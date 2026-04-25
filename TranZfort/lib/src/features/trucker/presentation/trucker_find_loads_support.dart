part of 'trucker_find_loads_screen.dart';

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
  final normalized = (bodyType ?? '').trim().toLowerCase();
  if (normalized.isEmpty) {
    return l10n.truckerFindLoadsAnyBodyFallback;
  }
  return l10n.truckerFindLoadsBodyTypeValue(normalized);
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
            DropdownMenuItem(value: 'Open', child: Text(l10n.truckerFindLoadsBodyTypeValue('open'))),
            DropdownMenuItem(value: 'Trailer', child: Text(l10n.truckerFindLoadsBodyTypeValue('trailer'))),
            DropdownMenuItem(value: 'Container', child: Text(l10n.truckerFindLoadsBodyTypeValue('container'))),
            DropdownMenuItem(value: 'Tanker', child: Text(l10n.truckerFindLoadsBodyTypeValue('tanker'))),
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
