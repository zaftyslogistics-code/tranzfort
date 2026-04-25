import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/trucker/data/trip_costing_service.dart';
import '../../features/trucker/data/trucker_marketplace_repository.dart';
import 'curved_arc_route.dart';
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
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);
    final routeSnapshot = load.routeSnapshot;

    final totalLoadValue = load.priceAmount * load.weightTonnes;
    final costEstimate = tripCostingService.estimate(
      distanceKm: routeSnapshot?.distanceKm,
      loadWeightTonnes: load.weightTonnes,
      dieselPricePerLitre: dieselPrice,
      priceAmountPerTonne: load.priceAmount,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceBase,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.elevation2,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Supplier avatar + name + super-load badge + age ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (supplierInitial != null) ...[
                      _SupplierAvatarBadge(
                        initial: supplierInitial!,
                        avatarUrl: supplierAvatarUrl,
                        onTap: onSupplierTap,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            load.supplierName ?? 'Supplier',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (load.isSuperLoad) ...[
                                _SuperLoadPill(),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Text(
                                _relativeAge(load.createdAt),
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: _localizedLoadStatus(l10n, load.status)),
                  ],
                ),
              ),
              // ── Curved Arc Route visualization ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: CurvedArcRoute.compact(
                  origin: load.originCity,
                  destination: load.destinationCity,
                  originSubtitle: load.originState,
                  destinationSubtitle: load.destinationState,
                  distanceLabel: routeSnapshot != null
                      ? '${routeSnapshot.distanceKm.toStringAsFixed(0)} km'
                      : null,
                  durationLabel: routeSnapshot != null
                      ? _durationCompact(routeSnapshot.durationMinutes)
                      : null,
                ),
              ),
              // ── Meta chips: material, tonnes, body type ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CompactChip(
                      icon: Icons.inventory_2_outlined,
                      label: load.material,
                    ),
                    _CompactChip(
                      icon: Icons.scale_outlined,
                      label: '${tonnes}T',
                    ),
                    _CompactChip(
                      icon: Icons.local_shipping_outlined,
                      label: _localizedBodyType(l10n, load.requiredBodyType),
                    ),
                    if (load.advancePercentage > 0)
                      _CompactChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: '${load.advancePercentage}% adv',
                        accent: AppColors.info,
                      ),
                  ],
                ),
              ),
              // ── Earnings strip: dark band with load value + profit ──
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inkSurface,
                  borderRadius: BorderRadius.circular(AppRadius.iconChip),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.inkSurface,
                      AppColors.inkMid,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LOAD VALUE',
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.inkTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatAmount(totalLoadValue)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primaryOnDark,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            '@ ₹${load.priceAmount.toStringAsFixed(0)}/T · ${tonnes}T',
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.inkTextSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (costEstimate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (costEstimate.isProfitable
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: (costEstimate.isProfitable
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              costEstimate.isProfitable ? 'EST. PROFIT' : 'EST. LOSS',
                              style: AppTypography.labelMicro.copyWith(
                                color: costEstimate.isProfitable
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '₹${_formatAmount(costEstimate.netProfit.abs())}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // ── Footer: View details CTA + quick actions ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(l10n.commonViewDetailsAction),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (onCall != null)
                      _IconActionButton(
                        icon: Icons.phone_outlined,
                        tooltip: l10n.commonCallAction,
                        color: AppColors.success,
                        onPressed: onCall,
                      ),
                    if (onChat != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _IconActionButton(
                        icon: Icons.chat_bubble_outline,
                        tooltip: l10n.commonChatLabel,
                        color: AppColors.primary,
                        onPressed: onChat,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
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

  static String _localizedLoadStatus(AppLocalizations l10n, String status) {
    return l10n.truckerFindLoadsStatusValue(status.trim().toLowerCase());
  }

  static String _localizedBodyType(AppLocalizations l10n, String? bodyType) {
    final normalized = (bodyType ?? '').trim();
    if (normalized.isEmpty) {
      return l10n.truckerFindLoadsAnyBodyFallback;
    }
    return l10n.truckerFindLoadsBodyTypeValue(normalized.toLowerCase());
  }
}

/// Compact pill chip used in marketplace card meta row.
class _CompactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _CompactChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon action button for Call / Chat.
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

/// Amber super-load pill (premium trust indicator).
class _SuperLoadPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.superLoadBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.superLoadText.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 10, color: AppColors.superLoadText),
          const SizedBox(width: 2),
          Text(
            'SUPER',
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.superLoadText,
              fontSize: 9,
            ),
          ),
        ],
      ),
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
