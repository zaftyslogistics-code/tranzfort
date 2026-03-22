import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        gradient: AppColors.heroCta,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.heroCta,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.icon,
  });

  factory PrimaryButton.icon({
    Key? key,
    required String label,
    required Widget icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 52,
  }) {
    return PrimaryButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white,
    );

    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        gradient: AppColors.heroCta,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.heroCta,
      ),
      child: icon == null
          ? Text(label, style: textStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon!,
                const SizedBox(width: 8),
                Text(label, style: textStyle),
              ],
            ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool filled;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: filled ? Colors.white : AppColors.primary,
        );

    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: filled ? Colors.white : AppColors.primary,
      decoration: BoxDecoration(
        gradient: filled ? AppColors.heroCta : null,
        color: filled ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: filled ? AppShadows.heroCta : null,
      ),
      child: Text(label, style: textStyle),
    );
  }
}

class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const TextActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: AppColors.primary,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
      ),
    );
  }
}

class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: AppColors.error,
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.error,
            ),
      ),
    );
  }
}

class _ActionButtonFrame extends StatefulWidget {
  final Widget child;
  final BoxDecoration decoration;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color foregroundColor;
  final double height;

  const _ActionButtonFrame({
    required this.child,
    required this.decoration,
    required this.onPressed,
    required this.isLoading,
    required this.foregroundColor,
    required this.height,
  });

  @override
  State<_ActionButtonFrame> createState() => _ActionButtonFrameState();
}

class _ActionButtonFrameState extends State<_ActionButtonFrame> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedScale(
        scale: _pressed && enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: widget.decoration,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: SizedBox(
                height: widget.height,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.foregroundColor),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: widget.child,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
