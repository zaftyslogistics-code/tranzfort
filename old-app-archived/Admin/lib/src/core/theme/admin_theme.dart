import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

class AdminTheme {
  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AdminColors.primary,
      secondary: AdminColors.secondary,
      surface: AdminColors.surface,
      onSurface: AdminColors.onSurface,
      error: AdminColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AdminColors.scaffoldBg,
    );

    return base.copyWith(
      textTheme: AdminTypography.textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.cardRadius),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.inputHorizontalPadding,
          vertical: AdminSpacing.inputVerticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.fieldRadius),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.fieldRadius),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.fieldRadius),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AdminSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      iconTheme: const IconThemeData(color: AdminColors.primary),
      dividerColor: AdminColors.border,
    );
  }
}
