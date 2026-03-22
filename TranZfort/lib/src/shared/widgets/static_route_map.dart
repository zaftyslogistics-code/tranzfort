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
        child: CustomPaint(
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
      ),
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
    canvas.drawPath(path, routePaint);

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
