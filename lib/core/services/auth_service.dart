// lib/core/services/auth_service.dart
// خدمة المصادقة الموحدة

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';
import 'firebase_service.dart';

/// حالات الموافقة على الحساب
class AccountStatus {
  static const String pending = 'pending'; // في انتظار الموافقة
  static const String approved = 'approved'; // تمت الموافقة
  static const String rejected = 'rejected'; // مرفوض
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
  final String authProvider; // 'email' or 'google'
  final bool isEmailVerified;
  final String accountStatus; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy;

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
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? AppConstants.roleEmployee,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'],
      authProvider: map['authProvider'] ?? 'email',
      isEmailVerified: map['isEmailVerified'] ?? false,
      accountStatus: map['accountStatus'] ?? AccountStatus.pending,
      rejectionReason: map['rejectionReason'],
      approvedAt: map['approvedAt']?.toDate(),
      approvedBy: map['approvedBy'],
    );
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
    };
  }

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isPending => accountStatus == AccountStatus.pending;
  bool get isApproved => accountStatus == AccountStatus.approved;
  bool get isRejected => accountStatus == AccountStatus.rejected;

  /// هل يمكن للمستخدم الدخول (مفعّل + موافق عليه)
  bool get canLogin => isActive && isApproved && isEmailVerified;

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
    );
  }
}

/// خدمة المصادقة
class AuthService extends BaseService {
  final FirebaseService _firebase = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // المستخدم الحالي
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Stream للمستخدم
  Stream<User?> get authStateChanges => _firebase.auth.authStateChanges();

  // هل المستخدم مسجل الدخول
  bool get isLoggedIn => _firebase.auth.currentUser != null;

  // ID المستخدم الحالي
  String? get currentUserId => _firebase.auth.currentUser?.uid;

  // هل البريد الإلكتروني مُتحقق منه
  bool get isEmailVerified =>
      _firebase.auth.currentUser?.emailVerified ?? false;

  /// تسجيل الدخول بالإيميل وكلمة المرور
  Future<ServiceResult<UserModel>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure('فشل تسجيل الدخول');
      }

      // جلب بيانات المستخدم من Firestore أولاً
      final userResult = await _getUserData(credential.user!.uid);
      if (!userResult.success) {
        await _firebase.auth.signOut();
        return ServiceResult.failure(userResult.error!);
      }

      // المدير لا يحتاج للتحقق من البريد
      final isAdmin = userResult.data!.isAdmin;

      // التحقق من البريد الإلكتروني (للمستخدمين العاديين فقط)
      if (!isAdmin && !credential.user!.emailVerified) {
        return ServiceResult.failure(
          'البريد الإلكتروني غير مُفعّل. الرجاء التحقق من بريدك الإلكتروني',
          'email-not-verified',
        );
      }

      // التحقق من حالة الموافقة على الحساب
      if (userResult.data!.isPending) {
        await _firebase.auth.signOut();
        return ServiceResult.failure(
          'حسابك في انتظار موافقة المدير. سيتم إعلامك عند الموافقة',
          'account-pending',
        );
      }

      if (userResult.data!.isRejected) {
        await _firebase.auth.signOut();
        final reason = userResult.data!.rejectionReason ?? 'لم يتم تحديد السبب';
        return ServiceResult.failure(
          'تم رفض طلب تسجيلك. السبب: $reason',
          'account-rejected',
        );
      }

      // التحقق من أن الحساب نشط
      if (!userResult.data!.isActive) {
        await _firebase.auth.signOut();
        return ServiceResult.failure('هذا الحساب معطل، تواصل مع المدير');
      }

      // تحديث حالة التحقق في Firestore إذا لزم الأمر
      if (!userResult.data!.isEmailVerified && credential.user!.emailVerified) {
        await _firebase.update(
          AppConstants.usersCollection,
          credential.user!.uid,
          {'isEmailVerified': true},
        );
      }

      _currentUser = userResult.data!.copyWith(isEmailVerified: true);
      return ServiceResult.success(_currentUser);
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تسجيل الدخول بـ Google
  Future<ServiceResult<UserModel>> signInWithGoogle() async {
    try {
      // بدء عملية تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return ServiceResult.failure('تم إلغاء تسجيل الدخول');
      }

      // الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // إنشاء credential لـ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول في Firebase
      final userCredential = await _firebase.auth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        return ServiceResult.failure('فشل تسجيل الدخول بـ Google');
      }

      final firebaseUser = userCredential.user!;

      // التحقق من وجود المستخدم في Firestore
      final existingUser = await _getUserData(firebaseUser.uid);

      if (existingUser.success) {
        // المستخدم موجود - التحقق من حالة الموافقة
        if (existingUser.data!.isPending) {
          await signOut();
          return ServiceResult.failure(
            'حسابك في انتظار موافقة المدير. سيتم إعلامك عند الموافقة',
            'account-pending',
          );
        }

        if (existingUser.data!.isRejected) {
          await signOut();
          final reason =
              existingUser.data!.rejectionReason ?? 'لم يتم تحديد السبب';
          return ServiceResult.failure(
            'تم رفض طلب تسجيلك. السبب: $reason',
            'account-rejected',
          );
        }

        if (!existingUser.data!.isActive) {
          await signOut();
          return ServiceResult.failure('هذا الحساب معطل، تواصل مع المدير');
        }

        _currentUser = existingUser.data;
        return ServiceResult.success(_currentUser);
      }

      // المستخدم جديد - إنشاء حساب جديد (في انتظار الموافقة)
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name:
            firebaseUser.displayName ??
            googleUser.displayName ??
            'مستخدم Google',
        role: AppConstants.roleEmployee,
        isActive: true,
        createdAt: DateTime.now(),
        photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
        authProvider: 'google',
        isEmailVerified: true, // Google يتحقق تلقائياً
        accountStatus: AccountStatus.pending, // في انتظار الموافقة
      );

      // حفظ بيانات المستخدم في Firestore
      final saveResult = await _firebase.set(
        AppConstants.usersCollection,
        firebaseUser.uid,
        newUser.toMap(),
      );

      if (!saveResult.success) {
        await signOut();
        return ServiceResult.failure('فشل حفظ بيانات المستخدم');
      }

      // تسجيل الخروج لأن الحساب يحتاج موافقة
      await signOut();

      return ServiceResult.failure(
        'تم إنشاء حسابك بنجاح! في انتظار موافقة المدير',
        'account-pending-new',
      );
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(
        'خطأ في تسجيل الدخول بـ Google: ${e.toString()}',
      );
    }
  }

  /// إنشاء حساب جديد بالإيميل (مع إرسال رابط التحقق)
  Future<ServiceResult<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.roleEmployee,
  }) async {
    try {
      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure('فشل إنشاء الحساب');
      }

      // تحديث اسم المستخدم في Firebase Auth
      await credential.user!.updateDisplayName(name);

      // إرسال رابط التحقق من البريد الإلكتروني
      await credential.user!.sendEmailVerification();

      // إنشاء بيانات المستخدم في Firestore (في انتظار الموافقة)
      final userData = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        name: name,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
        authProvider: 'email',
        isEmailVerified: false,
        accountStatus: AccountStatus.pending, // في انتظار الموافقة
      );

      final saveResult = await _firebase.set(
        AppConstants.usersCollection,
        credential.user!.uid,
        userData.toMap(),
      );

      if (!saveResult.success) {
        // حذف المستخدم من Auth إذا فشل الحفظ
        await credential.user!.delete();
        return ServiceResult.failure(saveResult.error!);
      }

      // تسجيل الخروج حتى يتم التحقق من البريد والموافقة
      await _firebase.auth.signOut();

      return ServiceResult.success(userData);
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// إعادة إرسال رابط التحقق من البريد الإلكتروني
  Future<ServiceResult<void>> resendVerificationEmail() async {
    try {
      final user = _firebase.auth.currentUser;
      if (user == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }

      if (user.emailVerified) {
        return ServiceResult.failure('البريد الإلكتروني مُفعّل بالفعل');
      }

      await user.sendEmailVerification();
      return ServiceResult.success();
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// إرسال رابط التحقق لمستخدم غير مسجل دخوله
  Future<ServiceResult<void>> sendVerificationEmailToUser(
    String email,
    String password,
  ) async {
    try {
      // تسجيل الدخول مؤقتاً
      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure('فشل تسجيل الدخول');
      }

      if (credential.user!.emailVerified) {
        await _firebase.auth.signOut();
        return ServiceResult.failure('البريد الإلكتروني مُفعّل بالفعل');
      }

      // إرسال رابط التحقق
      await credential.user!.sendEmailVerification();

      // تسجيل الخروج
      await _firebase.auth.signOut();

      return ServiceResult.success();
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// التحقق من حالة تفعيل البريد الإلكتروني
  Future<ServiceResult<bool>> checkEmailVerified() async {
    try {
      final user = _firebase.auth.currentUser;
      if (user == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }

      // تحديث بيانات المستخدم
      await user.reload();
      final refreshedUser = _firebase.auth.currentUser;

      return ServiceResult.success(refreshedUser?.emailVerified ?? false);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تسجيل مستخدم جديد (للمدير فقط)
  Future<ServiceResult<UserModel>> signUp({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.roleEmployee,
  }) async {
    return signUpWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  /// تسجيل الخروج
  Future<ServiceResult<void>> signOut() async {
    try {
      // تسجيل الخروج من Google إذا كان مسجل دخول
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _firebase.auth.signOut();
      _currentUser = null;
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<ServiceResult<void>> resetPassword(String email) async {
    try {
      await _firebase.auth.sendPasswordResetEmail(email: email.trim());
      return ServiceResult.success();
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تغيير كلمة المرور
  Future<ServiceResult<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _firebase.auth.currentUser;
      if (user == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }

      // التحقق من أن المستخدم مسجل بالإيميل
      if (_currentUser?.authProvider == 'google') {
        return ServiceResult.failure('لا يمكن تغيير كلمة المرور لحساب Google');
      }

      // إعادة المصادقة
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // تغيير كلمة المرور
      await user.updatePassword(newPassword);
      return ServiceResult.success();
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_handleAuthError(e));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// جلب بيانات المستخدم الحالي
  Future<ServiceResult<UserModel>> loadCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) {
      return ServiceResult.failure('لم يتم تسجيل الدخول');
    }

    final result = await _getUserData(userId);
    if (result.success) {
      _currentUser = result.data;
    }
    return result;
  }

  /// جلب بيانات مستخدم من Firestore
  Future<ServiceResult<UserModel>> _getUserData(String userId) async {
    final result = await _firebase.get(AppConstants.usersCollection, userId);

    if (!result.success) {
      return ServiceResult.failure(result.error!);
    }

    final data = result.data!.data();
    if (data == null) {
      return ServiceResult.failure('بيانات المستخدم غير موجودة');
    }

    return ServiceResult.success(UserModel.fromMap(userId, data));
  }

  /// تحديث صورة المستخدم
  Future<ServiceResult<void>> updateUserPhoto(String photoUrl) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
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

  /// تحديث اسم المستخدم
  Future<ServiceResult<void>> updateUserName(String name) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return ServiceResult.failure('يجب تسجيل الدخول أولاً');
      }

      // تحديث في Firebase Auth
      await _firebase.auth.currentUser?.updateDisplayName(name);

      // تحديث في Firestore
      await _firebase.update(AppConstants.usersCollection, userId, {
        'name': name,
      });

      _currentUser = _currentUser?.copyWith(name: name);
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// معالجة أخطاء المصادقة
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
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
        return 'تحقق من اتصالك بالإنترنت';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مسجل بطريقة أخرى';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صالحة';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى';
      default:
        return e.message ?? 'حدث خطأ في المصادقة';
    }
  }

  // ==================== إدارة المستخدمين (للمدير) ====================

  /// جلب قائمة المستخدمين في انتظار الموافقة
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

      final users = result.data!.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();

      return ServiceResult.success(users);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// جلب جميع المستخدمين
  Future<ServiceResult<List<UserModel>>> getAllUsers() async {
    try {
      final result = await _firebase.getAll(
        AppConstants.usersCollection,
        queryBuilder: (ref) => ref.orderBy('createdAt', descending: true),
      );

      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }

      final users = result.data!.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();

      return ServiceResult.success(users);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// الموافقة على حساب مستخدم
  Future<ServiceResult<void>> approveUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      await _firebase.update(AppConstants.usersCollection, userId, {
        'accountStatus': AccountStatus.approved,
        'approvedAt': DateTime.now(),
        'approvedBy': _currentUser!.id,
      });

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// رفض حساب مستخدم
  Future<ServiceResult<void>> rejectUser(String userId, String reason) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      await _firebase.update(AppConstants.usersCollection, userId, {
        'accountStatus': AccountStatus.rejected,
        'rejectionReason': reason,
        'isActive': false,
      });

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تعطيل حساب مستخدم
  Future<ServiceResult<void>> deactivateUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      await _firebase.update(AppConstants.usersCollection, userId, {
        'isActive': false,
      });

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تفعيل حساب مستخدم
  Future<ServiceResult<void>> activateUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      await _firebase.update(AppConstants.usersCollection, userId, {
        'isActive': true,
      });

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تغيير دور المستخدم
  Future<ServiceResult<void>> changeUserRole(
    String userId,
    String newRole,
  ) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      await _firebase.update(AppConstants.usersCollection, userId, {
        'role': newRole,
      });

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// حذف حساب مستخدم نهائياً
  Future<ServiceResult<void>> deleteUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        return ServiceResult.failure('غير مصرح لك بهذه العملية');
      }

      // حذف من Firestore فقط (لا يمكن حذف من Auth بدون Admin SDK)
      await _firebase.delete(AppConstants.usersCollection, userId);

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// Stream للمستخدمين في انتظار الموافقة
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
  Future<ServiceResult<UserModel>> signIn(String email, String password) async {
    return signInWithEmail(email, password);
  }
}
