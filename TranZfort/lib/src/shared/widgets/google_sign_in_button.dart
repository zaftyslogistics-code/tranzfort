import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A branded Google Sign-In button with white background, Google "G" icon,
/// and elevated styling to visually promote Google as the primary login option.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.button),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedScale(
          scale: enabled ? 1.0 : 0.98,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            height: height,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GoogleGIcon(size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
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

/// A custom-painted Google "G" icon using official brand colors.
/// This avoids the need for an external image asset.
class _GoogleGIcon extends StatelessWidget {
  final double size;

  const _GoogleGIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;

    // Google brand colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the "G" shape using arcs
    // Top arc (blue to red)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -0.3 * 3.14159, // Start angle
      0.8 * 3.14159,  // Sweep angle
      false,
      paint,
    );

    // Left arc (red)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.5 * 3.14159,
      0.5 * 3.14159,
      false,
      paint,
    );

    // Bottom arc (yellow to green)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.0 * 3.14159,
      0.5 * 3.14159,
      false,
      paint,
    );

    // Right arc (green)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.5 * 3.14159,
      0.5 * 3.14159,
      false,
      paint,
    );

    // Horizontal bar (blue)
    paint.style = PaintingStyle.fill;
    paint.color = blue;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.5,
        center.dy - strokeWidth * 0.5,
        size.width * 0.45,
        strokeWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
