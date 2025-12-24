import 'user_role.dart';

/// كيان المستخدم
class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? approvedBy;
  final DateTime? approvedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
    this.approvedBy,
    this.approvedAt,
  });

  /// هل المستخدم يمكنه الدخول للتطبيق
  bool get canAccessApp => status.isActive;

  /// هل المستخدم في انتظار الموافقة
  bool get isPendingApproval => status.isPending;

  /// هل المستخدم نشط
  bool get isActive => status.isActive;

  /// هل المستخدم في انتظار الموافقة
  bool get isPending => status.isPending;

  /// هل يمكنه إدارة المستخدمين
  bool get canManageUsers => role == UserRole.founder || role == UserRole.manager;

  /// هل يمكنه إدارة المنتجات
  bool get canManageProducts => role == UserRole.founder || role == UserRole.manager;

  /// هل المستخدم مؤسس
  bool get isFounder => role == UserRole.founder;

  /// هل المستخدم مدير
  bool get isManager => role == UserRole.manager;

  /// هل المستخدم موظف
  bool get isEmployee => role == UserRole.employee;

  /// نسخة معدلة من المستخدم
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    AccountStatus? status,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, fullName: $fullName, role: ${role.arabicName}, status: ${status.arabicName})';
  }
}
