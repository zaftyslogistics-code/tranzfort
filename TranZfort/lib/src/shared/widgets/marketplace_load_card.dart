import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trip_costing_service.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import 'action_buttons.dart';
import 'content_cards.dart';
import 'status_components.dart';

// AppRadius is defined in app_spacing.dart

class MarketplaceLoadCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = statusPaletteFor(load.status);
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);
    final routeSnapshot = load.routeSnapshot;

    final totalLoadValue = load.priceAmount * load.weightTonnes;
    final costEstimate = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: load.weightTonnes,
      dieselPricePerLitre: dieselPrice,
    );

    return StandardListCard(
      accent: palette.foreground,
      title: '${load.originCity} > ${load.destinationCity}',
      subtitle: routeSnapshot == null
          ? '${load.originLabel} - ${load.destinationLabel}'
          : '${routeSnapshot.distanceKm.toStringAsFixed(0)} km - ${_durationCompact(routeSnapshot.durationMinutes)}',
      trailing: StatusChip(label: _localizedLoadStatus(l10n, load.status)),
      onTap: onViewDetails,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriceRow(
            priceAmount: load.priceAmount,
            relativeAge: _relativeAge(load.createdAt),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total load value: ₹${totalLoadValue.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            costEstimate?.compactLabel ?? l10n.truckerFindLoadsTripCostUnavailable,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: costEstimate == null ? AppColors.textMuted : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          _MetaChipsRow(
            material: load.material,
            tonnes: tonnes,
            bodyType: _localizedBodyType(l10n, load.requiredBodyType),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.truckerFindLoadsPriceAdvancePickup(
              load.priceAmount.toStringAsFixed(0),
              load.advancePercentage,
              _formatDate(load.pickupDate),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (onChat != null || onCall != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _QuickActionsRow(
              onChat: onChat,
              onCall: onCall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (supplierInitial != null)
                _SupplierAvatarBadge(
                  initial: supplierInitial!,
                  avatarUrl: supplierAvatarUrl,
                  onTap: onSupplierTap,
                ),
              if (supplierInitial != null) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextActionButton(
                  label: l10n.truckerFindLoadsViewDetailsAction,
                  onPressed: onViewDetails,
                ),
              ),
            ],
          ),
        ],
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

  String _durationCompact(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours <= 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _localizedLoadStatus(AppLocalizations l10n, String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return l10n.truckerFindLoadsStatusActive;
      case 'assigned_partial':
        return l10n.truckerFindLoadsStatusAssignedPartial;
      default:
        return l10n.truckerFindLoadsStatusUnknown;
    }
  }

  static String _localizedBodyType(AppLocalizations l10n, String? bodyType) {
    final normalized = (bodyType ?? '').trim();
    switch (normalized.toLowerCase()) {
      case 'open':
        return l10n.truckerFindLoadsBodyTypeOpen;
      case 'trailer':
        return l10n.truckerFindLoadsBodyTypeTrailer;
      case 'container':
        return l10n.truckerFindLoadsBodyTypeContainer;
      case 'tanker':
        return l10n.truckerFindLoadsBodyTypeTanker;
      default:
        return normalized.isEmpty
            ? l10n.truckerFindLoadsAnyBodyFallback
            : l10n.truckerFindLoadsBodyTypeUnknown;
    }
  }
}

class _PriceRow extends StatelessWidget {
  final double priceAmount;
  final String relativeAge;

  const _PriceRow({
    required this.priceAmount,
    required this.relativeAge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.currency_rupee, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '₹${priceAmount.toStringAsFixed(0)} / T',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.subtleSurface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            relativeAge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _MetaChipsRow extends StatelessWidget {
  final String material;
  final String tonnes;
  final String bodyType;

  const _MetaChipsRow({
    required this.material,
    required this.tonnes,
    required this.bodyType,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _LoadMetaChip(
          icon: Icons.inventory_2_outlined,
          label: material,
          accentColor: AppColors.info,
        ),
        _LoadMetaChip(
          icon: Icons.scale_outlined,
          label: '${tonnes}T',
          accentColor: AppColors.success,
        ),
        _LoadMetaChip(
          icon: Icons.local_shipping_outlined,
          label: bodyType,
          accentColor: AppColors.warning,
        ),
      ],
    );
  }
}

class _LoadMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _LoadMetaChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const _QuickActionsRow({
    this.onChat,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onChat != null)
          Expanded(
            child: OutlineButton(
              label: 'Chat',
              onPressed: onChat,
              height: 40,
            ),
          ),
        if (onChat != null && onCall != null) const SizedBox(width: AppSpacing.sm),
        if (onCall != null)
          Expanded(
            child: OutlineButton(
              label: 'Call',
              onPressed: onCall,
              height: 40,
            ),
          ),
      ],
    );
  }
}

/// Supplier avatar badge that navigates to supplier profile on tap.
class _SupplierAvatarBadge extends StatelessWidget {
  final String initial;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _SupplierAvatarBadge({
    required this.initial,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'supplier_avatar_${initial}_${DateTime.now().millisecondsSinceEpoch}',
        child: _AvatarCircle(
          avatarUrl: avatarUrl,
          radius: radius,
          fallback: _AvatarFallback(
            radius: radius,
            initial: initial,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Widget fallback;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();

    if (url == null || url.isEmpty) {
      return fallback;
    }

    if (!url.startsWith('http')) {
      return FutureBuilder<String?>(
        future: _createSignedUrl(url),
        builder: (context, snapshot) {
          final resolvedUrl = snapshot.data;
          if (resolvedUrl == null || resolvedUrl.isEmpty) {
            return fallback;
          }
          return _AvatarImage(url: resolvedUrl, radius: radius, fallback: fallback);
        },
      );
    }

    return _AvatarImage(url: url, radius: radius, fallback: fallback);
  }

  Future<String?> _createSignedUrl(String path) async {
    try {
      final client = Supabase.instance.client;
      // Try verification-documents bucket first (for user's own profile)
      try {
        return await client.storage.from('verification-documents').createSignedUrl(path, 3600);
      } catch (_) {
        // Fallback to profile-photos bucket (for supplier profiles)
        return await client.storage.from('profile-photos').createSignedUrl(path, 3600);
      }
    } catch (_) {
      return null;
    }
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  final double radius;
  final Widget fallback;

  const _AvatarImage({
    required this.url,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final double radius;
  final String initial;
  final ColorScheme colorScheme;

  const _AvatarFallback({
    required this.radius,
    required this.initial,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
