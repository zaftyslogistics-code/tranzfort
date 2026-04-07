import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_badge.dart';

class LoadSummaryCard extends StatelessWidget {
  final Map<String, dynamic> load;
  final VoidCallback? onTap;

  const LoadSummaryCard({
    super.key,
    required this.load,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = (load['origin_city'] ?? 'Unknown').toString();
    final destination = (load['destination_city'] ?? 'Unknown').toString();
    final status = (load['status'] ?? '').toString();
    
    final trucksNeeded = (load['trucks_needed'] as num?)?.toInt() ?? 1;
    final trucksBooked = (load['trucks_booked'] as num?)?.toInt() ?? 0;

    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'active':
        statusColor = AppColors.primary;
        statusLabel = l10n.myLoadsActiveLabel;
        break;
      case 'in_transit':
        statusColor = AppColors.warning;
        statusLabel = l10n.myLoadsInTransitLabel;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = l10n.completedTab;
        break;
      case 'cancelled':
      case 'expired':
        statusColor = AppColors.error;
        statusLabel = status == 'cancelled' ? l10n.loadDetailRejectAction : 'Expired';
        break;
      default:
        statusColor = AppColors.neutral;
        statusLabel = status;
    }

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$origin → $destination',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.richLoadCardTrucksNeededSummary(trucksNeeded, trucksBooked),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: statusLabel,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                textColor: statusColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.neutral, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
