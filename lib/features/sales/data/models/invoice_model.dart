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
    super.notes,
    required super.saleDate,
    required super.soldBy,
    super.soldByName,
    super.cancelledAt,
    super.cancelledBy,
    super.cancellationReason,
  });

  /// إنشاء من Map (Firestore)
  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    // التعامل مع أنواع التاريخ المختلفة
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber']?.toString() ?? '',
      items: itemsList,
      subtotal: _toDouble(map['subtotal']),
      discount: map['discount'] != null
          ? Discount.fromMap(map['discount'] as Map<String, dynamic>)
          : Discount.none,
      discountAmount: _toDouble(map['discountAmount']),
      total: _toDouble(map['total']),
      totalCost: _toDouble(map['totalCost']),
      profit: _toDouble(map['profit']),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']?.toString()),
      amountPaid: _toDouble(map['amountPaid']),
      change: _toDouble(map['change']),
      status: InvoiceStatus.fromString(map['status']?.toString()),
      notes: map['notes']?.toString(),
      saleDate: parseDateTime(map['saleDate']),
      soldBy: map['soldBy']?.toString() ?? '',
      soldByName: map['soldByName']?.toString(),
      cancelledAt: parseNullableDateTime(map['cancelledAt']),
      cancelledBy: map['cancelledBy']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
    );
  }

  /// تحويل آمن للـ double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      notes: entity.notes,
      saleDate: entity.saleDate,
      soldBy: entity.soldBy,
      soldByName: entity.soldByName,
      cancelledAt: entity.cancelledAt,
      cancelledBy: entity.cancelledBy,
      cancellationReason: entity.cancellationReason,
    );
  }

  /// تحويل إلى Map (للـ Firestore)
  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'items':
          items.map((item) => CartItemModel.fromEntity(item).toMap()).toList(),
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
      'notes': notes,
      'saleDate': Timestamp.fromDate(saleDate),
      'soldBy': soldBy,
      'soldByName': soldByName,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      // حقول للفلترة
      'saleDateDay': Timestamp.fromDate(DateTime(
        saleDate.year,
        saleDate.month,
        saleDate.day,
      )),
      'saleMonth':
          '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}',
      'itemCount': itemCount,
    };
  }

  /// إنشاء من Map محلي (بدون Timestamp - للتخزين المحلي)
  factory InvoiceModel.fromOfflineMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber']?.toString() ?? '',
      items: itemsList,
      subtotal: _toDouble(map['subtotal']),
      discount: map['discount'] != null
          ? Discount.fromMap(map['discount'] as Map<String, dynamic>)
          : Discount.none,
      discountAmount: _toDouble(map['discountAmount']),
      total: _toDouble(map['total']),
      totalCost: _toDouble(map['totalCost']),
      profit: _toDouble(map['profit']),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']?.toString()),
      amountPaid: _toDouble(map['amountPaid']),
      change: _toDouble(map['change']),
      status: InvoiceStatus.fromString(map['status']?.toString()),
      notes: map['notes']?.toString(),
      saleDate: parseDateTime(map['saleDate']),
      soldBy: map['soldBy']?.toString() ?? '',
      soldByName: map['soldByName']?.toString(),
      cancelledAt: parseNullableDateTime(map['cancelledAt']),
      cancelledBy: map['cancelledBy']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
    );
  }

  /// تحويل إلى Map للتخزين المحلي (بدون Timestamp)
  Map<String, dynamic> toOfflineMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'items':
          items.map((item) => CartItemModel.fromEntity(item).toMap()).toList(),
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
      'notes': notes,
      'saleDate': saleDate.toIso8601String(),
      'soldBy': soldBy,
      'soldByName': soldByName,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'saleDateDay': DateTime(saleDate.year, saleDate.month, saleDate.day)
          .toIso8601String(),
      'saleMonth':
          '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}',
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
