// lib/features/auth/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'admin' or 'employee'
  final String status; // 'pending', 'approved', 'rejected'
  final bool isActive;
  final bool isGoogleUser;
  final bool emailVerified; // ✅ حقل جديد
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'employee',
    this.status = 'pending',
    this.isActive = true,
    this.isGoogleUser = false,
    this.emailVerified = false, // ✅ افتراضي false
    required this.createdAt,
    this.lastLoginAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'employee',
      status: data['status'] ?? 'approved',
      isActive: data['isActive'] ?? true,
      isGoogleUser: data['isGoogleUser'] ?? false,
      emailVerified: data['emailVerified'] ?? false, // ✅
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'employee',
      status: data['status'] ?? 'approved',
      isActive: data['isActive'] ?? true,
      isGoogleUser: data['isGoogleUser'] ?? false,
      emailVerified: data['emailVerified'] ?? false, // ✅
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'isActive': isActive,
      'isGoogleUser': isGoogleUser,
      'emailVerified': emailVerified, // ✅
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    String? status,
    bool? isActive,
    bool? isGoogleUser,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // الحالات
  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' && isActive;
  bool get isRejected => status == 'rejected';

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, role: $role, status: $status, emailVerified: $emailVerified)';
}
