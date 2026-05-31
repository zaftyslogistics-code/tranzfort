import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'marketplace/marketplace_price_fact_row.dart';
import 'marketplace_load_card.dart';

/// Body + tyre accent chips for fleet and load meta rows (Appendix F).
class VehicleMetaChips extends StatelessWidget {
  final String? bodyType;
  final int? tyres;
  final bool mini;

  const VehicleMetaChips({
    super.key,
    required this.bodyType,
    this.tyres,
    this.mini = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bodyLabel = MarketplaceLoadCard.localizeBodyType(l10n, bodyType);
    final tyreLabel = tyres == null || tyres! <= 0 ? null : formatMarketplaceTyreLabel([tyres!]);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (bodyLabel.trim().isNotEmpty)
          BrandAccentChip(label: bodyLabel, mini: mini),
        if (tyreLabel != null && tyreLabel.trim().isNotEmpty)
          BrandAccentChip(label: tyreLabel, mini: mini),
      ],
    );
  }
}
