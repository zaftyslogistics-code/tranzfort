/// TranZfort Spacing & Dimension Tokens
/// Source of truth: docs/39-ui-ux-layout-spacing-and-component-composition.md §3
/// 4px-based scale. No ad hoc values in code.
class AppSpacing {
  AppSpacing._();

  // ─── Spacing Scale ───
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ─── Screen Padding ───
  static const double screenHorizontal = lg; // 16
  static const double screenTop = xxl; // 32

  // ─── Card Gaps ───
  static const double cardGap = md; // 12 between cards
  static const double sectionGap = xl; // 24 between sections

  // ─── Bottom Safe Area ───
  static const double bottomNavSafe = xxxl; // 48 terminal padding
}

/// TranZfort Border Radius Tokens
/// Source of truth: docs/39-ui-ux-layout-spacing-and-component-composition.md §3
class AppRadius {
  AppRadius._();

  static const double card = 12.0;
  static const double button = 12.0;
  static const double input = 8.0;
  static const double chip = 20.0;
  static const double bottomSheet = 16.0;
}

/// Minimum touch target size (48x48 px) — non-negotiable
class AppTouchTarget {
  AppTouchTarget._();
  static const double min = 48.0;
}
