import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع السندات المالية
abstract class PaymentRepository {
  /// الحصول على جميع السندات
  Stream<List<PaymentVoucherEntity>> watchPayments();

  /// الحصول على سند بالمعرف
  Future<Result<PaymentVoucherEntity>> getPaymentById(String id);

  /// الحصول على سندات العميل
  Stream<List<PaymentVoucherEntity>> watchPaymentsByCustomer(String customerId);

  /// الحصول على سندات المورد
  Stream<List<PaymentVoucherEntity>> watchPaymentsBySupplier(String supplierId);

  /// الحصول على سندات القبض
  Stream<List<PaymentVoucherEntity>> watchReceipts();

  /// الحصول على سندات الصرف
  Stream<List<PaymentVoucherEntity>> watchPaymentVouchers();

  /// البحث في السندات
  Future<Result<List<PaymentVoucherEntity>>> searchPayments(String query);

  /// الحصول على سندات فترة معينة
  Future<Result<List<PaymentVoucherEntity>>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    PaymentVoucherType? type,
  });

  /// إنشاء سند جديد
  Future<Result<PaymentVoucherEntity>> createPayment(
      PaymentVoucherEntity payment);

  /// تحديث سند
  Future<Result<PaymentVoucherEntity>> updatePayment(
      PaymentVoucherEntity payment);

  /// حذف سند
  Future<Result<void>> deletePayment(String id);

  /// تحديث حالة السند
  Future<Result<void>> updatePaymentStatus({
    required String id,
    required PaymentVoucherStatus status,
    String? approvedBy,
  });

  /// توليد رقم سند جديد
  Future<String> generateVoucherNumber(PaymentVoucherType type);

  /// الحصول على إحصائيات السندات
  Future<Result<PaymentStats>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// إحصائيات السندات
class PaymentStats {
  final int totalReceipts;
  final int totalPayments;
  final double receiptsAmount;
  final double paymentsAmount;
  final double netCashFlow;
  final int totalVouchers;
  final int draftCount;

  const PaymentStats({
    required this.totalReceipts,
    required this.totalPayments,
    required this.receiptsAmount,
    required this.paymentsAmount,
    required this.netCashFlow,
    this.totalVouchers = 0,
    this.draftCount = 0,
  });

  factory PaymentStats.empty() {
    return const PaymentStats(
      totalReceipts: 0,
      totalPayments: 0,
      receiptsAmount: 0,
      paymentsAmount: 0,
      netCashFlow: 0,
      totalVouchers: 0,
      draftCount: 0,
    );
  }
}
