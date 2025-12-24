import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// أنماط النصوص الموحدة في التطبيق
class AppTextStyles {
  AppTextStyles._();

  // الخط الأساسي - Cairo للعربية
  static String? get _fontFamily => GoogleFonts.cairo().fontFamily;

  // العناوين الكبيرة
  static TextStyle get headingLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontHeading,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontXxl,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // العناوين الفرعية
  static TextStyle get titleLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontXl,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontMd,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // النص العادي
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontMd,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // النص الصغير
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontMd,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontXs,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // نص الأزرار
  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
        height: 1.2,
      );

  // نص حقول الإدخال
  static TextStyle get input => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get inputHint => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
        height: 1.4,
      );

  static TextStyle get inputError => TextStyle(
        fontFamily: _fontFamily,
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.normal,
        color: AppColors.error,
        height: 1.4,
      );
}
