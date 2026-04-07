import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/marketplace_providers.dart';

class BookingRequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const BookingRequestCard({
    super.key,
    required this.booking,
    this.onApprove,
    this.onReject,
  });

  @override
  ConsumerState<BookingRequestCard> createState() => _BookingRequestCardState();
}

class _BookingRequestCardState extends ConsumerState<BookingRequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = (widget.booking['origin_city'] ?? 'Unknown').toString();
    final destination = (widget.booking['destination_city'] ?? 'Unknown').toString();
    final truckerName = (widget.booking['trucker_label'] ?? 'Trucker').toString();
    final truckDetails = (widget.booking['truck_type'] ?? 'Truck').toString();
    
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.warning), // Warning border for pending action
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    truckerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending', // Consider translating
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.neutral, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  truckDetails,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.route, color: AppColors.neutral, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$origin → $destination',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlineButton(
                      label: l10n.loadDetailRejectAction,
                      onPressed: () async {
                        setState(() => _isProcessing = true);
                        if (widget.onReject != null) widget.onReject!();
                        
                        try {
                           await ref.read(loadDetailActionProvider.notifier).rejectBooking(
                            widget.booking['id'].toString(),
                            widget.booking['parent_load_id']?.toString() ?? '',
                          );
                        } finally {
                           if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.loadDetailApproveAction,
                      color: AppColors.success,
                      onPressed: () async {
                        setState(() => _isProcessing = true);
                        if (widget.onApprove != null) widget.onApprove!();
                        
                        try {
                          await ref.read(loadDetailActionProvider.notifier).approveBooking(
                            widget.booking['id'].toString(),
                            widget.booking['parent_load_id']?.toString() ?? '',
                          );
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
