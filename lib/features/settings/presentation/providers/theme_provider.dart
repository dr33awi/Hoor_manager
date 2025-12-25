import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';

/// مزود حالة الوضع الداكن
final isDarkModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

/// مزود وضع الثيم
final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(isDarkModeProvider);
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

/// مدير حالة الوضع الداكن
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(StorageService().getDarkMode());

  /// تبديل الوضع الداكن
  Future<void> toggle() async {
    state = !state;
    await StorageService().setDarkMode(state);
  }

  /// تعيين الوضع الداكن
  Future<void> setDarkMode(bool value) async {
    state = value;
    await StorageService().setDarkMode(value);
  }
}
