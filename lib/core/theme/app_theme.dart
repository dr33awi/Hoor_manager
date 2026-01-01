import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'redesign/design_tokens.dart';

// Re-export design system tokens for backward compatibility
export 'redesign/design_tokens.dart';
export 'redesign/typography.dart';
export 'redesign/app_theme.dart' show HoorTheme;

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HoorColors.primary,
        secondary: HoorColors.accent,
        surface: HoorColors.surface,
        brightness: Brightness.light,
        error: HoorColors.error,
      ),
      primaryColor: HoorColors.primary,
      scaffoldBackgroundColor: HoorColors.background,

      // Typography
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: HoorColors.textPrimary,
        displayColor: HoorColors.textPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: HoorColors.surface,
        foregroundColor: HoorColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: HoorColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: HoorColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: HoorColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HoorColors.border),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HoorColors.primary,
          foregroundColor: HoorColors.accent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HoorColors.primary,
          side: const BorderSide(color: HoorColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoorColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HoorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HoorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HoorColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HoorColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: HoorColors.textSecondary),
        hintStyle: const TextStyle(color: HoorColors.textTertiary),
      ),

      // Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HoorColors.surface,
        selectedItemColor: HoorColors.primary,
        unselectedItemColor: HoorColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HoorColors.primary,
        foregroundColor: HoorColors.accent,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: HoorColors.divider,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    // Keeping dark theme minimal for now, focusing on light theme redesign
    return ThemeData.dark().copyWith(
      primaryColor: HoorColors.primary,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    );
  }
}
