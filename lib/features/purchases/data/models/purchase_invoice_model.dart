import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج فاتورة الشراء للتعامل مع Firestore
class PurchaseInvoiceModel extends PurchaseInvoiceEntity {
  const PurchaseInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    super.type,
    super.status,
    super.paymentStatus,
    required super.supplierId,
    super.supplierName,
    super.supplierInvoiceNumber,
    required super.date,
    super.dueDate,
    super.expectedDeliveryDate,
    super.items,
    super.subtotal,
    super.discountAmount,
    super.discountPercent,
    super.taxAmount,
    super.taxPercent,
    super.shippingCost,
    super.total,
    super.paidAmount,
    super.warehouseId,
    super.warehouseName,
    super.notes,
    super.terms,
    super.attachments,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  /// إنشاء من Map
  factory PurchaseInvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((item) =>
                PurchaseItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return PurchaseInvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      type: PurchaseInvoiceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PurchaseInvoiceType.purchase,
      ),
      status: PurchaseInvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PurchaseInvoiceStatus.draft,
      ),
      paymentStatus: PurchasePaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PurchasePaymentStatus.unpaid,
      ),
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'],
      supplierInvoiceNumber: map['supplierInvoiceNumber'],
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      dueDate: _parseDateTime(map['dueDate']),
      expectedDeliveryDate: _parseDateTime(map['expectedDeliveryDate']),
      items: itemsList,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      discountPercent: (map['discountPercent'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      taxPercent: (map['taxPercent'] ?? 15).toDouble(),
      shippingCost: (map['shippingCost'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      warehouseId: map['warehouseId'],
      warehouseName: map['warehouseName'],
      notes: map['notes'],
      terms: map['terms'],
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      createdBy: map['createdBy'],
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory PurchaseInvoiceModel.fromDocument(DocumentSnapshot doc) {
    return PurchaseInvoiceModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  factory PurchaseInvoiceModel.fromEntity(PurchaseInvoiceEntity entity) {
    return PurchaseInvoiceModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      type: entity.type,
      status: entity.status,
      paymentStatus: entity.paymentStatus,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      supplierInvoiceNumber: entity.supplierInvoiceNumber,
      date: entity.date,
      dueDate: entity.dueDate,
      expectedDeliveryDate: entity.expectedDeliveryDate,
      items: entity.items,
      subtotal: entity.subtotal,
      discountAmount: entity.discountAmount,
      discountPercent: entity.discountPercent,
      taxAmount: entity.taxAmount,
      taxPercent: entity.taxPercent,
      shippingCost: entity.shippingCost,
      total: entity.total,
      paidAmount: entity.paidAmount,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      notes: entity.notes,
      terms: entity.terms,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'type': type.name,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierInvoiceNumber': supplierInvoiceNumber,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'expectedDeliveryDate': expectedDeliveryDate != null
          ? Timestamp.fromDate(expectedDeliveryDate!)
          : null,
      'items': items
          .map((item) => PurchaseItemModel.fromEntity(item).toMap())
          .toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'taxAmount': taxAmount,
      'taxPercent': taxPercent,
      'shippingCost': shippingCost,
      'total': total,
      'paidAmount': paidAmount,
      'warehouseId': warehouseId,
      'warehouseName': warehouseName,
      'notes': notes,
      'terms': terms,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }
}

/// نموذج صنف المشتريات
class PurchaseItemModel extends PurchaseItemEntity {
  const PurchaseItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.variantId,
    super.variantName,
    super.barcode,
    required super.quantity,
    super.receivedQuantity,
    required super.unitCost,
    super.discountAmount,
    super.discountPercent,
    super.taxAmount,
    required super.total,
    super.notes,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      variantId: map['variantId'],
      variantName: map['variantName'],
      barcode: map['barcode'],
      quantity: map['quantity'] ?? 0,
      receivedQuantity: map['receivedQuantity'] ?? 0,
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      discountPercent: (map['discountPercent'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      notes: map['notes'],
    );
  }

  factory PurchaseItemModel.fromEntity(PurchaseItemEntity entity) {
    return PurchaseItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      variantId: entity.variantId,
      variantName: entity.variantName,
      barcode: entity.barcode,
      quantity: entity.quantity,
      receivedQuantity: entity.receivedQuantity,
      unitCost: entity.unitCost,
      discountAmount: entity.discountAmount,
      discountPercent: entity.discountPercent,
      taxAmount: entity.taxAmount,
      total: entity.total,
      notes: entity.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'variantId': variantId,
      'variantName': variantName,
      'barcode': barcode,
      'quantity': quantity,
      'receivedQuantity': receivedQuantity,
      'unitCost': unitCost,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'taxAmount': taxAmount,
      'total': total,
      'notes': notes,
    };
  }
}
