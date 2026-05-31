import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Supplier load status timeline (X-4 / F-1).
class LoadLifecycleTimeline extends StatelessWidget {
  final String currentStatus;

  const LoadLifecycleTimeline({super.key, required this.currentStatus});

  static const _orderedStatuses = ['draft', 'active', 'assigned_partial', 'assigned_full', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalized = currentStatus.trim().toLowerCase();
    final currentIndex = _orderedStatuses.indexOf(normalized);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _orderedStatuses.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Container(width: 2, height: 16, color: AppColors.divider),
            ),
          Row(
            children: [
              Icon(
                i <= currentIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: i <= currentIndex ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.supplierLoadStatusValue(_orderedStatuses[i]),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.normal,
                        color: i <= currentIndex ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
