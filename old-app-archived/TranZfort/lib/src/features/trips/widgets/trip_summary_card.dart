import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ist_time.dart';
import '../../../shared/widgets/status_badge.dart';

class TripSummaryCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback? onTap;

  const TripSummaryCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final load = trip['load'] as Map<String, dynamic>? ?? const {};
    final origin = (load['origin_city'] ?? 'Unknown').toString();
    final destination = (load['dest_city'] ?? load['destination_city'] ?? 'Unknown').toString();
    final stage = (trip['stage'] ?? '').toString();

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
                      _timeContext(context, trip, l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStageBadge(context, stage, l10n),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.neutral, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageBadge(BuildContext context, String stage, AppLocalizations l10n) {
    Color statusColor;
    String statusLabel;
    
    switch (stage) {
      case 'pending_approval':
      case 'booked':
      case 'at_pickup':
        statusColor = AppColors.warning;
        statusLabel = l10n.tripApprovedPrefix;
        break;
      case 'in_transit':
        statusColor = AppColors.primary;
        statusLabel = l10n.tripStartedPrefix;
        break;
      case 'delivered':
      case 'pod_uploaded':
        statusColor = AppColors.info;
        statusLabel = l10n.tripDeliveredPrefix;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = l10n.tripCompletedPrefix;
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = l10n.loadDetailRejectAction;
        break;
      default:
        statusColor = AppColors.neutral;
        statusLabel = stage;
    }

    return StatusBadge(
      label: statusLabel,
      backgroundColor: statusColor.withValues(alpha: 0.1),
      textColor: statusColor,
    );
  }

  String _timeContext(BuildContext context, Map<String, dynamic> tripData, AppLocalizations l10n) {
    final stage = (tripData['stage'] ?? '').toString();
    final startedAt = DateTime.tryParse((tripData['start_time'] ?? '').toString());
    final createdAt = DateTime.tryParse((tripData['created_at'] ?? '').toString());

    final reference = startedAt ?? createdAt;
    if (reference == null) {
      return l10n.tripRecentlyUpdated;
    }

    final diff = IstTime.age(reference);
    final value = diff.inHours > 0
        ? '${diff.inHours}h ago'
        : '${diff.inMinutes}m ago';

    return switch (stage) {
      'completed' => '${l10n.tripCompletedPrefix} $value',
      'in_transit' => '${l10n.tripStartedPrefix} $value',
      'at_pickup' => '${l10n.tripApprovedPrefix} $value',
      'delivered' => '${l10n.tripDeliveredPrefix} $value',
      'pod_uploaded' => '${l10n.tripPodUploadedPrefix} $value',
      _ => '${l10n.tripUpdatedPrefix} $value',
    };
  }
}
