import 'package:flutter/material.dart';

/// نوع الحساب
enum AccountType {
  asset, // أصول
  liability, // خصوم
  equity, // حقوق ملكية
  revenue, // إيرادات
  expense; // مصروفات

  String get arabicName {
    switch (this) {
      case AccountType.asset:
        return 'أصول';
      case AccountType.liability:
        return 'خصوم';
      case AccountType.equity:
        return 'حقوق ملكية';
      case AccountType.revenue:
        return 'إيرادات';
      case AccountType.expense:
        return 'مصروفات';
    }
  }

  Color get color {
    switch (this) {
      case AccountType.asset:
        return Colors.blue;
      case AccountType.liability:
        return Colors.red;
      case AccountType.equity:
        return Colors.purple;
      case AccountType.revenue:
        return Colors.green;
      case AccountType.expense:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.asset:
        return Icons.account_balance_wallet;
      case AccountType.liability:
        return Icons.credit_card;
      case AccountType.equity:
        return Icons.pie_chart;
      case AccountType.revenue:
        return Icons.trending_up;
      case AccountType.expense:
        return Icons.trending_down;
    }
  }

  /// هل الطبيعة مدين
  bool get isDebitNature {
    switch (this) {
      case AccountType.asset:
      case AccountType.expense:
        return true;
      case AccountType.liability:
      case AccountType.equity:
      case AccountType.revenue:
        return false;
    }
  }
}

/// حالة الحساب
enum AccountStatus {
  active,
  inactive,
  frozen;

  String get arabicName {
    switch (this) {
      case AccountStatus.active:
        return 'نشط';
      case AccountStatus.inactive:
        return 'غير نشط';
      case AccountStatus.frozen:
        return 'مجمد';
    }
  }

  Color get color {
    switch (this) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.inactive:
        return Colors.grey;
      case AccountStatus.frozen:
        return Colors.blue;
    }
  }
}

/// حالة القيد
enum JournalEntryStatus {
  draft,
  posted,
  reversed;

  String get arabicName {
    switch (this) {
      case JournalEntryStatus.draft:
        return 'مسودة';
      case JournalEntryStatus.posted:
        return 'مرحّل';
      case JournalEntryStatus.reversed:
        return 'معكوس';
    }
  }

  Color get color {
    switch (this) {
      case JournalEntryStatus.draft:
        return Colors.grey;
      case JournalEntryStatus.posted:
        return Colors.green;
      case JournalEntryStatus.reversed:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case JournalEntryStatus.draft:
        return Icons.edit;
      case JournalEntryStatus.posted:
        return Icons.check_circle;
      case JournalEntryStatus.reversed:
        return Icons.undo;
    }
  }
}

/// كيان الحساب (شجرة الحسابات)
class AccountEntity {
  final String id;
  final String code; // رقم الحساب
  final String name;
  final String? nameEn; // الاسم بالإنجليزية
  final AccountType type;
  final AccountStatus status;
  final String? parentId; // الحساب الأب
  final String? parentCode;
  final int level; // مستوى الحساب في الشجرة
  final bool isParent; // هل هو حساب رئيسي
  final bool canPost; // هل يمكن الترحيل عليه
  final double openingBalance; // الرصيد الافتتاحي
  final double currentBalance; // الرصيد الحالي
  final String? currency;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountEntity({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    required this.type,
    this.status = AccountStatus.active,
    this.parentId,
    this.parentCode,
    this.level = 1,
    this.isParent = false,
    this.canPost = true,
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.currency,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  AccountEntity copyWith({
    String? id,
    String? code,
    String? name,
    String? nameEn,
    AccountType? type,
    AccountStatus? status,
    String? parentId,
    String? parentCode,
    int? level,
    bool? isParent,
    bool? canPost,
    double? openingBalance,
    double? currentBalance,
    String? currency,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      status: status ?? this.status,
      parentId: parentId ?? this.parentId,
      parentCode: parentCode ?? this.parentCode,
      level: level ?? this.level,
      isParent: isParent ?? this.isParent,
      canPost: canPost ?? this.canPost,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان القيد اليومي
class JournalEntryEntity {
  final String id;
  final String entryNumber; // رقم القيد
  final DateTime entryDate;
  final JournalEntryStatus status;
  final String description;
  final String? referenceType; // invoice, payment, etc.
  final String? referenceId;
  final String? referenceNumber;
  final List<JournalEntryLineEntity> lines;
  final double totalDebit;
  final double totalCredit;
  final String? notes;
  final String createdBy;
  final String? postedBy;
  final DateTime? postedAt;
  final String? reversedBy;
  final DateTime? reversedAt;
  final String? reversalEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntryEntity({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    this.status = JournalEntryStatus.draft,
    required this.description,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.lines = const [],
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.notes,
    required this.createdBy,
    this.postedBy,
    this.postedAt,
    this.reversedBy,
    this.reversedAt,
    this.reversalEntryId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// هل القيد متوازن
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  /// عدد السطور
  int get lineCount => lines.length;

  JournalEntryEntity copyWith({
    String? id,
    String? entryNumber,
    DateTime? entryDate,
    JournalEntryStatus? status,
    String? description,
    String? referenceType,
    String? referenceId,
    String? referenceNumber,
    List<JournalEntryLineEntity>? lines,
    double? totalDebit,
    double? totalCredit,
    String? notes,
    String? createdBy,
    String? postedBy,
    DateTime? postedAt,
    String? reversedBy,
    DateTime? reversedAt,
    String? reversalEntryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      entryNumber: entryNumber ?? this.entryNumber,
      entryDate: entryDate ?? this.entryDate,
      status: status ?? this.status,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      lines: lines ?? this.lines,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      postedBy: postedBy ?? this.postedBy,
      postedAt: postedAt ?? this.postedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reversedAt: reversedAt ?? this.reversedAt,
      reversalEntryId: reversalEntryId ?? this.reversalEntryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان سطر القيد
class JournalEntryLineEntity {
  final String id;
  final String accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String? description;
  final String? costCenterId;
  final String? costCenterName;

  const JournalEntryLineEntity({
    required this.id,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.debit = 0,
    this.credit = 0,
    this.description,
    this.costCenterId,
    this.costCenterName,
  });

  /// هل هو سطر مدين
  bool get isDebit => debit > 0;

  /// القيمة
  double get amount => isDebit ? debit : credit;

  JournalEntryLineEntity copyWith({
    String? id,
    String? accountId,
    String? accountCode,
    String? accountName,
    double? debit,
    double? credit,
    String? description,
    String? costCenterId,
    String? costCenterName,
  }) {
    return JournalEntryLineEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      description: description ?? this.description,
      costCenterId: costCenterId ?? this.costCenterId,
      costCenterName: costCenterName ?? this.costCenterName,
    );
  }
}

/// كيان مركز التكلفة
class CostCenterEntity {
  final String id;
  final String code;
  final String name;
  final String? parentId;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CostCenterEntity({
    required this.id,
    required this.code,
    required this.name,
    this.parentId,
    this.isActive = true,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  CostCenterEntity copyWith({
    String? id,
    String? code,
    String? name,
    String? parentId,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CostCenterEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان رصيد الحساب
class AccountBalanceEntity {
  final String accountId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final double openingDebit;
  final double openingCredit;
  final double periodDebit;
  final double periodCredit;
  final double closingDebit;
  final double closingCredit;

  const AccountBalanceEntity({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    this.openingDebit = 0,
    this.openingCredit = 0,
    this.periodDebit = 0,
    this.periodCredit = 0,
    this.closingDebit = 0,
    this.closingCredit = 0,
  });

  /// الرصيد الافتتاحي
  double get openingBalance => openingDebit - openingCredit;

  /// حركة الفترة
  double get periodMovement => periodDebit - periodCredit;

  /// الرصيد الختامي
  double get closingBalance => closingDebit - closingCredit;
}
