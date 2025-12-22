// lib/features/auth/providers/auth_provider.dart
// مزود حالة المصادقة

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/logger_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  bool _needsEmailVerification = false;
  String? _pendingVerificationEmail;
  String? _pendingVerificationPassword;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get userId => _user?.id;
  String? get userName => _user?.name;
  String? get userPhoto => _user?.photoUrl;
  String? get authProvider => _user?.authProvider;
  bool get isGoogleUser => _user?.authProvider == 'google';
  bool get needsEmailVerification => _needsEmailVerification;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  AuthProvider() {
    _init();
  }

  /// تهيئة المزود
  Future<void> _init() async {
    AppLogger.startOperation('تهيئة AuthProvider');
    _isLoading = true;
    notifyListeners();

    // تهيئة Firebase
    await _firebaseService.initialize();

    // الاستماع لتغييرات حالة المصادقة
    _authService.authStateChanges.listen(_onAuthStateChanged);
    AppLogger.endOperation('تهيئة AuthProvider');
  }

  /// معالجة تغيير حالة المصادقة
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // التحقق من البريد الإلكتروني
    if (!firebaseUser.emailVerified &&
        firebaseUser.providerData.any((p) => p.providerId == 'password')) {
      _needsEmailVerification = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // جلب بيانات المستخدم
    final result = await _authService.loadCurrentUser();
    if (result.success) {
      _user = result.data;
      _needsEmailVerification = false;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// تسجيل الدخول بالإيميل
  Future<bool> signInWithEmail(String email, String password) async {
    AppLogger.userAction(
      'محاولة تسجيل دخول بالإيميل',
      details: {'email': email},
    );
    _isLoading = true;
    _error = null;
    _errorCode = null;
    _needsEmailVerification = false;
    notifyListeners();

    final result = await _authService.signInWithEmail(email, password);

    if (result.success) {
      _user = result.data;
      _error = null;
      _errorCode = null;
      _needsEmailVerification = false;
      AppLogger.i('✅ تم تسجيل الدخول بنجاح: ${_user?.name}');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;

      // إذا كان البريد غير مُفعّل
      if (result.errorCode == 'email-not-verified') {
        _needsEmailVerification = true;
        _pendingVerificationEmail = email;
        _pendingVerificationPassword = password;
      }

      AppLogger.w('❌ فشل تسجيل الدخول', error: result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  /// تسجيل الدخول بـ Google
  Future<bool> signInWithGoogle() async {
    AppLogger.userAction('محاولة تسجيل دخول بـ Google');
    _isLoading = true;
    _error = null;
    _errorCode = null;
    _needsEmailVerification = false;
    notifyListeners();

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      _user = result.data;
      _error = null;
      _errorCode = null;
      _needsEmailVerification = false;
      AppLogger.i('✅ تم تسجيل الدخول بـ Google بنجاح: ${_user?.name}');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;

      // حفظ البريد للحسابات الجديدة المعلقة
      if (result.errorCode == 'account-pending-new' ||
          result.errorCode == 'account-pending') {
        // سنحتاج للبريد لعرضه في شاشة الانتظار
        _pendingVerificationEmail = result.error?.contains('@') == true
            ? result.error
            : null;
      }

      AppLogger.w('❌ فشل تسجيل الدخول بـ Google', error: result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  /// إنشاء حساب جديد بالإيميل
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    AppLogger.userAction('إنشاء حساب جديد', details: {'email': email});
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );

    if (result.success) {
      _error = null;
      // لن يتم تسجيل الدخول - يحتاج لتفعيل البريد
      _pendingVerificationEmail = email;
      _pendingVerificationPassword = password;
      AppLogger.i('✅ تم إنشاء الحساب - بانتظار تفعيل البريد');
    } else {
      _error = result.error;
      AppLogger.w('❌ فشل إنشاء الحساب', error: result.error);
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  /// إعادة إرسال رابط التحقق
  Future<bool> resendVerificationEmail() async {
    if (_pendingVerificationEmail == null ||
        _pendingVerificationPassword == null) {
      _error = 'لا توجد بيانات للتحقق';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.sendVerificationEmailToUser(
      _pendingVerificationEmail!,
      _pendingVerificationPassword!,
    );

    _isLoading = false;

    if (!result.success) {
      _error = result.error;
    }

    notifyListeners();
    return result.success;
  }

  /// التحقق من حالة تفعيل البريد وإعادة تسجيل الدخول
  Future<bool> checkVerificationAndLogin() async {
    if (_pendingVerificationEmail == null ||
        _pendingVerificationPassword == null) {
      _error = 'لا توجد بيانات للتحقق';
      notifyListeners();
      return false;
    }

    // محاولة تسجيل الدخول مرة أخرى
    return signInWithEmail(
      _pendingVerificationEmail!,
      _pendingVerificationPassword!,
    );
  }

  /// تسجيل الدخول (للتوافق مع الكود القديم)
  Future<bool> signIn(String email, String password) async {
    return signInWithEmail(email, password);
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    AppLogger.userAction('تسجيل خروج', details: {'user': _user?.name});
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _needsEmailVerification = false;
    _pendingVerificationEmail = null;
    _pendingVerificationPassword = null;

    AppLogger.i('✅ تم تسجيل الخروج');
    _isLoading = false;
    notifyListeners();
  }

  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    _error = null;
    final result = await _authService.resetPassword(email);

    if (!result.success) {
      _error = result.error;
    }

    notifyListeners();
    return result.success;
  }

  /// تغيير كلمة المرور
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _error = null;
    final result = await _authService.changePassword(
      currentPassword,
      newPassword,
    );

    if (!result.success) {
      _error = result.error;
    }

    notifyListeners();
    return result.success;
  }

  /// إنشاء مستخدم جديد (للمدير فقط)
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    String role = 'employee',
  }) async {
    if (!isAdmin) {
      _error = 'غير مصرح لك بهذه العملية';
      notifyListeners();
      return false;
    }

    _error = null;
    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );

    if (!result.success) {
      _error = result.error;
    }

    notifyListeners();
    return result.success;
  }

  /// تحديث اسم المستخدم
  Future<bool> updateUserName(String name) async {
    _error = null;
    final result = await _authService.updateUserName(name);

    if (result.success) {
      _user = _user?.copyWith(name: name);
    } else {
      _error = result.error;
    }

    notifyListeners();
    return result.success;
  }

  /// مسح حالة انتظار التحقق
  void clearVerificationState() {
    _needsEmailVerification = false;
    _pendingVerificationEmail = null;
    _pendingVerificationPassword = null;
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}
