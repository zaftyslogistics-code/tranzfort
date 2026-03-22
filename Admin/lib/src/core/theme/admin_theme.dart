import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

/// TranZfort Admin Dark Theme
/// Source of truth: docs/38-ui-ux-color-typography-and-elevation-system.md §4-5
/// Dark slate canvas + Teal accent + Electric-Blue for alerts
class AdminTheme {
  AdminTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.canvas,
      colorScheme: ColorScheme.dark(
        primary: AdminColors.accentTeal,
        onPrimary: AdminColors.textPrimary,
        secondary: AdminColors.accentBlue,
        onSecondary: AdminColors.textPrimary,
        surface: AdminColors.cardSurface,
        onSurface: AdminColors.textPrimary,
        error: AdminColors.error,
        onError: AdminColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w700, height: 1.2,
          color: AdminColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
          color: AdminColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,
          color: AdminColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
          color: AdminColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
          color: AdminColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w400, height: 1.4,
          color: AdminColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.0,
          color: AdminColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.cardSurface,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AdminColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.accentTeal,
          foregroundColor: AdminColors.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.accentTeal,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AdminColors.accentTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.raisedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AdminColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AdminColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.accentTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AdminColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.divider,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.raisedSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, color: AdminColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
