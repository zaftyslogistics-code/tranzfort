import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/supplier/data/load_marketplace_mapping.dart';
import '../../features/supplier/data/supplier_load_models.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import '../../features/profile/data/public_profile_models.dart';

/// Compact list row for loads/trips (public profile recent loads, dashboard widgets).
class CompactLoadListTile extends StatelessWidget {
  final String routeLabel;
  final String detailLine;
  final String? priceLine;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;

  const CompactLoadListTile({
    super.key,
    required this.routeLabel,
    required this.detailLine,
    this.priceLine,
    required this.statusLabel,
    required this.statusColor,
    this.onTap,
  });

  factory CompactLoadListTile.fromPublicLoadPreview({
    required BuildContext context,
    required PublicLoadPreview load,
    required String statusLabel,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return CompactLoadListTile(
      routeLabel: load.routeLabel,
      detailLine: '${load.material} • ${load.weightTonnes}T',
      priceLine: _formatPrice(load.priceAmount, load.priceType),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  factory CompactLoadListTile.fromSupplierLoad({
    required BuildContext context,
    required Load load,
    required String statusLabel,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    final item = load.toMarketplaceItem(supplierId: '');
    return CompactLoadListTile(
      routeLabel: '${item.originCity} → ${item.destinationCity}',
      detailLine: '${load.material} • ${load.weightTonnes}T',
      priceLine: _formatPrice(load.priceAmount, load.priceType),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  factory CompactLoadListTile.fromMarketplaceLoad({
    required MarketplaceLoadItem load,
    VoidCallback? onTap,
  }) {
    final rateLabel = load.priceType.trim().toLowerCase() == 'per_ton'
        ? '₹${load.priceAmount.toStringAsFixed(0)}/T'
        : '₹${load.priceAmount.toStringAsFixed(0)} fixed';
    return CompactLoadListTile(
      routeLabel: '${load.originCity} → ${load.destinationCity}',
      detailLine: '${load.material} • $rateLabel',
      statusLabel: load.isSuperLoad ? 'Super' : 'Open',
      statusColor: load.isSuperLoad ? AppColors.secondary : AppColors.primary,
      onTap: onTap,
    );
  }

  factory CompactLoadListTile.fromTruckerTrip({
    required String routeLabel,
    required String detailLine,
    required String statusLabel,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return CompactLoadListTile(
      routeLabel: routeLabel,
      detailLine: detailLine,
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  static String _formatPrice(double amount, String priceType) {
    final normalized = priceType.trim().toLowerCase();
    if (normalized == 'per_ton') {
      return '₹${amount.toStringAsFixed(0)}/T';
    }
    return '₹${amount.toStringAsFixed(0)} $priceType';
  }

  static Color statusColorForLoadStatus(String status, ColorScheme colorScheme) {
    return switch (status.trim().toLowerCase()) {
      'active' => Colors.green,
      'completed' => colorScheme.primary,
      'assigned_partial' => Colors.orange,
      'assigned_full' => Colors.blue,
      _ => colorScheme.onSurfaceVariant,
    };
  }

  static Color statusColorForTripStage(String stage) {
    return switch (stage.trim().toLowerCase()) {
      'completed' => AppColors.success,
      'delivered' || 'proof_submitted' => AppColors.info,
      'in_transit' || 'picked_up' => AppColors.warning,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              routeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _StatusChip(label: statusLabel, color: statusColor),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            detailLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (priceLine != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              priceLine!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Vertical list of [CompactLoadListTile] rows with dividers (dashboard / profile).
class CompactLoadList extends StatelessWidget {
  final List<Widget> children;

  const CompactLoadList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const BrandGradientDivider(),
        ],
      ],
    );
  }
}
