import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ألوان تطبيق تاجر - الأزرق الكلاسيكي
/// Classic Blue Theme
/// ═══════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Primary Colors - الأزرق الكلاسيكي
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF1565C0); // الأساسي
  static const Color primaryLight = Color(0xFF1E88E5); // فاتح
  static const Color primaryDark = Color(0xFF0D47A1); // غامق
  static const Color primarySoft = Color(0xFF42A5F5); // ناعم

  // ═══════════════════════════════════════════════════════════════════════════
  // Secondary Colors - الرمادي الفضي
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFF546E7A); // رمادي
  static const Color secondaryLight = Color(0xFF78909C); // رمادي فاتح
  static const Color secondaryDark = Color(0xFF37474F); // رمادي غامق
  static const Color secondaryMuted = Color(0xFF90A4AE); // رمادي باهت

  // ═══════════════════════════════════════════════════════════════════════════
  // Accent Colors - سماوي مميز
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color accent = Color(0xFF00ACC1); // سماوي
  static const Color accentLight = Color(0xFF26C6DA); // سماوي فاتح
  static const Color accentDark = Color(0xFF00838F); // سماوي غامق

  // ═══════════════════════════════════════════════════════════════════════════
  // Status Colors - ألوان الحالات
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF43A047); // أخضر
  static const Color successLight = Color(0xFF66BB6A); // أخضر فاتح
  static const Color warning = Color(0xFFFFA000); // برتقالي
  static const Color warningLight = Color(0xFFFFCA28); // أصفر
  static const Color error = Color(0xFFE53935); // أحمر
  static const Color errorLight = Color(0xFFEF5350); // أحمر فاتح
  static const Color info = Color(0xFF1E88E5); // أزرق معلومات

  // ═══════════════════════════════════════════════════════════════════════════
  // Background Colors - ألوان الخلفيات
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF5F7FA); // خلفية رمادية زرقاء
  static const Color surface = Color(0xFFFFFFFF); // أبيض
  static const Color cardBackground = Color(0xFFFFFFFF); // خلفية البطاقات
  static const Color scaffoldBackground = Color(0xFFFAFBFC); // خلفية الشاشات

  // ═══════════════════════════════════════════════════════════════════════════
  // Text Colors - ألوان النصوص
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF212121); // نص أساسي
  static const Color textSecondary = Color(0xFF616161); // نص ثانوي
  static const Color textHint = Color(0xFF9E9E9E); // نص تلميح
  static const Color textOnPrimary = Color(0xFFFFFFFF); // نص على الأزرق
  static const Color textOnSecondary = Color(0xFFFFFFFF); // نص على الرمادي

  // ═══════════════════════════════════════════════════════════════════════════
  // Border & Divider Colors - ألوان الحدود
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color border = Color(0xFFE0E0E0); // حدود رمادية
  static const Color borderLight = Color(0xFFEEEEEE); // حدود فاتحة
  static const Color divider = Color(0xFFE0E0E0); // فاصل

  // ═══════════════════════════════════════════════════════════════════════════
  // Specific App Colors - ألوان خاصة بالتطبيق
  // ═══════════════════════════════════════════════════════════════════════════

  // المبيعات والمشتريات
  static const Color sales = Color(0xFF1565C0); // أزرق للمبيعات
  static const Color salesLight = Color(0xFFE3F2FD); // خلفية المبيعات
  static const Color purchases = Color(0xFF546E7A); // رمادي للمشتريات
  static const Color purchasesLight = Color(0xFFECEFF1); // خلفية المشتريات

  // الدخل والمصروفات
  static const Color income = Color(0xFF43A047); // أخضر للدخل
  static const Color incomeLight = Color(0xFFE8F5E9); // خلفية الدخل
  static const Color expense = Color(0xFFE53935); // أحمر للمصروفات
  static const Color expenseLight = Color(0xFFFFEBEE); // خلفية المصروفات

  // المرتجعات والمخزون
  static const Color returns = Color(0xFF8E24AA); // بنفسجي للمرتجعات
  static const Color returnsLight = Color(0xFFF3E5F5); // خلفية المرتجعات
  static const Color inventory = Color(0xFF00ACC1); // سماوي للمخزون
  static const Color inventoryLight = Color(0xFFE0F7FA); // خلفية المخزون
  static const Color lowStock = Color(0xFFFF5722); // برتقالي للمخزون المنخفض

  // العملاء والموردين
  static const Color customers = Color(0xFF3F51B5); // نيلي للعملاء
  static const Color customersLight = Color(0xFFE8EAF6); // خلفية العملاء
  static const Color suppliers = Color(0xFF795548); // بني للموردين
  static const Color suppliersLight = Color(0xFFEFEBE9); // خلفية الموردين

  // المنتجات
  static const Color products = Color(0xFF607D8B); // رمادي مزرق
  static const Color productsLight = Color(0xFFECEFF1); // خلفية المنتجات

  // ═══════════════════════════════════════════════════════════════════════════
  // Gradient Colors - ألوان التدرجات
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<Color> primaryGradient = [
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF00ACC1),
    Color(0xFF26C6DA),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // Shimmer Colors - ألوان التحميل
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ═══════════════════════════════════════════════════════════════════════════
  // Shadow Color - لون الظل
  // ═══════════════════════════════════════════════════════════════════════════
  static Color shadowColor = const Color(0xFF1565C0).withOpacity(0.1);
}
