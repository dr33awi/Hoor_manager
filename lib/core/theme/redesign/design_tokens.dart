import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Manager - Professional Design System
/// A modern, minimal design system for enterprise accounting software
/// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class HoorColors {
  HoorColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // Primary Brand Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Deep Navy Blue - Primary brand color
  static const Color primary = Color(0xFF12334E);
  static const Color primaryDark = Color(0xFF0A1F2E);
  static const Color primaryLight = Color(0xFF1E4A6E);
  static const Color primarySoft = Color(0xFFE8EEF3);

  /// Elegant Beige/Champagne - Secondary accent
  static const Color accent = Color(0xFFE8D9C0);
  static const Color accentDark = Color(0xFFD4C4A8);
  static const Color accentLight = Color(0xFFF5EFE6);
  static const Color accentMuted = Color(0xFFF9F6F1);

  // ─────────────────────────────────────────────────────────────────────────
  // Surface & Background Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color background = Color(0xFFFAFBFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F7F9);
  static const Color surfaceHover = Color(0xFFF8F9FA);

  // ─────────────────────────────────────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFF12334E);
  static const Color textSecondary = Color(0xFF5A6B7D);
  static const Color textTertiary = Color(0xFF8E9AAB);
  static const Color textDisabled = Color(0xFFBBC5D0);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Color(0xFF12334E);

  // ─────────────────────────────────────────────────────────────────────────
  // Border & Divider Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color border = Color(0xFFE5E9ED);
  static const Color borderLight = Color(0xFFF0F2F5);
  static const Color borderFocused = Color(0xFF12334E);
  static const Color divider = Color(0xFFEEF1F4);

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic Colors - Financial Context
  // ─────────────────────────────────────────────────────────────────────────

  /// Income / Profit / Success
  static const Color income = Color(0xFF10B981);
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color incomeDark = Color(0xFF059669);

  /// Expense / Loss / Error
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color expenseDark = Color(0xFFDC2626);

  /// Sales / Revenue
  static const Color sales = Color(0xFF3B82F6);
  static const Color salesLight = Color(0xFFDBEAFE);
  static const Color salesDark = Color(0xFF2563EB);

  /// Purchases / Procurement
  static const Color purchases = Color(0xFF8B5CF6);
  static const Color purchasesLight = Color(0xFFEDE9FE);
  static const Color purchasesDark = Color(0xFF7C3AED);

  /// Inventory / Stock
  static const Color inventory = Color(0xFF14B8A6);
  static const Color inventoryLight = Color(0xFFCCFBF1);
  static const Color inventoryDark = Color(0xFF0D9488);

  /// Customers / Relations
  static const Color customers = Color(0xFF06B6D4);
  static const Color customersLight = Color(0xFFCFFAFE);
  static const Color customersDark = Color(0xFF0891B2);

  /// Suppliers / Vendors
  static const Color suppliers = Color(0xFFF59E0B);
  static const Color suppliersLight = Color(0xFFFEF3C7);
  static const Color suppliersDark = Color(0xFFD97706);

  /// Returns / Refunds
  static const Color returns = Color(0xFFA855F7);
  static const Color returnsLight = Color(0xFFF3E8FF);
  static const Color returnsDark = Color(0xFF9333EA);

  // ─────────────────────────────────────────────────────────────────────────
  // Status Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─────────────────────────────────────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF12334E), Color(0xFF1E4A6E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SPACING SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class HoorSpacing {
  HoorSpacing._();

  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// RADIUS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class HoorRadius {
  HoorRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;
  static const double full = 999.0;

  static BorderRadius get cardRadius => BorderRadius.circular(lg.r);
  static BorderRadius get buttonRadius => BorderRadius.circular(md.r);
  static BorderRadius get inputRadius => BorderRadius.circular(md.r);
  static BorderRadius get chipRadius => BorderRadius.circular(full.r);
  static BorderRadius get sheetRadius =>
      BorderRadius.vertical(top: Radius.circular(24.r));
}

// ═══════════════════════════════════════════════════════════════════════════
// SHADOW SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class HoorShadows {
  HoorShadows._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get xs => [
        BoxShadow(
          color: HoorColors.primary.withValues(alpha: 0.04),
          blurRadius: 2.r,
          offset: Offset(0, 1.h),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: HoorColors.primary.withValues(alpha: 0.06),
          blurRadius: 6.r,
          offset: Offset(0, 2.h),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: HoorColors.primary.withValues(alpha: 0.08),
          blurRadius: 12.r,
          offset: Offset(0, 4.h),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: HoorColors.primary.withValues(alpha: 0.10),
          blurRadius: 20.r,
          offset: Offset(0, 8.h),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: HoorColors.primary.withValues(alpha: 0.12),
          blurRadius: 32.r,
          offset: Offset(0, 12.h),
        ),
      ];

  static List<BoxShadow> colored(Color color, {double opacity = 0.2}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 16.r,
          offset: Offset(0, 6.h),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
// DURATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class HoorDurations {
  HoorDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
}

// ═══════════════════════════════════════════════════════════════════════════
// ICON SIZES
// ═══════════════════════════════════════════════════════════════════════════

class HoorIconSize {
  HoorIconSize._();

  static const double xs = 14.0;
  static const double sm = 18.0;
  static const double md = 22.0;
  static const double lg = 26.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 56.0;
}
