import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Phase 5: Premium route visualization (straight line).
///
/// Renders origin (teal dot) → straight dashed line → destination (orange pin) with
/// optional km/duration label floating above the line's midpoint.
///
/// Variants:
///   - CurvedArcRoute.compact(): for marketplace list cards (height 56)
///   - CurvedArcRoute.hero(): for detail page hero cards (height 88, dark-safe)
class CurvedArcRoute extends StatelessWidget {
  final String origin;
  final String destination;
  final String? originSubtitle; // e.g., state name below origin city
  final String? destinationSubtitle; // e.g., state name below destination city
  final String? distanceLabel; // e.g., "842 km"
  final String? durationLabel; // e.g., "14h 20m"
  final bool onDarkSurface; // text + arc adapt for dark bg
  final double height;

  const CurvedArcRoute({
    super.key,
    required this.origin,
    required this.destination,
    this.originSubtitle,
    this.destinationSubtitle,
    this.distanceLabel,
    this.durationLabel,
    this.onDarkSurface = false,
    this.height = 72,
  });

  const CurvedArcRoute.compact({
    super.key,
    required this.origin,
    required this.destination,
    this.originSubtitle,
    this.destinationSubtitle,
    this.distanceLabel,
    this.durationLabel,
  })  : onDarkSurface = false,
        height = 108;

  const CurvedArcRoute.hero({
    super.key,
    required this.origin,
    required this.destination,
    this.originSubtitle,
    this.destinationSubtitle,
    this.distanceLabel,
    this.durationLabel,
    this.onDarkSurface = true,
  }) : height = 128;

  @override
  Widget build(BuildContext context) {
    final textPrimary = onDarkSurface ? AppColors.inkTextPrimary : AppColors.textPrimary;
    final textMuted = onDarkSurface ? AppColors.inkTextSecondary : AppColors.textMuted;
    final arcColor = onDarkSurface ? AppColors.primaryOnDark : AppColors.primary;
    final destColor = onDarkSurface ? AppColors.secondaryOnDark : AppColors.secondary;

    final inlineLabel = <String>[
      ?distanceLabel,
      ?durationLabel,
    ].join(' · ');

    // Reserve vertical bands to prevent pins overlapping labels:
    //   top chip band ~20px, arc+pins band (flex), label band ~56px
    //   (FROM + city + optional state/subtitle).
    const double labelBandHeight = 56;
    final hasOriginSubtitle = (originSubtitle ?? '').trim().isNotEmpty;
    final hasDestinationSubtitle = (destinationSubtitle ?? '').trim().isNotEmpty;

    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top chip: km · duration
          SizedBox(
            height: 20,
            child: inlineLabel.isEmpty
                ? const SizedBox.shrink()
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: onDarkSurface ? AppColors.inkMid : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: onDarkSurface ? AppColors.inkBorder : AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        inlineLabel,
                        style: AppTypography.labelMicro.copyWith(
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
          ),
          // Arc + pins band (no labels overlap)
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ArcPainter(
                arcColor: arcColor,
                originColor: arcColor,
                destinationColor: destColor,
                onDark: onDarkSurface,
              ),
            ),
          ),
          // Labels band: FROM/city left-aligned under origin pin, TO/city right-aligned under dest pin.
          SizedBox(
            height: labelBandHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FROM',
                        style: AppTypography.labelMicro.copyWith(
                          color: textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        origin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                      ),
                      if (hasOriginSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          originSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TO',
                        style: AppTypography.labelMicro.copyWith(
                          color: textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                      ),
                      if (hasDestinationSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          destinationSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color arcColor;
  final Color originColor;
  final Color destinationColor;
  final bool onDark;

  _ArcPainter({
    required this.arcColor,
    required this.originColor,
    required this.destinationColor,
    required this.onDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Painter owns only the arc+pins band (labels render below in the widget).
    // Pins sit near the bottom of this band so the arc has room to breathe.
    final arcTop = 4.0;
    final arcBottom = size.height - 6.0;
    final midY = (arcTop + arcBottom) / 2;

    final originX = 6.0;
    final destX = size.width - 6.0;
    final originPoint = Offset(originX, arcBottom);
    final destPoint = Offset(destX, arcBottom);

    // Straight line control point: in line with origin and destination
    final controlPoint = Offset((originX + destX) / 2, arcBottom);

    // Draw dashed arc path
    final dashPaint = Paint()
      ..color = arcColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedQuadratic(
      canvas,
      originPoint,
      controlPoint,
      destPoint,
      dashPaint,
      dashLength: 5,
      gapLength: 4,
    );

    // Subtle glow along line midpoint (truck icon "travels" here)
    final midpoint = _quadraticBezier(originPoint, controlPoint, destPoint, 0.5);
    final glowPaint = Paint()
      ..color = arcColor.withValues(alpha: onDark ? 0.22 : 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(midpoint, 10, glowPaint);

    // Tiny truck dot at midpoint
    final truckPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(midpoint, 3.5, truckPaint);

    // Origin: solid teal dot with ring
    final originRing = Paint()
      ..color = originColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(originPoint, 9, originRing);
    final originFill = Paint()
      ..color = originColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(originPoint, 5, originFill);
    // White inner dot
    canvas.drawCircle(originPoint, 2, Paint()..color = onDark ? AppColors.inkDeep : Colors.white);

    // Destination: teardrop pin
    _drawPin(canvas, destPoint, destinationColor, onDark);

    // Avoid unused midY warning
    assert(midY >= arcTop);
  }

  void _drawPin(Canvas canvas, Offset tip, Color color, bool onDark) {
    final center = Offset(tip.dx, tip.dy - 8);
    final pinPath = Path()
      ..moveTo(tip.dx, tip.dy + 2)
      ..quadraticBezierTo(tip.dx - 8, tip.dy - 4, center.dx - 6, center.dy - 2)
      ..arcToPoint(
        Offset(center.dx + 6, center.dy - 2),
        radius: const Radius.circular(6),
        clockwise: true,
      )
      ..quadraticBezierTo(tip.dx + 8, tip.dy - 4, tip.dx, tip.dy + 2)
      ..close();

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: onDark ? 0.4 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(pinPath.shift(const Offset(0, 1)), shadow);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fill);

    // Inner dot
    canvas.drawCircle(
      center.translate(0, -1),
      2.2,
      Paint()..color = onDark ? AppColors.inkDeep : Colors.white,
    );
  }

  void _drawDashedQuadratic(
    Canvas canvas,
    Offset p0,
    Offset p1,
    Offset p2,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    const steps = 120;
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(_quadraticBezier(p0, p1, p2, t));
    }

    double accum = 0;
    bool drawing = true;
    Offset? segStart = points.first;

    for (var i = 1; i < points.length; i++) {
      final seg = (points[i] - points[i - 1]).distance;
      accum += seg;
      final limit = drawing ? dashLength : gapLength;
      if (accum >= limit) {
        if (drawing && segStart != null) {
          canvas.drawLine(segStart, points[i], paint);
        }
        drawing = !drawing;
        segStart = drawing ? points[i] : null;
        accum = 0;
      } else if (drawing && i == points.length - 1 && segStart != null) {
        canvas.drawLine(segStart, points[i], paint);
      }
    }
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor ||
      oldDelegate.originColor != originColor ||
      oldDelegate.destinationColor != destinationColor ||
      oldDelegate.onDark != onDark;
}

