import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/trip_route_label_parser.dart';
import 'marketplace/marketplace_route_line.dart';
import 'status_components.dart';

/// Compact trip row with route line + stage chip (Appendix F week 4).
class TripCompactCard extends StatelessWidget {
  final String routeLabel;
  final String subtitle;
  final String stageLabel;
  final StatusPalette stagePalette;
  final Widget? headerTrailing;
  final Widget? footer;
  final double? progressValue;
  final VoidCallback? onTap;

  const TripCompactCard({
    super.key,
    required this.routeLabel,
    required this.subtitle,
    required this.stageLabel,
    required this.stagePalette,
    this.headerTrailing,
    this.footer,
    this.progressValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final endpoints = parseTripRouteLabel(routeLabel);
    final onDark = !AppDecorations.marketplaceLoadCardLightExperiment;

    return DecoratedBox(
      decoration: AppDecorations.brandGradientBorderOuter(),
      child: Padding(
        padding: const EdgeInsets.all(AppDecorations.brandGradientBorderWidth),
        child: DecoratedBox(
          decoration: AppDecorations.marketplaceCardFill(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: endpoints == null
                              ? Text(
                                  routeLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDark),
                                        fontWeight: FontWeight.w700,
                                      ),
                                )
                              : MarketplaceRouteLine(
                                  originCity: endpoints.originCity,
                                  originState: endpoints.originState,
                                  destinationCity: endpoints.destinationCity,
                                  destinationState: endpoints.destinationState,
                                  onDarkSurface: onDark,
                                ),
                        ),
                        if (headerTrailing != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          headerTrailing!,
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppDecorations.marketplaceCardTextSecondary(onDarkSurface: onDark),
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(label: stageLabel, palette: stagePalette),
                      ],
                    ),
                  ),
                  if (progressValue != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressValue!.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.neutralBg,
                          valueColor: AlwaysStoppedAnimation<Color>(stagePalette.foreground),
                        ),
                      ),
                    ),
                  ],
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: footer!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
