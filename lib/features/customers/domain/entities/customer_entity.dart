/// تصنيف العميل
enum CustomerType {
  regular, // عادي
  vip, // VIP
  wholesale, // تاجر جملة
}

/// حالة العميل
enum CustomerStatus {
  active, // نشط
  inactive, // غير نشط
  blocked, // محظور
}

/// كيان العميل
class CustomerEntity {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? taxNumber; // الرقم الضريبي
  final String? commercialRegister; // السجل التجاري
  final CustomerType type;
  final CustomerStatus status;
  final double creditLimit; // حد الائتمان
  final double balance; // الرصيد الحالي (موجب = له، سالب = عليه)
  final double totalPurchases; // إجمالي المشتريات
  final double totalPayments; // إجمالي المدفوعات
  final int invoicesCount; // عدد الفواتير
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? lastPurchaseDate; // تاريخ آخر شراء

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.taxNumber,
    this.commercialRegister,
    this.type = CustomerType.regular,
    this.status = CustomerStatus.active,
    this.creditLimit = 0,
    this.balance = 0,
    this.totalPurchases = 0,
    this.totalPayments = 0,
    this.invoicesCount = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lastPurchaseDate,
  });

  /// المبلغ المستحق على العميل
  double get amountDue => balance < 0 ? balance.abs() : 0;

  /// المبلغ المستحق للعميل
  double get amountOwed => balance > 0 ? balance : 0;

  /// هل وصل لحد الائتمان
  bool get isAtCreditLimit => creditLimit > 0 && amountDue >= creditLimit;

  /// هل تجاوز حد الائتمان
  bool get isOverCreditLimit => creditLimit > 0 && amountDue > creditLimit;

  /// الرصيد المتاح للائتمان
  double get availableCredit =>
      creditLimit > 0 ? (creditLimit - amountDue).clamp(0, creditLimit) : 0;

  /// هل العميل نشط
  bool get isActive => status == CustomerStatus.active;

  /// هل العميل VIP
  bool get isVip => type == CustomerType.vip;

  /// هل تاجر جملة
  bool get isWholesale => type == CustomerType.wholesale;

  /// نسخ مع تعديلات
  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? taxNumber,
    String? commercialRegister,
    CustomerType? type,
    CustomerStatus? status,
    double? creditLimit,
    double? balance,
    double? totalPurchases,
    double? totalPayments,
    int? invoicesCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? lastPurchaseDate,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      taxNumber: taxNumber ?? this.taxNumber,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      type: type ?? this.type,
      status: status ?? this.status,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance ?? this.balance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPayments: totalPayments ?? this.totalPayments,
      invoicesCount: invoicesCount ?? this.invoicesCount,
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
    return other is CustomerEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CustomerEntity(id: $id, name: $name, phone: $phone, balance: $balance)';
  }
}
