import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trip_costing_service.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import '../../features/tts/data/load_marketplace_card_tts_builder.dart';
import '../../l10n/tts_localizations.dart';
import 'marketplace/marketplace_dark_header.dart';
import 'marketplace/marketplace_chips.dart';
import 'tts_card_speaker_button.dart';

class MarketplaceLoadCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = TtsLocalizations.of(context);
    final pickupDateLabel = MaterialLocalizations.of(context).formatMediumDate(load.pickupDate);
    final loadUtterance = const LoadMarketplaceCardTtsBuilder().build(
      load: load,
      tts: ttsL10n,
      ui: l10n,
      pickupDateLabel: pickupDateLabel,
    );
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);
    final routeSnapshot = load.routeSnapshot;
    final minCapacity = load.derivedMinTruckCapacityTonnes;
    final maxCapacity = load.derivedMaxTruckCapacityTonnes;
    
    // Task C: Show only truck capacity range
    // If capacity range is available, show min-max
    // Otherwise show actual load weight as fallback
    final weightLabel = minCapacity != null && maxCapacity != null
        ? '${minCapacity.toStringAsFixed(0)}-${maxCapacity.toStringAsFixed(0)}T'
        : tonnes;

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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.inkSurface,
            AppColors.inkMid,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.elevation2,
        border: Border.all(
          color: AppColors.divider,
          width: 0.75,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dark Header (150-170px max) ──
              MarketplaceDarkHeader(
                supplierName: load.supplierName ?? 'Supplier',
                supplierId: load.supplierId,
                supplierInitial: supplierInitial,
                supplierAvatarUrl: supplierAvatarUrl,
                age: _relativeAge(load.createdAt),
                status: load.status,
                isSuperLoad: load.isSuperLoad,
                originCity: load.originCity,
                originState: load.originState ?? '',
                destinationCity: load.destinationCity,
                destinationState: load.destinationState ?? '',
                totalLoadValue: totalLoadValue,
                costEstimate: costEstimate,
                priceAmount: load.priceAmount,
                priceType: load.priceType,
                onSupplierTap: onSupplierTap,
                headerTrailing: TtsCardSpeakerButton(message: loadUtterance),
              ),
              // ── Dark Section: Load/truck details only ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Primary chips: material, weight, body type ──
                    LoadChipWrap(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── Secondary inline metadata ──
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _InlineMetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: _formatPickupDate(context, load.pickupDate),
                        ),
                        if (load.advancePercentage > 0)
                          _InlineMetaItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: '${load.advancePercentage}% adv',
                            accentColor: AppColors.info,
                          ),
                        if (load.trucksNeeded > 1)
                          _InlineMetaItem(
                            icon: Icons.local_shipping_outlined,
                            label: '${load.trucksBooked}/${load.trucksNeeded}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Footer: Call/Details/Chat split action row ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onCall,
                        borderRadius: BorderRadius.circular(14.0), // AppSpacing.button
                        child: Container(
                          height: 48, // Increased from 44px to meet AppTouchTarget.min
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: AppColors.inkTextPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.commonCallAction,
                                style: TextStyle(
                                  color: AppColors.inkTextPrimary,
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
                        onTap: onViewDetails,
                        borderRadius: BorderRadius.circular(14.0), // AppSpacing.button
                        child: Container(
                          height: 48, // Increased from 44px to meet AppTouchTarget.min
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.inkTextPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.commonViewDetailsAction,
                                style: TextStyle(
                                  color: AppColors.inkTextPrimary,
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
                        borderRadius: BorderRadius.circular(14.0), // AppSpacing.button
                        child: Container(
                          height: 48, // Increased from 44px to meet AppTouchTarget.min
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                l10n.commonChatLabel,
                                style: TextStyle(
                                  color: AppColors.inkTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.inkTextPrimary,
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

  String _formatPickupDate(BuildContext context, DateTime pickupDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickupDay = DateTime(pickupDate.year, pickupDate.month, pickupDate.day);
    final daysUntil = pickupDay.difference(today).inDays;

    final l10n = AppLocalizations.of(context);
    if (daysUntil == 0) {
      return l10n.marketplaceLoadPickupToday;
    }
    if (daysUntil == 1) {
      return l10n.marketplaceLoadPickupTomorrow;
    }
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(pickupDate);
    return l10n.marketplaceLoadPickupOnDate(dateLabel);
  }

  static String _localizedBodyType(AppLocalizations l10n, String? bodyType) {
    final normalized = (bodyType ?? '').trim();
    if (normalized.isEmpty) {
      return l10n.truckerFindLoadsAnyBodyFallback;
    }
    return l10n.truckerFindLoadsBodyTypeValue(normalized.toLowerCase());
  }
}

/// Inline metadata item for secondary information.
class _InlineMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _InlineMetaItem({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: accentColor ?? AppColors.inkTextSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: accentColor ?? AppColors.inkTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
