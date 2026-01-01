import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';
import 'typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Manager - Professional App Theme
/// Modern, clean theme for enterprise accounting software
/// ═══════════════════════════════════════════════════════════════════════════

class HoorTheme {
  HoorTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.cairo().fontFamily,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: HoorColors.primary,
        onPrimary: HoorColors.textOnPrimary,
        primaryContainer: HoorColors.primarySoft,
        onPrimaryContainer: HoorColors.primary,
        secondary: HoorColors.accent,
        onSecondary: HoorColors.textOnAccent,
        secondaryContainer: HoorColors.accentLight,
        onSecondaryContainer: HoorColors.primary,
        surface: HoorColors.surface,
        onSurface: HoorColors.textPrimary,
        error: HoorColors.error,
        onError: Colors.white,
        outline: HoorColors.border,
        outlineVariant: HoorColors.borderLight,
      ),

      // Scaffold
      scaffoldBackgroundColor: HoorColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: HoorColors.surface,
        foregroundColor: HoorColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: HoorTypography.titleLarge.copyWith(
          color: HoorColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: HoorColors.textPrimary,
          size: HoorIconSize.md.w,
        ),
        actionsIconTheme: IconThemeData(
          color: HoorColors.textSecondary,
          size: HoorIconSize.md.w,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: HoorColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HoorRadius.cardRadius,
          side: BorderSide(color: HoorColors.border, width: 1.w),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HoorColors.primary,
          foregroundColor: HoorColors.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.xl.w,
            vertical: HoorSpacing.md.h,
          ),
          minimumSize: Size(88.w, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: HoorRadius.buttonRadius,
          ),
          textStyle: HoorTypography.buttonMedium,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HoorColors.primary,
          side: BorderSide(color: HoorColors.border, width: 1.5.w),
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.xl.w,
            vertical: HoorSpacing.md.h,
          ),
          minimumSize: Size(88.w, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: HoorRadius.buttonRadius,
          ),
          textStyle: HoorTypography.buttonMedium,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HoorColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md.w,
            vertical: HoorSpacing.sm.h,
          ),
          minimumSize: Size(64.w, 40.h),
          shape: RoundedRectangleBorder(
            borderRadius: HoorRadius.buttonRadius,
          ),
          textStyle: HoorTypography.buttonMedium,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: HoorColors.textSecondary,
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          minimumSize: Size(44.w, 44.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.md.r),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: HoorColors.primary,
        foregroundColor: HoorColors.textOnPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xl.r),
        ),
        extendedPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.xl.w,
          vertical: HoorSpacing.md.h,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoorColors.surface,
        hoverColor: HoorColors.surfaceHover,
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.md.w,
          vertical: HoorSpacing.md.h,
        ),
        border: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: const BorderSide(color: HoorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: const BorderSide(color: HoorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: BorderSide(color: HoorColors.primary, width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: const BorderSide(color: HoorColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: BorderSide(color: HoorColors.error, width: 2.w),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: HoorRadius.inputRadius,
          borderSide: const BorderSide(color: HoorColors.borderLight),
        ),
        labelStyle: HoorTypography.bodyMedium.copyWith(
          color: HoorColors.textSecondary,
        ),
        hintStyle: HoorTypography.bodyMedium.copyWith(
          color: HoorColors.textTertiary,
        ),
        errorStyle: HoorTypography.labelSmall.copyWith(
          color: HoorColors.error,
        ),
        helperStyle: HoorTypography.labelSmall.copyWith(
          color: HoorColors.textTertiary,
        ),
        prefixIconColor: HoorColors.textTertiary,
        suffixIconColor: HoorColors.textTertiary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: HoorColors.surfaceMuted,
        disabledColor: HoorColors.surfaceMuted.withValues(alpha: 0.5),
        selectedColor: HoorColors.primarySoft,
        secondarySelectedColor: HoorColors.accentLight,
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xxs.h,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: HoorSpacing.xs.w),
        labelStyle: HoorTypography.labelMedium,
        secondaryLabelStyle: HoorTypography.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: HoorRadius.chipRadius,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: HoorColors.surface,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xl.r),
        ),
        titleTextStyle: HoorTypography.titleLarge,
        contentTextStyle: HoorTypography.bodyMedium,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: HoorColors.surface,
        modalBackgroundColor: HoorColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: HoorRadius.sheetRadius,
        ),
        clipBehavior: Clip.antiAlias,
        dragHandleColor: HoorColors.border,
        dragHandleSize: Size(40.w, 4.h),
        showDragHandle: true,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HoorColors.primary,
        contentTextStyle: HoorTypography.bodyMedium.copyWith(
          color: HoorColors.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: HoorRadius.buttonRadius,
        ),
        elevation: 4,
        insetPadding: EdgeInsets.all(HoorSpacing.md.w),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: HoorColors.surface,
        selectedItemColor: HoorColors.primary,
        unselectedItemColor: HoorColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: HoorTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: HoorTypography.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HoorColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: HoorColors.primarySoft,
        elevation: 0,
        height: 72.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: HoorColors.primary,
              size: HoorIconSize.md.w,
            );
          }
          return IconThemeData(
            color: HoorColors.textTertiary,
            size: HoorIconSize.md.w,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorTypography.labelSmall.copyWith(
              color: HoorColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return HoorTypography.labelSmall.copyWith(
            color: HoorColors.textTertiary,
          );
        }),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: HoorColors.primary,
        unselectedLabelColor: HoorColors.textTertiary,
        labelStyle: HoorTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: HoorTypography.labelMedium,
        indicatorColor: HoorColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: HoorColors.border,
        overlayColor: WidgetStateProperty.all(
          HoorColors.primary.withValues(alpha: 0.08),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: HoorColors.divider,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.md.w,
          vertical: HoorSpacing.xs.h,
        ),
        titleTextStyle: HoorTypography.bodyMedium,
        subtitleTextStyle: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary,
        ),
        leadingAndTrailingTextStyle: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary,
        ),
        iconColor: HoorColors.textSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: HoorColors.primarySoft,
        selectedColor: HoorColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md.r),
        ),
        minLeadingWidth: 24.w,
        horizontalTitleGap: HoorSpacing.sm.w,
        dense: false,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primary;
          }
          return HoorColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primarySoft;
          }
          return HoorColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(HoorColors.textOnPrimary),
        side: BorderSide(color: HoorColors.border, width: 2.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xs.r),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primary;
          }
          return HoorColors.textTertiary;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HoorColors.primary,
        linearTrackColor: HoorColors.primarySoft,
        circularTrackColor: HoorColors.primarySoft,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: HoorColors.primary,
        inactiveTrackColor: HoorColors.primarySoft,
        thumbColor: HoorColors.primary,
        overlayColor: HoorColors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: HoorColors.primary,
        valueIndicatorTextStyle: HoorTypography.labelSmall.copyWith(
          color: HoorColors.textOnPrimary,
        ),
      ),

      // Badge
      badgeTheme: BadgeThemeData(
        backgroundColor: HoorColors.error,
        textColor: Colors.white,
        smallSize: 8.r,
        largeSize: 18.r,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
      ),

      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        color: HoorColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg.r),
        ),
        textStyle: HoorTypography.bodyMedium,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: HoorColors.primary,
          borderRadius: BorderRadius.circular(HoorRadius.sm.r),
        ),
        textStyle: HoorTypography.labelSmall.copyWith(
          color: HoorColors.textOnPrimary,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // Data Table
      dataTableTheme: DataTableThemeData(
        headingTextStyle: HoorTypography.labelMedium.copyWith(
          color: HoorColors.textSecondary,
        ),
        dataTextStyle: HoorTypography.bodyMedium,
        headingRowColor: WidgetStateProperty.all(HoorColors.surfaceMuted),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primarySoft;
          }
          if (states.contains(WidgetState.hovered)) {
            return HoorColors.surfaceHover;
          }
          return HoorColors.surface;
        }),
        dividerThickness: 1,
        horizontalMargin: HoorSpacing.md.w,
        columnSpacing: HoorSpacing.lg.w,
      ),

      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: HoorColors.surface,
        collapsedBackgroundColor: HoorColors.surface,
        iconColor: HoorColors.textSecondary,
        collapsedIconColor: HoorColors.textTertiary,
        tilePadding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
        childrenPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.md.w,
          vertical: HoorSpacing.sm.h,
        ),
      ),

      // Search Bar
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(HoorColors.surfaceMuted),
        elevation: WidgetStateProperty.all(0),
        overlayColor: WidgetStateProperty.all(HoorColors.primarySoft),
        textStyle: WidgetStateProperty.all(HoorTypography.bodyMedium),
        hintStyle: WidgetStateProperty.all(
          HoorTypography.bodyMedium.copyWith(color: HoorColors.textTertiary),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.lg.r),
          ),
        ),
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return HoorColors.primary;
            }
            return HoorColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return HoorColors.textOnPrimary;
            }
            return HoorColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: HoorColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md.r),
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: HoorSpacing.md.w,
              vertical: HoorSpacing.sm.h,
            ),
          ),
          textStyle: WidgetStateProperty.all(HoorTypography.labelMedium),
        ),
      ),

      // Date Picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: HoorColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: HoorColors.primary,
        headerForegroundColor: HoorColors.textOnPrimary,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.primary;
          }
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HoorColors.textOnPrimary;
          }
          return HoorColors.textPrimary;
        }),
        todayBackgroundColor: WidgetStateProperty.all(HoorColors.accentLight),
        todayForegroundColor: WidgetStateProperty.all(HoorColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xl.r),
        ),
      ),

      // Time Picker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: HoorColors.surface,
        dialBackgroundColor: HoorColors.surfaceMuted,
        dialHandColor: HoorColors.primary,
        hourMinuteColor: HoorColors.primarySoft,
        hourMinuteTextColor: HoorColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xl.r),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dark Theme (Future Implementation)
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    // TODO: Implement full dark theme
    return ThemeData.dark().copyWith(
      primaryColor: HoorColors.primary,
      colorScheme: ColorScheme.dark(
        primary: HoorColors.primary,
        secondary: HoorColors.accent,
      ),
    );
  }
}
