import 'dart:async';
import 'package:flutter/material.dart';

/// خدمة مراقبة الاتصال بالشبكة
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream لحالة الاتصال
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;

  /// هل متصل بالإنترنت
  bool get isConnected => _isConnected;

  /// تحديث حالة الاتصال
  void updateConnectivity(bool isConnected) {
    _isConnected = isConnected;
    _connectivityController.add(isConnected);
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// إغلاق الخدمة
  void dispose() {
    _connectivityController.close();
  }
}
