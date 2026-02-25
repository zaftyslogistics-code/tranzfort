import 'package:flutter/material.dart';

class AdminTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
