import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية
/// اللون الأساسي: #12334e (أزرق داكن)
/// اللون الثانوي: #e9dac1 (بيج فاتح)
class AppColors {
  AppColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF12334e);
  static const Color secondary = Color(0xFFe9dac1);

  // درجات اللون الأساسي
  static const Color primaryLight = Color(0xFF2a4a66);
  static const Color primaryDark = Color(0xFF0a1f30);

  // درجات اللون الثانوي
  static const Color secondaryLight = Color(0xFFf5ede0);
  static const Color secondaryDark = Color(0xFFd4c4a8);

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF12334e);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFF9CA3AF);

  // ألوان الخلفية
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF3F4F6);

  // ألوان الحالة
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ألوان الحدود
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // ألوان أخرى
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color shadow = Color(0x1A000000);

  // ===== ألوان الوضع الداكن =====

  // ألوان الخلفية الداكنة
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkScaffoldBackground = Color(0xFF0A0A0A);

  // ألوان النصوص الداكنة
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkTextHint = Color(0xFF757575);

  // ألوان الحدود الداكنة
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF2C2C2C);
}
