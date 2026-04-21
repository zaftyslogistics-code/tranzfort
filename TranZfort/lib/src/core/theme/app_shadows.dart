import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => AppColors.cardShadow;

  static List<BoxShadow> get cardPressed => AppColors.cardPressedShadow;

  static List<BoxShadow> get hero => AppColors.heroShadow;

  static List<BoxShadow> get heroCta => AppColors.heroCtaShadow;

  static List<BoxShadow> get bottomSheet => AppColors.bottomSheetShadow;

  static List<BoxShadow> get raised => AppColors.shadowRaised;

  static List<BoxShadow> get glowTeal => AppColors.glowTeal;

  // ─── Elevation Tiers (Phase 4) ───
  static List<BoxShadow> get elevation0 => AppColors.elevation0;
  static List<BoxShadow> get elevation1 => AppColors.elevation1;
  static List<BoxShadow> get elevation2 => AppColors.elevation2;
  static List<BoxShadow> get elevation3 => AppColors.elevation3;
  static List<BoxShadow> get elevation4 => AppColors.elevation4;
  static List<BoxShadow> get elevation4Dark => AppColors.elevation4Dark;
}
