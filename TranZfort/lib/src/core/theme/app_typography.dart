import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TranZfort Typography Tokens
/// Source of truth: docs/38-ui-ux-color-typography-and-elevation-system.md §8
/// Font: Inter (via Google Fonts)
class AppTypography {
  AppTypography._();

  // ─── Phase 4 Extended Scale ───
  static TextStyle get displayHero => GoogleFonts.inter(
        fontSize: 48, // Increased from 40px (+20%)
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMicro => GoogleFonts.inter(
        fontSize: 12, // Increased from 11px (+9%)
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      );

  // ─── Original Scale ───
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 28, // Increased from 24px (+17%)
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 22, // Increased from 20px (+10%)
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 18, // Increased from 16px (+12%)
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 17, // Increased from 15px (+13%)
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyPrimary => GoogleFonts.inter(
        fontSize: 15, // Increased from 14px (+7%)
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13, // Increased from 12px (+8%)
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12, // Increased from 11px (+9%)
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textMuted,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.0,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get chip => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.5,
      );
}
