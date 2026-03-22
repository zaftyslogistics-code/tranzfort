import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => AppColors.cardShadow;

  static List<BoxShadow> get cardPressed => AppColors.cardPressedShadow;

  static List<BoxShadow> get hero => AppColors.heroShadow;

  static List<BoxShadow> get heroCta => AppColors.heroCtaShadow;

  static List<BoxShadow> get bottomSheet => AppColors.bottomSheetShadow;
}
