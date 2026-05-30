import 'package:flutter/material.dart';

import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Integrated route line widget for load card dark header.
///
/// Renders FROM/TO text blocks with city/state and a simple arrow between them.
///
/// Layout:
/// - Row: FROM block + flexible space + arrow icon + flexible space + TO block
///
/// Target height: ~60px for the route row.
class MarketplaceRouteLine extends StatelessWidget {
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;
  final bool onDarkSurface;

  const MarketplaceRouteLine({
    super.key,
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrowColor = AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface)
        .withValues(alpha: 0.6);
    
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Left: FROM block (natural width)
          IntrinsicWidth(
            child: _LocationBlock(
              label: l10n.commonFromLabel,
              city: originCity,
              state: originState,
              isOrigin: true,
              onDarkSurface: onDarkSurface,
            ),
          ),
          // Center: flexible space + arrow icon + flexible space
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: arrowColor,
                  size: 24,
                ),
              ],
            ),
          ),
          // Right: TO block (natural width)
          IntrinsicWidth(
            child: _LocationBlock(
              label: l10n.commonToLabel,
              city: destinationCity,
              state: destinationState,
              isOrigin: false,
              onDarkSurface: onDarkSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Location block showing FROM/TO label, city, and state.
class _LocationBlock extends StatelessWidget {
  final String label;
  final String city;
  final String state;
  final bool isOrigin;
  final bool onDarkSurface;

  const _LocationBlock({
    required this.label,
    required this.city,
    required this.state,
    required this.isOrigin,
    this.onDarkSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDarkSurface);
    final secondaryColor = AppDecorations.marketplaceCardTextSecondary(onDarkSurface: onDarkSurface);
    return Column(
      crossAxisAlignment: isOrigin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // FROM/TO label
        Text(
          label,
          style: AppTypography.labelMicro.copyWith(
            color: secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        // City name
        Text(
          city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
        ),
        const SizedBox(height: 1),
        // State name
        Text(
          state,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySecondary.copyWith(
                color: secondaryColor,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
