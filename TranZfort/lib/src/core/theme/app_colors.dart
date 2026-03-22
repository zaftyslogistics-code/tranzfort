import 'package:flutter/material.dart';

/// TranZfort User App Color Tokens
/// Source of truth: docs/38-ui-ux-color-typography-and-elevation-system.md
/// DO NOT use raw hex codes in widgets. Always use AppColors.xxx
class AppColors {
  AppColors._();

  // ─── Brand Primary (Teal) ───
  static const Color primary = Color(0xFF0F6F69);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0A5550);

  // ─── Brand Secondary (Orange) ───
  static const Color secondary = Color(0xFFB45309);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFF92400E);

  // ─── User App Surfaces ───
  static const Color canvas = Color(0xFFFAFAF8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color raisedSurface = Color(0xFFFFFFFF);
  static const Color subtleSurface = Color(0xFFF5F3F0);
  static const Color divider = Color(0xFFE7E5E4);

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFFA8A29E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Semantic Status ───
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralBg = Color(0xFFF3F4F6);

  // ─── Special Badges ───
  static const Color superLoadText = Color(0xFF92400E);
  static const Color superLoadBg = Color(0xFFFEF3C7);
  static const Color verifiedText = Color(0xFF0284C7);
  static const Color verifiedBg = Color(0xFFEFF6FF);

  // ─── Gradients ───
  static const LinearGradient heroCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient heroCardWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x140F6F69), // 8% teal
      Color(0x0FB45309), // 6% orange
    ],
  );

  // ─── Shadows ───
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardPressedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get heroCtaShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get bottomSheetShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ];
}
