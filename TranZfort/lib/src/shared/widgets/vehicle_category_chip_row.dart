import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/supplier/data/supplier_load_repository.dart';
import '../../l10n/app_localizations.dart';

/// Compact ink chip for a vehicle catalog category (Find Loads pinned filter).
class VehicleCategoryInkChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const VehicleCategoryInkChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.primaryOnDark;
    final iconColor = selected ? accent : AppColors.inkTextSecondary;
    final textColor = selected ? accent : AppColors.inkTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Ink(
          decoration: AppDecorations.inkFilterChip(selected: selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData vehicleCategoryIcon(String categoryCode) {
  switch (categoryCode.trim().toLowerCase()) {
    case 'lcv':
      return Icons.local_shipping_outlined;
    case 'open_truck':
      return Icons.agriculture_outlined;
    case 'trailer':
      return Icons.rv_hookup_outlined;
    case 'container':
      return Icons.inventory_2_outlined;
    case 'bulker':
      return Icons.grain_outlined;
    case 'tanker':
      return Icons.water_drop_outlined;
    case 'tipper':
      return Icons.construction_outlined;
    case 'reefer':
      return Icons.ac_unit_outlined;
    case 'parcel':
      return Icons.all_inbox_outlined;
    case 'odc':
      return Icons.view_in_ar_outlined;
    default:
      return Icons.local_shipping_outlined;
  }
}

/// Horizontal Any + catalog category chips for pinned Find Loads filter.
class VehicleCategoryFilterChipRow extends StatelessWidget {
  final List<VehicleCategoryCatalogItem> categories;
  final String selectedCategoryCode;
  final VoidCallback onAnySelected;
  final ValueChanged<VehicleCategoryCatalogItem> onCategorySelected;
  final Widget? trailing;

  const VehicleCategoryFilterChipRow({
    super.key,
    required this.categories,
    required this.selectedCategoryCode,
    required this.onAnySelected,
    required this.onCategorySelected,
    this.trailing,
  });

  bool get _anySelected => selectedCategoryCode.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                VehicleCategoryInkChip(
                  label: l10n.commonAnyLabel,
                  icon: Icons.apps_outlined,
                  selected: _anySelected,
                  onTap: onAnySelected,
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final category in categories) ...[
                  VehicleCategoryInkChip(
                    label: category.nameEn,
                    icon: vehicleCategoryIcon(category.code),
                    selected: !_anySelected && selectedCategoryCode == category.code,
                    onTap: () => onCategorySelected(category),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
