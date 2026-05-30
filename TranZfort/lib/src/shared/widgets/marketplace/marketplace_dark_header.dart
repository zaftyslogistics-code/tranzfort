import 'package:flutter/material.dart';

import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../avatar_widget.dart';
import 'marketplace_route_line.dart';

/// Dark header widget for load card (supplier, route, optional TTS).
class MarketplaceDarkHeader extends StatelessWidget {
  static const _avatarRadius = 15.6;
  static const _supplierNameFontSize = 15.6;

  final String supplierName;
  final String supplierId;
  final String? supplierInitial;
  final String? supplierAvatarUrl;
  final String? age;
  final bool isSuperLoad;
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;
  final VoidCallback? onSupplierTap;
  final Widget? headerTrailing;
  final bool onDarkSurface;

  const MarketplaceDarkHeader({
    super.key,
    required this.supplierName,
    required this.supplierId,
    this.supplierInitial,
    this.supplierAvatarUrl,
    this.age,
    this.isSuperLoad = false,
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
    this.onSupplierTap,
    this.headerTrailing,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupplierRow(
            supplierName: supplierName,
            supplierId: supplierId,
            supplierInitial: supplierInitial,
            supplierAvatarUrl: supplierAvatarUrl,
            age: age,
            isSuperLoad: isSuperLoad,
            onSupplierTap: onSupplierTap,
            headerTrailing: headerTrailing,
            onDarkSurface: onDarkSurface,
          ),
          const SizedBox(height: AppSpacing.xs),
          MarketplaceRouteLine(
            originCity: originCity,
            originState: originState,
            destinationCity: destinationCity,
            destinationState: destinationState,
            onDarkSurface: onDarkSurface,
          ),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  final String supplierName;
  final String supplierId;
  final String? supplierInitial;
  final String? supplierAvatarUrl;
  final String? age;
  final bool isSuperLoad;
  final VoidCallback? onSupplierTap;
  final Widget? headerTrailing;
  final bool onDarkSurface;

  const _SupplierRow({
    required this.supplierName,
    required this.supplierId,
    this.supplierInitial,
    this.supplierAvatarUrl,
    this.age,
    required this.isSuperLoad,
    this.onSupplierTap,
    this.headerTrailing,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface);
    final mutedColor = AppDecorations.marketplaceCardTextSecondary(onDarkSurface: onDarkSurface);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (supplierInitial != null) ...[
          UserAvatar(
            avatarUrl: supplierAvatarUrl,
            userId: supplierId,
            initials: supplierInitial,
            radius: MarketplaceDarkHeader._avatarRadius,
            onTap: onSupplierTap,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                supplierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: nameColor,
                      fontWeight: FontWeight.w700,
                      fontSize: MarketplaceDarkHeader._supplierNameFontSize,
                    ),
              ),
              Row(
                children: [
                  if (isSuperLoad) ...[
                    _SuperLoadPill(),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (age != null)
                    Text(
                      age!,
                      style: AppTypography.labelMicro.copyWith(
                        color: mutedColor,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ?headerTrailing,
      ],
    );
  }
}

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
