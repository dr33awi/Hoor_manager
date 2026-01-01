import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Manager - Typography System
/// Professional, readable typography for accounting software
/// ═══════════════════════════════════════════════════════════════════════════

class HoorTypography {
  HoorTypography._();

  // ─────────────────────────────────────────────────────────────────────────
  // Font Family
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get _baseStyle => GoogleFonts.cairo(
        color: HoorColors.textPrimary,
        letterSpacing: 0.15,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Display Styles - For hero sections and large headings
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get displayLarge => _baseStyle.copyWith(
        fontSize: 48.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => _baseStyle.copyWith(
        fontSize: 40.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => _baseStyle.copyWith(
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Headline Styles - For page titles and sections
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get headlineLarge => _baseStyle.copyWith(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get headlineMedium => _baseStyle.copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineSmall => _baseStyle.copyWith(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Title Styles - For cards and subsections
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get titleLarge => _baseStyle.copyWith(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleMedium => _baseStyle.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleSmall => _baseStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Body Styles - For general content
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => _baseStyle.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _baseStyle.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Label Styles - For buttons, inputs, and small elements
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get labelLarge => _baseStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get labelMedium => _baseStyle.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => _baseStyle.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Numeric Styles - For financial data
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get numericLarge => GoogleFonts.ibmPlexSansArabic(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: HoorColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get numericMedium => GoogleFonts.ibmPlexSansArabic(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: HoorColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get numericSmall => GoogleFonts.ibmPlexSansArabic(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: HoorColors.textPrimary,
      );

  static TextStyle get numericTable => GoogleFonts.ibmPlexSansArabic(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: HoorColors.textPrimary,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Currency Styles
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get currencyLarge => numericLarge.copyWith(
        color: HoorColors.income,
      );

  static TextStyle get currencyExpense => numericLarge.copyWith(
        color: HoorColors.expense,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Caption & Helper Styles
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get caption => _baseStyle.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: HoorColors.textTertiary,
        height: 1.4,
      );

  static TextStyle get overline => _baseStyle.copyWith(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: HoorColors.textTertiary,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Button Text Styles
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get buttonLarge => _baseStyle.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get buttonMedium => _baseStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get buttonSmall => _baseStyle.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}

/// Extension for easy color modification
extension TextStyleX on TextStyle {
  TextStyle get primary => copyWith(color: HoorColors.textPrimary);
  TextStyle get secondary => copyWith(color: HoorColors.textSecondary);
  TextStyle get tertiary => copyWith(color: HoorColors.textTertiary);
  TextStyle get disabled => copyWith(color: HoorColors.textDisabled);
  TextStyle get onPrimary => copyWith(color: HoorColors.textOnPrimary);
  TextStyle get onAccent => copyWith(color: HoorColors.textOnAccent);

  TextStyle get success => copyWith(color: HoorColors.success);
  TextStyle get error => copyWith(color: HoorColors.error);
  TextStyle get warning => copyWith(color: HoorColors.warning);
  TextStyle get info => copyWith(color: HoorColors.info);

  TextStyle get income => copyWith(color: HoorColors.income);
  TextStyle get expense => copyWith(color: HoorColors.expense);

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
}
