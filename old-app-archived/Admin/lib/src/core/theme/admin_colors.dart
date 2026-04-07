import 'package:flutter/material.dart';

class AdminColors {
  // Shared brand palette (aligned with user app AppColors)
  static const Color brandTeal = Color(0xFF0F6F69);
  static const Color brandTealLight = Color(0xFFE6F5F3);
  static const Color brandTealDark = Color(0xFF0A4F4A);
  static const Color brandOrange = Color(0xFFD97706);
  static const Color brandOrangeLight = Color(0xFFFEF3C7);

  // Theme roles
  static const Color primary = brandTeal;
  static const Color secondary = brandOrange;
  static const Color scaffoldBg = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color inputBg = Color(0xFFFAFAFA);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6178);
  static const Color textTertiary = Color(0xFF8E95A9);
  static const Color border = Color(0xFFE0E4EA);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static const Color successTint = Color(0xFFECFDF5);
  static const Color warningTint = Color(0xFFFFFBEB);
  static const Color infoTint = Color(0xFFEFF6FF);
  static const Color errorTint = Color(0xFFFEF2F2);
  
  static Color brandTealLightMuted = brandTeal.withValues(alpha: 0.08);

  static const LinearGradient tranzfortGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTeal, brandOrange],
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
