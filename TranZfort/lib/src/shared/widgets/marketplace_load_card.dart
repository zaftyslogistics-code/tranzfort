import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trip_costing_service.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import 'avatar_widget.dart';
import 'curved_arc_route.dart';
import 'layout_components.dart';
import 'status_components.dart';

// AppRadius is defined in app_spacing.dart

class MarketplaceLoadCard extends StatelessWidget {
  final MarketplaceLoadItem load;
  final TripCostingService tripCostingService;
  final double? dieselPrice;
  final VoidCallback? onViewDetails;
  final VoidCallback? onChat;
  final VoidCallback? onCall;
  final VoidCallback? onSupplierTap;
  final String? supplierInitial;
  final String? supplierAvatarUrl;

  const MarketplaceLoadCard({
    super.key,
    required this.load,
    required this.tripCostingService,
    this.dieselPrice,
    this.onViewDetails,
    this.onChat,
    this.onCall,
    this.onSupplierTap,
    this.supplierInitial,
    this.supplierAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);
    final routeSnapshot = load.routeSnapshot;
    final minCapacity = load.derivedMinTruckCapacityTonnes;
    final maxCapacity = load.derivedMaxTruckCapacityTonnes;
    final weightLabel = minCapacity != null && maxCapacity != null
        ? '${minCapacity.toStringAsFixed(0)}-${maxCapacity.toStringAsFixed(0)}T'
        : '${tonnes}T';

    final isPerTon = load.priceType == 'per_ton';
    final totalLoadValue = isPerTon
        ? load.priceAmount * load.weightTonnes
        : load.priceAmount;
    final costEstimate = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: load.weightTonnes,
      dieselPricePerLitre: dieselPrice,
      priceAmountPerTonne: isPerTon ? load.priceAmount : null,
      fixedPriceAmount: isPerTon ? null : load.priceAmount,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceBase,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.elevation2,
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Supplier avatar + name + super-load badge + age ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  14,
                  16,
                  10,
                ),
                child: Row(
                  children: [
                    if (supplierInitial != null) ...[
                      UserAvatar(
                        avatarUrl: supplierAvatarUrl,
                        userId: load.supplierId,
                        initials: supplierInitial,
                        radius: 14.0,
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
                            load.supplierName ?? 'Supplier',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Row(
                            children: [
                              if (load.isSuperLoad) ...[
                                _SuperLoadPill(),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Text(
                                _relativeAge(load.createdAt),
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: _localizedLoadStatus(l10n, load.status)),
                  ],
                ),
              ),
              // ── Curved Arc Route visualization ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: CurvedArcRoute.compact(
                  origin: load.originCity,
                  destination: load.destinationCity,
                  originSubtitle: load.originState,
                  destinationSubtitle: load.destinationState,
                  distanceLabel: routeSnapshot != null
                      ? '${routeSnapshot.distanceKm.toStringAsFixed(0)} km'
                      : null,
                  durationLabel: routeSnapshot != null
                      ? _durationCompact(routeSnapshot.durationMinutes)
                      : null,
                ),
              ),
              // ── Meta chips: material, tonnes, body type ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8,
                ),
                child: LoadChipWrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  chips: [
                    LoadInfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: load.material,
                      level: LoadChipLevel.primary,
                    ),
                    LoadInfoChip(
                      icon: Icons.scale_outlined,
                      label: weightLabel,
                      level: LoadChipLevel.primary,
                    ),
                    LoadInfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: _localizedBodyType(l10n, load.requiredBodyType),
                      level: LoadChipLevel.primary,
                    ),
                    if (load.advancePercentage > 0)
                      LoadInfoChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: '${load.advancePercentage}% adv',
                        level: LoadChipLevel.secondary,
                        accentColor: AppColors.info,
                      ),
                  ],
                ),
              ),
              // ── Earnings strip: dark band with load value + profit ──
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inkSurface,
                  borderRadius: BorderRadius.circular(AppRadius.iconChip),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.inkSurface,
                      AppColors.inkMid,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.marketplaceLoadValue,
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.inkTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatAmount(totalLoadValue)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primaryOnDark,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            isPerTon
                                ? '@ ₹${load.priceAmount.toStringAsFixed(0)}/T · ${tonnes}T'
                                : 'Fixed: ₹${load.priceAmount.toStringAsFixed(0)} · ${tonnes}T',
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.inkTextSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (costEstimate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (costEstimate.isProfitable
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: (costEstimate.isProfitable
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              costEstimate.isProfitable ? l10n.marketplaceEstProfit : l10n.marketplaceEstLoss,
                              style: AppTypography.labelMicro.copyWith(
                                color: costEstimate.isProfitable
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '₹${_formatAmount(costEstimate.netProfit.abs())}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onViewDetails,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryOnDark,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.commonViewDetailsAction,
                              style: TextStyle(
                                color: AppColors.primaryOnDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppColors.primaryOnDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Footer: Call/Message split action row ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onCall,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: Container(
                          height: 48, // Increased from 44px to meet AppTouchTarget.min
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.commonCallAction,
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: onChat,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: Container(
                          height: 48, // Increased from 44px to meet AppTouchTarget.min
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                l10n.commonChatLabel,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  String _relativeAge(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inDays > 0) {
      return '${age.inDays}d';
    }
    if (age.inHours > 0) {
      return '${age.inHours}h';
    }
    if (age.inMinutes > 0) {
      return '${age.inMinutes}m';
    }
    return 'now';
  }

  String _durationCompact(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours <= 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  static String _localizedLoadStatus(AppLocalizations l10n, String status) {
    return l10n.truckerFindLoadsStatusValue(status.trim().toLowerCase());
  }

  static String _localizedBodyType(AppLocalizations l10n, String? bodyType) {
    final normalized = (bodyType ?? '').trim();
    if (normalized.isEmpty) {
      return l10n.truckerFindLoadsAnyBodyFallback;
    }
    return l10n.truckerFindLoadsBodyTypeValue(normalized.toLowerCase());
  }
}

/// Amber super-load pill (premium trust indicator).
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
