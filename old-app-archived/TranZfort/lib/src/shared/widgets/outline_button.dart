import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<OutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final resolvedOnPressed = (widget.isLoading) ? null : widget.onPressed;
    final isEnabled = resolvedOnPressed != null;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.mediumImpact();
                resolvedOnPressed();
              }
            : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppSpacing.fast,
          child: OutlinedButton(
            onPressed: null,
            style:
                OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isEnabled ? AppColors.primary : AppColors.neutralLight,
                    width: 1.25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                  foregroundColor: isEnabled
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ).copyWith(
                  overlayColor: WidgetStatePropertyAll(
                    AppColors.brandTeal.withValues(alpha: 0.08),
                  ),
                ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(
                      color: isEnabled
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
