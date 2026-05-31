import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/supplier/data/load_marketplace_mapping.dart';
import '../../features/supplier/data/supplier_load_models.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import '../../l10n/app_localizations.dart';
import 'marketplace/marketplace_price_fact_row.dart' show MarketplacePriceFactRow, formatMarketplaceTyreLabel;
import 'marketplace/marketplace_route_line.dart';
import 'marketplace_load_card.dart';

/// Dark marketplace-style card for supplier-owned loads (My Loads, dashboard recent).
class SupplierLoadCompactCard extends ConsumerWidget {
  final MarketplaceLoadItem item;
  final List<Widget> statusChips;
  final Widget? footer;
  final VoidCallback? onTap;

  const SupplierLoadCompactCard({
    super.key,
    required this.item,
    this.statusChips = const [],
    this.footer,
    this.onTap,
  });

  factory SupplierLoadCompactCard.fromLoad({
    required Load load,
    required String supplierId,
    required List<Widget> statusChips,
    Widget? footer,
    VoidCallback? onTap,
  }) {
    return SupplierLoadCompactCard(
      item: load.toMarketplaceItem(supplierId: supplierId),
      statusChips: statusChips,
      footer: footer,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final onDark = !AppDecorations.marketplaceLoadCardLightExperiment;
    final tyreLabel = formatMarketplaceTyreLabel(item.requiredTyres);

    final innerRadius = AppDecorations.marketplaceListCardInnerRadius;
    return DecoratedBox(
      decoration: AppDecorations.brandGradientBorderOuter(
        borderRadius: AppDecorations.marketplaceListCardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDecorations.brandGradientBorderWidth),
        child: DecoratedBox(
          decoration: AppDecorations.marketplaceCardFill(borderRadius: innerRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: innerRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: MarketplaceRouteLine(
                      originCity: item.originCity,
                      originState: item.originState ?? '',
                      destinationCity: item.destinationCity,
                      destinationState: item.destinationState ?? '',
                      onDarkSurface: onDark,
                    ),
                  ),
                  MarketplacePriceFactRow(
                    onDarkSurface: onDark,
                    priceAmount: item.priceAmount,
                    priceType: item.priceType,
                    material: item.material,
                    bodyTypeLabel: MarketplaceLoadCard.localizeBodyType(l10n, item.requiredBodyType),
                    tyreLabel: tyreLabel.isEmpty ? null : tyreLabel,
                  ),
                  if (statusChips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: statusChips,
                      ),
                    ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: footer!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
