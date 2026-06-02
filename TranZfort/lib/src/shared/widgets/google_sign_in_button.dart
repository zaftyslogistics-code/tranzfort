import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Google sign-in: brand gradient border, "Continue with" + horizontal wordmark.
class GoogleSignInButton extends StatelessWidget {
  static const double _wordmarkHeight = 50; // ~40% larger than prior 36dp

  final String continueWithLabel;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GoogleSignInButton({
    super.key,
    required this.continueWithLabel,
    required this.semanticLabel,
    this.onPressed,
    this.isLoading = false,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: AppDecorations.brandGradientCard(
        borderRadius: BorderRadius.circular(AppRadius.button),
        innerColor: Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            continueWithLabel,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: _wordmarkHeight,
                            child: Image.asset(
                              'assets/images/google-logo.png',
                              fit: BoxFit.contain,
                              semanticLabel: 'Google',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error_outline, size: 32),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
