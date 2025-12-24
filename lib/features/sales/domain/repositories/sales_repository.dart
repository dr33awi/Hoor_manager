import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع المبيعات
abstract class SalesRepository {
  /// إنشاء فاتورة جديدة
  Future<Result<InvoiceEntity>> createInvoice(InvoiceEntity invoice);

  /// الحصول على فاتورة بالمعرف
  Future<Result<InvoiceEntity>> getInvoiceById(String id);

  /// الحصول على فاتورة برقم الفاتورة
  Future<Result<InvoiceEntity>> getInvoiceByNumber(String invoiceNumber);

  /// الحصول على جميع الفواتير
  Future<Result<List<InvoiceEntity>>> getInvoices({
    DateTime? startDate,
    DateTime? endDate,
    InvoiceStatus? status,
    String? soldBy,
    int? limit,
  });

  /// الحصول على فواتير اليوم
  Future<Result<List<InvoiceEntity>>> getTodayInvoices();

  /// إلغاء فاتورة
  Future<Result<void>> cancelInvoice({
    required String invoiceId,
    required String cancelledBy,
    String? reason,
  });

  /// توليد رقم فاتورة جديد
  Future<Result<String>> generateInvoiceNumber();

  /// مراقبة الفواتير
  Stream<List<InvoiceEntity>> watchInvoices({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// مراقبة فواتير اليوم
  Stream<List<InvoiceEntity>> watchTodayInvoices();

  /// إحصائيات المبيعات اليومية
  Future<Result<DailySalesStats>> getDailySalesStats(DateTime date);

  /// إحصائيات المبيعات الشهرية
  Future<Result<MonthlySalesStats>> getMonthlySalesStats(int year, int month);
}

/// إحصائيات المبيعات اليومية
class DailySalesStats {
  final DateTime date;
  final int invoiceCount;
  final int itemCount;
  final double totalSales;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final int cancelledCount;

  const DailySalesStats({
    required this.date,
    required this.invoiceCount,
    required this.itemCount,
    required this.totalSales,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.cancelledCount,
  });

  /// نسبة الربح
  double get profitMargin {
    if (totalCost <= 0) return 0;
    return (totalProfit / totalCost) * 100;
  }

  /// متوسط قيمة الفاتورة
  double get averageInvoiceValue {
    if (invoiceCount <= 0) return 0;
    return totalSales / invoiceCount;
  }

  factory DailySalesStats.empty(DateTime date) {
    return DailySalesStats(
      date: date,
      invoiceCount: 0,
      itemCount: 0,
      totalSales: 0,
      totalCost: 0,
      totalProfit: 0,
      totalDiscount: 0,
      cancelledCount: 0,
    );
  }

  factory DailySalesStats.fromInvoices(DateTime date, List<InvoiceEntity> invoices) {
    final completedInvoices = invoices.where((i) => i.isCompleted).toList();
    final cancelledInvoices = invoices.where((i) => i.isCancelled).toList();

    return DailySalesStats(
      date: date,
      invoiceCount: completedInvoices.length,
      itemCount: completedInvoices.fold(0, (sum, i) => sum + i.itemCount),
      totalSales: completedInvoices.fold(0, (sum, i) => sum + i.total),
      totalCost: completedInvoices.fold(0, (sum, i) => sum + i.totalCost),
      totalProfit: completedInvoices.fold(0, (sum, i) => sum + i.profit),
      totalDiscount: completedInvoices.fold(0, (sum, i) => sum + i.discountAmount),
      cancelledCount: cancelledInvoices.length,
    );
  }
}

/// إحصائيات المبيعات الشهرية
class MonthlySalesStats {
  final int year;
  final int month;
  final int invoiceCount;
  final int itemCount;
  final double totalSales;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final int cancelledCount;
  final List<DailySalesStats> dailyStats;

  const MonthlySalesStats({
    required this.year,
    required this.month,
    required this.invoiceCount,
    required this.itemCount,
    required this.totalSales,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.cancelledCount,
    this.dailyStats = const [],
  });

  /// نسبة الربح
  double get profitMargin {
    if (totalCost <= 0) return 0;
    return (totalProfit / totalCost) * 100;
  }

  /// متوسط المبيعات اليومية
  double get averageDailySales {
    if (dailyStats.isEmpty) return 0;
    final daysWithSales = dailyStats.where((d) => d.invoiceCount > 0).length;
    if (daysWithSales <= 0) return 0;
    return totalSales / daysWithSales;
  }

  factory MonthlySalesStats.empty(int year, int month) {
    return MonthlySalesStats(
      year: year,
      month: month,
      invoiceCount: 0,
      itemCount: 0,
      totalSales: 0,
      totalCost: 0,
      totalProfit: 0,
      totalDiscount: 0,
      cancelledCount: 0,
    );
  }
}
