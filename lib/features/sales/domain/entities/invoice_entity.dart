import 'cart_item.dart';
import 'discount.dart';

/// حالة الفاتورة
enum InvoiceStatus {
  /// مكتملة
  completed('completed', 'مكتملة'),

  /// ملغاة
  cancelled('cancelled', 'ملغاة'),

  /// مسترجعة
  refunded('refunded', 'مسترجعة');

  final String value;
  final String arabicName;

  const InvoiceStatus(this.value, this.arabicName);

  static InvoiceStatus fromString(String? value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvoiceStatus.completed,
    );
  }
}

/// طريقة الدفع
enum PaymentMethod {
  /// نقدي
  cash('cash', 'نقدي');

  final String value;
  final String arabicName;

  const PaymentMethod(this.value, this.arabicName);

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// كيان الفاتورة
class InvoiceEntity {
  final String id;
  final String invoiceNumber;
  final List<CartItem> items;
  final double subtotal;
  final Discount discount;
  final double discountAmount;
  final double total;
  final double totalCost;
  final double profit;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final InvoiceStatus status;
  final String? notes;
  final DateTime saleDate;
  final String soldBy;
  final String? soldByName;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.discountAmount,
    required this.total,
    required this.totalCost,
    required this.profit,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.status,
    this.notes,
    required this.saleDate,
    required this.soldBy,
    this.soldByName,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
  });

  /// عدد المنتجات
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// هل الفاتورة مكتملة
  bool get isCompleted => status == InvoiceStatus.completed;

  /// هل الفاتورة ملغاة
  bool get isCancelled => status == InvoiceStatus.cancelled;

  /// هل يوجد خصم
  bool get hasDiscount => discount.hasDiscount && discountAmount > 0;

  /// نسبة الربح
  double get profitMargin {
    if (totalCost <= 0) return 0;
    return (profit / totalCost) * 100;
  }

  /// إنشاء فاتورة من السلة
  factory InvoiceEntity.fromCart({
    required String id,
    required String invoiceNumber,
    required List<CartItem> items,
    required Discount discount,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required String soldBy,
    String? soldByName,
    String? notes,
  }) {
    final subtotal =
        items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final discountAmount = discount.calculate(subtotal);
    final total = subtotal - discountAmount;
    final totalCost =
        items.fold<double>(0, (sum, item) => sum + item.totalCost);
    final profit = total - totalCost;
    final change = amountPaid - total;

    return InvoiceEntity(
      id: id,
      invoiceNumber: invoiceNumber,
      items: items,
      subtotal: subtotal,
      discount: discount,
      discountAmount: discountAmount,
      total: total,
      totalCost: totalCost,
      profit: profit,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: change > 0 ? change : 0,
      status: InvoiceStatus.completed,
      notes: notes,
      saleDate: DateTime.now(),
      soldBy: soldBy,
      soldByName: soldByName,
    );
  }

  InvoiceEntity copyWith({
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
    return InvoiceEntity(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InvoiceEntity(invoiceNumber: $invoiceNumber, total: $total, status: ${status.arabicName})';
}
