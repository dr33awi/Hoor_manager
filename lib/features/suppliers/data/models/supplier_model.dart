import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج المورد للتعامل مع Firestore
class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.contactPerson,
    super.phone,
    super.phone2,
    super.email,
    super.address,
    super.city,
    super.country,
    super.taxNumber,
    super.commercialRegister,
    super.bankName,
    super.bankAccount,
    super.iban,
    super.status,
    super.rating,
    super.balance,
    super.totalPurchases,
    super.totalPayments,
    super.purchaseOrdersCount,
    super.productCategories,
    super.notes,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.lastPurchaseDate,
  });

  /// إنشاء من Map
  factory SupplierModel.fromMap(Map<String, dynamic> map, String id) {
    return SupplierModel(
      id: id,
      name: map['name'] ?? '',
      contactPerson: map['contactPerson'],
      phone: map['phone'],
      phone2: map['phone2'],
      email: map['email'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      taxNumber: map['taxNumber'],
      commercialRegister: map['commercialRegister'],
      bankName: map['bankName'],
      bankAccount: map['bankAccount'],
      iban: map['iban'],
      status: SupplierStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SupplierStatus.active,
      ),
      rating: SupplierRating.values.firstWhere(
        (e) => e.name == map['rating'],
        orElse: () => SupplierRating.good,
      ),
      balance: (map['balance'] ?? 0).toDouble(),
      totalPurchases: (map['totalPurchases'] ?? 0).toDouble(),
      totalPayments: (map['totalPayments'] ?? 0).toDouble(),
      purchaseOrdersCount: map['purchaseOrdersCount'] ?? 0,
      productCategories: List<String>.from(map['productCategories'] ?? []),
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
  factory SupplierModel.fromDocument(DocumentSnapshot doc) {
    return SupplierModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من Entity
  factory SupplierModel.fromEntity(SupplierEntity entity) {
    return SupplierModel(
      id: entity.id,
      name: entity.name,
      contactPerson: entity.contactPerson,
      phone: entity.phone,
      phone2: entity.phone2,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      country: entity.country,
      taxNumber: entity.taxNumber,
      commercialRegister: entity.commercialRegister,
      bankName: entity.bankName,
      bankAccount: entity.bankAccount,
      iban: entity.iban,
      status: entity.status,
      rating: entity.rating,
      balance: entity.balance,
      totalPurchases: entity.totalPurchases,
      totalPayments: entity.totalPayments,
      purchaseOrdersCount: entity.purchaseOrdersCount,
      productCategories: entity.productCategories,
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
      'contactPerson': contactPerson,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'taxNumber': taxNumber,
      'commercialRegister': commercialRegister,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'iban': iban,
      'status': status.name,
      'rating': rating.name,
      'balance': balance,
      'totalPurchases': totalPurchases,
      'totalPayments': totalPayments,
      'purchaseOrdersCount': purchaseOrdersCount,
      'productCategories': productCategories,
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
    if (contactPerson != null && contactPerson!.isNotEmpty) {
      terms.add(contactPerson!.toLowerCase());
    }
    return terms;
  }

  /// تحويل إلى Map للتحديث
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'taxNumber': taxNumber,
      'commercialRegister': commercialRegister,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'iban': iban,
      'status': status.name,
      'rating': rating.name,
      'productCategories': productCategories,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
      'searchTerms': _generateSearchTerms(),
    };
  }
}
