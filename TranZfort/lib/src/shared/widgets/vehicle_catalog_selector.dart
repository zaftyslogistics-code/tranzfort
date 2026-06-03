import 'package:flutter/material.dart';

import '../../core/models/load_body_types.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/supplier/data/supplier_load_repository.dart';
import '../../l10n/app_localizations.dart';
import 'action_buttons.dart';
import 'form_inputs.dart';
import 'vehicle_category_chip_row.dart';

class VehicleRequirementLegacyFields {
  final String bodyType;
  final Set<int> selectedTyres;

  const VehicleRequirementLegacyFields({
    required this.bodyType,
    required this.selectedTyres,
  });
}

VehicleRequirementLegacyFields resolveVehicleRequirementLegacyFields({
  required VehicleRequirementSelection selection,
  required VehicleCatalog catalog,
}) {
  final selectedConfigs = catalog.configurations
      .where((item) => selection.configurationCodes.contains(item.code))
      .toList(growable: false);
  final selectedTyres = selectedConfigs.map((item) => item.wheelsW).whereType<int>().toSet();

  if (selection.bodyStyleCodes.isNotEmpty) {
    final firstCode = selection.bodyStyleCodes.first;
    for (final item in catalog.bodyStyles) {
      if (item.code == firstCode) {
        return VehicleRequirementLegacyFields(
          bodyType: mapVehicleBodyStyleLabelToLegacyBodyType(item.nameEn),
          selectedTyres: selectedTyres,
        );
      }
    }
  }

  return VehicleRequirementLegacyFields(
    bodyType: mapVehicleCategoryCodeToLegacyBodyType(selection.categoryCode),
    selectedTyres: selectedTyres,
  );
}

/// Legacy Find Loads pinned body types → catalog category codes.
String mapLegacyBodyTypeToVehicleCategoryCode(String bodyType) {
  switch (bodyType.trim().toLowerCase()) {
    case LoadBodyTypes.container:
      return 'container';
    case LoadBodyTypes.trailer:
      return 'trailer';
    case LoadBodyTypes.tanker:
      return 'tanker';
    case LoadBodyTypes.refrigerated:
      return 'reefer';
    case LoadBodyTypes.open:
    default:
      return 'open_truck';
  }
}

const Set<String> pinnedFindLoadsVehicleCategoryCodes = <String>{
  'open_truck',
  'container',
  'trailer',
  'tanker',
  'reefer',
};

const Set<String> extendedFindLoadsVehicleCategoryCodes = <String>{
  'lcv',
  'bulker',
  'tipper',
  'parcel',
  'odc',
};

bool isPinnedFindLoadsVehicleCategory(String categoryCode) {
  return pinnedFindLoadsVehicleCategoryCodes.contains(categoryCode.trim().toLowerCase());
}

String mapVehicleCategoryCodeToLegacyBodyType(String categoryCode) {
  switch (categoryCode.trim().toLowerCase()) {
    case 'container':
      return LoadBodyTypes.container;
    case 'trailer':
      return LoadBodyTypes.trailer;
    case 'tanker':
      return LoadBodyTypes.tanker;
    case 'reefer':
      return LoadBodyTypes.refrigerated;
    case 'open_truck':
      return LoadBodyTypes.open;
    default:
      return LoadBodyTypes.open;
  }
}

String mapVehicleBodyStyleLabelToLegacyBodyType(String? label) {
  final normalized = (label ?? '').trim().toLowerCase();
  if (normalized.contains('container')) {
    return LoadBodyTypes.container;
  }
  if (normalized.contains('trailer')) {
    return LoadBodyTypes.trailer;
  }
  if (normalized.contains('tanker')) {
    return LoadBodyTypes.tanker;
  }
  if (normalized.contains('reefer') || normalized.contains('refrigerated')) {
    return LoadBodyTypes.refrigerated;
  }
  return LoadBodyTypes.open;
}

class VehicleRequirementSelection {
  final String categoryCode;
  final List<String> bodyStyleCodes;
  final List<String> configurationCodes;

  const VehicleRequirementSelection({
    required this.categoryCode,
    required this.bodyStyleCodes,
    required this.configurationCodes,
  });
}

Future<VehicleRequirementSelection?> showVehicleCatalogBottomSheet({
  required BuildContext context,
  required VehicleCatalog catalog,
  required VehicleRequirementSelection initialSelection,
  bool lockCategorySelection = false,
  bool onDarkSurface = true,
}) {
  return showModalBottomSheet<VehicleRequirementSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final borderRadius = BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet));
      return DecoratedBox(
        decoration: onDarkSurface
            ? AppDecorations.inkHeroCard(borderRadius: borderRadius)
            : BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: borderRadius,
              ),
        child: VehicleCatalogSelectorSheet(
          catalog: catalog,
          initialSelection: initialSelection,
          onDarkSurface: onDarkSurface,
          lockCategorySelection: lockCategorySelection,
          embedInParentSheet: true,
        ),
      );
    },
  );
}

class VehicleCatalogSelectorSheet extends StatefulWidget {
  final VehicleCatalog catalog;
  final VehicleRequirementSelection initialSelection;
  final bool onDarkSurface;
  final bool lockCategorySelection;
  final bool embedInParentSheet;
  final bool hideSheetActions;
  final ValueChanged<VehicleRequirementSelection>? onChanged;

  const VehicleCatalogSelectorSheet({
    super.key,
    required this.catalog,
    required this.initialSelection,
    this.onDarkSurface = true,
    this.lockCategorySelection = false,
    this.embedInParentSheet = false,
    this.hideSheetActions = false,
    this.onChanged,
  });

  @override
  State<VehicleCatalogSelectorSheet> createState() => _VehicleCatalogSelectorSheetState();
}

class _VehicleCatalogSelectorSheetState extends State<VehicleCatalogSelectorSheet> {
  late String _categoryCode;
  late List<String> _bodyStyleCodes;
  late List<String> _configurationCodes;

  @override
  void initState() {
    super.initState();
    _syncFromInitial(widget.initialSelection);
  }

  @override
  void didUpdateWidget(covariant VehicleCatalogSelectorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSelection;
    final prev = oldWidget.initialSelection;
    if (prev.categoryCode != next.categoryCode ||
        !_listEquals(prev.bodyStyleCodes, next.bodyStyleCodes) ||
        !_listEquals(prev.configurationCodes, next.configurationCodes)) {
      _syncFromInitial(next);
    }
  }

  void _syncFromInitial(VehicleRequirementSelection selection) {
    _categoryCode = selection.categoryCode;
    _bodyStyleCodes = List<String>.from(selection.bodyStyleCodes);
    _configurationCodes = List<String>.from(selection.configurationCodes);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      VehicleRequirementSelection(
        categoryCode: _categoryCode,
        bodyStyleCodes: _bodyStyleCodes,
        configurationCodes: _configurationCodes,
      ),
    );
  }

  String? get _lockedCategoryLabel {
    if (!widget.lockCategorySelection || _categoryCode.trim().isEmpty) {
      return null;
    }
    for (final item in widget.catalog.categories) {
      if (item.code == _categoryCode) {
        return item.nameEn;
      }
    }
    return _categoryCode;
  }

  TextStyle? _titleStyle(ThemeData theme) {
    if (!widget.onDarkSurface) {
      return theme.textTheme.titleLarge;
    }
    return theme.textTheme.titleLarge?.copyWith(color: AppColors.inkTextPrimary);
  }

  TextStyle? _sectionStyle(ThemeData theme) {
    if (!widget.onDarkSurface) {
      return theme.textTheme.titleSmall;
    }
    return theme.textTheme.titleSmall?.copyWith(color: AppColors.inkTextPrimary);
  }

  Widget _buildOptionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    if (widget.onDarkSurface) {
      return VehicleCategoryInkChip(
        label: label,
        icon: selected ? Icons.check_circle_outline : Icons.circle_outlined,
        selected: selected,
        onTap: onTap,
      );
    }

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = widget.catalog.categories;
    final bodyStyles = widget.catalog.bodyStyles.where((item) => item.categoryCode == _categoryCode).toList(growable: false);
    final configurations = widget.catalog.configurations.where((item) {
      if (item.categoryCode != _categoryCode) {
        return false;
      }
      if (_bodyStyleCodes.isEmpty) {
        return true;
      }
      final bodyStyleCode = (item.bodyStyleCode ?? '').trim();
      if (bodyStyleCode.isEmpty) {
        return true;
      }
      return _bodyStyleCodes.contains(bodyStyleCode);
    }).toList(growable: false);

    final horizontalPadding = widget.embedInParentSheet ? 0.0 : AppSpacing.lg;
    final topPadding = widget.embedInParentSheet ? 0.0 : AppSpacing.lg;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          bottom: MediaQuery.of(context).viewInsets.bottom + (widget.embedInParentSheet ? AppSpacing.md : AppSpacing.lg),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.embedInParentSheet) ...[
                Text(
                  l10n.supplierPostLoadVehicleRequirementsTitle,
                  style: _titleStyle(theme),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (widget.lockCategorySelection && _lockedCategoryLabel != null) ...[
                Text('Vehicle type', style: _sectionStyle(theme)),
                const SizedBox(height: AppSpacing.sm),
                VehicleCategoryInkChip(
                  label: _lockedCategoryLabel!,
                  icon: vehicleCategoryIcon(_categoryCode),
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                AppDropdown<String>(
                  label: 'Vehicle category',
                  value: _categoryCode.isEmpty ? null : _categoryCode,
                  onDarkSurface: widget.onDarkSurface,
                  items: categories
                      .map((item) => DropdownMenuItem<String>(value: item.code, child: Text(item.nameEn)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _categoryCode = value;
                      _bodyStyleCodes = const <String>[];
                      _configurationCodes = const <String>[];
                    });
                    _notifyChanged();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (bodyStyles.isNotEmpty) ...[
                Text('Body style', style: _sectionStyle(theme)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final item in bodyStyles)
                      _buildOptionChip(
                        label: item.nameEn,
                        selected: _bodyStyleCodes.contains(item.code),
                        onTap: () {
                          setState(() {
                            final next = List<String>.from(_bodyStyleCodes);
                            if (next.contains(item.code)) {
                              next.remove(item.code);
                            } else {
                              next.add(item.code);
                            }
                            _bodyStyleCodes = next;
                            _configurationCodes = _configurationCodes
                                .where((code) => configurations.any((cfg) => cfg.code == code))
                                .toList(growable: false);
                          });
                          _notifyChanged();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Configuration', style: _sectionStyle(theme)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final item in configurations)
                    _buildOptionChip(
                      label: item.labelEn,
                      selected: _configurationCodes.contains(item.code),
                      onTap: () {
                        setState(() {
                          final next = List<String>.from(_configurationCodes);
                          if (next.contains(item.code)) {
                            next.remove(item.code);
                          } else {
                            next.add(item.code);
                          }
                          _configurationCodes = next;
                        });
                        _notifyChanged();
                      },
                    ),
                ],
              ),
              if (!widget.hideSheetActions) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButton(
                        label: l10n.commonCancelAction,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Apply',
                        onPressed: _categoryCode.trim().isEmpty
                            ? null
                            : () => Navigator.of(context).pop(
                                  VehicleRequirementSelection(
                                    categoryCode: _categoryCode,
                                    bodyStyleCodes: _bodyStyleCodes,
                                    configurationCodes: _configurationCodes,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String vehicleRequirementSummaryLabel({
  required VehicleCatalog catalog,
  required VehicleRequirementSelection selection,
  required AppLocalizations l10n,
}) {
  if (selection.categoryCode.trim().isEmpty) {
    return l10n.commonAnyLabel;
  }
  VehicleCategoryCatalogItem? category;
  for (final item in catalog.categories) {
    if (item.code == selection.categoryCode) {
      category = item;
      break;
    }
  }
  final bodyLabels = selection.bodyStyleCodes
      .map((code) {
        for (final item in catalog.bodyStyles) {
          if (item.code == code) {
            return item.nameEn;
          }
        }
        return code;
      })
      .toList(growable: false);
  final configLabels = selection.configurationCodes
      .map((code) {
        for (final item in catalog.configurations) {
          if (item.code == code) {
            return item.labelEn;
          }
        }
        return code;
      })
      .toList(growable: false);
  final parts = <String>[
    category?.nameEn ?? selection.categoryCode,
    if (bodyLabels.isNotEmpty) bodyLabels.join(', '),
    if (configLabels.isNotEmpty) configLabels.take(2).join(', '),
    if (configLabels.length > 2) '+${configLabels.length - 2} more',
  ];
  return parts.join(' • ');
}
