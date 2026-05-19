import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Integrated route line widget for load card dark header.
///
/// Renders FROM/TO text blocks with city/state, a dashed route line between them,
/// and a center distance/time capsule embedded in the line.
///
/// Target height: 70-78px for the entire route row.
class IntegratedRouteLine extends StatelessWidget {
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;
  final String? distanceLabel;
  final String? durationLabel;

  const IntegratedRouteLine({
    super.key,
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
    this.distanceLabel,
    this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final centerLabel = _buildCenterLabel();

    return SizedBox(
      height: 70, // Target height for route row
      child: Row(
        children: [
          // Left: FROM block
          Expanded(
            child: _LocationBlock(
              label: 'FROM',
              city: originCity,
              state: originState,
              isOrigin: true,
            ),
          ),
          // Center: dashed line with capsule
          _DashedLineWithCapsule(label: centerLabel),
          // Right: TO block
          Expanded(
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

  String? _buildCenterLabel() {
    if (distanceLabel == null && durationLabel == null) {
      return null;
    }
    if (distanceLabel != null && durationLabel != null) {
      return '$distanceLabel · $durationLabel';
    }
    return distanceLabel ?? durationLabel;
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

/// Dashed line with center capsule for distance/time.
class _DashedLineWithCapsule extends StatelessWidget {
  final String? label;

  const _DashedLineWithCapsule({this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line (background)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _DashedLine(
                    color: AppColors.inkTextSecondary.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DashedLine(
                    color: AppColors.inkTextSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          // Center capsule
          if (label != null)
            Center(
              child: _DistanceTimeCapsule(label: label!),
            ),
        ],
      ),
    );
  }
}

/// Simple dashed line widget.
class _DashedLine extends StatelessWidget {
  final Color color;

  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(color: color),
    );
  }
}

/// Custom painter for dashed line.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}

/// Center capsule for distance/time display.
class _DistanceTimeCapsule extends StatelessWidget {
  final String label;

  const _DistanceTimeCapsule({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inkMid,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
