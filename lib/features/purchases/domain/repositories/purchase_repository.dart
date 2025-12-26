import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع المشتريات
abstract class PurchaseRepository {
  /// الحصول على جميع فواتير الشراء
  Stream<List<PurchaseInvoiceEntity>> watchPurchases();

  /// الحصول على فاتورة شراء بالمعرف
  Future<Result<PurchaseInvoiceEntity>> getPurchaseById(String id);

  /// الحصول على فواتير مورد معين
  Stream<List<PurchaseInvoiceEntity>> watchPurchasesBySupplier(
      String supplierId);

  /// الحصول على فواتير بحالة معينة
  Stream<List<PurchaseInvoiceEntity>> watchPurchasesByStatus(
      PurchaseInvoiceStatus status);

  /// الحصول على الفواتير غير المدفوعة
  Stream<List<PurchaseInvoiceEntity>> watchUnpaidPurchases();

  /// البحث في الفواتير
  Future<Result<List<PurchaseInvoiceEntity>>> searchPurchases(String query);

  /// الحصول على فواتير فترة معينة
  Future<Result<List<PurchaseInvoiceEntity>>> getPurchasesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// إنشاء فاتورة شراء جديدة
  Future<Result<PurchaseInvoiceEntity>> createPurchase(
      PurchaseInvoiceEntity purchase);

  /// تحديث فاتورة شراء
  Future<Result<PurchaseInvoiceEntity>> updatePurchase(
      PurchaseInvoiceEntity purchase);

  /// حذف فاتورة شراء
  Future<Result<void>> deletePurchase(String id);

  /// تحديث حالة الفاتورة
  Future<Result<void>> updatePurchaseStatus({
    required String id,
    required PurchaseInvoiceStatus status,
  });

  /// تسجيل دفعة على الفاتورة
  Future<Result<void>> recordPayment({
    required String purchaseId,
    required double amount,
    required String paymentMethod,
    String? reference,
  });

  /// استلام البضاعة
  Future<Result<void>> receiveItems({
    required String purchaseId,
    required Map<String, int> receivedQuantities, // itemId -> quantity
  });

  /// توليد رقم فاتورة جديد
  Future<String> generateInvoiceNumber();

  /// الحصول على إحصائيات المشتريات
  Future<Result<PurchaseStats>> getPurchaseStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// إحصائيات المشتريات
class PurchaseStats {
  final int totalPurchases;
  final double totalAmount;
  final double totalPaid;
  final double totalUnpaid;
  final int pendingOrders;

  const PurchaseStats({
    required this.totalPurchases,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalUnpaid,
    required this.pendingOrders,
  });

  factory PurchaseStats.empty() {
    return const PurchaseStats(
      totalPurchases: 0,
      totalAmount: 0,
      totalPaid: 0,
      totalUnpaid: 0,
      pendingOrders: 0,
    );
  }
}
