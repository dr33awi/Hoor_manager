// ═══════════════════════════════════════════════════════════════════════════
// Hoor Manager Pro - App Theme Configuration
// Material 3 Theme with custom design tokens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.cairo().fontFamily,

      // ─────────────────────────────────────────────────────────────────────
      // Color Scheme
      // ─────────────────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.secondaryMuted,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnSecondary,
        secondaryContainer: AppColors.secondaryMuted,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: AppColors.accentMuted,
        onTertiaryContainer: AppColors.accent,
        error: AppColors.expense,
        onError: Colors.white,
        errorContainer: AppColors.expenseLight,
        onErrorContainer: AppColors.expenseDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceMuted,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        shadow: AppColors.primary,
        scrim: AppColors.primary,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Scaffold
      // ─────────────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ─────────────────────────────────────────────────────────────────────
      // AppBar Theme
      // ─────────────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppIconSize.md,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: AppIconSize.md,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Card Theme
      // ─────────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Elevated Button Theme
      // ─────────────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w,
            vertical: AppSpacing.md.h,
          ),
          minimumSize: Size(88.w, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Filled Button Theme (Primary action)
      // ─────────────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnSecondary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w,
            vertical: AppSpacing.md.h,
          ),
          minimumSize: Size(88.w, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Outlined Button Theme
      // ─────────────────────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w,
            vertical: AppSpacing.md.h,
          ),
          minimumSize: Size(88.w, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Text Button Theme
      // ─────────────────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.sm.h,
          ),
          textStyle: AppTypography.labelMedium,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Floating Action Button Theme
      // ─────────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        extendedTextStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.textOnSecondary,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Input Decoration Theme
      // ─────────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.md.h,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expense, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.expense,
        ),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Chip Theme
      // ─────────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.secondaryMuted,
        disabledColor: AppColors.surfaceMuted,
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.secondary,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xs.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
          side: const BorderSide(color: AppColors.border),
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Bottom Navigation Bar Theme
      // ─────────────────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Navigation Bar Theme (Material 3)
      // ─────────────────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.secondaryMuted,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.secondary,
              size: AppIconSize.md,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,
            size: AppIconSize.md,
          );
        }),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Navigation Rail Theme
      // ─────────────────────────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.secondaryMuted,
        selectedIconTheme: const IconThemeData(
          color: AppColors.secondary,
          size: AppIconSize.md,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textTertiary,
          size: AppIconSize.md,
        ),
        selectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Tab Bar Theme
      // ─────────────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.secondary,
            width: 2.w,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Dialog Theme
      // ─────────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Bottom Sheet Theme
      // ─────────────────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
        ),
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(40.w, 4.h),
        showDragHandle: true,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Snackbar Theme
      // ─────────────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // List Tile Theme
      // ─────────────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.xs.h,
        ),
        minVerticalPadding: AppSpacing.sm.h,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.textSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.secondaryMuted,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Divider Theme
      // ─────────────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppSpacing.md.h,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Progress Indicator Theme
      // ─────────────────────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: AppColors.secondaryMuted,
        circularTrackColor: AppColors.secondaryMuted,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Switch Theme
      // ─────────────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textOnSecondary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return AppColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Checkbox Theme
      // ─────────────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnSecondary),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Radio Theme
      // ─────────────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return AppColors.border;
        }),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Tooltip Theme
      // ─────────────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textOnPrimary,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xs.h,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Badge Theme
      // ─────────────────────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.expense,
        textColor: AppColors.textOnPrimary,
        textStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontSize: 10.sp,
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Search Bar Theme
      // ─────────────────────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceMuted),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: AppRadius.input,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.bodyMedium),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Popup Menu Theme
      // ─────────────────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: AppTypography.bodyMedium,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Date Picker Theme
      // ─────────────────────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.textOnPrimary,
        dayStyle: AppTypography.bodyMedium,
        yearStyle: AppTypography.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Time Picker Theme
      // ─────────────────────────────────────────────────────────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteColor: AppColors.surfaceMuted,
        hourMinuteTextColor: AppColors.textPrimary,
        dialHandColor: AppColors.secondary,
        dialBackgroundColor: AppColors.surfaceMuted,
        entryModeIconColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Extensions
      // ─────────────────────────────────────────────────────────────────────
      extensions: const [
        AppThemeExtension.light,
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark {
    return light.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.expense,
        onError: Colors.white,
        outline: AppColors.darkBorder,
      ),
      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: light.cardTheme.copyWith(
        color: AppColors.darkSurface,
      ),
      bottomSheetTheme: light.bottomSheetTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
      ),
      dialogTheme: light.dialogTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
      ),
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurfaceElevated,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      navigationBarTheme: light.navigationBarTheme.copyWith(
        backgroundColor: AppColors.darkSurface,
      ),
      dividerTheme: light.dividerTheme.copyWith(
        color: AppColors.darkBorder,
      ),
      extensions: const [
        AppThemeExtension.dark,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME EXTENSION - Custom theme properties
// ═══════════════════════════════════════════════════════════════════════════

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.income,
    required this.incomeLight,
    required this.expense,
    required this.expenseLight,
    required this.warning,
    required this.warningLight,
    required this.cardShadow,
  });

  final Color income;
  final Color incomeLight;
  final Color expense;
  final Color expenseLight;
  final Color warning;
  final Color warningLight;
  final List<BoxShadow> cardShadow;

  static const light = AppThemeExtension(
    income: AppColors.income,
    incomeLight: AppColors.incomeLight,
    expense: AppColors.expense,
    expenseLight: AppColors.expenseLight,
    warning: AppColors.warning,
    warningLight: AppColors.warningLight,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const dark = AppThemeExtension(
    income: AppColors.income,
    incomeLight: Color(0xFF064E3B),
    expense: AppColors.expense,
    expenseLight: Color(0xFF7F1D1D),
    warning: AppColors.warning,
    warningLight: Color(0xFF78350F),
    cardShadow: [],
  );

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? income,
    Color? incomeLight,
    Color? expense,
    Color? expenseLight,
    Color? warning,
    Color? warningLight,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeExtension(
      income: income ?? this.income,
      incomeLight: incomeLight ?? this.incomeLight,
      expense: expense ?? this.expense,
      expenseLight: expenseLight ?? this.expenseLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      income: Color.lerp(income, other.income, t)!,
      incomeLight: Color.lerp(incomeLight, other.incomeLight, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseLight: Color.lerp(expenseLight, other.expenseLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME HELPERS
// ═══════════════════════════════════════════════════════════════════════════

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  AppThemeExtension get appColors => theme.extension<AppThemeExtension>()!;

  bool get isDarkMode => theme.brightness == Brightness.dark;
}
