// lib/features/auth/providers/auth_provider.dart
// مزود حالة المصادقة - مُصحح ومحسن

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/logger_service.dart';

/// ✅ كلاس لتخزين بيانات التحقق المؤقتة بشكل آمن
class _PendingVerification {
  final String email;
  String? _password;
  final DateTime createdAt;

  _PendingVerification({required this.email, String? password})
    : _password = password,
      createdAt = DateTime.now();

  String? get password => _password;

  /// ✅ مسح كلمة المرور من الذاكرة
  void clearPassword() {
    _password = null;
  }

  /// ✅ التحقق من انتهاء صلاحية البيانات (30 دقيقة)
  bool get isExpired =>
      DateTime.now().difference(createdAt) > const Duration(minutes: 30);
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  bool _needsEmailVerification = false;

  // ✅ استخدام كلاس آمن بدلاً من تخزين كلمة المرور مباشرة
  _PendingVerification? _pendingVerification;

  // ✅ إضافة StreamSubscription للتنظيف الصحيح
  StreamSubscription<User?>? _authStateSubscription;

  // ✅ إضافة debounce لتجنب Race Conditions
  Timer? _debounceTimer;
  bool _isProcessingAuthChange = false;

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
  String? get pendingVerificationEmail => _pendingVerification?.email;

  // ✅ التحقق من وجود بيانات تحقق صالحة
  bool get hasPendingVerification =>
      _pendingVerification != null &&
      !_pendingVerification!.isExpired &&
      _pendingVerification!.password != null;

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

    // ✅ الاستماع لتغييرات حالة المصادقة مع حفظ الـ subscription
    _authStateSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error) {
        AppLogger.e('خطأ في stream المصادقة', error: error);
        _isLoading = false;
        _error = 'حدث خطأ في المصادقة';
        notifyListeners();
      },
    );

    AppLogger.endOperation('تهيئة AuthProvider');
  }

  /// معالجة تغيير حالة المصادقة مع debounce
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // ✅ منع المعالجة المتزامنة
    if (_isProcessingAuthChange) {
      AppLogger.d('تجاهل تغيير المصادقة - المعالجة جارية');
      return;
    }

    // ✅ إلغاء أي timer سابق
    _debounceTimer?.cancel();

    // ✅ debounce لتجنب الاستدعاءات المتكررة
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _processAuthStateChange(firebaseUser);
    });
  }

  Future<void> _processAuthStateChange(User? firebaseUser) async {
    _isProcessingAuthChange = true;

    try {
      AppLogger.d('Auth state changed: ${firebaseUser?.email ?? "null"}');

      if (firebaseUser == null) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // التحقق من البريد الإلكتروني (فقط لمستخدمي Email)
      final isEmailProvider = firebaseUser.providerData.any(
        (p) => p.providerId == 'password',
      );

      if (isEmailProvider && !firebaseUser.emailVerified) {
        AppLogger.d('Email not verified for: ${firebaseUser.email}');
        _needsEmailVerification = true;
        _pendingVerification = _PendingVerification(
          email: firebaseUser.email ?? '',
        );
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // جلب بيانات المستخدم
      final result = await _authService.loadCurrentUser();

      if (result.success) {
        final userData = result.data!;
        AppLogger.d(
          'User data loaded: ${userData.name}, status: ${userData.accountStatus}',
        );

        // التحقق من حالة الحساب
        if (userData.isPending) {
          AppLogger.d('Account is pending approval');
          _error = 'حسابك في انتظار موافقة المدير';
          _errorCode = 'account-pending';
          _pendingVerification = _PendingVerification(email: userData.email);
          _user = null;
          _needsEmailVerification = false;
          await _authService.signOut();
        } else if (userData.isRejected) {
          AppLogger.d('Account is rejected');
          _error = 'تم رفض حسابك: ${userData.rejectionReason ?? "غير محدد"}';
          _errorCode = 'account-rejected';
          _user = null;
          await _authService.signOut();
        } else if (!userData.isActive) {
          AppLogger.d('Account is disabled');
          _error = 'هذا الحساب معطل';
          _errorCode = 'account-disabled';
          _user = null;
          await _authService.signOut();
        } else {
          AppLogger.d('Account is approved, logging in');
          _user = userData;
          _needsEmailVerification = false;
          _error = null;
          _errorCode = null;
          // ✅ مسح بيانات التحقق عند تسجيل الدخول بنجاح
          _clearPendingVerification();
        }
      } else {
        AppLogger.e('Failed to load user data: ${result.error}');
        _error = result.error;
        _errorCode = result.errorCode;
      }

      _isLoading = false;
      notifyListeners();
    } finally {
      _isProcessingAuthChange = false;
    }
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
      _clearPendingVerification();
      AppLogger.i('✅ تم تسجيل الدخول بنجاح: ${_user?.name}');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;

      // حفظ بيانات التحقق حسب نوع الخطأ
      if (result.errorCode == 'email-not-verified') {
        _needsEmailVerification = true;
        _pendingVerification = _PendingVerification(
          email: email,
          password: password,
        );
      } else if (result.errorCode == 'account-pending') {
        _pendingVerification = _PendingVerification(
          email: email,
          password: password,
        );
        _needsEmailVerification = false;
      }

      AppLogger.w('❌ فشل تسجيل الدخول: ${result.error} (${result.errorCode})');
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
      _clearPendingVerification();
      AppLogger.i('✅ تم تسجيل الدخول بـ Google بنجاح: ${_user?.name}');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;

      // للحسابات الجديدة أو المعلقة
      if (result.errorCode == 'account-pending-new' ||
          result.errorCode == 'account-pending') {
        final currentUser = FirebaseAuth.instance.currentUser;
        _pendingVerification = _PendingVerification(
          email: currentUser?.email ?? '',
        );
      }

      AppLogger.w(
        '❌ فشل تسجيل الدخول بـ Google: ${result.error} (${result.errorCode})',
      );
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
      _errorCode = null;
      _pendingVerification = _PendingVerification(
        email: email,
        password: password,
      );
      _needsEmailVerification = true;
      AppLogger.i('✅ تم إنشاء الحساب - بانتظار تفعيل البريد');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;
      AppLogger.w('❌ فشل إنشاء الحساب: ${result.error}');
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  /// إعادة إرسال رابط التحقق
  Future<bool> resendVerificationEmail() async {
    if (!hasPendingVerification) {
      _error = 'لا توجد بيانات للتحقق أو انتهت صلاحيتها';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.sendVerificationEmailToUser(
      _pendingVerification!.email,
      _pendingVerification!.password!,
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
    AppLogger.d('checkVerificationAndLogin called');
    AppLogger.d('Email: ${_pendingVerification?.email}');

    if (!hasPendingVerification) {
      _error = 'لا توجد بيانات للتحقق أو انتهت صلاحيتها';
      _errorCode = 'no-pending-data';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    // محاولة تسجيل الدخول مرة أخرى
    final result = await _authService.signInWithEmail(
      _pendingVerification!.email,
      _pendingVerification!.password!,
    );

    AppLogger.d(
      'Sign in result: success=${result.success}, errorCode=${result.errorCode}',
    );

    if (result.success) {
      _user = result.data;
      _error = null;
      _errorCode = null;
      _needsEmailVerification = false;
      _clearPendingVerification();
      AppLogger.i('✅ تم التحقق وتسجيل الدخول بنجاح');
    } else {
      _error = result.error;
      _errorCode = result.errorCode;

      AppLogger.d('Login failed with errorCode: ${result.errorCode}');

      // تحديث حالة التحقق من البريد
      if (result.errorCode == 'email-not-verified') {
        _needsEmailVerification = true;
        AppLogger.d('Email still not verified');
      } else if (result.errorCode == 'account-pending') {
        // ✅ البريد تم تفعيله لكن الحساب في الانتظار
        _needsEmailVerification = false;
        // ✅ مسح كلمة المرور فقط مع الإبقاء على البريد
        _pendingVerification?.clearPassword();
        AppLogger.d('Email verified but account pending approval');
      } else {
        _needsEmailVerification = false;
      }
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
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
    _clearPendingVerification();
    _error = null;
    _errorCode = null;

    AppLogger.i('✅ تم تسجيل الخروج');
    _isLoading = false;
    notifyListeners();
  }

  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    _error = null;
    _errorCode = null;
    final result = await _authService.resetPassword(email);

    if (!result.success) {
      _error = result.error;
      _errorCode = result.errorCode;
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
    _errorCode = null;
    final result = await _authService.changePassword(
      currentPassword,
      newPassword,
    );

    if (!result.success) {
      _error = result.error;
      _errorCode = result.errorCode;
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
      _errorCode = 'permission-denied';
      notifyListeners();
      return false;
    }

    _error = null;
    _errorCode = null;
    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );

    if (!result.success) {
      _error = result.error;
      _errorCode = result.errorCode;
    }

    notifyListeners();
    return result.success;
  }

  /// تحديث اسم المستخدم
  Future<bool> updateUserName(String name) async {
    _error = null;
    _errorCode = null;
    final result = await _authService.updateUserName(name);

    if (result.success) {
      _user = _user?.copyWith(name: name);
    } else {
      _error = result.error;
      _errorCode = result.errorCode;
    }

    notifyListeners();
    return result.success;
  }

  /// ✅ مسح بيانات التحقق المعلقة بشكل آمن
  void _clearPendingVerification() {
    _pendingVerification?.clearPassword();
    _pendingVerification = null;
  }

  /// مسح حالة انتظار التحقق
  void clearVerificationState() {
    _needsEmailVerification = false;
    _clearPendingVerification();
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  /// تحديث بيانات المستخدم من الخادم
  Future<void> refreshUser() async {
    if (_user == null) return;

    final result = await _authService.loadCurrentUser();
    if (result.success) {
      _user = result.data;
      notifyListeners();
    }
  }

  /// ✅ تنظيف الموارد بشكل صحيح
  @override
  void dispose() {
    AppLogger.d('تنظيف AuthProvider');
    _debounceTimer?.cancel();
    _authStateSubscription?.cancel();
    _clearPendingVerification();
    super.dispose();
  }
}
