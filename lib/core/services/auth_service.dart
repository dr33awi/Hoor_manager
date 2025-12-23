// lib/core/services/auth_service.dart
// خدمة المصادقة الموحدة - محسنة ومصححة

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';
import 'audit_service.dart';
import 'logger_service.dart';

/// حالات الموافقة على الحساب
class AccountStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';
}

/// نموذج بيانات المستخدم
class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? photoUrl;
  final String authProvider;
  final bool isEmailVerified;
  final String accountStatus;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.photoUrl,
    this.authProvider = 'email',
    this.isEmailVerified = false,
    this.accountStatus = AccountStatus.pending,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    this.lastLoginAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? AppConstants.roleEmployee,
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      photoUrl: map['photoUrl'],
      authProvider: map['authProvider'] ?? 'email',
      isEmailVerified: map['isEmailVerified'] ?? false,
      accountStatus: map['accountStatus'] ?? AccountStatus.pending,
      rejectionReason: map['rejectionReason'],
      approvedAt: _parseDateTimeNullable(map['approvedAt']),
      approvedBy: map['approvedBy'],
      lastLoginAt: _parseDateTimeNullable(map['lastLoginAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'isEmailVerified': isEmailVerified,
      'accountStatus': accountStatus,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt,
      'approvedBy': approvedBy,
      'lastLoginAt': lastLoginAt,
    };
  }

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isManager => role == AppConstants.roleManager || isAdmin;
  bool get isPending => accountStatus == AccountStatus.pending;
  bool get isApproved => accountStatus == AccountStatus.approved;
  bool get isRejected => accountStatus == AccountStatus.rejected;
  bool get canLogin => isActive && isApproved;

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    String? photoUrl,
    String? authProvider,
    bool? isEmailVerified,
    String? accountStatus,
    String? rejectionReason,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      accountStatus: accountStatus ?? this.accountStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// خدمة المصادقة
class AuthService extends BaseService with SubscriptionMixin {
  final FirebaseService _firebase = FirebaseService();
  final LocalStorageService _storage = LocalStorageService();
  final AuditService _audit = AuditService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ✅ إضافة Rate Limiting
  final Map<String, List<DateTime>> _loginAttempts = {};
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  // ✅ إضافة Timeout للعمليات
  static const Duration _operationTimeout = Duration(seconds: 30);

  Stream<User?> get authStateChanges => _firebase.auth.authStateChanges();
  bool get isLoggedIn =>
      _firebase.auth.currentUser != null && _currentUser != null;
  String? get currentUserId => _firebase.auth.currentUser?.uid;
  bool get isEmailVerified =>
      _firebase.auth.currentUser?.emailVerified ?? false;

  /// ✅ التحقق من Rate Limiting
  bool _isRateLimited(String email) {
    final attempts = _loginAttempts[email];
    if (attempts == null || attempts.isEmpty) return false;

    // إزالة المحاولات القديمة
    final now = DateTime.now();
    attempts.removeWhere(
      (attempt) => now.difference(attempt) > _lockoutDuration,
    );

    return attempts.length >= _maxLoginAttempts;
  }

  /// ✅ تسجيل محاولة دخول
  void _recordLoginAttempt(String email) {
    _loginAttempts.putIfAbsent(email, () => []);
    _loginAttempts[email]!.add(DateTime.now());
  }

  /// ✅ مسح محاولات الدخول عند النجاح
  void _clearLoginAttempts(String email) {
    _loginAttempts.remove(email);
  }

  /// ✅ الحصول على الوقت المتبقي للحظر
  Duration? getRemainingLockoutTime(String email) {
    final attempts = _loginAttempts[email];
    if (attempts == null || attempts.isEmpty) return null;

    final oldestAttempt = attempts.first;
    final unlockTime = oldestAttempt.add(_lockoutDuration);
    final remaining = unlockTime.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  Future<ServiceResult<UserModel>> signInWithEmail(
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim().toLowerCase();

    // ✅ التحقق من Rate Limiting
    if (_isRateLimited(trimmedEmail)) {
      final remaining = getRemainingLockoutTime(trimmedEmail);
      final minutes = remaining?.inMinutes ?? 15;
      return ServiceResult.failure(
        'تم تجاوز عدد المحاولات المسموحة. حاول بعد $minutes دقيقة',
        'too-many-attempts',
      );
    }

    try {
      AppLogger.userAction(
        'محاولة تسجيل دخول',
        details: {'email': trimmedEmail},
      );

      // ✅ إضافة Timeout
      final credential = await _firebase.auth
          .signInWithEmailAndPassword(email: trimmedEmail, password: password)
          .timeout(_operationTimeout);

      if (credential.user == null) {
        _recordLoginAttempt(trimmedEmail);
        return ServiceResult.failure('فشل تسجيل الدخول');
      }

      final userResult = await _getUserData(credential.user!.uid);
      if (!userResult.success) {
        _recordLoginAttempt(trimmedEmail);
        await _firebase.auth.signOut();
        return ServiceResult.failure(userResult.error!);
      }

      final user = userResult.data!;
      final validationResult = await _validateUserAccess(
        credential.user!,
        user,
      );
      if (!validationResult.success) {
        _recordLoginAttempt(trimmedEmail);
        await _firebase.auth.signOut();
        return validationResult;
      }

      // ✅ مسح محاولات الدخول عند النجاح
      _clearLoginAttempts(trimmedEmail);

      await _updateLastLogin(user.id);
      await _saveSession(user);

      _currentUser = user.copyWith(
        isEmailVerified: credential.user!.emailVerified,
        lastLoginAt: DateTime.now(),
      );

      _audit.setCurrentUser(user.id, user.name);
      await _audit.logLogin();

      AppLogger.i('✅ تم تسجيل الدخول: ${_currentUser?.name}');
      return ServiceResult.success(_currentUser);
    } on FirebaseAuthException catch (e) {
      _recordLoginAttempt(trimmedEmail);
      return ServiceResult.failure(_handleAuthError(e), e.code);
    } on TimeoutException {
      return ServiceResult.failure(
        'انتهت مهلة الاتصال، حاول مرة أخرى',
        'timeout',
      );
    } catch (e) {
      _recordLoginAttempt(trimmedEmail);
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<UserModel>> _validateUserAccess(
    User firebaseUser,
    UserModel user,
  ) async {
    // ✅ المدير لا يحتاج تفعيل البريد
    if (!user.isAdmin && !firebaseUser.emailVerified) {
      return ServiceResult.failure(
        'البريد الإلكتروني غير مُفعّل',
        'email-not-verified',
      );
    }
    if (user.isPending) {
      return ServiceResult.failure(
        'حسابك في انتظار موافقة المدير',
        'account-pending',
      );
    }
    if (user.isRejected) {
      return ServiceResult.failure(
        'تم رفض طلب تسجيلك. السبب: ${user.rejectionReason ?? "غير محدد"}',
        'account-rejected',
      );
    }
    if (!user.isActive) {
      return ServiceResult.failure('هذا الحساب معطل', 'account-disabled');
    }
    return ServiceResult.success(user);
  }

  Future<ServiceResult<UserModel>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return ServiceResult.failure('تم إلغاء تسجيل الدخول', 'cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebase.auth
          .signInWithCredential(credential)
          .timeout(_operationTimeout);

      if (userCredential.user == null) {
        return ServiceResult.failure('فشل تسجيل الدخول بـ Google');
      }

      final firebaseUser = userCredential.user!;
      final existingUser = await _getUserData(firebaseUser.uid);

      if (existingUser.success) {
        final validationResult = await _validateUserAccess(
          firebaseUser,
          existingUser.data!,
        );
        if (!validationResult.success) {
          await signOut();
          return validationResult;
        }

        await _updateLastLogin(existingUser.data!.id);
        await _saveSession(existingUser.data!);
        _currentUser = existingUser.data;
        _audit.setCurrentUser(_currentUser!.id, _currentUser!.name);
        await _audit.logLogin();
        return ServiceResult.success(_currentUser);
      }

      final newUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'مستخدم Google',
        role: AppConstants.roleEmployee,
        isActive: true,
        createdAt: DateTime.now(),
        photoUrl: firebaseUser.photoURL,
        authProvider: 'google',
        isEmailVerified: true,
        accountStatus: AccountStatus.pending,
      );

      await _firebase.set(
        AppConstants.usersCollection,
        firebaseUser.uid,
        newUser.toMap(),
      );
      await signOut();
      return ServiceResult.failure(
        'تم إنشاء حسابك! في انتظار موافقة المدير',
        'account-pending-new',
      );
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e), e.code);
    } on TimeoutException {
      return ServiceResult.failure(
        'انتهت مهلة الاتصال، حاول مرة أخرى',
        'timeout',
      );
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.roleEmployee,
  }) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedName = name.trim();

      // ✅ التحقق من صحة البيانات
      if (trimmedName.length < 2) {
        return ServiceResult.failure('الاسم يجب أن يكون حرفين على الأقل');
      }

      if (password.length < 6) {
        return ServiceResult.failure(
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        );
      }

      final credential = await _firebase.auth
          .createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          )
          .timeout(_operationTimeout);

      if (credential.user == null) {
        return ServiceResult.failure('فشل إنشاء الحساب');
      }

      await credential.user!.updateDisplayName(trimmedName);
      await credential.user!.sendEmailVerification();

      final userData = UserModel(
        id: credential.user!.uid,
        email: trimmedEmail,
        name: trimmedName,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
        authProvider: 'email',
        isEmailVerified: false,
        accountStatus: AccountStatus.pending,
      );

      await _firebase.set(
        AppConstants.usersCollection,
        credential.user!.uid,
        userData.toMap(),
      );
      await _firebase.auth.signOut();
      return ServiceResult.success(userData);
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e), e.code);
    } on TimeoutException {
      return ServiceResult.failure(
        'انتهت مهلة الاتصال، حاول مرة أخرى',
        'timeout',
      );
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> resendVerificationEmail() async {
    try {
      final user = _firebase.auth.currentUser;
      if (user == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }
      if (user.emailVerified) {
        return ServiceResult.failure('البريد مُفعّل بالفعل');
      }
      await user.sendEmailVerification();
      return ServiceResult.success();
    } on TimeoutException {
      return ServiceResult.failure('انتهت مهلة الاتصال، حاول مرة أخرى');
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> sendVerificationEmailToUser(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebase.auth
          .signInWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          )
          .timeout(_operationTimeout);

      if (credential.user?.emailVerified == true) {
        await _firebase.auth.signOut();
        return ServiceResult.failure('البريد مُفعّل بالفعل');
      }
      await credential.user?.sendEmailVerification();
      await _firebase.auth.signOut();
      return ServiceResult.success();
    } on TimeoutException {
      return ServiceResult.failure('انتهت مهلة الاتصال، حاول مرة أخرى');
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> signOut() async {
    try {
      await _audit.logLogout();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _firebase.auth.signOut();
      await _storage.clearSession();
      _currentUser = null;
      _audit.clearCurrentUser();
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> resetPassword(String email) async {
    try {
      await _firebase.auth
          .sendPasswordResetEmail(email: email.trim().toLowerCase())
          .timeout(_operationTimeout);
      return ServiceResult.success();
    } on TimeoutException {
      return ServiceResult.failure('انتهت مهلة الاتصال، حاول مرة أخرى');
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _firebase.auth.currentUser;
      if (user == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }
      if (_currentUser?.authProvider == 'google') {
        return ServiceResult.failure('لا يمكن تغيير كلمة المرور لحساب Google');
      }

      // ✅ التحقق من قوة كلمة المرور الجديدة
      if (newPassword.length < 6) {
        return ServiceResult.failure(
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return ServiceResult.success();
    } on TimeoutException {
      return ServiceResult.failure('انتهت مهلة الاتصال، حاول مرة أخرى');
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<UserModel>> loadCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) {
      return ServiceResult.failure('لم يتم تسجيل الدخول');
    }
    final result = await _getUserData(userId);
    if (result.success) {
      _currentUser = result.data;
      _audit.setCurrentUser(_currentUser!.id, _currentUser!.name);
    }
    return result;
  }

  Future<ServiceResult<UserModel>> _getUserData(String userId) async {
    try {
      final result = await _firebase.get(AppConstants.usersCollection, userId);
      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }
      final data = result.data!.data();
      if (data == null) {
        return ServiceResult.failure('بيانات المستخدم غير موجودة');
      }
      return ServiceResult.success(UserModel.fromMap(userId, data));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firebase.update(AppConstants.usersCollection, userId, {
        'lastLoginAt': DateTime.now(),
      });
    } catch (e) {
      AppLogger.e('فشل تحديث آخر تسجيل دخول', error: e);
    }
  }

  Future<void> _saveSession(UserModel user) async {
    await _storage.saveSession(
      userId: user.id,
      userName: user.name,
      userRole: user.role,
    );
  }

  Future<ServiceResult<void>> updateUserName(String name) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return ServiceResult.failure('يجب تسجيل الدخول');
      }

      final trimmedName = name.trim();
      if (trimmedName.length < 2) {
        return ServiceResult.failure('الاسم يجب أن يكون حرفين على الأقل');
      }

      await _firebase.auth.currentUser?.updateDisplayName(trimmedName);
      await _firebase.update(AppConstants.usersCollection, userId, {
        'name': trimmedName,
      });
      _currentUser = _currentUser?.copyWith(name: trimmedName);
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> updateUserPhoto(String photoUrl) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return ServiceResult.failure('يجب تسجيل الدخول');
      }
      await _firebase.update(AppConstants.usersCollection, userId, {
        'photoUrl': photoUrl,
      });
      _currentUser = _currentUser?.copyWith(photoUrl: photoUrl);
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// ✅ رسائل خطأ موحدة لمنع تسريب المعلومات
  String _handleAuthError(FirebaseAuthException e) {
    AppLogger.e('Auth Error: ${e.code}', error: e);

    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // ✅ رسالة موحدة لمنع كشف معلومات
        return 'بيانات الدخول غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return AppConstants.networkError;
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }

  // ==================== إدارة المستخدمين ====================

  Future<ServiceResult<List<UserModel>>> getPendingUsers() async {
    try {
      final result = await _firebase.getAll(
        AppConstants.usersCollection,
        queryBuilder: (ref) => ref
            .where('accountStatus', isEqualTo: AccountStatus.pending)
            .orderBy('createdAt', descending: true),
      );
      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }
      return ServiceResult.success(
        result.data!.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList(),
      );
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<List<UserModel>>> getAllUsers() async {
    try {
      final result = await _firebase.getAll(
        AppConstants.usersCollection,
        queryBuilder: (ref) => ref.orderBy('createdAt', descending: true),
      );
      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }
      return ServiceResult.success(
        result.data!.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList(),
      );
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> approveUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure(AppConstants.permissionDenied);
      }
      final userResult = await _getUserData(userId);
      await _firebase.update(AppConstants.usersCollection, userId, {
        'accountStatus': AccountStatus.approved,
        'approvedAt': DateTime.now(),
        'approvedBy': _currentUser!.id,
      });
      if (userResult.success) {
        await _audit.logApproveUser(
          userId: userId,
          userName: userResult.data!.name,
        );
      }
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> rejectUser(String userId, String reason) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure(AppConstants.permissionDenied);
      }
      final userResult = await _getUserData(userId);
      await _firebase.update(AppConstants.usersCollection, userId, {
        'accountStatus': AccountStatus.rejected,
        'rejectionReason': reason,
        'isActive': false,
      });
      if (userResult.success) {
        await _audit.logRejectUser(
          userId: userId,
          userName: userResult.data!.name,
          reason: reason,
        );
      }
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  Future<ServiceResult<void>> deactivateUser(String userId) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      return ServiceResult.failure(AppConstants.permissionDenied);
    }
    return _firebase.update(AppConstants.usersCollection, userId, {
      'isActive': false,
    });
  }

  Future<ServiceResult<void>> activateUser(String userId) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      return ServiceResult.failure(AppConstants.permissionDenied);
    }
    return _firebase.update(AppConstants.usersCollection, userId, {
      'isActive': true,
    });
  }

  Future<ServiceResult<void>> changeUserRole(
    String userId,
    String newRole,
  ) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      return ServiceResult.failure(AppConstants.permissionDenied);
    }
    return _firebase.update(AppConstants.usersCollection, userId, {
      'role': newRole,
    });
  }

  Future<ServiceResult<void>> deleteUser(String userId) async {
    if (_currentUser == null || !_currentUser!.isAdmin) {
      return ServiceResult.failure(AppConstants.permissionDenied);
    }
    return _firebase.delete(AppConstants.usersCollection, userId);
  }

  Stream<List<UserModel>> streamPendingUsers() {
    return _firebase
        .streamCollection(
          AppConstants.usersCollection,
          queryBuilder: (ref) => ref
              .where('accountStatus', isEqualTo: AccountStatus.pending)
              .orderBy('createdAt', descending: true),
        )
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // للتوافق مع الكود القديم
  Future<ServiceResult<UserModel>> signIn(String email, String password) =>
      signInWithEmail(email, password);

  Future<ServiceResult<UserModel>> signUp({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.roleEmployee,
  }) =>
      signUpWithEmail(email: email, password: password, name: name, role: role);

  @override
  void dispose() {
    _loginAttempts.clear();
    super.dispose();
  }
}
