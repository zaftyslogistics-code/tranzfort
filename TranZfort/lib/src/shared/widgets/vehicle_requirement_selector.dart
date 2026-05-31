import 'package:flutter/material.dart';

import '../../core/models/load_body_types.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'form_inputs.dart';

/// Shared body-type dropdown for post-load and filters (P1-1 partial).
class VehicleRequirementSelector extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> bodyTypes;

  const VehicleRequirementSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.bodyTypes = LoadBodyTypes.selectable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppDropdown<String>(
      label: label,
      value: value,
      items: bodyTypes
          .map(
            (bodyType) => DropdownMenuItem<String>(
              value: bodyType,
              child: Text(_localizedBodyTypeLabel(l10n, bodyType)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  static String _localizedBodyTypeLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'any' => l10n.supplierPostLoadBodyTypeAny,
      'open' => l10n.supplierPostLoadBodyTypeOpen,
      'container' => l10n.supplierPostLoadBodyTypeContainer,
      'trailer' => l10n.supplierPostLoadBodyTypeTrailer,
      'tanker' => l10n.supplierPostLoadBodyTypeTanker,
      'refrigerated' => l10n.supplierPostLoadBodyTypeRefrigerated,
      _ => value,
    };
  }
}

/// Tyre count chips used by post-load and fleet (P1-1 partial).
class VehicleTyreSelector extends StatelessWidget {
  final List<int> selectedTyres;
  final ValueChanged<List<int>> onChanged;
  final List<int> options;

  const VehicleTyreSelector({
    super.key,
    required this.selectedTyres,
    required this.onChanged,
    this.options = const [6, 10, 12, 14, 16, 18, 22],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilterChip(
          label: Text(l10n.commonAnyLabel),
          selected: selectedTyres.isEmpty,
          onSelected: (_) => onChanged(const []),
        ),
        for (final tyres in options)
          FilterChip(
            label: Text('$tyres'),
            selected: selectedTyres.contains(tyres),
            onSelected: (selected) {
              final next = List<int>.from(selectedTyres);
              if (selected) {
                next.add(tyres);
              } else {
                next.remove(tyres);
              }
              next.sort();
              onChanged(next);
            },
          ),
      ],
    );
  }
}
