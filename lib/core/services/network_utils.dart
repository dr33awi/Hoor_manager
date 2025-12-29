import 'connectivity_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Network Utils - أدوات الشبكة الموحدة
/// ═══════════════════════════════════════════════════════════════════════════

/// استثناء عدم وجود اتصال
class NoConnectionException implements Exception {
  final String message;

  const NoConnectionException([this.message = 'لا يوجد اتصال بالإنترنت']);

  @override
  String toString() => message;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Network Required Wrapper - غلاف للعمليات التي تتطلب اتصال
/// ═══════════════════════════════════════════════════════════════════════════
class NetworkRequired {
  final ConnectivityService _connectivity;

  const NetworkRequired(this._connectivity);

  /// تنفيذ عملية تتطلب اتصال
  /// يرمي [NoConnectionException] إذا لم يكن هناك اتصال
  Future<T> run<T>(Future<T> Function() operation) async {
    if (!_connectivity.isOnline) {
      throw const NoConnectionException();
    }
    return operation();
  }

  /// تنفيذ عملية تتطلب اتصال مع رسالة خطأ مخصصة
  Future<T> runWithMessage<T>(
    Future<T> Function() operation, {
    required String offlineMessage,
  }) async {
    if (!_connectivity.isOnline) {
      throw NoConnectionException(offlineMessage);
    }
    return operation();
  }

  /// تنفيذ عملية مع fallback للـ offline
  Future<T> runWithFallback<T>(
    Future<T> Function() onlineOperation,
    T Function() offlineFallback,
  ) async {
    if (_connectivity.isOnline) {
      return onlineOperation();
    }
    return offlineFallback();
  }

  /// تنفيذ عملية اختياريًا (فقط إذا كان هناك اتصال)
  Future<T?> runOptional<T>(Future<T> Function() operation) async {
    if (!_connectivity.isOnline) {
      return null;
    }
    return operation();
  }

  /// التحقق من الاتصال فقط
  void requireConnection() {
    if (!_connectivity.isOnline) {
      throw const NoConnectionException();
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Extension على ConnectivityService
/// ═══════════════════════════════════════════════════════════════════════════
extension ConnectivityExtension on ConnectivityService {
  /// تنفيذ عملية تتطلب اتصال
  Future<T> requireOnline<T>(Future<T> Function() operation) async {
    if (!isOnline) {
      throw const NoConnectionException();
    }
    return operation();
  }

  /// تنفيذ مع fallback
  Future<T> withFallback<T>(
    Future<T> Function() onlineOperation,
    T Function() offlineFallback,
  ) async {
    if (isOnline) {
      return onlineOperation();
    }
    return offlineFallback();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Retry Mechanism - آلية إعادة المحاولة
/// ═══════════════════════════════════════════════════════════════════════════
class RetryConfig {
  final int maxAttempts;
  final Duration delay;
  final bool exponentialBackoff;

  const RetryConfig({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
    this.exponentialBackoff = true,
  });
}

class NetworkRetry {
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(Exception)? shouldRetry,
  }) async {
    Exception? lastException;

    for (var attempt = 0; attempt < config.maxAttempts; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // التحقق مما إذا كان يجب إعادة المحاولة
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // لا نعيد المحاولة في المحاولة الأخيرة
        if (attempt == config.maxAttempts - 1) {
          rethrow;
        }

        // حساب التأخير
        final delay = config.exponentialBackoff
            ? config.delay * (1 << attempt) // 1s, 2s, 4s, ...
            : config.delay;

        await Future.delayed(delay);
      }
    }

    throw lastException!;
  }
}
