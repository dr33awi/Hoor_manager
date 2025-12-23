// lib/core/services/auth_service.dart
// خدمة المصادقة المحسنة - مع دعم كامل للتحقق من الإيميل ومعالجة محسنة للأخطاء

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hoor_manager/core/services/base_service.dart';
import 'package:hoor_manager/core/services/logger_service.dart';
import 'package:hoor_manager/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// أنواع أخطاء المصادقة
enum AuthErrorType {
  invalidCredential,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  networkError,
  emailNotVerified,
  accountPending,
  accountRejected,
  accountDisabled,
  operationCancelled,
  unknown,
}

/// نتيجة المصادقة المحسنة
class AuthResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final AuthErrorType? errorType;
  final String? errorCode;

  AuthResult._({
    required this.success,
    this.data,
    this.errorMessage,
    this.errorType,
    this.errorCode,
  });

  factory AuthResult.success([T? data]) {
    return AuthResult._(success: true, data: data);
  }

  factory AuthResult.failure({
    required String message,
    required AuthErrorType type,
    String? code,
  }) {
    return AuthResult._(
      success: false,
      errorMessage: message,
      errorType: type,
      errorCode: code,
    );
  }

  /// هل الخطأ يتطلب إجراء من المستخدم؟
  bool get requiresUserAction =>
      errorType == AuthErrorType.emailNotVerified ||
      errorType == AuthErrorType.accountPending;

  /// هل الخطأ نهائي (لا يمكن إعادة المحاولة)؟
  bool get isFinalError =>
      errorType == AuthErrorType.accountRejected ||
      errorType == AuthErrorType.accountDisabled;
}

class AuthService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _usersCollection = 'users';

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;

  // Getters
  User? get firebaseUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  UserModel? get currentUser => _currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  /// ==================== تسجيل الدخول بالإيميل ====================
  Future<AuthResult<UserModel>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      AppLogger.i('🔐 محاولة تسجيل الدخول: $email');

      // 1. محاولة تسجيل الدخول
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure(
          message: 'حدث خطأ غير متوقع',
          type: AuthErrorType.unknown,
        );
      }

      // 2. التحقق من تفعيل الإيميل
      if (!user.emailVerified) {
        AppLogger.w('⚠️ الإيميل غير مفعل');
        // لا نسجل الخروج - نحتاج المستخدم مسجل لإعادة إرسال الرابط
        return AuthResult.failure(
          message: 'يرجى تفعيل بريدك الإلكتروني أولاً',
          type: AuthErrorType.emailNotVerified,
          code: 'email-not-verified',
        );
      }

      // 3. جلب بيانات المستخدم من Firestore
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // المستخدم موجود في Auth لكن ليس في Firestore - إنشاء سجل
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? email,
          name: user.displayName ?? 'مستخدم',
          role: 'employee',
          status: 'pending',
          isActive: true,
          emailVerified: true,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .set(newUser.toMap());

        await _auth.signOut();
        return AuthResult.failure(
          message: 'حسابك قيد المراجعة من قبل المدير',
          type: AuthErrorType.accountPending,
          code: 'account-pending',
        );
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromFirestore(userDoc);

      // 4. التحقق من حالة الحساب
      final statusCheck = _checkAccountStatus(userData);
      if (!statusCheck.success) {
        await _auth.signOut();
        return AuthResult<UserModel>.failure(
          message: statusCheck.errorMessage ?? 'حالة الحساب غير صالحة',
          type: statusCheck.errorType ?? AuthErrorType.unknown,
          code: statusCheck.errorCode,
        );
      }

      // 5. تحديث بيانات آخر تسجيل دخول
      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'emailVerified': true,
      });

      _currentUser = userModel;
      AppLogger.i('✅ تسجيل الدخول ناجح: ${userModel.name}');

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('❌ FirebaseAuthException: ${e.code}', error: e);
      return _handleFirebaseAuthError(e);
    } on FirebaseException catch (e) {
      AppLogger.e('❌ FirebaseException: ${e.code}', error: e);
      // محاولة استخراج الكود من الرسالة
      final code = e.code ?? _extractErrorCode(e.message ?? '');
      return AuthResult.failure(
        message: _getErrorInfo(code).message,
        type: _getErrorInfo(code).type,
        code: code,
      );
    } catch (e) {
      AppLogger.e('❌ خطأ غير متوقع: ${e.runtimeType}', error: e);
      return _handleGenericError(e);
    }
  }

  /// استخراج كود الخطأ من رسالة الخطأ
  String _extractErrorCode(String message) {
    // البحث عن النمط [firebase_auth/error-code]
    final regex = RegExp(r'\[firebase_auth/([^\]]+)\]');
    final match = regex.firstMatch(message);
    if (match != null) {
      return match.group(1) ?? 'unknown';
    }

    // البحث عن أنماط شائعة
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('invalid-credential') ||
        lowerMessage.contains('incorrect') ||
        lowerMessage.contains('wrong-password')) {
      return 'invalid-credential';
    }
    if (lowerMessage.contains('user-not-found')) {
      return 'user-not-found';
    }
    if (lowerMessage.contains('email-already-in-use')) {
      return 'email-already-in-use';
    }
    if (lowerMessage.contains('weak-password')) {
      return 'weak-password';
    }
    if (lowerMessage.contains('network')) {
      return 'network-request-failed';
    }

    return 'unknown';
  }

  /// ==================== تسجيل الدخول بـ Google ====================
  Future<AuthResult<UserModel>> signInWithGoogle() async {
    try {
      AppLogger.i('🔐 محاولة تسجيل الدخول بـ Google');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure(
          message: 'تم إلغاء تسجيل الدخول',
          type: AuthErrorType.operationCancelled,
          code: 'cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // التحقق من وجود المستخدم في Firestore
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      UserModel userModel;

      if (!userDoc.exists) {
        // مستخدم جديد
        userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'مستخدم',
          photoUrl: user.photoURL,
          role: 'employee',
          status: 'pending',
          isActive: true,
          isGoogleUser: true,
          emailVerified: true,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());

        await _auth.signOut();
        await _googleSignIn.signOut();

        return AuthResult.failure(
          message: 'تم إنشاء حسابك بنجاح!\nحسابك قيد المراجعة من قبل المدير.',
          type: AuthErrorType.accountPending,
          code: 'account-pending',
        );
      }

      // مستخدم موجود - التحقق من الحالة
      final statusCheck = _checkAccountStatus(userDoc.data()!);
      if (!statusCheck.success) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return AuthResult<UserModel>.failure(
          message: statusCheck.errorMessage ?? 'حالة الحساب غير صالحة',
          type: statusCheck.errorType ?? AuthErrorType.unknown,
          code: statusCheck.errorCode,
        );
      }

      // تحديث البيانات
      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL,
      });

      userModel = UserModel.fromFirestore(userDoc);
      _currentUser = userModel;

      AppLogger.i('✅ تسجيل الدخول بـ Google ناجح');
      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      AppLogger.e(
        '❌ FirebaseAuthException في Google Sign-In: ${e.code}',
        error: e,
      );
      await _googleSignIn.signOut();
      return _handleFirebaseAuthError(e);
    } catch (e) {
      AppLogger.e('❌ خطأ في Google Sign-In: ${e.runtimeType}', error: e);
      await _googleSignIn.signOut();

      final errorString = e.toString().toLowerCase();

      // التحقق من أنواع أخطاء Google Sign-In المحددة
      if (errorString.contains('canceled') ||
          errorString.contains('cancelled') ||
          errorString.contains('sign_in_canceled')) {
        return AuthResult.failure(
          message: 'تم إلغاء تسجيل الدخول',
          type: AuthErrorType.operationCancelled,
          code: 'cancelled',
        );
      }

      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        return AuthResult.failure(
          message: 'خطأ في الاتصال بالإنترنت',
          type: AuthErrorType.networkError,
          code: 'network-error',
        );
      }

      if (errorString.contains('developer_error') ||
          errorString.contains('configuration')) {
        return AuthResult.failure(
          message: 'خطأ في إعدادات التطبيق. يرجى التواصل مع الدعم الفني.',
          type: AuthErrorType.unknown,
          code: 'configuration-error',
        );
      }

      return _handleGenericError(e);
    }
  }

  /// ==================== إنشاء حساب جديد ====================
  Future<AuthResult<void>> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      AppLogger.i('🔐 إنشاء حساب جديد: $email');

      // 1. إنشاء الحساب في Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // 2. تحديث اسم المستخدم
      await user.updateDisplayName(name.trim());

      // 3. إرسال رابط التحقق
      await user.sendEmailVerification();
      AppLogger.i('📧 تم إرسال رابط التحقق إلى: $email');

      // 4. إنشاء سجل في Firestore
      final userModel = UserModel(
        id: user.uid,
        email: email.trim(),
        name: name.trim(),
        role: 'employee',
        status: 'pending',
        isActive: true,
        emailVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      _currentUser = userModel;

      AppLogger.i('✅ تم إنشاء الحساب بنجاح');
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      AppLogger.e('❌ خطأ Firebase: ${e.code}', error: e);
      return _handleFirebaseAuthError(e);
    } catch (e) {
      AppLogger.e('❌ خطأ غير متوقع', error: e);
      return _handleGenericError(e);
    }
  }

  /// ==================== إعادة إرسال رابط التحقق ====================
  Future<AuthResult<void>> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(
          message: 'لا يوجد مستخدم مسجل',
          type: AuthErrorType.userNotFound,
        );
      }

      if (user.emailVerified) {
        return AuthResult.failure(
          message: 'البريد الإلكتروني مفعّل بالفعل',
          type: AuthErrorType.unknown,
        );
      }

      await user.sendEmailVerification();
      AppLogger.i('📧 تم إعادة إرسال رابط التحقق');
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return AuthResult.failure(
          message: 'تم إرسال الكثير من الطلبات. انتظر قليلاً',
          type: AuthErrorType.tooManyRequests,
          code: e.code,
        );
      }
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// ==================== التحقق من تفعيل الإيميل ====================
  Future<AuthResult<bool>> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(
          message: 'لا يوجد مستخدم مسجل',
          type: AuthErrorType.userNotFound,
        );
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser?.emailVerified == true) {
        AppLogger.i('✅ تم التحقق من الإيميل');

        // تحديث Firestore
        await _firestore
            .collection(_usersCollection)
            .doc(refreshedUser!.uid)
            .update({'emailVerified': true});

        return AuthResult.success(true);
      }

      return AuthResult.success(false);
    } catch (e) {
      AppLogger.e('خطأ في التحقق من الإيميل', error: e);
      return _handleGenericError(e);
    }
  }

  /// ==================== تسجيل الخروج ====================
  Future<AuthResult<void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
      AppLogger.i('✅ تم تسجيل الخروج');
      return AuthResult.success();
    } catch (e) {
      AppLogger.e('خطأ في تسجيل الخروج', error: e);
      return _handleGenericError(e);
    }
  }

  /// ==================== التحقق من وجود البريد الإلكتروني ====================
  Future<bool> isEmailRegistered(String email) async {
    try {
      // البحث في Firestore
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }

      // البحث بالإيميل الأصلي (بدون تحويل لأحرف صغيرة)
      final querySnapshot2 = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return querySnapshot2.docs.isNotEmpty;
    } catch (e) {
      AppLogger.e('❌ خطأ في التحقق من البريد الإلكتروني', error: e);
      // في حالة الخطأ، نعيد true للسماح بالمتابعة (لتجنب حظر المستخدمين الشرعيين)
      return true;
    }
  }

  /// ==================== إعادة تعيين كلمة المرور ====================
  Future<AuthResult<void>> resetPassword(String email) async {
    try {
      final trimmedEmail = email.trim();

      // التحقق من صحة صيغة البريد الإلكتروني
      if (!_isValidEmail(trimmedEmail)) {
        return AuthResult.failure(
          message: 'البريد الإلكتروني غير صالح',
          type: AuthErrorType.invalidEmail,
          code: 'invalid-email',
        );
      }

      // التحقق من وجود البريد الإلكتروني في النظام
      final isRegistered = await isEmailRegistered(trimmedEmail);

      if (!isRegistered) {
        AppLogger.w(
          '⚠️ محاولة إعادة تعيين كلمة مرور لبريد غير مسجل: $trimmedEmail',
        );
        return AuthResult.failure(
          message: 'لا يوجد حساب مسجل بهذا البريد الإلكتروني',
          type: AuthErrorType.userNotFound,
          code: 'user-not-found',
        );
      }

      // إرسال رابط إعادة تعيين كلمة المرور
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      AppLogger.i(
        '📧 تم إرسال رابط إعادة تعيين كلمة المرور إلى: $trimmedEmail',
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      AppLogger.e(
        '❌ خطأ Firebase في إعادة تعيين كلمة المرور: ${e.code}',
        error: e,
      );
      return _handleFirebaseAuthError(e);
    } catch (e) {
      AppLogger.e('❌ خطأ في إعادة تعيين كلمة المرور', error: e);
      return _handleGenericError(e);
    }
  }

  /// التحقق من صحة صيغة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// ==================== جلب بيانات المستخدم ====================
  Future<AuthResult<UserModel>> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) {
        return AuthResult.failure(
          message: 'المستخدم غير موجود',
          type: AuthErrorType.userNotFound,
        );
      }
      return AuthResult.success(UserModel.fromFirestore(doc));
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// ==================== إدارة المستخدمين ====================
  Future<AuthResult<List<UserModel>>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return AuthResult.success(users);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  Future<AuthResult<void>> approveUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'status': 'approved',
        'isActive': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('✅ تمت الموافقة على المستخدم: $uid');
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  Future<AuthResult<void>> rejectUser(String uid, [String? reason]) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'status': 'rejected',
        'isActive': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('❌ تم رفض المستخدم: $uid');
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  Future<AuthResult<void>> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': isActive,
        if (isActive) 'status': 'approved',
      });
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  Future<AuthResult<void>> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': role,
      });
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// تفعيل مستخدم
  Future<AuthResult<void>> activateUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': true,
        'status': 'approved',
      });
      AppLogger.i('✅ تم تفعيل المستخدم: $uid');
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// تعطيل مستخدم
  Future<AuthResult<void>> deactivateUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isActive': false,
      });
      AppLogger.i('🚫 تم تعطيل المستخدم: $uid');
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// إنشاء أو تحديث مستخدم
  Future<AuthResult<void>> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
      return AuthResult.success();
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  // ==================== الدوال المساعدة ====================

  /// التحقق من حالة الحساب
  AuthResult<void> _checkAccountStatus(Map<String, dynamic> userData) {
    final hasStatusField = userData.containsKey('status');
    final status = userData['status'] as String?;
    final isActive = userData['isActive'] as bool? ?? true;

    // Debug logging
    AppLogger.d('📋 _checkAccountStatus:');
    AppLogger.d('   - status field exists: $hasStatusField');
    AppLogger.d('   - status value: $status');
    AppLogger.d(
      '   - isActive field exists: ${userData.containsKey('isActive')}',
    );
    AppLogger.d('   - isActive value: $isActive');

    // إذا كان الحساب غير نشط
    if (!isActive) {
      return AuthResult.failure(
        message: 'تم تعطيل حسابك. تواصل مع المدير',
        type: AuthErrorType.accountDisabled,
        code: 'account-disabled',
      );
    }

    // إذا لم يوجد حقل status أو كان null، نعتبر الحساب موافق عليه (للتوافق مع الحسابات القديمة)
    if (!hasStatusField || status == null) {
      AppLogger.d(
        '   ✅ No status field - treating as approved (legacy account)',
      );
      return AuthResult.success();
    }

    // الحساب موافق عليه
    if (status == 'approved' || status == 'active') {
      return AuthResult.success();
    }

    // الحساب قيد الانتظار
    if (status == 'pending') {
      return AuthResult.failure(
        message: 'حسابك قيد المراجعة من قبل المدير',
        type: AuthErrorType.accountPending,
        code: 'account-pending',
      );
    }

    // الحساب مرفوض
    if (status == 'rejected') {
      final reason = userData['rejectionReason'] as String?;
      return AuthResult.failure(
        message: reason != null
            ? 'تم رفض حسابك\nالسبب: $reason'
            : 'تم رفض حسابك',
        type: AuthErrorType.accountRejected,
        code: 'account-rejected',
      );
    }

    // أي حالة أخرى غير معروفة - نعتبرها موافق عليها
    AppLogger.w('⚠️ Unknown status: $status - treating as approved');
    return AuthResult.success();
  }

  /// معالجة أخطاء Firebase Auth
  AuthResult<T> _handleFirebaseAuthError<T>(FirebaseAuthException e) {
    final errorInfo = _getErrorInfo(e.code);
    return AuthResult.failure(
      message: errorInfo.message,
      type: errorInfo.type,
      code: e.code,
    );
  }

  /// معالجة الأخطاء العامة
  AuthResult<T> _handleGenericError<T>(dynamic e) {
    final errorString = e.toString().toLowerCase();

    // محاولة تحديد نوع الخطأ من النص
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return AuthResult.failure(
        message: 'خطأ في الاتصال بالإنترنت',
        type: AuthErrorType.networkError,
        code: 'network-error',
      );
    }

    if (errorString.contains('invalid-credential') ||
        errorString.contains('wrong-password') ||
        errorString.contains('incorrect')) {
      return AuthResult.failure(
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        type: AuthErrorType.invalidCredential,
        code: 'invalid-credential',
      );
    }

    if (errorString.contains('user-not-found')) {
      return AuthResult.failure(
        message: 'لا يوجد حساب بهذا البريد الإلكتروني',
        type: AuthErrorType.userNotFound,
        code: 'user-not-found',
      );
    }

    return AuthResult.failure(
      message: 'حدث خطأ غير متوقع',
      type: AuthErrorType.unknown,
    );
  }

  /// الحصول على معلومات الخطأ
  ({String message, AuthErrorType type}) _getErrorInfo(String code) {
    switch (code) {
      case 'user-not-found':
        return (
          message: 'لا يوجد حساب بهذا البريد الإلكتروني',
          type: AuthErrorType.userNotFound,
        );
      case 'wrong-password':
        return (
          message: 'كلمة المرور غير صحيحة',
          type: AuthErrorType.wrongPassword,
        );
      case 'invalid-credential':
        return (
          message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
          type: AuthErrorType.invalidCredential,
        );
      case 'email-already-in-use':
        return (
          message: 'البريد الإلكتروني مستخدم بالفعل',
          type: AuthErrorType.emailAlreadyInUse,
        );
      case 'weak-password':
        return (
          message: 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)',
          type: AuthErrorType.weakPassword,
        );
      case 'invalid-email':
        return (
          message: 'البريد الإلكتروني غير صالح',
          type: AuthErrorType.invalidEmail,
        );
      case 'user-disabled':
        return (message: 'هذا الحساب معطل', type: AuthErrorType.userDisabled);
      case 'too-many-requests':
        return (
          message: 'محاولات كثيرة جداً. حاول بعد قليل',
          type: AuthErrorType.tooManyRequests,
        );
      case 'network-request-failed':
        return (
          message: 'خطأ في الاتصال بالإنترنت',
          type: AuthErrorType.networkError,
        );
      default:
        return (message: 'حدث خطأ أثناء المصادقة', type: AuthErrorType.unknown);
    }
  }

  // ==================== الحفظ المحلي (Offline Support) ====================

  static const String _userCacheKey = 'cached_user_data';
  static const String _lastLoginKey = 'last_login_time';

  /// حفظ بيانات المستخدم محلياً
  Future<void> cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // تحويل البيانات لصيغة قابلة للحفظ في JSON (بدون Timestamp)
      final userData = jsonEncode({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'photoUrl': user.photoUrl,
        'role': user.role,
        'status': user.status,
        'isActive': user.isActive,
        'isGoogleUser': user.isGoogleUser,
        'emailVerified': user.emailVerified,
        'createdAt': user.createdAt.millisecondsSinceEpoch,
        'lastLoginAt': user.lastLoginAt?.millisecondsSinceEpoch,
        'approvedAt': user.approvedAt?.millisecondsSinceEpoch,
        'rejectedAt': user.rejectedAt?.millisecondsSinceEpoch,
        'rejectionReason': user.rejectionReason,
      });
      await prefs.setString(_userCacheKey, userData);
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
      AppLogger.d('💾 تم حفظ بيانات المستخدم محلياً');
    } catch (e) {
      AppLogger.e('❌ خطأ في حفظ بيانات المستخدم محلياً', error: e);
    }
  }

  /// استرجاع بيانات المستخدم المحفوظة محلياً
  Future<UserModel?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userCacheKey);

      if (userData != null) {
        final map = jsonDecode(userData) as Map<String, dynamic>;
        AppLogger.d('💾 تم استرجاع بيانات المستخدم من الذاكرة المحلية');

        // تحويل البيانات من JSON إلى UserModel
        return UserModel(
          id: map['id'] as String? ?? '',
          email: map['email'] as String? ?? '',
          name: map['name'] as String? ?? '',
          photoUrl: map['photoUrl'] as String?,
          role: map['role'] as String? ?? 'employee',
          status: map['status'] as String? ?? 'approved',
          isActive: map['isActive'] as bool? ?? true,
          isGoogleUser: map['isGoogleUser'] as bool? ?? false,
          emailVerified: map['emailVerified'] as bool? ?? false,
          createdAt: map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : DateTime.now(),
          lastLoginAt: map['lastLoginAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int)
              : null,
          approvedAt: map['approvedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['approvedAt'] as int)
              : null,
          rejectedAt: map['rejectedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['rejectedAt'] as int)
              : null,
          rejectionReason: map['rejectionReason'] as String?,
        );
      }
    } catch (e) {
      AppLogger.e('❌ خطأ في استرجاع بيانات المستخدم المحلية', error: e);
    }
    return null;
  }

  /// التحقق من صلاحية البيانات المحفوظة (خلال 7 أيام)
  Future<bool> isCachedDataValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getInt(_lastLoginKey);

      if (lastLogin != null) {
        final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastLogin);
        final daysSinceLogin = DateTime.now().difference(lastLoginDate).inDays;
        return daysSinceLogin < 7; // صالحة لمدة 7 أيام
      }
    } catch (e) {
      AppLogger.e('❌ خطأ في التحقق من صلاحية البيانات', error: e);
    }
    return false;
  }

  /// مسح البيانات المحفوظة محلياً
  Future<void> clearCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      await prefs.remove(_lastLoginKey);
      AppLogger.d('🗑️ تم مسح بيانات المستخدم المحلية');
    } catch (e) {
      AppLogger.e('❌ خطأ في مسح البيانات المحلية', error: e);
    }
  }

  /// جلب بيانات المستخدم (من السيرفر أو المحلي)
  Future<AuthResult<UserModel>> getUserDataWithOfflineSupport(
    String uid,
  ) async {
    try {
      // محاولة جلب البيانات من السيرفر أولاً
      final result = await getUserById(uid);

      if (result.success && result.data != null) {
        // حفظ البيانات محلياً للاستخدام لاحقاً
        await cacheUserData(result.data!);
        return result;
      }

      // إذا فشل، حاول استخدام البيانات المحلية
      if (await isCachedDataValid()) {
        final cachedUser = await getCachedUserData();
        if (cachedUser != null && cachedUser.id == uid) {
          AppLogger.i('📱 استخدام البيانات المحلية (وضع أوفلاين)');
          return AuthResult.success(cachedUser);
        }
      }

      return result;
    } catch (e) {
      // في حالة خطأ الشبكة، حاول استخدام البيانات المحلية
      if (await isCachedDataValid()) {
        final cachedUser = await getCachedUserData();
        if (cachedUser != null && cachedUser.id == uid) {
          AppLogger.i('📱 استخدام البيانات المحلية (خطأ شبكة)');
          return AuthResult.success(cachedUser);
        }
      }

      return AuthResult.failure(
        message: 'لا يمكن الوصول للبيانات. تحقق من الاتصال بالإنترنت.',
        type: AuthErrorType.networkError,
        code: 'offline-no-cache',
      );
    }
  }
}
