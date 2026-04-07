import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class FindLoadsQuickFilters extends ConsumerWidget {
  final String material;
  final String truckType;
  final String sortBy;
  final Function(String) onMaterialChanged;
  final Function(String) onTruckTypeChanged;
  final Function(String) onSortChanged;
  final bool compact;

  const FindLoadsQuickFilters({
    super.key,
    required this.material,
    required this.truckType,
    required this.sortBy,
    required this.onMaterialChanged,
    required this.onTruckTypeChanged,
    required this.onSortChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            l10n.findLoadsAdvancedFilters,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          children: [
            Expanded(
              child: _buildQuickChip(
                context,
                label: _materialLabel(l10n),
                onTap: () => _cycleValue(
                  material,
                  ['', 'Coal', 'Steel', 'Cement', 'Sand'],
                  onMaterialChanged,
                ),
                icon: Icons.category_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildQuickChip(
                context,
                label: _truckLabel(l10n),
                onTap: () => _cycleValue(
                  truckType,
                  ['', 'open', 'container', 'trailer', 'tanker'],
                  onTruckTypeChanged,
                ),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildQuickChip(
                context,
                label: _sortLabel(l10n),
                onTap: () => _cycleValue(
                  sortBy,
                  ['newest', 'price_high', 'price_low', 'pickup_date'],
                  onSortChanged,
                ),
                icon: Icons.sort_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: AppColors.textSecondary,
            ),
            if (!compact) const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 11 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: compact ? 14 : 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _materialLabel(AppLocalizations l10n) {
    return switch (material) {
      'Coal' => l10n.findLoadsMaterialCoal,
      'Steel' => l10n.findLoadsMaterialSteel,
      'Cement' => l10n.findLoadsMaterialCement,
      'Sand' => l10n.findLoadsMaterialSand,
      '' => l10n.findLoadsAnyMaterial,
      _ => material,
    };
  }

  String _truckLabel(AppLocalizations l10n) {
    return truckType.isEmpty
        ? l10n.findLoadsAnyTruck
        : _truckTypeLabel(l10n, truckType);
  }

  String _truckTypeLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'open' => l10n.postLoadTruckTypeOpen,
      'container' => l10n.postLoadTruckTypeContainer,
      'trailer' => l10n.postLoadTruckTypeTrailer,
      'tanker' => l10n.postLoadTruckTypeTanker,
      _ => value,
    };
  }

  String _sortLabel(AppLocalizations l10n) {
    return switch (sortBy) {
      'price_high' => l10n.findLoadsSortPriceHighLow,
      'price_low' => l10n.findLoadsSortPriceLowHigh,
      'pickup_date' => l10n.findLoadsSortPickupDate,
      _ => l10n.findLoadsSortNewest,
    };
  }

  String _nextValue(String current, List<String> values) {
    final currentIndex = values.indexOf(current);
    if (currentIndex == -1 || currentIndex == values.length - 1) {
      return values.first;
    }
    return values[currentIndex + 1];
  }

  void _cycleValue(String current, List<String> values, Function(String) onChanged) {
    final next = _nextValue(current, values);
    onChanged(next);
  }
}
