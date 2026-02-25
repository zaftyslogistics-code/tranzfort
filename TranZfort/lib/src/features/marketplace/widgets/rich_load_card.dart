import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/marketplace_providers.dart';

class RichLoadCard extends ConsumerWidget {
  final Map<String, dynamic> load;
  final VoidCallback? onChat;
  final VoidCallback? onBook;
  final VoidCallback? onTap;
  final bool showActions;

  const RichLoadCard({
    super.key,
    required this.load,
    this.onChat,
    this.onBook,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuper = load['is_super_load'] == true;
    final createdAt = DateTime.tryParse((load['created_at'] ?? '').toString());
    final pickupDate = DateTime.tryParse(
      (load['pickup_date'] ?? '').toString(),
    );

    final distanceKm = (load['distance_km'] as num?)?.toDouble();
    final tripCostResult = ref
        .read(tripCostingServiceProvider)
        .estimate(
          distanceKm: distanceKm,
          loadWeightTonnes: (load['weight_tonnes'] as num?)?.toDouble(),
          payloadKg: 10000,
          emptyMileageKmpl: 4,
          loadedMileageKmpl: 2.5,
          axleCount: 2,
          dieselPricePerLitre: 90,
        );

    final tripCostText = switch (tripCostResult) {
      Success(data: final estimate) =>
        'Est. Trip Cost: ${_formatCurrency(estimate.totalCost)}',
      Failure() => 'Trip cost unavailable',
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSuper)
                    const StatusBadge(
                      label: 'Super Load',
                      backgroundColor: Color(0xFFFFF3C4),
                      textColor: Color(0xFF8A6B00),
                      icon: Icons.star,
                    ),
                  if (isSuper) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _timeAgo(createdAt),
                      textAlign: TextAlign.end,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${load['origin_city']}, ${load['origin_state']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                '${load['dest_city']}, ${load['dest_state']}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.neutral),
              ),
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${distanceKm.toStringAsFixed(0)} km',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '${load['material']} · ${load['weight_tonnes']}T · ${_truckType(load['required_truck_type'])} ${_tyres(load['required_tyres'])}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Pickup: ${pickupDate != null ? DateFormat('d MMM').format(pickupDate) : '-'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _rateText(load),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _formatCurrency((load['price'] as num?)?.toDouble()),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _advanceText(load),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
              ),
              const SizedBox(height: 4),
              Text(
                tripCostText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tripCostResult is Success
                      ? AppColors.success
                      : AppColors.neutral,
                ),
              ),
              if ((load['trucks_needed'] as num? ?? 1) > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '${load['trucks_needed']} trucks needed · ${load['trucks_booked'] ?? 0} booked',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                ),
              ],
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButton(label: 'Chat', onPressed: onChat),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Book Load',
                        color: AppColors.success,
                        onPressed: onBook,
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

  String _rateText(Map<String, dynamic> load) {
    final price = (load['price'] as num?)?.toDouble();
    final weight = (load['weight_tonnes'] as num?)?.toDouble();
    if (price == null || weight == null || weight <= 0) {
      return 'Rate unavailable';
    }
    final rate = price / weight;
    return '${_formatCurrency(rate)}/T';
  }

  String _advanceText(Map<String, dynamic> load) {
    final percent = (load['advance_percentage'] as num?)?.toInt();
    final price = (load['price'] as num?)?.toDouble();
    if (percent == null || price == null) {
      return 'Advance: -';
    }
    final value = price * (percent / 100);
    return 'Advance: $percent% (${_formatCurrency(value)})';
  }

  String _truckType(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return 'Any';
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _tyres(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.join('/');
    }
    return 'Any';
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

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Just now';
    }
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}
