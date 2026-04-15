import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/public_profile_models.dart';

/// Trust score card displaying rating metrics.
class TrustScoreCard extends StatelessWidget {
  final PublicProfile profile;

  const TrustScoreCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasRating = profile.hasReviews;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trust & Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildMainRating(context, hasRating),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildMetrics(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRating(BuildContext context, bool hasRating) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasRating) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 32,
              ),
              const SizedBox(width: 4),
              Text(
                profile.avgRating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'out of 5',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '(${profile.reviewCount} reviews)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          Icon(
            Icons.star_border,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No rating yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final metrics = <Widget>[];

    // Review count metric
    metrics.add(_buildMetricRow(
      context,
      icon: Icons.rate_review_outlined,
      label: 'Reviews received',
      value: profile.reviewCount.toString(),
    ));

    // Completed trips (for truckers) or loads posted (for suppliers)
    if (profile.role == 'trucker' && profile.completedTripsCount != null) {
      metrics.add(const SizedBox(height: AppSpacing.sm));
      metrics.add(_buildMetricRow(
        context,
        icon: Icons.local_shipping_outlined,
        label: 'Trips completed',
        value: profile.completedTripsCount.toString(),
      ));
    } else if (profile.role == 'supplier' && profile.totalLoadsPosted != null) {
      metrics.add(const SizedBox(height: AppSpacing.sm));
      metrics.add(_buildMetricRow(
        context,
        icon: Icons.inventory_2_outlined,
        label: 'Loads posted',
        value: profile.totalLoadsPosted.toString(),
      ));
    }

    // Truck count (for truckers)
    if (profile.role == 'trucker' && profile.truckCount != null) {
      metrics.add(const SizedBox(height: AppSpacing.sm));
      metrics.add(_buildMetricRow(
        context,
        icon: Icons.directions_bus_outlined,
        label: 'Trucks in fleet',
        value: profile.truckCount.toString(),
      ));
    }

    // Super load eligibility (for suppliers)
    if (profile.role == 'supplier' && profile.isSuperLoadEligible == true) {
      metrics.add(const SizedBox(height: AppSpacing.sm));
      metrics.add(_buildMetricRow(
        context,
        icon: Icons.verified_outlined,
        label: 'Super Load eligible',
        value: 'Yes',
        valueColor: Colors.green,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metrics,
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
