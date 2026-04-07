import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/city_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../models/load_filters.dart';

class FindLoadsFilterSheet extends ConsumerStatefulWidget {
  final LoadFilters initialFilters;
  final Function(LoadFilters) onApply;

  const FindLoadsFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  ConsumerState<FindLoadsFilterSheet> createState() => _FindLoadsFilterSheetState();
}

class _FindLoadsFilterSheetState extends ConsumerState<FindLoadsFilterSheet> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late String _material;
  late String _truckType;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.initialFilters.originCity);
    _destinationController = TextEditingController(text: widget.initialFilters.destinationCity);
    _material = widget.initialFilters.material;
    _truckType = widget.initialFilters.truckType;
    _sortBy = widget.initialFilters.sortBy;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.cardRadius),
              topRight: Radius.circular(AppSpacing.cardRadius),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.findLoadsAdvancedFilters,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _originController.clear();
                        _destinationController.clear();
                        setState(() {
                          _material = '';
                          _truckType = '';
                          _sortBy = 'newest';
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.resetAction,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.findLoadsFromLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      CityField(
                        label: l10n.findLoadsFromLabel,
                        controller: _originController,
                        searchKey: 'origin',
                        onSelected: (city) {
                          _originController.text = city.city;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.findLoadsToLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      CityField(
                        label: l10n.findLoadsToLabel,
                        controller: _destinationController,
                        searchKey: 'destination',
                        onSelected: (city) {
                          _destinationController.text = city.city;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.findLoadsMaterialLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _buildMaterialChip(l10n, ''),
                          _buildMaterialChip(l10n, 'Coal'),
                          _buildMaterialChip(l10n, 'Steel'),
                          _buildMaterialChip(l10n, 'Cement'),
                          _buildMaterialChip(l10n, 'Sand'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.findLoadsTruckLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _buildTruckTypeChip(l10n, ''),
                          _buildTruckTypeChip(l10n, 'open'),
                          _buildTruckTypeChip(l10n, 'container'),
                          _buildTruckTypeChip(l10n, 'trailer'),
                          _buildTruckTypeChip(l10n, 'tanker'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.findLoadsSortByLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _buildSortChip(l10n, 'newest'),
                          _buildSortChip(l10n, 'price_high'),
                          _buildSortChip(l10n, 'price_low'),
                          _buildSortChip(l10n, 'pickup_date'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderDefault)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlineButton(
                        onPressed: () => Navigator.pop(context),
                        label: l10n.tripCancelAction,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        onPressed: () {
                          final filters = LoadFilters(
                            originCity: _originController.text.trim(),
                            destinationCity: _destinationController.text.trim(),
                            material: _material,
                            truckType: _truckType,
                            sortBy: _sortBy,
                          );
                          widget.onApply(filters);
                          Navigator.pop(context);
                        },
                        label: l10n.tripConfirmAction,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialChip(AppLocalizations l10n, String value) {
    final isSelected = _material == value;
    final label = value.isEmpty
        ? l10n.findLoadsAnyMaterial
        : switch (value) {
            'Coal' => l10n.findLoadsMaterialCoal,
            'Steel' => l10n.findLoadsMaterialSteel,
            'Cement' => l10n.findLoadsMaterialCement,
            'Sand' => l10n.findLoadsMaterialSand,
            _ => value,
          };

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _material = selected ? value : '';
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryMuted,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTruckTypeChip(AppLocalizations l10n, String value) {
    final isSelected = _truckType == value;
    final label = value.isEmpty
        ? l10n.findLoadsAnyTruck
        : switch (value) {
            'open' => l10n.postLoadTruckTypeOpen,
            'container' => l10n.postLoadTruckTypeContainer,
            'trailer' => l10n.postLoadTruckTypeTrailer,
            'tanker' => l10n.postLoadTruckTypeTanker,
            _ => value,
          };

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _truckType = selected ? value : '';
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryMuted,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSortChip(AppLocalizations l10n, String value) {
    final isSelected = _sortBy == value;
    final label = switch (value) {
      'price_high' => l10n.findLoadsSortPriceHighLow,
      'price_low' => l10n.findLoadsSortPriceLowHigh,
      'pickup_date' => l10n.findLoadsSortPickupDate,
      _ => l10n.findLoadsSortNewest,
    };

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = selected ? value : 'newest';
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryMuted,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
