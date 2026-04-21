import 'package:flutter/material.dart';

/// TranZfort User App Color Tokens
/// Source of truth: docs/38-ui-ux-color-typography-and-elevation-system.md
/// DO NOT use raw hex codes in widgets. Always use AppColors.xxx
class AppColors {
  AppColors._();

  // ─── Brand Primary (Teal) ───
  static const Color primary = Color(0xFF0E8C84);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0A5550);

  // ─── Brand Secondary (Orange) ───
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFF92400E);

  // ─── User App Surfaces ───
  static const Color canvas = Color(0xFFF7F5F1);
  static const Color canvasTop = Color(0xFFFDFDFC);
  static const Color canvasBottom = Color(0xFFF3F1EE);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color raisedSurface = Color(0xFFFFFFFF);
  static const Color subtleSurface = Color(0xFFEFEDE9);
  static const Color divider = Color(0xFFE7E5E4);

  // ─── Elevated Surface (New for Phase 2) ───
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ─── Optional Texture Tokens (New for Phase 3) ───
  static const Color noiseOverlay = Color(0x0A000000); // 4% black alpha
  static const Color gridPattern = Color(0x0AFFFFFF); // 4% white alpha

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF8A8481);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDisabled = Color(0xFF6B6560);

  // ─── Semantic Status ───
  static const Color success = Color(0xFF047857);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFF92400E);
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
      Color(0x1F0E8C84), // 12% teal
      Color(0x19D97706), // 10% orange
    ],
  );

  static const LinearGradient canvasWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [canvasTop, canvasBottom],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          spreadRadius: -8,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardPressedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
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

  static List<BoxShadow> get shadowRaised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowTeal => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 60,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.20),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ];
}
