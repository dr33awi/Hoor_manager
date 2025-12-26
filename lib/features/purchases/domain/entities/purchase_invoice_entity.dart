/// نوع فاتورة الشراء
enum PurchaseInvoiceType {
  purchase, // فاتورة شراء عادية
  returnPurchase, // مرتجع مشتريات
  purchaseOrder, // أمر شراء
}

/// حالة فاتورة الشراء
enum PurchaseInvoiceStatus {
  draft, // مسودة
  pending, // معلقة
  approved, // موافق عليها
  received, // تم الاستلام
  partiallyReceived, // استلام جزئي
  completed, // مكتملة
  cancelled, // ملغاة
}

/// حالة الدفع
enum PurchasePaymentStatus {
  unpaid, // غير مدفوعة
  partiallyPaid, // مدفوعة جزئياً
  paid, // مدفوعة بالكامل
}

/// كيان فاتورة الشراء
class PurchaseInvoiceEntity {
  final String id;
  final String invoiceNumber;
  final PurchaseInvoiceType type;
  final PurchaseInvoiceStatus status;
  final PurchasePaymentStatus paymentStatus;
  final String supplierId;
  final String? supplierName;
  final String? supplierInvoiceNumber; // رقم فاتورة المورد
  final DateTime date;
  final DateTime? dueDate; // تاريخ الاستحقاق
  final DateTime? expectedDeliveryDate; // تاريخ التسليم المتوقع
  final List<PurchaseItemEntity> items;
  final double subtotal; // المجموع الفرعي
  final double discountAmount; // قيمة الخصم
  final double discountPercent; // نسبة الخصم
  final double taxAmount; // قيمة الضريبة
  final double taxPercent; // نسبة الضريبة
  final double shippingCost; // تكلفة الشحن
  final double total; // الإجمالي
  final double paidAmount; // المبلغ المدفوع
  final String? warehouseId; // المخزن المستلم
  final String? warehouseName;
  final String? notes;
  final String? terms; // الشروط والأحكام
  final List<String> attachments; // المرفقات
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const PurchaseInvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    this.type = PurchaseInvoiceType.purchase,
    this.status = PurchaseInvoiceStatus.draft,
    this.paymentStatus = PurchasePaymentStatus.unpaid,
    required this.supplierId,
    this.supplierName,
    this.supplierInvoiceNumber,
    required this.date,
    this.dueDate,
    this.expectedDeliveryDate,
    this.items = const [],
    this.subtotal = 0,
    this.discountAmount = 0,
    this.discountPercent = 0,
    this.taxAmount = 0,
    this.taxPercent = 15,
    this.shippingCost = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.warehouseId,
    this.warehouseName,
    this.notes,
    this.terms,
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// المبلغ المتبقي
  double get remainingAmount => total - paidAmount;

  /// هل مدفوعة بالكامل
  bool get isFullyPaid => paidAmount >= total;

  /// هل مرتجع
  bool get isReturn => type == PurchaseInvoiceType.returnPurchase;

  /// عدد الأصناف
  int get itemsCount => items.length;

  /// إجمالي الكميات
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// نسخ مع تعديلات
  PurchaseInvoiceEntity copyWith({
    String? id,
    String? invoiceNumber,
    PurchaseInvoiceType? type,
    PurchaseInvoiceStatus? status,
    PurchasePaymentStatus? paymentStatus,
    String? supplierId,
    String? supplierName,
    String? supplierInvoiceNumber,
    DateTime? date,
    DateTime? dueDate,
    DateTime? expectedDeliveryDate,
    List<PurchaseItemEntity>? items,
    double? subtotal,
    double? discountAmount,
    double? discountPercent,
    double? taxAmount,
    double? taxPercent,
    double? shippingCost,
    double? total,
    double? paidAmount,
    String? warehouseId,
    String? warehouseName,
    String? notes,
    String? terms,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PurchaseInvoiceEntity(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierInvoiceNumber:
          supplierInvoiceNumber ?? this.supplierInvoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseInvoiceEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// كيان صنف المشتريات
class PurchaseItemEntity {
  final String id;
  final String productId;
  final String? productName;
  final String? variantId;
  final String? variantName; // اسم المتغير (اللون + المقاس)
  final String? barcode;
  final int quantity;
  final int receivedQuantity; // الكمية المستلمة
  final double unitCost; // سعر الوحدة
  final double discountAmount;
  final double discountPercent;
  final double taxAmount;
  final double total;
  final String? notes;

  const PurchaseItemEntity({
    required this.id,
    required this.productId,
    this.productName,
    this.variantId,
    this.variantName,
    this.barcode,
    required this.quantity,
    this.receivedQuantity = 0,
    required this.unitCost,
    this.discountAmount = 0,
    this.discountPercent = 0,
    this.taxAmount = 0,
    required this.total,
    this.notes,
  });

  /// سعر الوحدة (alias for unitCost)
  double get unitPrice => unitCost;

  /// إجمالي السعر (alias for total)
  double get totalPrice => total;

  /// الكمية المتبقية للاستلام
  int get remainingQuantity => quantity - receivedQuantity;

  /// هل تم استلام الكمية بالكامل
  bool get isFullyReceived => receivedQuantity >= quantity;

  /// نسخ مع تعديلات
  PurchaseItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    String? variantId,
    String? variantName,
    String? barcode,
    int? quantity,
    int? receivedQuantity,
    double? unitCost,
    double? discountAmount,
    double? discountPercent,
    double? taxAmount,
    double? total,
    String? notes,
  }) {
    return PurchaseItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      unitCost: unitCost ?? this.unitCost,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
    );
  }
}
