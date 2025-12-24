import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import 'cart_item_model.dart';

/// نموذج الفاتورة للتعامل مع Firestore
class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.items,
    required super.subtotal,
    required super.discount,
    required super.discountAmount,
    required super.total,
    required super.totalCost,
    required super.profit,
    required super.paymentMethod,
    required super.amountPaid,
    required super.change,
    required super.status,
    super.customerName,
    super.customerPhone,
    super.notes,
    required super.saleDate,
    required super.soldBy,
    super.soldByName,
    super.cancelledAt,
    super.cancelledBy,
    super.cancellationReason,
  });

  /// إنشاء من Map
  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      items: itemsList,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: map['discount'] != null
          ? Discount.fromMap(map['discount'] as Map<String, dynamic>)
          : Discount.none,
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      profit: (map['profit'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      change: (map['change'] ?? 0).toDouble(),
      status: InvoiceStatus.fromString(map['status']),
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      notes: map['notes'],
      saleDate: (map['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldBy: map['soldBy'] ?? '',
      soldByName: map['soldByName'],
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      cancelledBy: map['cancelledBy'],
      cancellationReason: map['cancellationReason'],
    );
  }

  /// إنشاء من DocumentSnapshot
  factory InvoiceModel.fromDocument(DocumentSnapshot doc) {
    return InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من Entity
  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      items: entity.items,
      subtotal: entity.subtotal,
      discount: entity.discount,
      discountAmount: entity.discountAmount,
      total: entity.total,
      totalCost: entity.totalCost,
      profit: entity.profit,
      paymentMethod: entity.paymentMethod,
      amountPaid: entity.amountPaid,
      change: entity.change,
      status: entity.status,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      notes: entity.notes,
      saleDate: entity.saleDate,
      soldBy: entity.soldBy,
      soldByName: entity.soldByName,
      cancelledAt: entity.cancelledAt,
      cancelledBy: entity.cancelledBy,
      cancellationReason: entity.cancellationReason,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toMap())
          .toList(),
      'subtotal': subtotal,
      'discount': discount.toMap(),
      'discountAmount': discountAmount,
      'total': total,
      'totalCost': totalCost,
      'profit': profit,
      'paymentMethod': paymentMethod.value,
      'amountPaid': amountPaid,
      'change': change,
      'status': status.value,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      'saleDate': Timestamp.fromDate(saleDate),
      'soldBy': soldBy,
      'soldByName': soldByName,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      // حقول للفلترة
      'saleDateDay': Timestamp.fromDate(DateTime(
        saleDate.year,
        saleDate.month,
        saleDate.day,
      )),
      'saleMonth': '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}',
      'itemCount': itemCount,
    };
  }

  @override
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    List<CartItem>? items,
    double? subtotal,
    Discount? discount,
    double? discountAmount,
    double? total,
    double? totalCost,
    double? profit,
    PaymentMethod? paymentMethod,
    double? amountPaid,
    double? change,
    InvoiceStatus? status,
    String? customerName,
    String? customerPhone,
    String? notes,
    DateTime? saleDate,
    String? soldBy,
    String? soldByName,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      totalCost: totalCost ?? this.totalCost,
      profit: profit ?? this.profit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      change: change ?? this.change,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      saleDate: saleDate ?? this.saleDate,
      soldBy: soldBy ?? this.soldBy,
      soldByName: soldByName ?? this.soldByName,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
