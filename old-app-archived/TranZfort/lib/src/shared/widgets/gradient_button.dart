import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = AppSpacing.buttonHeight,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttonShadow = _isEnabled
        ? [
            BoxShadow(
              color: AppColors.brandTeal.withValues(alpha: 0.24),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ]
        : null;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.isLoading
          ? '${widget.label}, ${l10n.sharedLoadingSuffix}'
          : widget.label,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.mediumImpact();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppSpacing.fast,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: _isEnabled ? AppColors.ctaGradient : null,
              color: _isEnabled ? null : AppColors.neutralLight,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              boxShadow: buttonShadow,
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isEnabled
                            ? Colors.white
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
