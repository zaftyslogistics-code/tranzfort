import 'package:flutter/material.dart';

import '../../../core/utils/avatar_storage_path.dart';
import '../../../core/theme/app_decorations.dart';
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
  final String? supplierProfilePhotoPath;
  final String? age;
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
    this.supplierProfilePhotoPath,
    this.age,
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
            supplierProfilePhotoPath: supplierProfilePhotoPath,
            age: age,
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
  final String? supplierProfilePhotoPath;
  final String? age;
  final VoidCallback? onSupplierTap;
  final Widget? headerTrailing;
  final bool onDarkSurface;

  const _SupplierRow({
    required this.supplierName,
    required this.supplierId,
    this.supplierInitial,
    this.supplierAvatarUrl,
    this.supplierProfilePhotoPath,
    this.age,
    this.onSupplierTap,
    this.headerTrailing,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface);
    final mutedColor = AppDecorations.marketplaceCardTextSecondary(onDarkSurface: onDarkSurface);
    final initials = supplierInitial ??
        AvatarStoragePath.initialsFor(
          displayName: supplierName,
          userId: supplierId,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UserAvatar(
          avatarUrl: supplierAvatarUrl,
          profilePhotoPath: supplierProfilePhotoPath,
          userId: supplierId,
          initials: initials,
          radius: MarketplaceDarkHeader._avatarRadius,
          onTap: onSupplierTap,
        ),
        const SizedBox(width: AppSpacing.xs),
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
        ),
        ?headerTrailing,
      ],
    );
  }
}
