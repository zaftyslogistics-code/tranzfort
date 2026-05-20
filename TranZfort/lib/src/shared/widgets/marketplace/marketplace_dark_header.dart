import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trip_costing_service.dart';
import '../avatar_widget.dart';
import 'marketplace_route_line.dart';

/// Dark header widget for load card.
///
/// Contains supplier/status row, integrated route line, and money row.
/// Target height: 150-170px max.
///
/// Breakdown:
/// - Supplier/status row: 34-40px
/// - Route row: 70-78px
/// - Money row: 34-42px
class MarketplaceDarkHeader extends StatelessWidget {
  final String supplierName;
  final String supplierId;
  final String? supplierInitial;
  final String? supplierAvatarUrl;
  final String? age;
  final String status;
  final bool isSuperLoad;
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;
  final double totalLoadValue;
  final TripCostEstimate? costEstimate;
  final double priceAmount;
  final String priceType;
  final VoidCallback? onSupplierTap;

  const MarketplaceDarkHeader({
    super.key,
    required this.supplierName,
    required this.supplierId,
    this.supplierInitial,
    this.supplierAvatarUrl,
    this.age,
    required this.status,
    this.isSuperLoad = false,
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
    required this.totalLoadValue,
    this.costEstimate,
    required this.priceAmount,
    required this.priceType,
    this.onSupplierTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row A: Supplier + Status (34-40px)
          _SupplierStatusRow(
            supplierName: supplierName,
            supplierId: supplierId,
            supplierInitial: supplierInitial,
            supplierAvatarUrl: supplierAvatarUrl,
            age: age,
            status: status,
            isSuperLoad: isSuperLoad,
            onSupplierTap: onSupplierTap,
          ),
          const SizedBox(height: 8),
          // Row B: Integrated Route Line (70-78px)
          MarketplaceRouteLine(
            originCity: originCity,
            originState: originState,
            destinationCity: destinationCity,
            destinationState: destinationState,
          ),
          const SizedBox(height: 8),
          // Row C: Load Value + Profit (34-42px)
          if (costEstimate != null)
            _MoneyRow(
              totalLoadValue: totalLoadValue,
              costEstimate: costEstimate!,
              priceAmount: priceAmount,
              priceType: priceType,
              l10n: l10n,
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

/// Supplier + Status row in dark header.
class _SupplierStatusRow extends StatelessWidget {
  final String supplierName;
  final String supplierId;
  final String? supplierInitial;
  final String? supplierAvatarUrl;
  final String? age;
  final String status;
  final bool isSuperLoad;
  final VoidCallback? onSupplierTap;

  const _SupplierStatusRow({
    required this.supplierName,
    required this.supplierId,
    this.supplierInitial,
    this.supplierAvatarUrl,
    this.age,
    required this.status,
    this.isSuperLoad = false,
    this.onSupplierTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        if (supplierInitial != null) ...[
          UserAvatar(
            avatarUrl: supplierAvatarUrl,
            userId: supplierId,
            initials: supplierInitial,
            radius: 17.0, // Increased from 14.0 (20% bigger)
            onTap: onSupplierTap,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                supplierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17, // Increased from 14 (20% bigger)
                    ),
              ),
              Row(
                children: [
                  if (isSuperLoad) ...[
                    _SuperLoadPill(),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (age != null)
                    Text(
                      age!,
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CompactStatusChip(label: _localizedLoadStatus(l10n, status)),
      ],
    );
  }

  static String _localizedLoadStatus(AppLocalizations l10n, String status) {
    return l10n.truckerFindLoadsStatusValue(status.trim().toLowerCase());
  }
}

/// Compact status chip for dark header.
class _CompactStatusChip extends StatelessWidget {
  final String label;

  const _CompactStatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelMicro.copyWith(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Super load pill (compact version).
class _SuperLoadPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.superLoadBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.superLoadText.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 10, color: AppColors.superLoadText),
          const SizedBox(width: 2),
          Text(
            'SUPER',
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.superLoadText,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Money row in dark header (price type + load value + profit/loss).
class _MoneyRow extends StatelessWidget {
  final double totalLoadValue;
  final TripCostEstimate costEstimate;
  final double priceAmount;
  final String priceType;
  final AppLocalizations l10n;

  const _MoneyRow({
    required this.totalLoadValue,
    required this.costEstimate,
    required this.priceAmount,
    required this.priceType,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isPerTon = priceType == 'per_ton';
    final priceDisplay = isPerTon
        ? '₹${priceAmount.toStringAsFixed(0)}'
        : MarketplaceDarkHeader._formatAmount(priceAmount);
    final priceLabel = isPerTon ? '₹/T' : 'Fixed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.heroCta,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Price type column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priceLabel,
                  style: AppTypography.labelMicro.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceDisplay,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Load value column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.marketplaceLoadValue,
                  style: AppTypography.labelMicro.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${MarketplaceDarkHeader._formatAmount(totalLoadValue)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Profit/loss column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  costEstimate.isProfitable ? l10n.marketplaceEstProfit : l10n.marketplaceEstLoss,
                  style: AppTypography.labelMicro.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${MarketplaceDarkHeader._formatAmount(costEstimate.netProfit.abs())}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
