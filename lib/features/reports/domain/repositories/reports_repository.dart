import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع التقارير
abstract class ReportsRepository {
  /// ملخص لوحة التحكم
  Future<Result<DashboardSummary>> getDashboardSummary();

  /// مراقبة ملخص لوحة التحكم (تحديث تلقائي)
  Stream<DashboardSummary> watchDashboardSummary();

  /// تقرير المبيعات
  Future<Result<SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// مراقبة تقرير المبيعات (تحديث تلقائي)
  Stream<SalesReport> watchSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// تقرير المخزون
  Future<Result<InventoryReport>> getInventoryReport();

  /// مراقبة تقرير المخزون (تحديث تلقائي)
  Stream<InventoryReport> watchInventoryReport();

  /// المنتجات الأكثر مبيعاً
  Future<Result<List<TopSellingProduct>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });

  /// مراقبة المنتجات الأكثر مبيعاً (تحديث تلقائي)
  Stream<List<TopSellingProduct>> watchTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });

  /// بيانات المبيعات اليومية للرسم البياني
  Future<Result<List<DailySalesData>>> getDailySalesData({
    required DateTime startDate,
    required DateTime endDate,
  });
}
