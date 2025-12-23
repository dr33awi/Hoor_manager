// lib/features/auth/providers/auth_provider.dart
// مزود المصادقة المحسن - مع إدارة حالة أفضل ومعالجة أخطاء موحدة

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoor_manager/core/services/auth_service.dart';
import '../../../core/services/logger_service.dart';
import '../models/user_model.dart';

/// حالات المصادقة
enum AuthState {
  initial, // الحالة الأولية
  loading, // جاري التحميل
  authenticated, // مصادق
  unauthenticated, // غير مصادق
  needsEmailVerification, // يحتاج تفعيل الإيميل
  pendingApproval, // ينتظر موافقة المدير
  rejected, // مرفوض
  disabled, // معطل
  error, // خطأ
}

/// نموذج معلومات الخطأ
class AuthError {
  final String message;
  final AuthErrorType type;
  final String? code;
  final bool canRetry;
  final bool requiresAction;

  const AuthError({
    required this.message,
    required this.type,
    this.code,
    this.canRetry = true,
    this.requiresAction = false,
  });

  /// هل يجب إظهار dialog بدلاً من snackbar؟
  bool get showAsDialog =>
      type == AuthErrorType.accountPending ||
      type == AuthErrorType.accountRejected ||
      type == AuthErrorType.accountDisabled;

  /// الأيقونة المناسبة للخطأ
  String get icon {
    switch (type) {
      case AuthErrorType.emailNotVerified:
        return '📧';
      case AuthErrorType.accountPending:
        return '⏳';
      case AuthErrorType.accountRejected:
        return '❌';
      case AuthErrorType.accountDisabled:
        return '🚫';
      case AuthErrorType.networkError:
        return '🌐';
      case AuthErrorType.tooManyRequests:
        return '⏱️';
      default:
        return '⚠️';
    }
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // الحالة - تم تغييرها من initial إلى loading لمنع ظهور شاشة تسجيل الدخول مؤقتاً
  AuthState _state = AuthState.loading;
  UserModel? _currentUser;
  AuthError? _lastError;
  String? _pendingEmail;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  AuthState get state => _state;
  UserModel? get currentUser => _currentUser;
  AuthError? get lastError => _lastError;
  String? get pendingEmail => _pendingEmail;
  bool get isLoading => _state == AuthState.loading;

  bool get isAuthenticated =>
      _state == AuthState.authenticated && _currentUser != null;

  bool get needsEmailVerification => _state == AuthState.needsEmailVerification;
  bool get isPendingApproval => _state == AuthState.pendingApproval;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get userName => _currentUser?.name;
  String? get userPhoto => _currentUser?.photoUrl;
  bool get isGoogleUser => _currentUser?.isGoogleUser ?? false;

  // للتوافق مع الكود القديم
  String? get error => _lastError?.message;
  String? get errorCode => _lastError?.code;
  bool get needsEmailVerificationLegacy =>
      _state == AuthState.needsEmailVerification;
  String? get pendingVerificationEmail => _pendingEmail;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _firebaseAuth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      _authService.setCurrentUser(null);
      if (_state != AuthState.needsEmailVerification &&
          _state != AuthState.pendingApproval) {
        _state = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // استخدام الدالة الجديدة التي تدعم الأوفلاين
      final result = await _authService.getUserDataWithOfflineSupport(uid);

      if (result.success && result.data != null) {
        _currentUser = result.data;
        _authService.setCurrentUser(_currentUser);

        // تحديد الحالة بناءً على بيانات المستخدم
        final status = _currentUser!.status;

        // إذا لم يكن هناك status أو كان approved/active
        if (status == null || status == 'approved' || status == 'active') {
          if (!_currentUser!.isActive) {
            _state = AuthState.disabled;
          } else {
            _state = AuthState.authenticated;
          }
        } else if (status == 'pending') {
          _state = AuthState.pendingApproval;
        } else if (status == 'rejected') {
          _state = AuthState.rejected;
        } else {
          // أي حالة أخرى نعتبرها authenticated
          _state = AuthState.authenticated;
        }

        AppLogger.d('✅ تم تحميل بيانات المستخدم: ${_currentUser!.name}');
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      AppLogger.e('خطأ في تحميل بيانات المستخدم', error: e);

      // محاولة استخدام البيانات المحلية في حالة الخطأ
      final cachedUser = await _authService.getCachedUserData();
      if (cachedUser != null && cachedUser.id == uid) {
        _currentUser = cachedUser;
        _authService.setCurrentUser(_currentUser);
        _state = AuthState.authenticated;
        AppLogger.i('📱 تم استخدام البيانات المحلية');
      } else {
        _state = AuthState.error;
      }
    }
  }

  /// ==================== تسجيل الدخول بالإيميل ====================
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading();

    final result = await _authService.signInWithEmail(email, password);

    AppLogger.d('📧 signInWithEmail result: success=${result.success}');
    AppLogger.d('📧 result.errorMessage: ${result.errorMessage}');
    AppLogger.d('📧 result.errorType: ${result.errorType}');

    if (result.success) {
      _currentUser = result.data;
      _state = AuthState.authenticated;
      _clearError();
      notifyListeners();
      return true;
    }

    // معالجة الخطأ
    AppLogger.d('📧 Calling _handleAuthError...');
    _handleAuthError(result, email);
    AppLogger.d('📧 After _handleAuthError, lastError: $_lastError');
    return false;
  }

  /// ==================== تسجيل الدخول بـ Google ====================
  Future<bool> signInWithGoogle() async {
    _setLoading();

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      _currentUser = result.data;
      _state = AuthState.authenticated;
      _clearError();
      notifyListeners();
      return true;
    }

    // معالجة الخطأ
    _handleAuthError(result, null);
    return false;
  }

  /// ==================== إنشاء حساب جديد ====================
  Future<bool> signUp(String email, String password, String name) async {
    return signUpWithEmail(email, password, name);
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _setLoading();

    final result = await _authService.signUp(email, password, name);

    if (result.success) {
      _pendingEmail = email;
      _state = AuthState.needsEmailVerification;
      _clearError();
      notifyListeners();
      return true;
    }

    _handleAuthError(result, email);
    return false;
  }

  /// ==================== إعادة إرسال رابط التحقق ====================
  Future<bool> resendVerificationEmail() async {
    final result = await _authService.resendVerificationEmail();

    if (!result.success) {
      _lastError = AuthError(
        message: result.errorMessage ?? 'حدث خطأ',
        type: result.errorType ?? AuthErrorType.unknown,
        code: result.errorCode,
      );
      notifyListeners();
    }

    return result.success;
  }

  /// ==================== التحقق من تفعيل الإيميل ====================
  Future<bool> checkEmailVerificationOnly() async {
    final result = await _authService.checkEmailVerification();
    return result.success && result.data == true;
  }

  Future<bool> checkVerificationAndLogin() async {
    _setLoading();

    final result = await _authService.checkEmailVerification();

    if (result.success && result.data == true) {
      // الإيميل مفعل - تحميل بيانات المستخدم
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);

        if (_currentUser != null && _currentUser!.isApproved) {
          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }
      }

      // الإيميل مفعل لكن الحساب يحتاج موافقة
      _state = AuthState.pendingApproval;
      notifyListeners();
      return true;
    }

    _state = AuthState.needsEmailVerification;
    notifyListeners();
    return false;
  }

  /// ==================== تسجيل الخروج ====================
  Future<void> signOut() async {
    _setLoading();
    await _authService.signOut();
    await _authService.clearCachedUserData(); // مسح البيانات المحلية
    _currentUser = null;
    _state = AuthState.unauthenticated;
    _clearError();
    _pendingEmail = null;
    notifyListeners();
  }

  /// تسجيل الخروج بعد تفعيل الإيميل (للانتقال لشاشة الانتظار)
  Future<void> signOutAfterVerification() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _state = AuthState.pendingApproval;
    notifyListeners();
  }

  /// ==================== إعادة تعيين كلمة المرور ====================
  Future<bool> resetPassword(String email) async {
    _setLoading();

    final result = await _authService.resetPassword(email);

    _state = AuthState.unauthenticated;

    if (!result.success) {
      _lastError = AuthError(
        message: result.errorMessage ?? 'حدث خطأ',
        type: result.errorType ?? AuthErrorType.unknown,
        code: result.errorCode,
      );
    }

    notifyListeners();
    return result.success;
  }

  /// ==================== التحقق من حالة المصادقة ====================
  Future<void> checkAuthStatus() async {
    _setLoading();

    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// ==================== دوال مساعدة ====================

  void _setLoading() {
    _state = AuthState.loading;
    _clearError();
    // لا نستدعي notifyListeners هنا لأن الـ UI يدير الـ loading state محلياً
  }

  void _clearError() {
    _lastError = null;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearVerificationState() {
    _pendingEmail = null;
    if (_state == AuthState.needsEmailVerification ||
        _state == AuthState.pendingApproval) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  void _handleAuthError<T>(AuthResult<T> result, String? email) {
    _pendingEmail = email;

    // تحديد الحالة بناءً على نوع الخطأ
    switch (result.errorType) {
      case AuthErrorType.emailNotVerified:
        _state = AuthState.needsEmailVerification;
        break;
      case AuthErrorType.accountPending:
        _state = AuthState.pendingApproval;
        break;
      case AuthErrorType.accountRejected:
        _state = AuthState.rejected;
        break;
      case AuthErrorType.accountDisabled:
        _state = AuthState.disabled;
        break;
      case AuthErrorType.operationCancelled:
        _state = AuthState.unauthenticated;
        break;
      default:
        // للأخطاء العادية (مثل كلمة مرور خاطئة)، نبقى في حالة unauthenticated
        // حتى لا يُعاد بناء الـ UI
        _state = AuthState.unauthenticated;
    }

    _lastError = AuthError(
      message: result.errorMessage ?? 'حدث خطأ',
      type: result.errorType ?? AuthErrorType.unknown,
      code: result.errorCode,
      canRetry:
          result.errorType != AuthErrorType.accountRejected &&
          result.errorType != AuthErrorType.accountDisabled,
      requiresAction:
          result.errorType == AuthErrorType.emailNotVerified ||
          result.errorType == AuthErrorType.accountPending,
    );

    // لا نستدعي notifyListeners للأخطاء البسيطة حتى لا يُعاد بناء الـ UI
    // الـ UI سيقرأ lastError مباشرة
    if (result.errorType == AuthErrorType.emailNotVerified ||
        result.errorType == AuthErrorType.accountPending ||
        result.errorType == AuthErrorType.accountRejected ||
        result.errorType == AuthErrorType.accountDisabled) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
