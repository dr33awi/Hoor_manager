/// نتيجة العمليات - إما نجاح أو فشل
sealed class Result<T> {
  const Result();

  /// هل العملية ناجحة
  bool get isSuccess => this is Success<T>;

  /// هل العملية فاشلة
  bool get isFailure => this is Failure<T>;

  /// الحصول على القيمة إذا كانت ناجحة
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// الحصول على الخطأ إذا كانت فاشلة
  String? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final message) => message,
      };

  /// تنفيذ دالة حسب النتيجة
  R when<R>({
    required R Function(T value) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final message) => failure(message),
    };
  }

  /// تحويل القيمة
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Success(transform(value)),
      Failure<T>(:final message) => Failure(message),
    };
  }
}

/// نتيجة ناجحة
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// نتيجة فاشلة
final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Failure($message)';
}
