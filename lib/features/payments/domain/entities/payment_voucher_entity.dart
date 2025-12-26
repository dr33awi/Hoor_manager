import 'package:flutter/material.dart';

/// نوع السند المالي
enum PaymentVoucherType {
  receipt, // سند قبض (من العميل)
  payment, // سند صرف (للمورد أو مصروفات)
  journalEntry, // قيد محاسبي
  transfer, // تحويل بين الحسابات
}

/// امتداد نوع السند
extension PaymentVoucherTypeX on PaymentVoucherType {
  String get arabicName {
    switch (this) {
      case PaymentVoucherType.receipt:
        return 'سند قبض';
      case PaymentVoucherType.payment:
        return 'سند صرف';
      case PaymentVoucherType.journalEntry:
        return 'قيد محاسبي';
      case PaymentVoucherType.transfer:
        return 'تحويل';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentVoucherType.receipt:
        return Icons.call_received;
      case PaymentVoucherType.payment:
        return Icons.call_made;
      case PaymentVoucherType.journalEntry:
        return Icons.receipt_long;
      case PaymentVoucherType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color get color {
    switch (this) {
      case PaymentVoucherType.receipt:
        return Colors.green;
      case PaymentVoucherType.payment:
        return Colors.red;
      case PaymentVoucherType.journalEntry:
        return Colors.blue;
      case PaymentVoucherType.transfer:
        return Colors.orange;
    }
  }
}

/// حالة السند
enum PaymentVoucherStatus {
  draft, // مسودة
  pending, // في انتظار الموافقة
  approved, // موافق عليه
  posted, // مرحل
  cancelled, // ملغى
}

/// امتداد حالة السند
extension PaymentVoucherStatusX on PaymentVoucherStatus {
  String get arabicName {
    switch (this) {
      case PaymentVoucherStatus.draft:
        return 'مسودة';
      case PaymentVoucherStatus.pending:
        return 'معلق';
      case PaymentVoucherStatus.approved:
        return 'موافق عليه';
      case PaymentVoucherStatus.posted:
        return 'مرحّل';
      case PaymentVoucherStatus.cancelled:
        return 'ملغى';
    }
  }

  Color get color {
    switch (this) {
      case PaymentVoucherStatus.draft:
        return Colors.grey;
      case PaymentVoucherStatus.pending:
        return Colors.orange;
      case PaymentVoucherStatus.approved:
        return Colors.blue;
      case PaymentVoucherStatus.posted:
        return Colors.green;
      case PaymentVoucherStatus.cancelled:
        return Colors.red;
    }
  }
}

/// طريقة الدفع
enum PaymentMethod {
  cash, // نقدي
  bankTransfer, // تحويل بنكي
  card, // بطاقة (شبكة)
  cheque, // شيك
  creditCard, // بطاقة ائتمان
  other, // أخرى
}

/// امتداد طريقة الدفع
extension PaymentMethodX on PaymentMethod {
  String get arabicName {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.card:
        return 'شبكة';
      case PaymentMethod.cheque:
        return 'شيك';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.other:
        return 'أخرى';
    }
  }
}

/// كيان السند المالي
class PaymentVoucherEntity {
  final String id;
  final String voucherNumber;
  final PaymentVoucherType type;
  final PaymentVoucherStatus status;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final double amount;

  // معلومات الطرف الآخر
  final String? customerId;
  final String? customerName;
  final String? supplierId;
  final String? supplierName;
  final String? accountId; // للمصروفات
  final String? accountName;

  // ربط بالفواتير
  final String? invoiceId;
  final String? invoiceNumber;
  final String? purchaseId;
  final String? purchaseNumber;

  // تفاصيل الدفع
  final String? chequeNumber;
  final String? chequeDate;
  final String? bankName;
  final String? bankAccount;
  final String? transferReference;
  final String? referenceNumber; // رقم المرجع

  final String? description;
  final String? notes;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;

  const PaymentVoucherEntity({
    required this.id,
    required this.voucherNumber,
    required this.type,
    this.status = PaymentVoucherStatus.draft,
    required this.paymentMethod,
    required this.date,
    required this.amount,
    this.customerId,
    this.customerName,
    this.supplierId,
    this.supplierName,
    this.accountId,
    this.accountName,
    this.invoiceId,
    this.invoiceNumber,
    this.purchaseId,
    this.purchaseNumber,
    this.chequeNumber,
    this.chequeDate,
    this.bankName,
    this.bankAccount,
    this.transferReference,
    this.referenceNumber,
    this.description,
    this.notes,
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
  });

  /// تاريخ السند (alias for date)
  DateTime get voucherDate => date;

  /// طريقة الدفع (alias for paymentMethod)
  PaymentMethod get method => paymentMethod;

  /// هل سند قبض
  bool get isReceipt => type == PaymentVoucherType.receipt;

  /// هل سند صرف
  bool get isPayment => type == PaymentVoucherType.payment;

  /// اسم الطرف الآخر
  String get partyName {
    if (customerName != null) return customerName!;
    if (supplierName != null) return supplierName!;
    if (accountName != null) return accountName!;
    return 'غير محدد';
  }

  /// نسخ مع تعديلات
  PaymentVoucherEntity copyWith({
    String? id,
    String? voucherNumber,
    PaymentVoucherType? type,
    PaymentVoucherStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? date,
    double? amount,
    String? customerId,
    String? customerName,
    String? supplierId,
    String? supplierName,
    String? accountId,
    String? accountName,
    String? invoiceId,
    String? invoiceNumber,
    String? purchaseId,
    String? purchaseNumber,
    String? chequeNumber,
    String? chequeDate,
    String? bankName,
    String? bankAccount,
    String? transferReference,
    String? description,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return PaymentVoucherEntity(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      chequeDate: chequeDate ?? this.chequeDate,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      transferReference: transferReference ?? this.transferReference,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentVoucherEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
