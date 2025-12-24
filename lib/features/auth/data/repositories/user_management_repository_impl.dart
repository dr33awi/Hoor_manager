import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// تنفيذ مستودع إدارة المستخدمين
class UserManagementRepositoryImpl implements UserManagementRepository {
  final FirebaseFirestore _firestore;

  UserManagementRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// مرجع مجموعة المستخدمين
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<Result<List<UserEntity>>> getUsers() async {
    try {
      final snapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      return Success(users);
    } catch (e) {
      return Failure('فشل جلب قائمة المستخدمين: $e');
    }
  }

  /// جلب جميع المستخدمين
  Future<Result<List<UserEntity>>> getAllUsers() async {
    return getUsers();
  }

  @override
  Future<Result<List<UserEntity>>> getPendingUsers() async {
    try {
      final snapshot = await _usersCollection
          .where('status', isEqualTo: AccountStatus.pending.value)
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      return Success(users);
    } catch (e) {
      return Failure('فشل جلب قائمة المستخدمين المنتظرين: $e');
    }
  }

  @override
  Future<Result<void>> approveUser(String userId, [String? approvedBy]) async {
    try {
      await _usersCollection.doc(userId).update({
        'status': AccountStatus.active.value,
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل تفعيل المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> rejectUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'status': AccountStatus.rejected.value,
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل رفض المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> suspendUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'status': AccountStatus.suspended.value,
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل تعليق المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> activateUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'status': AccountStatus.active.value,
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل تفعيل المستخدم: $e');
    }
  }

  /// تبديل حالة المستخدم (تفعيل/تعطيل)
  Future<Result<void>> toggleUserStatus(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        return const Failure('المستخدم غير موجود');
      }

      final currentStatus = AccountStatus.fromString(doc.data()?['status']);
      final newStatus = currentStatus.isActive
          ? AccountStatus.suspended.value
          : AccountStatus.active.value;

      await _usersCollection.doc(userId).update({'status': newStatus});
      return const Success(null);
    } catch (e) {
      return Failure('فشل تغيير حالة المستخدم: $e');
    }
  }

  /// تحديث دور المستخدم
  Future<Result<void>> updateUserRole(String userId, UserRole role) async {
    return changeUserRole(userId, role);
  }

  @override
  Future<Result<void>> changeUserRole(String userId, UserRole newRole) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': newRole.value,
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل تغيير دور المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      return const Success(null);
    } catch (e) {
      return Failure('فشل حذف المستخدم: $e');
    }
  }
}
