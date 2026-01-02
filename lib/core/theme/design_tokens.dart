// ═══════════════════════════════════════════════════════════════════════════
// Hoor Manager Pro - Design System 2026
// A professional, minimal design system for enterprise accounting software
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE - Professional & Trust-inspiring
// ═══════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // Primary Colors - Deep Navy (Trust & Professionalism)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color primarySoft = Color(0xFF334155);
  static const Color primaryMuted = Color(0xFF475569);

  // ─────────────────────────────────────────────────────────────────────────
  // Secondary Colors - Ocean Blue (Action & Clarity)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0284C7);
  static const Color secondaryMuted = Color(0xFFE0F2FE);

  // ─────────────────────────────────────────────────────────────────────────
  // Accent Colors - Warm Gold (Premium feel)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentMuted = Color(0xFFFEF3C7);

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic Colors - Financial Context
  // ─────────────────────────────────────────────────────────────────────────

  /// Income / Profit / Success - Green
  static const Color income = Color(0xFF10B981);
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color incomeDark = Color(0xFF059669);
  static const Color incomeSurface = Color(0xFFECFDF5);

  /// Expense / Loss / Error - Red
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color expenseDark = Color(0xFFDC2626);
  static const Color expenseSurface = Color(0xFFFEF2F2);

  // Aliases for common naming conventions
  static const Color success = income;
  static const Color successLight = incomeLight;
  static const Color error = expense;
  static const Color errorLight = expenseLight;

  /// Warning - Orange
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningSurface = Color(0xFFFFFBEB);

  /// Info - Blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoSurface = Color(0xFFEFF6FF);

  /// Neutral - Gray
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralLight = Color(0xFFE2E8F0);
  static const Color neutralSurface = Color(0xFFF8FAFC);

  // ─────────────────────────────────────────────────────────────────────────
  // Business-Specific Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Sales - Blue
  static const Color sales = Color(0xFF3B82F6);
  static const Color salesLight = Color(0xFFDBEAFE);

  /// Purchases - Purple
  static const Color purchases = Color(0xFF8B5CF6);
  static const Color purchasesLight = Color(0xFFEDE9FE);

  /// Inventory - Teal
  static const Color inventory = Color(0xFF14B8A6);
  static const Color inventoryLight = Color(0xFFCCFBF1);

  /// Customers - Cyan
  static const Color customers = Color(0xFF06B6D4);
  static const Color customersLight = Color(0xFFCFFAFE);

  /// Suppliers - Amber
  static const Color suppliers = Color(0xFFF59E0B);
  static const Color suppliersLight = Color(0xFFFEF3C7);

  /// Cash - Emerald
  static const Color cash = Color(0xFF10B981);
  static const Color cashLight = Color(0xFFD1FAE5);

  // ─────────────────────────────────────────────────────────────────────────
  // Surface & Background Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceHover = Color(0xFFF8FAFC);
  static const Color surfaceVariant =
      Color(0xFFF1F5F9); // For subtle backgrounds

  // ─────────────────────────────────────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF0EA5E9);

  // ─────────────────────────────────────────────────────────────────────────
  // Border & Divider Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocused = Color(0xFF0EA5E9);
  static const Color divider = Color(0xFFE2E8F0);

  // ─────────────────────────────────────────────────────────────────────────
  // Gradient Presets
  // ─────────────────────────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Dark Theme Colors
  // ─────────────────────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}

// ═══════════════════════════════════════════════════════════════════════════
// SPACING SYSTEM - 8-point grid
// ═══════════════════════════════════════════════════════════════════════════

class AppSpacing {
  AppSpacing._();

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

  // Semantic spacing
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  static const double sectionGap = 24.0;
  static const double listItemGap = 12.0;
  static const double buttonPadding = 16.0;
  static const double inputPadding = 16.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// RADIUS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;
  static const double full = 999.0;

  // Component-specific
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get cardLarge => BorderRadius.circular(xl);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get buttonPill => BorderRadius.circular(full);
  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get chip => BorderRadius.circular(full);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(24));
  static BorderRadius get dialog => BorderRadius.circular(xl);
  static BorderRadius get avatar => BorderRadius.circular(full);
}

// ═══════════════════════════════════════════════════════════════════════════
// SHADOW SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get xs => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.04),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Colored shadow for accent elements
  static List<BoxShadow> colored(Color color, {double opacity = 0.25}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  /// Glow effect for highlighted elements
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];

  /// Card shadow - subtle elevation
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating action button shadow
  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class AppTypography {
  AppTypography._();

  // Base font family
  static TextStyle get _baseStyle => GoogleFonts.cairo(
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  // Monospace for numbers
  static TextStyle get _monoStyle => GoogleFonts.jetBrainsMono(
        color: AppColors.textPrimary,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Display Styles - Hero sections
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
  // Headline Styles - Page titles
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
  // Title Styles - Cards & sections
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
  // Body Styles - General content
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
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Label Styles - Buttons & inputs
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get labelLarge => _baseStyle.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _baseStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => _baseStyle.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Money Styles - Financial amounts (Monospace)
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get moneyLarge => _monoStyle.copyWith(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get moneyMedium => _monoStyle.copyWith(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get moneySmall => _monoStyle.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Caption & Overline
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get caption => _baseStyle.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppColors.textTertiary,
      );

  static TextStyle get overline => _baseStyle.copyWith(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 1.0,
        color: AppColors.textTertiary,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// ICON SIZES
// ═══════════════════════════════════════════════════════════════════════════

class AppIconSize {
  AppIconSize._();

  static const double xxs = 12.0;
  static const double xs = 14.0;
  static const double sm = 18.0;
  static const double md = 22.0;
  static const double lg = 26.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 56.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION DURATIONS
// ═══════════════════════════════════════════════════════════════════════════

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 350); // Alias
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration slowest = Duration(milliseconds: 800);
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION CURVES
// ═══════════════════════════════════════════════════════════════════════════

class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.easeOutBack;
  static const Curve easeOut = Curves.easeOut; // Alias
  static const Curve easeIn = Curves.easeIn; // Alias
}

// ═══════════════════════════════════════════════════════════════════════════
// BREAKPOINTS
// ═══════════════════════════════════════════════════════════════════════════

class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600; // Mobile
  static const double medium = 840; // Tablet
  static const double expanded = 1200; // Desktop
  static const double large = 1600; // Large desktop

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact &&
      MediaQuery.sizeOf(context).width < medium;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium &&
      MediaQuery.sizeOf(context).width < expanded;

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}

// ═══════════════════════════════════════════════════════════════════════════
// COLOR EXTENSIONS - Common opacity patterns
// ═══════════════════════════════════════════════════════════════════════════

/// Extension on Color for common opacity variations
/// Replaces repetitive .withOpacity() calls with semantic names
extension ColorOpacity on Color {
  // ─────────────────────────────────────────────────────────────────────────
  // Surface/Background variants (light overlays)
  // ─────────────────────────────────────────────────────────────────────────

  /// Very subtle background (5% opacity) - hover states
  Color get subtle => withValues(alpha: 0.05);

  /// Soft background (10% opacity) - card backgrounds, badges
  Color get soft => withValues(alpha: 0.10);

  /// Muted background (15% opacity) - selected states
  Color get muted => withValues(alpha: 0.15);

  /// Light background (20% opacity) - emphasized backgrounds
  Color get light => withValues(alpha: 0.20);

  // ─────────────────────────────────────────────────────────────────────────
  // Border variants
  // ─────────────────────────────────────────────────────────────────────────

  /// Subtle border (20% opacity)
  Color get borderSubtle => withValues(alpha: 0.20);

  /// Normal border (30% opacity)
  Color get border => withValues(alpha: 0.30);

  /// Strong border (50% opacity)
  Color get borderStrong => withValues(alpha: 0.50);

  // ─────────────────────────────────────────────────────────────────────────
  // Overlay variants
  // ─────────────────────────────────────────────────────────────────────────

  /// Light overlay (40% opacity)
  Color get overlayLight => withValues(alpha: 0.40);

  /// Medium overlay (60% opacity) - backdrop
  Color get overlay => withValues(alpha: 0.60);

  /// Heavy overlay (80% opacity) - strong backdrop
  Color get overlayHeavy => withValues(alpha: 0.80);

  // ─────────────────────────────────────────────────────────────────────────
  // Text variants
  // ─────────────────────────────────────────────────────────────────────────

  /// Disabled text (40% opacity)
  Color get textDisabled => withValues(alpha: 0.40);

  /// Secondary text (60% opacity)
  Color get textSecondary => withValues(alpha: 0.60);

  /// Primary text (87% opacity) - Material standard
  Color get textPrimary => withValues(alpha: 0.87);

  // ─────────────────────────────────────────────────────────────────────────
  // Specific opacity levels
  // ─────────────────────────────────────────────────────────────────────────

  /// 8% opacity - very subtle
  Color get o8 => withValues(alpha: 0.08);

  /// 12% opacity
  Color get o12 => withValues(alpha: 0.12);

  /// 24% opacity
  Color get o24 => withValues(alpha: 0.24);

  /// 38% opacity - disabled
  Color get o38 => withValues(alpha: 0.38);

  /// 54% opacity - medium emphasis
  Color get o54 => withValues(alpha: 0.54);

  /// 70% opacity
  Color get o70 => withValues(alpha: 0.70);

  /// 87% opacity - high emphasis
  Color get o87 => withValues(alpha: 0.87);
}

// ═══════════════════════════════════════════════════════════════════════════
// APP COLOR UTILITIES - Pre-computed semantic colors
// ═══════════════════════════════════════════════════════════════════════════

/// Utility class for common color combinations
class AppColorUtils {
  AppColorUtils._();

  // ─────────────────────────────────────────────────────────────────────────
  // Primary variants
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary color with soft background
  static Color get primarySoft => AppColors.primary.soft;
  static Color get primaryMuted => AppColors.primary.muted;
  static Color get primaryBorder => AppColors.primary.border;

  // ─────────────────────────────────────────────────────────────────────────
  // Secondary variants
  // ─────────────────────────────────────────────────────────────────────────

  static Color get secondarySoft => AppColors.secondary.soft;
  static Color get secondaryMuted => AppColors.secondary.muted;
  static Color get secondaryBorder => AppColors.secondary.border;

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic variants
  // ─────────────────────────────────────────────────────────────────────────

  static Color get successSoft => AppColors.success.soft;
  static Color get errorSoft => AppColors.error.soft;
  static Color get warningSoft => AppColors.warning.soft;
  static Color get infoSoft => AppColors.info.soft;

  static Color get successBorder => AppColors.success.border;
  static Color get errorBorder => AppColors.error.border;
  static Color get warningBorder => AppColors.warning.border;
  static Color get infoBorder => AppColors.info.border;

  // ─────────────────────────────────────────────────────────────────────────
  // Business domain variants
  // ─────────────────────────────────────────────────────────────────────────

  static Color get salesSoft => AppColors.sales.soft;
  static Color get purchasesSoft => AppColors.purchases.soft;
  static Color get inventorySoft => AppColors.inventory.soft;
  static Color get customersSoft => AppColors.customers.soft;
  static Color get suppliersSoft => AppColors.suppliers.soft;
  static Color get incomeSoft => AppColors.income.soft;
  static Color get expenseSoft => AppColors.expense.soft;
  static Color get cashSoft => AppColors.cash.soft;

  // ─────────────────────────────────────────────────────────────────────────
  // Common overlays
  // ─────────────────────────────────────────────────────────────────────────

  static Color get blackOverlay => Colors.black.overlay;
  static Color get whiteOverlay => Colors.white.overlayHeavy;
  static Color get scrim => Colors.black.o54;
}
