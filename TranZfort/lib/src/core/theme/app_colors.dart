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
  static const Color primaryOnDark = Color(0xFF2DD4BF); // brighter for dark surfaces (Phase 4)

  // ─── Brand Secondary (Orange) ───
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFF92400E);
  static const Color secondaryOnDark = Color(0xFFFBBF24); // brighter amber for dark surfaces (Phase 4)

  // ─── User App Surfaces ───
  static const Color canvas = Color(0xFFF7F5F1);
  static const Color canvasTop = Color(0xFFFDFDFC);
  static const Color canvasBottom = Color(0xFFF3F1EE);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color raisedSurface = Color(0xFFFFFFFF);
  static const Color subtleSurface = Color(0xFFEFEDE9);
  static const Color divider = Color(0xFFE7E5E4);

  // ─── Light Surface Tiers (Phase 4) ───
  static const Color surfaceBase = Color(0xFFFFFFFF); // standard cards
  static const Color surfaceSoft = Color(0xFFFAF7F2); // nested cards, list rows
  static const Color surfaceTint = Color(0xFFF0EBE3); // disabled slots, filter bg

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

  // ─── Dark Contrast Layer (Phase 4) ───
  static const Color inkDeep = Color(0xFF0A1614); // bottom nav bg, deepest surface
  static const Color inkMid = Color(0xFF14221F); // secondary dark surface, app-bar on scroll
  static const Color inkSurface = Color(0xFF1C2A27); // dark cards, hero layer
  static const Color inkBorder = Color(0xFF2A3B37); // subtle dividers on dark surfaces
  static const Color inkTextPrimary = Color(0xFFFFFFFF);
  static const Color inkTextSecondary = Color(0xFFA8BAB6); // teal-tinted muted for dark bg
  static const Color inkTextMuted = Color(0xFF6B807B);
  static const Color inkTextOnAccent = Color(0xFF0A1614); // text inside bright teal pills on dark

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

  // ─── Chip Backgrounds (Phase 4) ───
  static const Color primaryChipBg = Color(0xFFE6F4F2); // teal-tinted chip bg (on light)
  static const Color primaryChipText = Color(0xFF0A5550); // primaryDark text
  static const Color orangeChipBg = Color(0xFFFEF0E0); // warm orange chip (on light)
  static const Color orangeChipText = Color(0xFF92400E); // secondaryDark text
  static const Color primaryChipBgDark = Color(0x262DD4BF); // teal @ 15% (on dark)
  static const Color orangeChipBgDark = Color(0x26FBBF24); // amber @ 15% (on dark)

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

  // ─── Ambient Canvas Gradient (Phase 4) ───
  static const RadialGradient canvasAmbient = RadialGradient(
    center: Alignment(-0.8, -1.0),
    radius: 1.4,
    colors: [
      Color(0x0A0E8C84), // 4% teal
      Color(0x00F7F5F1), // transparent
    ],
  );

  // ─── Hero Dark Gradient (Phase 4) ───
  static const RadialGradient heroDark = RadialGradient(
    center: Alignment(-0.6, -0.8),
    radius: 1.5,
    colors: [
      Color(0xFF0A2220), // deep teal
      Color(0xFF0A1614), // ink deep
    ],
  );

  static const LinearGradient heroDarkGlow = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.center,
    colors: [
      Color(0x33D97706), // 20% orange glow
      Color(0x00000000), // transparent
    ],
  );

  // ─── Shadow Elevation Tiers (Phase 4) ───
  static List<BoxShadow> get elevation0 => []; // flat tiles, filters

  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 8),
        ),
      ]; // list rows

  static List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 6,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 4),
        ),
      ]; // standard cards — DEFAULT

  static List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 32),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 8),
        ),
      ]; // hero cards, modals

  static List<BoxShadow> get elevation4 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 20,
          offset: const Offset(0, 48),
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.18),
          blurRadius: 0,
          offset: const Offset(0, 24),
        ),
      ]; // floating CTA, selected

  static List<BoxShadow> get elevation4Dark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 20,
          offset: const Offset(0, 48),
        ),
        BoxShadow(
          color: primaryOnDark.withValues(alpha: 0.25),
          blurRadius: 0,
          offset: const Offset(0, 24),
        ),
      ]; // floating CTA on dark bg

  // ─── Legacy Shadow Aliases (for backward compatibility) ───
  static List<BoxShadow> get cardShadow => elevation2;
  static List<BoxShadow> get cardPressedShadow => elevation1;
  static List<BoxShadow> get heroShadow => elevation3;
  static List<BoxShadow> get heroCtaShadow => elevation4;
  static List<BoxShadow> get bottomSheetShadow => elevation3;
  static List<BoxShadow> get shadowRaised => elevation3;

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
