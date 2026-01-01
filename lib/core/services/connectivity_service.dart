import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Connection Quality - جودة الاتصال
/// ═══════════════════════════════════════════════════════════════════════════
enum ConnectionQuality {
  excellent, // اتصال ممتاز
  good, // اتصال جيد
  poor, // اتصال ضعيف
  offline, // غير متصل
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Connectivity Service - خدمة الاتصال المحسّنة
/// ═══════════════════════════════════════════════════════════════════════════
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectionQuality _quality = ConnectionQuality.excellent;
  ConnectionQuality get quality => _quality;

  ConnectivityResult _connectionType = ConnectivityResult.none;
  ConnectivityResult get connectionType => _connectionType;

  DateTime? _lastOnlineTime;
  DateTime? get lastOnlineTime => _lastOnlineTime;

  int _offlineDuration = 0; // بالثواني
  int get offlineDuration => _offlineDuration;

  Timer? _offlineTimer;
  Timer? _pingTimer;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // قائمة المستمعين لتغيير حالة الاتصال
  final List<Function(bool isOnline)> _onlineStatusListeners = [];

  ConnectivityService(this._connectivity);

  /// Initialize and start monitoring connectivity
  Future<void> initialize() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    await _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);

    // Start periodic connectivity check
    _startPeriodicCheck();
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;

    // تحديد نوع الاتصال
    if (results.contains(ConnectivityResult.wifi)) {
      _connectionType = ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _connectionType = ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _connectionType = ConnectivityResult.ethernet;
    } else {
      _connectionType = ConnectivityResult.none;
    }

    _isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    // التحقق الفعلي من الاتصال بالإنترنت
    if (_isOnline) {
      _isOnline = await _hasActualInternet();
    }

    if (_isOnline) {
      _lastOnlineTime = DateTime.now();
      _offlineDuration = 0;
      _stopOfflineTimer();
      _quality = await _checkConnectionQuality();
    } else {
      _quality = ConnectionQuality.offline;
      _startOfflineTimer();
    }

    if (wasOnline != _isOnline) {
      // إخطار المستمعين
      for (final listener in _onlineStatusListeners) {
        listener(_isOnline);
      }
      notifyListeners();
    }
  }

  /// التحقق الفعلي من الاتصال بالإنترنت
  Future<bool> _hasActualInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// فحص جودة الاتصال
  Future<ConnectionQuality> _checkConnectionQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (result.isEmpty) return ConnectionQuality.offline;

      final latency = stopwatch.elapsedMilliseconds;
      if (latency < 100) {
        return ConnectionQuality.excellent;
      } else if (latency < 300) {
        return ConnectionQuality.good;
      } else {
        return ConnectionQuality.poor;
      }
    } catch (e) {
      return ConnectionQuality.poor;
    }
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _offlineDuration++;
      notifyListeners();
    });
  }

  void _stopOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = null;
  }

  void _startPeriodicCheck() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await checkConnectivity();
    });
  }

  /// Check if currently online
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    await _updateStatus(results);
    return _isOnline;
  }

  /// إضافة مستمع لتغيير حالة الاتصال
  void addOnlineStatusListener(Function(bool isOnline) listener) {
    _onlineStatusListeners.add(listener);
  }

  /// إزالة مستمع
  void removeOnlineStatusListener(Function(bool isOnline) listener) {
    _onlineStatusListeners.remove(listener);
  }

  /// الحصول على وصف حالة الاتصال
  String getConnectionStatusText() {
    if (!_isOnline) {
      if (_offlineDuration > 0) {
        final minutes = _offlineDuration ~/ 60;
        final seconds = _offlineDuration % 60;
        return 'غير متصل منذ ${minutes > 0 ? "$minutes د " : ""}$seconds ث';
      }
      return 'غير متصل';
    }

    switch (_quality) {
      case ConnectionQuality.excellent:
        return 'اتصال ممتاز';
      case ConnectionQuality.good:
        return 'اتصال جيد';
      case ConnectionQuality.poor:
        return 'اتصال ضعيف';
      case ConnectionQuality.offline:
        return 'غير متصل';
    }
  }

  /// الحصول على نوع الاتصال كنص
  String getConnectionTypeText() {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'بيانات الجوال';
      case ConnectivityResult.ethernet:
        return 'إيثرنت';
      default:
        return 'غير متصل';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _offlineTimer?.cancel();
    _pingTimer?.cancel();
    _onlineStatusListeners.clear();
    super.dispose();
  }
}
