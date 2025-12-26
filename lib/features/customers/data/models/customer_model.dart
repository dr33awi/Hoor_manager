import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج العميل للتعامل مع Firestore
class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.city,
    super.taxNumber,
    super.commercialRegister,
    super.type,
    super.status,
    super.creditLimit,
    super.balance,
    super.totalPurchases,
    super.totalPayments,
    super.invoicesCount,
    super.notes,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.lastPurchaseDate,
  });

  /// إنشاء من Map
  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      city: map['city'],
      taxNumber: map['taxNumber'],
      commercialRegister: map['commercialRegister'],
      type: CustomerType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CustomerType.regular,
      ),
      status: CustomerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CustomerStatus.active,
      ),
      creditLimit: (map['creditLimit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      totalPurchases: (map['totalPurchases'] ?? 0).toDouble(),
      totalPayments: (map['totalPayments'] ?? 0).toDouble(),
      invoicesCount: map['invoicesCount'] ?? 0,
      notes: map['notes'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      createdBy: map['createdBy'],
      lastPurchaseDate: _parseDateTime(map['lastPurchaseDate']),
    );
  }

  /// تحويل قيمة التاريخ
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as int) * 1000 + ((nanoseconds as int) ~/ 1000000),
        );
      }
    }
    return null;
  }

  /// إنشاء من DocumentSnapshot
  factory CustomerModel.fromDocument(DocumentSnapshot doc) {
    return CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من Entity
  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      taxNumber: entity.taxNumber,
      commercialRegister: entity.commercialRegister,
      type: entity.type,
      status: entity.status,
      creditLimit: entity.creditLimit,
      balance: entity.balance,
      totalPurchases: entity.totalPurchases,
      totalPayments: entity.totalPayments,
      invoicesCount: entity.invoicesCount,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
      lastPurchaseDate: entity.lastPurchaseDate,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'taxNumber': taxNumber,
      'commercialRegister': commercialRegister,
      'type': type.name,
      'status': status.name,
      'creditLimit': creditLimit,
      'balance': balance,
      'totalPurchases': totalPurchases,
      'totalPayments': totalPayments,
      'invoicesCount': invoicesCount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'lastPurchaseDate': lastPurchaseDate != null
          ? Timestamp.fromDate(lastPurchaseDate!)
          : null,
      // حقول للبحث
      'searchTerms': _generateSearchTerms(),
    };
  }

  /// توليد مصطلحات البحث
  List<String> _generateSearchTerms() {
    final terms = <String>[];
    if (name.isNotEmpty) {
      terms.add(name.toLowerCase());
      terms.addAll(name.toLowerCase().split(' '));
    }
    if (phone != null && phone!.isNotEmpty) {
      terms.add(phone!);
    }
    if (email != null && email!.isNotEmpty) {
      terms.add(email!.toLowerCase());
    }
    return terms;
  }

  /// تحويل إلى Map للتحديث
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'taxNumber': taxNumber,
      'commercialRegister': commercialRegister,
      'type': type.name,
      'status': status.name,
      'creditLimit': creditLimit,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
      'searchTerms': _generateSearchTerms(),
    };
  }
}
