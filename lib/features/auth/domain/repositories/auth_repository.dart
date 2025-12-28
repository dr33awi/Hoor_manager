import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع المصادقة
abstract class AuthRepository {
  /// الحصول على المستخدم الحالي
  UserEntity? get currentUser;

  /// مراقبة حالة المصادقة
  Stream<UserEntity?> get authStateChanges;

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// تسجيل الدخول بواسطة Google
  Future<Result<UserEntity>> signInWithGoogle();

  /// إنشاء حساب جديد
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// تسجيل الخروج
  Future<Result<void>> signOut();

  /// إعادة تعيين كلمة المرور
  Future<Result<void>> resetPassword(String email);

  /// إعادة إرسال بريد التحقق
  Future<Result<void>> resendVerificationEmail();

  /// تحديث بيانات المستخدم
  Future<Result<UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  });

  /// تحديث كلمة المرور
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// حذف الحساب
  Future<Result<void>> deleteAccount();

  /// الحصول على بيانات المستخدم من Firestore
  Future<Result<UserEntity>> getUserData(String userId);

  /// تحديث آخر تسجيل دخول
  Future<Result<void>> updateLastLogin();
}

/// واجهة إدارة المستخدمين (للمدير والمؤسس)
abstract class UserManagementRepository {
  /// الحصول على قائمة المستخدمين
  Future<Result<List<UserEntity>>> getUsers();

  /// مراقبة قائمة المستخدمين (تحديث تلقائي)
  Stream<List<UserEntity>> watchUsers();

  /// الحصول على المستخدمين في انتظار الموافقة
  Future<Result<List<UserEntity>>> getPendingUsers();

  /// الموافقة على مستخدم
  Future<Result<void>> approveUser(String userId, String approvedBy);

  /// رفض مستخدم
  Future<Result<void>> rejectUser(String userId);

  /// تعليق مستخدم
  Future<Result<void>> suspendUser(String userId);

  /// تفعيل مستخدم معلق
  Future<Result<void>> activateUser(String userId);

  /// تغيير دور المستخدم
  Future<Result<void>> changeUserRole(String userId, UserRole newRole);

  /// حذف مستخدم
  Future<Result<void>> deleteUser(String userId);
}
