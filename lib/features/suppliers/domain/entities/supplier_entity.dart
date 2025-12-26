/// حالة المورد
enum SupplierStatus {
  active, // نشط
  inactive, // غير نشط
  blocked, // محظور
}

/// تقييم المورد
enum SupplierRating {
  excellent, // ممتاز
  good, // جيد
  average, // متوسط
  poor, // ضعيف
}

/// كيان المورد
class SupplierEntity {
  final String id;
  final String name;
  final String? contactPerson; // الشخص المسؤول
  final String? phone;
  final String? phone2; // هاتف إضافي
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? taxNumber; // الرقم الضريبي
  final String? commercialRegister; // السجل التجاري
  final String? bankName; // اسم البنك
  final String? bankAccount; // رقم الحساب البنكي
  final String? iban; // رقم IBAN
  final SupplierStatus status;
  final SupplierRating rating;
  final double balance; // الرصيد (موجب = له، سالب = عليه)
  final double totalPurchases; // إجمالي المشتريات
  final double totalPayments; // إجمالي المدفوعات
  final int purchaseOrdersCount; // عدد أوامر الشراء
  final List<String> productCategories; // فئات المنتجات التي يوردها
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? lastPurchaseDate; // تاريخ آخر شراء

  const SupplierEntity({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.phone2,
    this.email,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.commercialRegister,
    this.bankName,
    this.bankAccount,
    this.iban,
    this.status = SupplierStatus.active,
    this.rating = SupplierRating.good,
    this.balance = 0,
    this.totalPurchases = 0,
    this.totalPayments = 0,
    this.purchaseOrdersCount = 0,
    this.productCategories = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lastPurchaseDate,
  });

  /// المبلغ المستحق للمورد
  double get amountDue => balance > 0 ? balance : 0;

  /// المبلغ المستحق من المورد (دفعات مقدمة)
  double get advancePayments => balance < 0 ? balance.abs() : 0;

  /// هل المورد نشط
  bool get isActive => status == SupplierStatus.active;

  /// نسخ مع تعديلات
  SupplierEntity copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? phone2,
    String? email,
    String? address,
    String? city,
    String? country,
    String? taxNumber,
    String? commercialRegister,
    String? bankName,
    String? bankAccount,
    String? iban,
    SupplierStatus? status,
    SupplierRating? rating,
    double? balance,
    double? totalPurchases,
    double? totalPayments,
    int? purchaseOrdersCount,
    List<String>? productCategories,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? lastPurchaseDate,
  }) {
    return SupplierEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      iban: iban ?? this.iban,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      balance: balance ?? this.balance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPayments: totalPayments ?? this.totalPayments,
      purchaseOrdersCount: purchaseOrdersCount ?? this.purchaseOrdersCount,
      productCategories: productCategories ?? this.productCategories,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SupplierEntity(id: $id, name: $name, balance: $balance)';
  }
}
