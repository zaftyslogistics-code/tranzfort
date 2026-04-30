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
  /// @deprecated Dark surface variants will be handled by ThemeExtension. This parameter will be removed in Phase 4.
  /// Migration: Remove useDarkVariant parameter. Theme will automatically handle dark mode colors.
  final bool useDarkVariant; // Phase 4: use primaryOnDark for dark surfaces

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.icon,
    this.useDarkVariant = false,
  });

  factory PrimaryButton.icon({
    Key? key,
    required String label,
    required Widget icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    double height = 52,
    @Deprecated('Dark surface variants will be handled by ThemeExtension. Remove useDarkVariant parameter.')
    bool useDarkVariant = false,
  }) {
    return PrimaryButton(
      key: key,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      icon: icon,
      useDarkVariant: useDarkVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = useDarkVariant ? AppColors.primaryOnDark : AppColors.primary;
    final textColor = useDarkVariant ? AppColors.inkDeep : AppColors.inkTextOnAccent;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: textColor,
    );

    return _ActionButtonFrame(
      height: height,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: textColor,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: useDarkVariant ? AppShadows.elevation4Dark : AppShadows.elevation4,
      ),
      pressedShadow: AppShadows.elevation2, // Phase 4: drop to elevation2 on press
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
  /// @deprecated Use GradientButton for filled buttons. This parameter will be removed in Phase 4.
  /// Migration: Replace `OutlineButton(filled: true)` with `GradientButton` or `PrimaryButton`.
  final bool filled; // Phase 4: legacy mode

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
    if (filled) {
      // Legacy filled mode (backward compatibility)
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
        child: Text(label, style: textStyle),
      );
    }

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
    this.height = 44, // Phase 4: reduced from 48
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
