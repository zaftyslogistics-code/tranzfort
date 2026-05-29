import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/trucker_fleet_provider.dart';

/// Truck-type-first filter bar for Find Loads (FP-3 / FP-4).
///
/// Shows Any + body-type segments and tyre counts from fleet options.
class MarketplaceFilterBar extends StatelessWidget {
  static const truckBodyTypes = <String>['Open', 'Container', 'Trailer', 'Tanker'];

  final String selectedBodyType;
  final List<int> selectedTyres;
  final ValueChanged<String> onBodyTypeChanged;
  final ValueChanged<int> onTyreToggled;
  final bool onDarkSurface;

  const MarketplaceFilterBar({
    super.key,
    required this.selectedBodyType,
    required this.selectedTyres,
    required this.onBodyTypeChanged,
    required this.onTyreToggled,
    this.onDarkSurface = false,
  });

  bool get _showTyreRow => selectedBodyType.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _BodyTypeChip(
                label: l10n.commonAnyLabel,
                icon: Icons.apps_outlined,
                selected: selectedBodyType.isEmpty,
                onDarkSurface: onDarkSurface,
                onTap: () => onBodyTypeChanged(''),
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final bodyType in truckBodyTypes) ...[
                _BodyTypeChip(
                  label: l10n.truckerFindLoadsBodyTypeValue(bodyType.toLowerCase()),
                  icon: _bodyTypeIcon(bodyType),
                  selected: selectedBodyType == bodyType,
                  onDarkSurface: onDarkSurface,
                  onTap: () {
                    if (selectedBodyType == bodyType) {
                      onBodyTypeChanged('');
                    } else {
                      onBodyTypeChanged(bodyType);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        if (_showTyreRow) ...[
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final count in truckerFleetTyreOptions) ...[
                  _TyreChip(
                    count: count,
                    selected: selectedTyres.contains(count),
                    onDarkSurface: onDarkSurface,
                    onTap: () => onTyreToggled(count),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static IconData _bodyTypeIcon(String bodyType) {
    switch (bodyType.toLowerCase()) {
      case 'open':
        return Icons.local_shipping_outlined;
      case 'container':
        return Icons.inventory_2_outlined;
      case 'trailer':
        return Icons.rv_hookup_outlined;
      case 'tanker':
        return Icons.water_drop_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}

class _BodyTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool onDarkSurface;
  final VoidCallback onTap;

  const _BodyTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onDarkSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (onDarkSurface) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TyreChip extends StatelessWidget {
  final int count;
  final bool selected;
  final bool onDarkSurface;
  final VoidCallback onTap;

  const _TyreChip({
    required this.count,
    required this.selected,
    required this.onDarkSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (onDarkSurface) {
      final accent = AppColors.secondaryOnDark;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Ink(
            decoration: AppDecorations.inkFilterChip(
              selected: selected,
              accent: accent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tire_repair_outlined,
                    size: 14,
                    color: selected ? accent : AppColors.inkTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : AppColors.inkTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FilterChip(
      label: Text('$count'),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      avatar: Icon(
        Icons.tire_repair_outlined,
        size: 14,
        color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
      ),
    );
  }
}
