import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class StaticRouteMap extends StatelessWidget {
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String? originLabel;
  final String? destLabel;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onOpenMaps;
  final String? distanceLabel;
  final String? durationLabel;

  const StaticRouteMap({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.originLabel,
    this.destLabel,
    this.height = 116,
    this.onTap,
    this.onOpenMaps,
    this.distanceLabel,
    this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.canvasTop, AppColors.cardSurface],
          ),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: _RouteMapPainter(
                originLat: originLat,
                originLng: originLng,
                destLat: destLat,
                destLng: destLng,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LocationPill(
                            label: originLabel ?? 'Origin',
                            color: AppColors.success,
                            icon: Icons.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _LocationPill(
                            label: destLabel ?? 'Destination',
                            color: AppColors.error,
                            icon: Icons.location_on,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (distanceLabel != null || durationLabel != null || onOpenMaps != null)
              Positioned(
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _RouteInfoOverlay(
                  distanceLabel: distanceLabel,
                  durationLabel: durationLabel,
                  onOpenMaps: onOpenMaps,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteInfoOverlay extends StatelessWidget {
  final String? distanceLabel;
  final String? durationLabel;
  final VoidCallback? onOpenMaps;

  const _RouteInfoOverlay({
    this.distanceLabel,
    this.durationLabel,
    this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (distanceLabel != null)
            _MapInfoItem(
              icon: Icons.straighten,
              label: distanceLabel!,
            ),
          if (distanceLabel != null && durationLabel != null)
            Container(
              width: 1,
              height: 16,
              color: AppColors.divider,
            ),
          if (durationLabel != null)
            _MapInfoItem(
              icon: Icons.schedule,
              label: durationLabel!,
            ),
          if (onOpenMaps != null) ...[
            if (distanceLabel != null || durationLabel != null)
              Container(
                width: 1,
                height: 16,
                color: AppColors.divider,
              ),
            InkWell(
              onTap: onOpenMaps,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      'Maps',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapInfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool alignEnd;

  const _LocationPill({
    required this.label,
    required this.color,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  _RouteMapPainter({
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 20.0;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    final minLat = math.min(originLat, destLat);
    final maxLat = math.max(originLat, destLat);
    final minLng = math.min(originLng, destLng);
    final maxLng = math.max(originLng, destLng);

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    final effectiveLatRange = latRange < 0.01 ? 1.0 : latRange;
    final effectiveLngRange = lngRange < 0.01 ? 1.0 : lngRange;

    Offset toCanvas(double lat, double lng) {
      final x = padding + ((lng - minLng) / effectiveLngRange) * usableWidth;
      final y = padding + (1 - (lat - minLat) / effectiveLatRange) * usableHeight;
      return Offset(x, y);
    }

    final origin = toCanvas(originLat, originLng);
    final dest = toCanvas(destLat, destLng);

    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.65)
      ..strokeWidth = 0.6;

    for (var i = 0; i <= 4; i++) {
      final y = padding + (usableHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final x = padding + (usableWidth / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midX = (origin.dx + dest.dx) / 2;
    final midY = math.min(origin.dy, dest.dy) - 18;

    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(midX, midY, dest.dx, dest.dy);

    canvas.drawPath(path, shadowPaint);

    // Draw dashed route
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    const dashLength = 6.0;
    const gapLength = 4.0;
    var distance = 0.0;
    while (distance < totalLength) {
      final end = (distance + dashLength).clamp(0.0, totalLength);
      final dashPath = pathMetrics.extractPath(distance, end);
      canvas.drawPath(dashPath, routePaint);
      distance += dashLength + gapLength;
    }

    canvas.drawCircle(origin, 6, Paint()..color = AppColors.success);
    canvas.drawCircle(origin, 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(dest, 6, Paint()..color = AppColors.error);
    canvas.drawCircle(dest, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return originLat != oldDelegate.originLat ||
        originLng != oldDelegate.originLng ||
        destLat != oldDelegate.destLat ||
        destLng != oldDelegate.destLng;
  }
}
