import 'package:flutter/material.dart';

/// إضافات على BuildContext للوصول السريع للثيم والأبعاد
extension BuildContextExtensions on BuildContext {
  // الثيم
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // الألوان
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get backgroundColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;

  // أبعاد الشاشة
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // التوجه
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;
  bool get isLTR => Directionality.of(this) == TextDirection.ltr;

  // حجم الشاشة
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 900;
  bool get isLargeScreen => screenWidth >= 900;

  // إظهار SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorColor : primaryColor,
      ),
    );
  }

  // إظهار Dialog
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) {
    return showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // إخفاء لوحة المفاتيح
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
