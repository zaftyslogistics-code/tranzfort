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

  // ─── Phase 4 Tiered Radii ───
  static const double button = 14.0; // balanced — not pill-like, not boxy
  static const double input = 12.0; // up from 8
  static const double card = 16.0; // modern sweet spot (list cards, stat cards)
  static const double hero = 20.0; // premium feel without being playful
  static const double bottomSheet = 24.0; // modern mobile standard
  static const double iconChip = 14.0; // rounded square for leading icons

  // ─── Legacy (for backward compatibility) ───
  static const double chip = 20.0; // fully rounded / pill (status chips, badges)
}

/// Minimum touch target size (48x48 px) — non-negotiable
class AppTouchTarget {
  AppTouchTarget._();
  static const double min = 48.0;
}
