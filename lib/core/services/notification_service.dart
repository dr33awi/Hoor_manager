import 'package:flutter/material.dart';

/// خدمة الإشعارات داخل التطبيق
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// عرض إشعار SnackBar
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? Colors.red
          : isSuccess
              ? Colors.green
              : null,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// عرض إشعار نجاح
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message: message, isSuccess: true);
  }

  /// عرض إشعار خطأ
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message: message, isError: true);
  }

  /// عرض إشعار تحميل
  static void showLoading(BuildContext context, {String message = 'جاري التحميل...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// إخفاء إشعار التحميل
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
