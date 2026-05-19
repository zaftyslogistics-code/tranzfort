import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Integrated route line widget for load card dark header.
///
/// Renders FROM/TO text blocks with city/state and a dashed route line between them.
///
/// Layout:
/// - Row: FROM block + flexible dashed line + TO block
///
/// Target height: ~60px for the route row.
class IntegratedRouteLine extends StatelessWidget {
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;

  const IntegratedRouteLine({
    super.key,
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Left: FROM block (natural width)
          IntrinsicWidth(
            child: _LocationBlock(
              label: 'FROM',
              city: originCity,
              state: originState,
              isOrigin: true,
            ),
          ),
          // Center: dashed line (flexible, takes remaining space)
          Expanded(
            child: _DashedLine(
              color: AppColors.inkTextSecondary.withValues(alpha: 0.3),
            ),
          ),
          // Right: TO block (natural width)
          IntrinsicWidth(
            child: _LocationBlock(
              label: 'TO',
              city: destinationCity,
              state: destinationState,
              isOrigin: false,
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

  const _LocationBlock({
    required this.label,
    required this.city,
    required this.state,
    required this.isOrigin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isOrigin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // FROM/TO label
        Text(
          label,
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.inkTextSecondary,
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
                color: AppColors.inkTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
        ),
        const SizedBox(height: 1),
        // State name
        Text(
          state,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySecondary.copyWith(
                color: AppColors.inkTextSecondary,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

/// Simple dashed line widget with arrow.
class _DashedLine extends StatelessWidget {
  final Color color;

  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLineWithArrowPainter(color: color),
    );
  }
}

/// Custom painter for dashed line with arrow at the end.
class _DashedLineWithArrowPainter extends CustomPainter {
  final Color color;

  _DashedLineWithArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 8.0;
    const arrowSize = 6.0;

    // Draw dashed line (stop before arrow)
    double startX = 0;
    final lineEndX = size.width - arrowSize;
    
    while (startX < lineEndX) {
      final endX = (startX + dashWidth).clamp(0.0, lineEndX);
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw arrow at the end
    final arrowPath = Path();
    arrowPath.moveTo(lineEndX, size.height / 2);
    arrowPath.lineTo(lineEndX - arrowSize, size.height / 2 - arrowSize / 2);
    arrowPath.lineTo(lineEndX - arrowSize, size.height / 2 + arrowSize / 2);
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(_DashedLineWithArrowPainter oldDelegate) => false;
}
