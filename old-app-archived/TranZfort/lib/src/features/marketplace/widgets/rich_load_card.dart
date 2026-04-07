import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/map_navigation_utils.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/static_route_map.dart';
import '../../../shared/widgets/status_badge.dart';
import '../utils/load_pricing.dart';
import '../providers/marketplace_providers.dart';
import '../providers/splitted/shared_providers.dart';

class RichLoadCard extends ConsumerWidget {
  final Map<String, dynamic> load;
  final VoidCallback? onChat;
  final VoidCallback? onBook;
  final VoidCallback? onTap;
  final bool showActions;
  final int? driveTimeMinutes;
  final double? tollEstimate;
  final double? fuelEstimate;
  final String? weatherSummary;
  final double? weatherTempC;
  final Color? backgroundColor;
  final Color? borderColor;

  const RichLoadCard({
    super.key,
    required this.load,
    this.onChat,
    this.onBook,
    this.onTap,
    this.showActions = true,
    this.driveTimeMinutes,
    this.tollEstimate,
    this.fuelEstimate,
    this.weatherSummary,
    this.weatherTempC,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isSuper = load['is_super_load'] == true;
    final isTruckMatch = load['truck_match'] is bool
        ? load['truck_match'] as bool
        : null;
    final createdAt = DateTime.tryParse((load['created_at'] ?? '').toString());
    final pickupDate = DateTime.tryParse(
      (load['pickup_date'] ?? '').toString(),
    );
    final supplierLabel =
        ((load['poster_label'] ?? '') as String).trim().isEmpty
        ? l10n.richLoadCardVerifiedSupplierFallback
        : load['poster_label'];

    final distanceKm = CoordinateUtils.parseDouble(load['distance_km']);
    final originLat = CoordinateUtils.parseDouble(load['origin_lat']);
    final originLng = CoordinateUtils.parseDouble(load['origin_lng']);
    final destLat = CoordinateUtils.parseDouble(load['dest_lat']);
    final destLng = CoordinateUtils.parseDouble(load['dest_lng']);
    final hasRoutePreview =
        originLat != null && originLng != null && destLat != null && destLng != null;
    final tripCostResult = ref
        .read(tripCostingServiceProvider)
        .estimate(
          distanceKm: distanceKm,
          loadWeightTonnes: CoordinateUtils.parseDouble(load['weight_tonnes']),
          payloadKg: 10000,
          emptyMileageKmpl: 4,
          loadedMileageKmpl: 2.5,
          axleCount: 2,
          dieselPricePerLitre: 90,
        );

    final tripCostText = switch (tripCostResult) {
      Success(data: final estimate) => l10n.richLoadCardTripCostEstimate(
        _formatCurrency(estimate.totalCost),
      ),
      Failure() => l10n.loadDetailTripCostUnavailable,
    };

    return Card(
      color: backgroundColor ?? AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: borderColor ?? AppColors.neutralLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${load['origin_city']} → ${load['dest_city']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _timeAgo(createdAt, l10n),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (hasRoutePreview) ...[
                Stack(
                  children: [
                    StaticRouteMap(
                      originLat: originLat,
                      originLng: originLng,
                      destLat: destLat,
                      destLng: destLng,
                      originLabel: '${load['origin_city'] ?? '-'}',
                      destLabel: '${load['dest_city'] ?? '-'}',
                      height: 128,
                      onTap: () {
                        final loadId = (load['id'] ?? '').toString();
                        if (loadId.isNotEmpty) {
                          context.push('/route-preview/$loadId');
                        } else {
                          onTap?.call();
                        }
                      },
                    ),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: FilledButton.tonalIcon(
                        onPressed: () => openGoogleMapsRoute(
                          context: context,
                          originLat: originLat,
                          originLng: originLng,
                          destLat: destLat,
                          destLng: destLng,
                        ),
                        icon: const Icon(Icons.map_outlined, size: AppSpacing.iconSm),
                        label: Text(l10n.routePreviewStartNavigation),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primary,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _rateText(load, l10n),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _headlinePriceText(load),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.richLoadCardPickupPrefix}: ${pickupDate != null ? IstTime.formatDayMonth(pickupDate) : '-'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
              ),
              Text(
                _advanceText(load, l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                tripCostText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tripCostResult is Success
                      ? AppColors.success
                      : AppColors.neutral,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(label: '${load['material'] ?? '-'}'),
                  _MetaChip(label: '${load['weight_tonnes'] ?? '-'}T'),
                  _MetaChip(
                    label:
                        '${_truckType(load['required_truck_type'], l10n)} / ${_tyres(load['required_tyres'], l10n)}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.postedByPrefix}: $supplierLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge(
                    label: l10n.profileVerifiedChip,
                    backgroundColor: AppColors.successTint,
                    textColor: AppColors.success,
                    icon: Icons.verified,
                  ),
                ],
              ),
              if (distanceKm != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${distanceKm.toStringAsFixed(0)} km',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      _routeMetaText(context, l10n, distanceKm),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (weatherSummary != null &&
                  weatherSummary!.isNotEmpty &&
                  weatherTempC != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud, size: 14, color: AppColors.info),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        '${weatherTempC!.toStringAsFixed(0)}°C · $weatherSummary',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (isSuper) ...[
                    StatusBadge(
                      label: l10n.richLoadCardSuperLoadLabel,
                      backgroundColor: AppColors.brandOrangeLight,
                      textColor: AppColors.brandOrangeDark,
                      icon: Icons.star,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (isTruckMatch != null)
                    StatusBadge(
                      label: isTruckMatch
                          ? l10n.findLoadsMatchLabel
                          : l10n.findLoadsMismatchLabel,
                      backgroundColor: isTruckMatch
                          ? AppColors.successTint
                          : AppColors.warningTint,
                      textColor: isTruckMatch
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                ],
              ),
              if ((load['trucks_needed'] as num? ?? 1) > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.richLoadCardTrucksNeededSummary(
                    (load['trucks_needed'] as num?)?.toInt() ?? 1,
                    (load['trucks_booked'] as num?)?.toInt() ?? 0,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                ),
              ],
              if (showActions) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: l10n.chatBookThisLoad,
                        onPressed: onBook,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlineButton(
                        label: l10n.loadDetailTitle,
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
                if (onChat != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(l10n.chatWithSupplier),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _routeMetaText(
    BuildContext context,
    AppLocalizations l10n,
    double? distanceKm,
  ) {
    if (distanceKm == null || driveTimeMinutes == null) {
      return l10n.postLoadDistanceUnavailableFallback;
    }

    final hours = driveTimeMinutes! ~/ 60;
    final mins = driveTimeMinutes! % 60;
    final durationText = hours > 0 ? '~${hours}h ${mins}m' : '~${mins}m';

    final parts = <String>['${distanceKm.toStringAsFixed(0)} km', durationText];

    if (tollEstimate != null) {
      parts.add('₹${tollEstimate!.toStringAsFixed(0)} tolls');
    }

    if (fuelEstimate != null) {
      parts.add('${fuelEstimate!.toStringAsFixed(1)}L');
    }

    return parts.join(' · ');
  }

  String _headlinePriceText(Map<String, dynamic> load) {
    final price = LoadPricing.priceValue(load['price']);
    if (price == null) {
      return _formatCurrency(null);
    }
    final formatted = _formatCurrency(price);
    if (LoadPricing.isPerTon(load['price_type'])) {
      return '$formatted/T';
    }
    return formatted;
  }

  String _rateText(Map<String, dynamic> load, AppLocalizations l10n) {
    if (LoadPricing.isPerTon(load['price_type'])) {
      return l10n.postLoadPriceTypeNegotiable;
    }

    final rate = LoadPricing.ratePerTonFromMap(load);
    if (rate == null) {
      return '—';
    }
    return '${_formatCurrency(rate)}/T';
  }

  String _advanceText(Map<String, dynamic> load, AppLocalizations l10n) {
    final percent = (load['advance_percentage'] as num?)?.toInt();
    final advanceAmount = LoadPricing.advanceAmountFromMap(load);
    if (percent == null || advanceAmount == null) {
      return l10n.richLoadCardAdvanceUnavailable;
    }
    return l10n.richLoadCardAdvanceLabel(
      percent,
      _formatCurrency(advanceAmount),
    );
  }

  String _truckType(dynamic value, AppLocalizations l10n) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return l10n.findLoadsAny;
    }
    switch (text) {
      case 'open':
        return l10n.postLoadTruckTypeOpen;
      case 'container':
        return l10n.postLoadTruckTypeContainer;
      case 'trailer':
        return l10n.postLoadTruckTypeTrailer;
      case 'tanker':
        return l10n.postLoadTruckTypeTanker;
      case 'refrigerated':
        return l10n.postLoadTruckTypeRefrigerated;
      default:
        return '${text[0].toUpperCase()}${text.substring(1)}';
    }
  }

  String _tyres(dynamic value, AppLocalizations l10n) {
    if (value is List && value.isNotEmpty) {
      return value.join('/');
    }
    return l10n.findLoadsAny;
  }

  String _formatCurrency(double? value) {
    if (value == null) {
      return '₹-';
    }
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  String _timeAgo(DateTime? dateTime, AppLocalizations l10n) {
    if (dateTime == null) {
      return l10n.richLoadCardJustNow;
    }
    final diff = IstTime.age(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return l10n.richLoadCardJustNow;
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
