import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import '../../features/tts/data/load_marketplace_card_tts_builder.dart';
import '../../l10n/tts_localizations.dart';
import 'marketplace/marketplace_dark_header.dart';
import 'marketplace/marketplace_price_fact_row.dart';
import 'tts_card_speaker_button.dart';

class MarketplaceLoadCard extends ConsumerWidget {
  final MarketplaceLoadItem load;
  final VoidCallback? onViewDetails;
  final VoidCallback? onChat;
  final VoidCallback? onCall;
  final VoidCallback? onSupplierTap;
  final String? supplierInitial;
  final String? supplierAvatarUrl;

  const MarketplaceLoadCard({
    super.key,
    required this.load,
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
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final tyreLabel = formatMarketplaceTyreLabel(load.requiredTyres);

    return DecoratedBox(
      decoration: AppDecorations.brandGradientBorderOuter(),
      child: Padding(
        padding: const EdgeInsets.all(AppDecorations.brandGradientBorderWidth),
        child: DecoratedBox(
          decoration: AppDecorations.marketplaceCardFill(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarketplaceDarkHeader(
                    onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                    supplierName: load.supplierName ?? 'Supplier',
                    supplierId: load.supplierId,
                    supplierInitial: supplierInitial,
                    supplierAvatarUrl: supplierAvatarUrl,
                    age: _relativeAge(load.createdAt),
                    isSuperLoad: load.isSuperLoad,
                    originCity: load.originCity,
                    originState: load.originState ?? '',
                    destinationCity: load.destinationCity,
                    destinationState: load.destinationState ?? '',
                    onSupplierTap: onSupplierTap,
                    headerTrailing: TtsCardSpeakerButton(
                      message: loadUtterance,
                      onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                    ),
                  ),
                  MarketplacePriceFactRow(
                    onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                    priceAmount: load.priceAmount,
                    priceType: load.priceType,
                    material: load.material,
                    bodyTypeLabel: _localizedBodyType(l10n, load.requiredBodyType),
                    tyreLabel: tyreLabel.isEmpty ? null : tyreLabel,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _InlineMetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: _formatPickupDate(context, load.pickupDate),
                          onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                        ),
                        if (load.advancePercentage > 0)
                          _InlineMetaItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: '${load.advancePercentage}% adv',
                            accentColor: AppColors.info,
                            onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                          ),
                        if (load.trucksNeeded > 1)
                          _InlineMetaItem(
                            icon: Icons.local_shipping_outlined,
                            label: '${load.trucksBooked}/${load.trucksNeeded}',
                            onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FooterAction(
                            icon: Icons.phone_outlined,
                            label: l10n.commonCallAction,
                            alignment: Alignment.centerLeft,
                            onTap: onCall,
                            onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _FooterAction(
                            icon: Icons.info_outline,
                            label: l10n.commonViewDetailsAction,
                            alignment: Alignment.center,
                            onTap: onViewDetails,
                            onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _FooterAction(
                            icon: Icons.chat_bubble_outline,
                            label: l10n.commonChatLabel,
                            alignment: Alignment.centerRight,
                            iconAfterLabel: true,
                            onTap: onChat,
                            onDarkSurface: !AppDecorations.marketplaceLoadCardLightExperiment,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

class _FooterAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Alignment alignment;
  final VoidCallback? onTap;
  final bool iconAfterLabel;
  final bool onDarkSurface;

  const _FooterAction({
    required this.icon,
    required this.label,
    required this.alignment,
    this.onTap,
    this.iconAfterLabel = false,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: _mainAxisAlignment,
          children: [
            if (!iconAfterLabel) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (iconAfterLabel) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(icon, color: textColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  MainAxisAlignment get _mainAxisAlignment {
    if (alignment == Alignment.centerLeft) {
      return MainAxisAlignment.start;
    }
    if (alignment == Alignment.centerRight) {
      return MainAxisAlignment.end;
    }
    return MainAxisAlignment.center;
  }
}

class _InlineMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;
  final bool onDarkSurface;

  const _InlineMetaItem({
    required this.icon,
    required this.label,
    this.accentColor,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = AppDecorations.marketplaceCardTextSecondary(onDarkSurface: onDarkSurface);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: accentColor ?? defaultColor,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: accentColor ?? defaultColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
