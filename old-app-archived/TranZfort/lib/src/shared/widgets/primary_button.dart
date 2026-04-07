import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? iconData;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedOnPressed = (isLoading) ? null : onPressed;
    final resolvedColor = color ?? AppColors.primary;

    final style = ElevatedButton.styleFrom(
      backgroundColor: resolvedColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutralLight,
      disabledForegroundColor: AppColors.textTertiary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
    );

    if (isLoading) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: ElevatedButton(
          onPressed: null,
          style: style,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (iconData != null) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: resolvedOnPressed,
          style: style,
          icon: Icon(iconData, color: Colors.white, size: 20),
          label: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: resolvedOnPressed,
        style: style,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
