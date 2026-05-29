import 'package:flutter/material.dart';

import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Price (hero size) on the left; material / body / tyre accent chips on the right.
class MarketplacePriceFactRow extends StatelessWidget {
  final double priceAmount;
  final String priceType;
  final String material;
  final String bodyTypeLabel;
  final String? tyreLabel;

  const MarketplacePriceFactRow({
    super.key,
    required this.priceAmount,
    required this.priceType,
    required this.material,
    required this.bodyTypeLabel,
    this.tyreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPerTon = priceType == 'per_ton';
    final priceLabel = isPerTon
        ? '₹${priceAmount.toStringAsFixed(0)}/T'
        : '₹${_formatAmount(priceAmount)} ${l10n.supplierPostLoadPriceTypeValue('fixed')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            priceLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.inkTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  BrandAccentChip(label: material, mini: true),
                  const SizedBox(width: AppSpacing.xs),
                  BrandAccentChip(label: bodyTypeLabel, mini: true),
                  if (tyreLabel != null && tyreLabel!.trim().isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    BrandAccentChip(label: tyreLabel!, mini: true),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

String formatMarketplaceTyreLabel(List<int> requiredTyres) {
  if (requiredTyres.isEmpty) {
    return '';
  }
  final sorted = List<int>.from(requiredTyres)..sort();
  if (sorted.length == 1) {
    return '${sorted.first}T';
  }
  return sorted.map((t) => '${t}T').join('·');
}
