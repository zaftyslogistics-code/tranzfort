import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

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
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
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
    final textStyle = AppTypography.button;

    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: AppColors.textOnPrimary,
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
                IconTheme(
                  data: const IconThemeData(color: AppColors.textOnPrimary, size: 20),
                  child: icon!,
                ),
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
  final Widget? icon;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Phase 4 GhostButton spec
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
        );

    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: AppColors.primary,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: icon == null
          ? Text(label, style: textStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: AppColors.primary, size: 20),
                  child: icon!,
                ),
                const SizedBox(width: 8),
                Text(label, style: textStyle),
              ],
            ),
    );
  }
}

class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool onDarkSurface;

  const TextActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 44, // Phase 4: reduced from 48
    this.onDarkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDarkSurface ? AppColors.primaryOnDark : AppColors.primary;
    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: color,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              decoration: TextDecoration.none, // Phase 4: no default underline
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
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        color: AppColors.error, // Phase 4: solid error color instead of errorBg
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.elevation2, // Phase 4: elevation2 shadow
      ),
      pressedShadow: AppShadows.elevation1, // Phase 4: drop to elevation1 on press
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
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
  final List<BoxShadow>? pressedShadow; // Phase 4: shadow tier to drop to on press

  const _ActionButtonFrame({
    required this.child,
    required this.decoration,
    required this.onPressed,
    required this.isLoading,
    required this.foregroundColor,
    required this.height,
    this.pressedShadow, // Phase 4: optional pressed shadow
  });

  @override
  State<_ActionButtonFrame> createState() => _ActionButtonFrameState();
}

class _ActionButtonFrameState extends State<_ActionButtonFrame> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final shadow = _pressed && enabled && widget.pressedShadow != null
        ? widget.pressedShadow
        : widget.decoration.boxShadow;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedScale(
        scale: _pressed && enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 150), // Phase 4: 150ms ease-out
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: widget.decoration.copyWith(
              boxShadow: shadow,
            ),
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
                          child: DefaultTextStyle(
                            style: AppTypography.button.copyWith(color: widget.foregroundColor),
                            child: IconTheme(
                              data: IconThemeData(color: widget.foregroundColor, size: 20),
                              child: widget.child,
                            ),
                          ),
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
