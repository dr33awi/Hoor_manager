import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// تنفيذ مستودع المصادقة مع Firebase
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  UserModel? _cachedUser;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  /// مرجع مجموعة المستخدمين
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  UserEntity? get currentUser => _cachedUser;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cachedUser = null;
        return null;
      }

      final result = await getUserData(user.uid);
      return result.valueOrNull;
    });
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Failure('فشل تسجيل الدخول');
      }

      // جلب بيانات المستخدم من Firestore
      final userResult = await getUserData(credential.user!.uid);
      if (userResult.isFailure) {
        return Failure(userResult.errorOrNull ?? 'فشل جلب بيانات المستخدم');
      }

      final user = userResult.valueOrNull!;

      // التحقق من حالة الحساب
      if (!user.canAccessApp) {
        if (user.isPendingApproval) {
          return const Failure('حسابك في انتظار موافقة المدير');
        }
        return const Failure('حسابك غير مفعّل، تواصل مع الإدارة');
      }

      // تحديث آخر تسجيل دخول
      await updateLastLogin();

      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (e) {
      return Failure('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      // بدء عملية تسجيل الدخول بـ Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure('تم إلغاء تسجيل الدخول');
      }

      // الحصول على بيانات المصادقة
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول في Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Failure('فشل تسجيل الدخول');
      }

      // التحقق من وجود المستخدم في Firestore
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // مستخدم جديد - إنشاء حساب
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          fullName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.employee,
          status: AccountStatus.pending,
          createdAt: DateTime.now(),
        );

        await _usersCollection.doc(firebaseUser.uid).set(newUser.toMap());
        _cachedUser = newUser;

        return const Failure('تم إنشاء حسابك، في انتظار موافقة المدير');
      }

      // مستخدم موجود
      final user = UserModel.fromDocument(userDoc);
      _cachedUser = user;

      if (!user.canAccessApp) {
        if (user.isPendingApproval) {
          return const Failure('حسابك في انتظار موافقة المدير');
        }
        return const Failure('حسابك غير مفعّل، تواصل مع الإدارة');
      }

      await updateLastLogin();
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (e) {
      return Failure('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // إنشاء حساب في Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Failure('فشل إنشاء الحساب');
      }

      // تحديث اسم المستخدم
      await credential.user!.updateDisplayName(fullName);

      // إنشاء بيانات المستخدم في Firestore
      final newUser = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone?.trim(),
        role: UserRole.employee,
        status: AccountStatus.pending,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(credential.user!.uid).set(newUser.toMap());

      // إرسال بريد التحقق
      await credential.user!.sendEmailVerification();

      _cachedUser = newUser;
      return Success(newUser);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (e) {
      return Failure('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _cachedUser = null;
      return const Success(null);
    } catch (e) {
      return Failure('فشل تسجيل الخروج: $e');
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (e) {
      return Failure('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<Result<void>> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Failure('لم يتم تسجيل الدخول');
      }
      await user.sendEmailVerification();
      return const Success(null);
    } catch (e) {
      return Failure('فشل إرسال بريد التحقق: $e');
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Failure('لم يتم تسجيل الدخول');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) {
        updates['fullName'] = fullName.trim();
        await user.updateDisplayName(fullName.trim());
      }
      if (phone != null) updates['phone'] = phone.trim();
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await user.updatePhotoURL(photoUrl);
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(user.uid).update(updates);
      }

      final result = await getUserData(user.uid);
      return result;
    } catch (e) {
      return Failure('فشل تحديث البيانات: $e');
    }
  }

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return const Failure('لم يتم تسجيل الدخول');
      }

      // إعادة المصادقة
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // تحديث كلمة المرور
      await user.updatePassword(newPassword);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (e) {
      return Failure('فشل تحديث كلمة المرور: $e');
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Failure('لم يتم تسجيل الدخول');
      }

      // حذف بيانات المستخدم من Firestore
      await _usersCollection.doc(user.uid).delete();

      // حذف الحساب
      await user.delete();
      _cachedUser = null;

      return const Success(null);
    } catch (e) {
      return Failure('فشل حذف الحساب: $e');
    }
  }

  @override
  Future<Result<UserEntity>> getUserData(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        return const Failure('المستخدم غير موجود');
      }

      final user = UserModel.fromDocument(doc);
      _cachedUser = user;
      return Success(user);
    } catch (e) {
      return Failure('فشل جلب بيانات المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> updateLastLogin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Success(null);

      await _usersCollection.doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      // لا نريد فشل العملية بسبب هذا
      return const Success(null);
    }
  }

  /// تحويل أخطاء Firebase لرسائل عربية
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      case 'requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}
