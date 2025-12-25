import 'dart:async';
import 'package:flutter/material.dart';
import 'offline_service.dart';

/// خدمة مراقبة الاتصال بالشبكة
/// ملاحظة: تم دمج معظم الوظائف في OfflineService
/// هذه الخدمة تبقى للتوافق مع الكود القديم
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Stream لحالة الاتصال (يستخدم OfflineService)
  Stream<bool> get connectivityStream => OfflineService().connectivityStream;

  /// هل متصل بالإنترنت
  bool get isConnected => OfflineService().isOnline;

  /// تحديث حالة الاتصال
  @Deprecated('استخدم OfflineService مباشرة')
  void updateConnectivity(bool isConnected) {
    // لم يعد ضرورياً - OfflineService يتعامل مع هذا تلقائياً
  }

  /// عرض رسالة عدم الاتصال
  static void showNoConnectionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('لا يوجد اتصال بالإنترنت'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// عرض رسالة عدم الاتصال مع خيار إعادة المحاولة
  static void showNoConnectionWithRetry(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('لا يوجد اتصال بالإنترنت'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  /// التحقق من الاتصال وعرض رسالة إذا غير متصل
  static bool checkAndShowMessage(BuildContext context) {
    if (!OfflineService().isOnline) {
      showNoConnectionMessage(context);
      return false;
    }
    return true;
  }

  /// إغلاق الخدمة
  @Deprecated('استخدم OfflineService().dispose() بدلاً من ذلك')
  void dispose() {
    // لم يعد ضرورياً
  }
}

/// Extension للتعامل مع الاتصال بسهولة
extension ConnectivityExtension on BuildContext {
  /// هل متصل بالإنترنت
  bool get isOnline => OfflineService().isOnline;

  /// عرض رسالة عدم الاتصال
  void showNoConnectionMessage() {
    ConnectivityService.showNoConnectionMessage(this);
  }

  /// التحقق من الاتصال وعرض رسالة
  bool checkConnection() {
    return ConnectivityService.checkAndShowMessage(this);
  }
}

/// Mixin للتعامل مع الاتصال في الـ State
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<bool>? _connectivitySubscription;

  /// هل متصل
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// الاستماع لتغييرات الاتصال
  void listenToConnectivity({
    VoidCallback? onOnline,
    VoidCallback? onOffline,
  }) {
    _isOnline = OfflineService().isOnline;

    _connectivitySubscription = OfflineService().connectivityStream.listen(
      (isOnline) {
        if (mounted) {
          setState(() => _isOnline = isOnline);

          if (isOnline) {
            onOnline?.call();
          } else {
            onOffline?.call();
          }
        }
      },
    );
  }

  /// إلغاء الاستماع
  void cancelConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  @override
  void dispose() {
    cancelConnectivityListener();
    super.dispose();
  }
}
