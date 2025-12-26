import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// موديل الحساب
class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.code,
    required super.name,
    super.nameEn,
    required super.type,
    super.status,
    super.parentId,
    super.parentCode,
    super.level,
    super.isParent,
    super.canPost,
    super.openingBalance,
    super.currentBalance,
    super.currency,
    super.description,
    super.metadata,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      nameEn: entity.nameEn,
      type: entity.type,
      status: entity.status,
      parentId: entity.parentId,
      parentCode: entity.parentCode,
      level: entity.level,
      isParent: entity.isParent,
      canPost: entity.canPost,
      openingBalance: entity.openingBalance,
      currentBalance: entity.currentBalance,
      currency: entity.currency,
      description: entity.description,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      nameEn: map['nameEn'],
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.asset,
      ),
      status: AccountStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AccountStatus.active,
      ),
      parentId: map['parentId'],
      parentCode: map['parentCode'],
      level: map['level'] ?? 1,
      isParent: map['isParent'] ?? false,
      canPost: map['canPost'] ?? true,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0,
      currency: map['currency'],
      description: map['description'],
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'nameEn': nameEn,
      'type': type.name,
      'status': status.name,
      'parentId': parentId,
      'parentCode': parentCode,
      'level': level,
      'isParent': isParent,
      'canPost': canPost,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'currency': currency,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'searchTerms': _generateSearchTerms(),
    };
  }

  List<String> _generateSearchTerms() {
    final terms = <String>[];
    terms.add(code.toLowerCase());
    terms.addAll(name.toLowerCase().split(' '));
    if (nameEn != null) {
      terms.addAll(nameEn!.toLowerCase().split(' '));
    }
    return terms;
  }
}

/// موديل القيد اليومي
class JournalEntryModel extends JournalEntryEntity {
  const JournalEntryModel({
    required super.id,
    required super.entryNumber,
    required super.entryDate,
    super.status,
    required super.description,
    super.referenceType,
    super.referenceId,
    super.referenceNumber,
    super.lines,
    super.totalDebit,
    super.totalCredit,
    super.notes,
    required super.createdBy,
    super.postedBy,
    super.postedAt,
    super.reversedBy,
    super.reversedAt,
    super.reversalEntryId,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory JournalEntryModel.fromEntity(JournalEntryEntity entity) {
    return JournalEntryModel(
      id: entity.id,
      entryNumber: entity.entryNumber,
      entryDate: entity.entryDate,
      status: entity.status,
      description: entity.description,
      referenceType: entity.referenceType,
      referenceId: entity.referenceId,
      referenceNumber: entity.referenceNumber,
      lines:
          entity.lines.map((e) => JournalEntryLineModel.fromEntity(e)).toList(),
      totalDebit: entity.totalDebit,
      totalCredit: entity.totalCredit,
      notes: entity.notes,
      createdBy: entity.createdBy,
      postedBy: entity.postedBy,
      postedAt: entity.postedAt,
      reversedBy: entity.reversedBy,
      reversedAt: entity.reversedAt,
      reversalEntryId: entity.reversalEntryId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory JournalEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntryModel(
      id: id,
      entryNumber: map['entryNumber'] ?? '',
      entryDate: (map['entryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: JournalEntryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JournalEntryStatus.draft,
      ),
      description: map['description'] ?? '',
      referenceType: map['referenceType'],
      referenceId: map['referenceId'],
      referenceNumber: map['referenceNumber'],
      lines: (map['lines'] as List<dynamic>?)
              ?.map((e) =>
                  JournalEntryLineModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDebit: (map['totalDebit'] as num?)?.toDouble() ?? 0,
      totalCredit: (map['totalCredit'] as num?)?.toDouble() ?? 0,
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      postedBy: map['postedBy'],
      postedAt: (map['postedAt'] as Timestamp?)?.toDate(),
      reversedBy: map['reversedBy'],
      reversedAt: (map['reversedAt'] as Timestamp?)?.toDate(),
      reversalEntryId: map['reversalEntryId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'entryNumber': entryNumber,
      'entryDate': Timestamp.fromDate(entryDate),
      'status': status.name,
      'description': description,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'lines': lines
          .map((e) => JournalEntryLineModel.fromEntity(e).toMap())
          .toList(),
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'notes': notes,
      'createdBy': createdBy,
      'postedBy': postedBy,
      'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'reversedBy': reversedBy,
      'reversedAt': reversedAt != null ? Timestamp.fromDate(reversedAt!) : null,
      'reversalEntryId': reversalEntryId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// موديل سطر القيد
class JournalEntryLineModel extends JournalEntryLineEntity {
  const JournalEntryLineModel({
    required super.id,
    required super.accountId,
    required super.accountCode,
    required super.accountName,
    super.debit,
    super.credit,
    super.description,
    super.costCenterId,
    super.costCenterName,
  });

  /// تحويل من Entity
  factory JournalEntryLineModel.fromEntity(JournalEntryLineEntity entity) {
    return JournalEntryLineModel(
      id: entity.id,
      accountId: entity.accountId,
      accountCode: entity.accountCode,
      accountName: entity.accountName,
      debit: entity.debit,
      credit: entity.credit,
      description: entity.description,
      costCenterId: entity.costCenterId,
      costCenterName: entity.costCenterName,
    );
  }

  /// تحويل من Map
  factory JournalEntryLineModel.fromMap(Map<String, dynamic> map) {
    return JournalEntryLineModel(
      id: map['id'] ?? '',
      accountId: map['accountId'] ?? '',
      accountCode: map['accountCode'] ?? '',
      accountName: map['accountName'] ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0,
      description: map['description'],
      costCenterId: map['costCenterId'],
      costCenterName: map['costCenterName'],
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'accountCode': accountCode,
      'accountName': accountName,
      'debit': debit,
      'credit': credit,
      'description': description,
      'costCenterId': costCenterId,
      'costCenterName': costCenterName,
    };
  }
}

/// موديل مركز التكلفة
class CostCenterModel extends CostCenterEntity {
  const CostCenterModel({
    required super.id,
    required super.code,
    required super.name,
    super.parentId,
    super.isActive,
    super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory CostCenterModel.fromEntity(CostCenterEntity entity) {
    return CostCenterModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      parentId: entity.parentId,
      isActive: entity.isActive,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory CostCenterModel.fromMap(Map<String, dynamic> map, String id) {
    return CostCenterModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'],
      isActive: map['isActive'] ?? true,
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'parentId': parentId,
      'isActive': isActive,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
