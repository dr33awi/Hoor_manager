/// ═══════════════════════════════════════════════════════════════════════════
/// Accounting Exceptions - استثناءات موحدة للعمليات المحاسبية
/// ═══════════════════════════════════════════════════════════════════════════
library;

/// استثناء نقص المخزون
class InsufficientStockException implements Exception {
  final String productId;
  final String productName;
  final int requested;
  final int available;

  const InsufficientStockException({
    required this.productId,
    required this.productName,
    required this.requested,
    required this.available,
  });

  @override
  String toString() =>
      'الكمية المطلوبة ($requested) من "$productName" أكبر من المتوفر ($available)';

  String get message => toString();
}

/// استثناء عدم وجود وردية مفتوحة
class NoOpenShiftException implements Exception {
  final String? message;

  const NoOpenShiftException([this.message]);

  @override
  String toString() => message ?? 'لا توجد وردية مفتوحة. يرجى فتح وردية أولاً.';
}

/// استثناء وجود وردية مفتوحة بالفعل
class ShiftAlreadyOpenException implements Exception {
  final String shiftId;

  const ShiftAlreadyOpenException(this.shiftId);

  @override
  String toString() =>
      'يوجد وردية مفتوحة بالفعل (رقم: $shiftId). يرجى إغلاقها أولاً.';
}

/// استثناء رصيد غير صفري
class NonZeroBalanceException implements Exception {
  final String entityType; // 'customer' أو 'supplier'
  final String entityId;
  final String entityName;
  final double balance;

  const NonZeroBalanceException({
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.balance,
  });

  @override
  String toString() {
    final type = entityType == 'customer' ? 'العميل' : 'المورد';
    return 'لا يمكن حذف $type "$entityName" لوجود رصيد ($balance) عليه.';
  }

  String get message => toString();
}

/// استثناء عملية على وردية مغلقة
class ClosedShiftOperationException implements Exception {
  final String shiftId;
  final String operation;

  const ClosedShiftOperationException({
    required this.shiftId,
    required this.operation,
  });

  @override
  String toString() =>
      'لا يمكن إجراء عملية "$operation" على وردية مغلقة (رقم: $shiftId).';
}

/// استثناء المخزون السالب
class NegativeStockException implements Exception {
  final String productId;
  final String productName;
  final int currentQuantity;
  final int requestedWithdraw;

  const NegativeStockException({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.requestedWithdraw,
  });

  @override
  String toString() =>
      'لا يمكن سحب ($requestedWithdraw) من "$productName". الكمية الحالية ($currentQuantity) غير كافية.';

  String get message => toString();
}

/// استثناء فاتورة غير موجودة
class InvoiceNotFoundException implements Exception {
  final String invoiceId;

  const InvoiceNotFoundException(this.invoiceId);

  @override
  String toString() => 'الفاتورة غير موجودة (رقم: $invoiceId).';
}

/// استثناء عميل/مورد غير موجود
class EntityNotFoundException implements Exception {
  final String entityType;
  final String entityId;

  const EntityNotFoundException({
    required this.entityType,
    required this.entityId,
  });

  @override
  String toString() {
    final type = entityType == 'customer' ? 'العميل' : 'المورد';
    return '$type غير موجود (رقم: $entityId).';
  }
}
