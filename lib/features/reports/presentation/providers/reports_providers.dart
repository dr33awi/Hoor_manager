import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_service.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reports_repository.dart';

// ==================== Repository Provider ====================

/// مزود مستودع التقارير مع دعم الأوفلاين
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    offlineService: OfflineService(),
  );
});

// ==================== Dashboard Providers ====================

/// مزود ملخص لوحة التحكم (Future - للاستخدام مرة واحدة)
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final result = await repository.getDashboardSummary();
  return result.valueOrNull ?? DashboardSummary.empty();
});

/// مزود ملخص لوحة التحكم (Stream - للتحديث التلقائي)
final dashboardSummaryStreamProvider = StreamProvider<DashboardSummary>((ref) {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.watchDashboardSummary();
});

// ==================== Sales Report Providers ====================

/// حالة تقرير المبيعات
class SalesReportState {
  final ReportPeriod period;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const SalesReportState({
    this.period = ReportPeriod.today,
    this.customStartDate,
    this.customEndDate,
  });

  ({DateTime start, DateTime end}) get dateRange {
    if (period == ReportPeriod.custom &&
        customStartDate != null &&
        customEndDate != null) {
      return (start: customStartDate!, end: customEndDate!);
    }
    return period.dateRange;
  }

  SalesReportState copyWith({
    ReportPeriod? period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return SalesReportState(
      period: period ?? this.period,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

/// مدير حالة تقرير المبيعات
class SalesReportNotifier extends Notifier<SalesReportState> {
  @override
  SalesReportState build() {
    return const SalesReportState();
  }

  void setPeriod(ReportPeriod period) {
    state = state.copyWith(period: period);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = SalesReportState(
      period: ReportPeriod.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }
}

/// مزود حالة تقرير المبيعات
final salesReportStateProvider =
    NotifierProvider<SalesReportNotifier, SalesReportState>(() {
  return SalesReportNotifier();
});

/// مزود تقرير المبيعات
final salesReportProvider = FutureProvider<SalesReport>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final state = ref.watch(salesReportStateProvider);
  final range = state.dateRange;

  final result = await repository.getSalesReport(
    startDate: range.start,
    endDate: range.end,
  );

  return result.valueOrNull ??
      SalesReport.empty(start: range.start, end: range.end);
});

/// مزود تقرير المبيعات (Stream - للتحديث التلقائي)
final salesReportStreamProvider = StreamProvider<SalesReport>((ref) {
  ref.keepAlive();
  final repository = ref.watch(reportsRepositoryProvider);
  final state = ref.watch(salesReportStateProvider);
  final range = state.dateRange;

  return repository.watchSalesReport(
    startDate: range.start,
    endDate: range.end,
  );
});

// ==================== Inventory Report Provider ====================

/// مزود تقرير المخزون
final inventoryReportProvider = FutureProvider<InventoryReport>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final result = await repository.getInventoryReport();
  return result.valueOrNull ?? InventoryReport.empty();
});

/// مزود تقرير المخزون (Stream - للتحديث التلقائي)
final inventoryReportStreamProvider = StreamProvider<InventoryReport>((ref) {
  ref.keepAlive();
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.watchInventoryReport();
});

// ==================== Top Products Provider ====================

/// مزود المنتجات الأكثر مبيعاً
final topSellingProductsProvider = FutureProvider.family<
    List<TopSellingProduct>, ({DateTime start, DateTime end, int limit})>(
  (ref, params) async {
    final repository = ref.watch(reportsRepositoryProvider);
    final result = await repository.getTopSellingProducts(
      startDate: params.start,
      endDate: params.end,
      limit: params.limit,
    );
    return result.valueOrNull ?? [];
  },
);

/// مزود المنتجات الأكثر مبيعاً (Stream - للتحديث التلقائي)
final topSellingProductsStreamProvider = StreamProvider.family<
    List<TopSellingProduct>, ({DateTime start, DateTime end, int limit})>(
  (ref, params) {
    ref.keepAlive();
    final repository = ref.watch(reportsRepositoryProvider);
    return repository.watchTopSellingProducts(
      startDate: params.start,
      endDate: params.end,
      limit: params.limit,
    );
  },
);

/// مزود أفضل المنتجات لهذا الشهر
final monthlyTopProductsProvider =
    FutureProvider<List<TopSellingProduct>>((ref) async {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final repository = ref.watch(reportsRepositoryProvider);

  final result = await repository.getTopSellingProducts(
    startDate: monthStart,
    endDate: now,
    limit: 10,
  );

  return result.valueOrNull ?? [];
});

/// مزود أفضل المنتجات لهذا الشهر (Stream - للتحديث التلقائي)
final monthlyTopProductsStreamProvider =
    StreamProvider<List<TopSellingProduct>>((ref) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final repository = ref.watch(reportsRepositoryProvider);

  return repository.watchTopSellingProducts(
    startDate: monthStart,
    endDate: now,
    limit: 10,
  );
});

// ==================== Daily Sales Data Provider ====================

/// مزود بيانات المبيعات اليومية
final dailySalesDataProvider = FutureProvider.family<List<DailySalesData>,
    ({DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(reportsRepositoryProvider);
    final result = await repository.getDailySalesData(
      startDate: params.start,
      endDate: params.end,
    );
    return result.valueOrNull ?? [];
  },
);
