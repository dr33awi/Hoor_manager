// lib/features/auth/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/logger_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  String? _pendingVerificationEmail;
  bool _needsEmailVerification = false;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get needsEmailVerification => _needsEmailVerification;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isApproved;
  bool get isAdmin => _currentUser?.role == 'admin';
  String? get userName => _currentUser?.name;
  String? get userPhoto => _currentUser?.photoUrl;
  bool get isGoogleUser => _currentUser?.isGoogleUser ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        _authService.setCurrentUser(null);
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      AppLogger.e('Error checking auth status', error: e);
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final result = await _authService.getUserById(uid);
      if (result.success && result.data != null) {
        _currentUser = result.data;
        _authService.setCurrentUser(_currentUser);

        if (_currentUser!.status == 'pending') {
          _errorCode = 'account-pending';
          _error = 'حسابك قيد المراجعة من قبل المدير';
        } else if (_currentUser!.status == 'rejected') {
          _errorCode = 'account-rejected';
          _error = _currentUser!.rejectionReason ?? 'تم رفض حسابك';
        } else if (!_currentUser!.isActive) {
          _errorCode = 'account-disabled';
          _error = 'تم تعطيل حسابك. تواصل مع المدير';
        } else {
          _errorCode = null;
          _error = null;
        }
      } else {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          _currentUser = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'مستخدم',
            role: 'employee',
            status: 'pending',
            isActive: true,
            createdAt: DateTime.now(),
          );
          await _authService.createOrUpdateUser(_currentUser!);
          _authService.setCurrentUser(_currentUser);
          _errorCode = 'account-pending';
          _error = 'حسابك قيد المراجعة من قبل المدير';
        }
      }
    } catch (e) {
      AppLogger.e('Error loading user data', error: e);
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userResult = await _authService.getUserById(credential.user!.uid);

      if (!userResult.success || userResult.data == null) {
        await _firebaseAuth.signOut();
        _error = 'حدث خطأ في تحميل بيانات المستخدم';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = userResult.data!;

      // ✅ التحقق من حالة الحساب وعرض رسالة مناسبة
      if (user.status == 'pending') {
        await _firebaseAuth.signOut();
        _error =
            '⏳ حسابك قيد المراجعة\n\nيرجى الانتظار حتى يتم تفعيل حسابك من قبل المدير.';
        _errorCode = 'account-pending';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.status == 'rejected') {
        await _firebaseAuth.signOut();
        final reason = user.rejectionReason ?? 'لم يتم تحديد السبب';
        _error = '❌ تم رفض حسابك\n\nالسبب: $reason';
        _errorCode = 'account-rejected';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!user.isActive) {
        await _firebaseAuth.signOut();
        _error =
            '🚫 حسابك معطل\n\nتم تعطيل حسابك من قبل المدير. تواصل معه لمعرفة السبب.';
        _errorCode = 'account-disabled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ الحساب نشط ومفعل
      _currentUser = user;
      _authService.setCurrentUser(_currentUser);
      _error = null;
      _errorCode = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ أثناء تسجيل الدخول';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      if (result.success) {
        await _loadUserData(_firebaseAuth.currentUser!.uid);

        if (_currentUser != null && !_currentUser!.isApproved) {
          await _firebaseAuth.signOut();
          if (_currentUser!.status == 'pending') {
            _error =
                '⏳ حسابك قيد المراجعة\n\nيرجى الانتظار حتى يتم تفعيل حسابك من قبل المدير.';
            _errorCode = 'account-pending';
          } else if (_currentUser!.status == 'rejected') {
            final reason =
                _currentUser!.rejectionReason ?? 'لم يتم تحديد السبب';
            _error = '❌ تم رفض حسابك\n\nالسبب: $reason';
            _errorCode = 'account-rejected';
          } else {
            _error = '🚫 حسابك معطل';
            _errorCode = 'account-disabled';
          }
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ أثناء تسجيل الدخول بـ Google';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    return signUpWithEmail(email, password, name);
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      final result = await _authService.signUp(email, password, name);
      if (result.success) {
        _pendingVerificationEmail = email;
        await _firebaseAuth.signOut();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error;
        _errorCode = _getErrorCodeFromMessage(result.error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ أثناء إنشاء الحساب';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _error = null;
      _errorCode = null;
      _pendingVerificationEmail = null;
      _needsEmailVerification = false;
    } catch (e) {
      AppLogger.e('Error signing out', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(email);
      _isLoading = false;
      if (!result.success) {
        _error = result.error;
      }
      notifyListeners();
      return result.success;
    } catch (e) {
      _error = 'حدث خطأ';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.resendVerificationEmail();
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkVerificationAndLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.checkVerificationAndLogin();
      if (result.success && result.data == true) {
        await _loadUserData(_firebaseAuth.currentUser!.uid);
        _needsEmailVerification = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _needsEmailVerification = true;
        _errorCode = 'email-not-verified';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearVerificationState() {
    _pendingVerificationEmail = null;
    _needsEmailVerification = false;
    _errorCode = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً. حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      default:
        return 'حدث خطأ أثناء تسجيل الدخول';
    }
  }

  String? _getErrorCodeFromMessage(String? message) {
    if (message == null) return null;
    if (message.contains('قيد المراجعة')) return 'account-pending';
    if (message.contains('رفض')) return 'account-rejected';
    if (message.contains('معطل')) return 'account-disabled';
    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
