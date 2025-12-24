import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع التقارير
abstract class ReportsRepository {
  /// ملخص لوحة التحكم
  Future<Result<DashboardSummary>> getDashboardSummary();

  /// تقرير المبيعات
  Future<Result<SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// تقرير المخزون
  Future<Result<InventoryReport>> getInventoryReport();

  /// المنتجات الأكثر مبيعاً
  Future<Result<List<TopSellingProduct>>> getTopSellingProducts({
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
