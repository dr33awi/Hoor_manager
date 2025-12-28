import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج المستخدم للتعامل مع Firestore
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    required super.status,
    super.photoUrl,
    required super.createdAt,
    super.lastLoginAt,
    super.approvedBy,
    super.approvedAt,
  });

  /// إنشاء من Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'],
      role: UserRole.fromString(map['role']),
      status: AccountStatus.fromString(map['status']),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// إنشاء من DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      role: entity.role,
      status: entity.status,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
    );
  }

  /// تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.value,
      'status': status.value,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  /// تحويل إلى Map للتحديث
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    return map;
  }

  /// نسخة معدلة
  @override
  UserModel copyWith({
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
    return UserModel(
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
}
