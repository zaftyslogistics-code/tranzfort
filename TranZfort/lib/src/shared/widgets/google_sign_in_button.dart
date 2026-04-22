import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A branded Google Sign-In button with white background, horizontal Google logo,
/// and elevated styling to visually promote Google as the primary login option.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;

  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.button),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedScale(
          scale: enabled ? 1.0 : 0.98,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            height: height,
            width: width ?? double.infinity, // Fill width by default
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
                  : Image.asset(
                      'assets/images/google-logo.png',
                      height: height * 0.6, // Use 60% of button height for logo
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 32),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
