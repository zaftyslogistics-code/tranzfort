import 'package:flutter/material.dart';

class AppColors {
  // Brand (old reference app)
  static const Color brandTeal = Color(0xFF0F6F69);
  static const Color brandTealLight = Color(0xFFE6F5F3);
  static const Color brandTealDark = Color(0xFF0A4F4A);
  static const Color brandOrange = Color(0xFFB45309);
  static const Color brandOrangeLight = Color(0xFFFEF3C7);
  static const Color brandOrangeDark = Color(0xFF92400E);

  // Theme roles
  static const Color primary = brandTeal;
  static const Color secondaryAmber = brandOrange;

  // UI v2 role tokens
  static const Color canvasWarm = Color(0xFFF6F4EE);
  static const Color surfaceLevel1 = Color(0xFFFFFFFF);
  static const Color surfaceLevel2 = Color(0xFFFCFDFE);

  // Surfaces
  static const Color scaffoldBg = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color background = scaffoldBg;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFFAFAFA);
  static Color surfaceGlass = Colors.white.withValues(alpha: 0.85);
  static Color surfaceGlassBorder = Colors.white.withValues(alpha: 0.40);
  static Color primaryMuted = brandTeal.withValues(alpha: 0.08);
  static Color heroBg = primaryMuted;
  static const Color kpiChipBg = Color(0xFFE7F4F2);
  static const Color kpiChipBorder = Color(0xFFBFD8D4);

  // Text
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6178);
  static const Color textTertiary = Color(0xFF8E95A9);

  // Borders & dividers
  static const Color borderDefault = Color(0xFFE0E4EA);
  static const Color divider = Color(0xFFF0F1F3);

  // Semantic
  static const Color error = Color(0xFFB91C1C);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color success = Color(0xFF047857);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = brandOrange;
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  static const Color neutral = textSecondary;
  static const Color neutralLight = borderDefault;
  static const Color neutralDark = Color(0xFF374151);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);

  // Chat (kept as-is for now; can be adjusted to match old bubbles later)
  static const Color chatSender = Color(0xFFE6F5F3);
  static const Color chatReceiver = Color(0xFFFFFFFF);

  // Tints (for StatusBadge-like UI)
  static const Color successTint = Color(0xFFECFDF5);
  static const Color warningTint = Color(0xFFFFFBEB);
  static const Color errorTint = Color(0xFFFEF2F2);
  static const Color infoTint = Color(0xFFEFF6FF);

  // Gradients
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTeal, brandOrange],
  );

  static const LinearGradient tranzfortGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTeal, brandOrange],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F6F3), Color(0xFFFFF3E0)],
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get superLoadGlow => [
    BoxShadow(
      color: brandOrange.withValues(alpha: 0.25),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];
}
