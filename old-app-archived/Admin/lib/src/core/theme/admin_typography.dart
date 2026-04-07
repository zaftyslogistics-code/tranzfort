import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_colors.dart';

class AdminTypography {
  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: AdminColors.onSurface,
      displayColor: AdminColors.onSurface,
    );
  }
}
