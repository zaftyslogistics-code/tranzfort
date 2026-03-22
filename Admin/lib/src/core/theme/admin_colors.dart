import 'package:flutter/material.dart';

/// TranZfort Admin App Color Tokens — DARK THEME
/// Source of truth: docs/38-ui-ux-color-typography-and-elevation-system.md §4
/// Admin uses Teal + Electric-Blue on dark slate surfaces.
/// Admin must NOT use the user-app teal+orange gradient for CTAs.
class AdminColors {
  AdminColors._();

  // ─── Admin Surfaces (Dark Slate) ───
  static const Color canvas = Color(0xFF0F172A);
  static const Color cardSurface = Color(0xFF1E293B);
  static const Color raisedSurface = Color(0xFF334155);
  static const Color divider = Color(0xFF475569);

  // ─── Admin Text ───
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Admin Accents ───
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentBlue = Color(0xFF3B82F6);

  // ─── Admin Glow Effects ───
  static List<BoxShadow> get glowTeal => [
        BoxShadow(
          color: accentTeal.withValues(alpha: 0.15),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get glowBlue => [
        BoxShadow(
          color: accentBlue.withValues(alpha: 0.15),
          blurRadius: 12,
        ),
      ];

  // ─── Admin Gradient (Teal → Blue, NOT orange) ───
  static const LinearGradient adminPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F6F69), Color(0xFF3B82F6)],
  );

  // ─── Semantic Status (same across both apps) ───
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFF064E3B);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFF78350F);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFF0C4A6E);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralBg = Color(0xFF374151);
}
