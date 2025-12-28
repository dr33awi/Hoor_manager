import '../../domain/entities/entities.dart';

/// حالة المصادقة
sealed class AuthState {
  const AuthState();
}

/// حالة التحميل الأولي
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// حالة التحميل
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// حالة المستخدم مسجل دخوله
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);
}

/// حالة المستخدم غير مسجل
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// حالة انتظار الموافقة
class AuthPendingApproval extends AuthState {
  final UserEntity user;

  const AuthPendingApproval(this.user);
}

/// حالة الخطأ
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
