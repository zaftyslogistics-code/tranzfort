import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing (reference app)
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Component tokens (reference app)
  static const double screenPaddingH = 16;
  static const double screenPaddingV = 16;
  static const double sectionGap = 20;
  static const double cardPadding = 16;
  static const double cardInnerPaddingCompact = 12;
  static const double listItemGap = 10;
  static const double cardRadius = 16;
  static const double heroCardRadius = 20;
  static const double cardGap = 12;
  static const double buttonRadius = 12;
  static const double buttonHeight = 52;
  static const double inputRadius = 12;
  static const double inputHeight = 56;
  static const double chipRadius = 20;
  static const double chipHeight = 36;
  static const double bottomNavHeight = 72;
  static const double drawerWidth = 300;
  static const double avatarSmall = 40;
  static const double avatarMedium = 52;
  static const double avatarLarge = 80;
  static const double glassBlurSigma = 12.0;

  // Icon and compact component tokens
  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconLg = 22;
  static const double iconXl = 28;
  static const double iconDisplay = 64;
  static const double tileLeadingSize = 36;
  static const double tileLeadingRadius = 10;
  static const double statusBadgeRadius = 20;

  // Screen-specific component tokens
  static const double mapViewportPadding = 50;
  static const double mapMarkerSize = 40;
  static const double floatingCtaInset = 24;
  static const double composerRadius = 24;
  static const double minTouchTarget = 48;

  // Legacy convenience alias used throughout current code
  static const double screenPadding = screenPaddingH;

  static double safeBottomPadding(
    BuildContext context, {
    double extra = 0,
  }) {
    return bottomNavHeight +
        screenPaddingV +
        MediaQuery.paddingOf(context).bottom +
        extra;
  }

  // Animation durations (reference app)
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration staggerDelay = Duration(milliseconds: 50);
}
