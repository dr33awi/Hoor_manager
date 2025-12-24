/// أدوار المستخدمين في التطبيق
enum UserRole {
  /// مؤسس - صلاحيات كاملة
  founder('founder', 'مؤسس', 'صلاحيات كاملة على جميع أقسام التطبيق'),

  /// مدير - إدارة المنتجات والمبيعات والتقارير
  manager('manager', 'مدير', 'إدارة المنتجات والمبيعات والتقارير'),

  /// موظف - المبيعات فقط
  employee('employee', 'موظف', 'صلاحية المبيعات فقط');

  final String value;
  final String arabicName;
  final String arabicDescription;

  const UserRole(this.value, this.arabicName, this.arabicDescription);

  /// تحويل من نص إلى UserRole
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.employee,
    );
  }

  /// هل لديه صلاحية الوصول للتقارير
  bool get canAccessReports =>
      this == UserRole.founder || this == UserRole.manager;

  /// هل لديه صلاحية إدارة المنتجات
  bool get canManageProducts =>
      this == UserRole.founder || this == UserRole.manager;

  /// هل لديه صلاحية إدارة المستخدمين
  bool get canManageUsers => this == UserRole.founder || this == UserRole.manager;

  /// هل لديه صلاحية الإعدادات المتقدمة
  bool get canAccessSettings =>
      this == UserRole.founder || this == UserRole.manager;

  /// هل لديه صلاحية إلغاء الفواتير
  bool get canCancelInvoices =>
      this == UserRole.founder || this == UserRole.manager;

  /// هل لديه صلاحية تطبيق الخصومات
  bool get canApplyDiscounts =>
      this == UserRole.founder || this == UserRole.manager;
}

/// حالة حساب المستخدم
enum AccountStatus {
  /// في انتظار الموافقة
  pending('pending', 'في انتظار الموافقة'),

  /// مفعّل
  active('active', 'مفعّل'),

  /// معلّق
  suspended('suspended', 'معلّق'),

  /// مرفوض
  rejected('rejected', 'مرفوض');

  final String value;
  final String arabicName;

  const AccountStatus(this.value, this.arabicName);

  /// تحويل من نص إلى AccountStatus
  static AccountStatus fromString(String? value) {
    return AccountStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AccountStatus.pending,
    );
  }

  /// هل الحساب نشط
  bool get isActive => this == AccountStatus.active;

  /// هل الحساب في الانتظار
  bool get isPending => this == AccountStatus.pending;
}
