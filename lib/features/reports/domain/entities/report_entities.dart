/// تقرير المبيعات
class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalInvoices;
  final int totalItems;
  final double totalSales;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final int cancelledInvoices;
  final double cancelledAmount;
  final List<DailySalesData> dailyData;

  const SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalInvoices,
    required this.totalItems,
    required this.totalSales,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.cancelledInvoices,
    required this.cancelledAmount,
    this.dailyData = const [],
  });

  /// نسبة الربح
  double get profitMargin {
    if (totalCost <= 0) return 0;
    return (totalProfit / totalCost) * 100;
  }

  /// متوسط قيمة الفاتورة
  double get averageInvoiceValue {
    if (totalInvoices <= 0) return 0;
    return totalSales / totalInvoices;
  }

  /// متوسط المبيعات اليومية
  double get averageDailySales {
    final days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) return 0;
    return totalSales / days;
  }

  factory SalesReport.empty({DateTime? start, DateTime? end}) {
    final now = DateTime.now();
    return SalesReport(
      startDate: start ?? now,
      endDate: end ?? now,
      totalInvoices: 0,
      totalItems: 0,
      totalSales: 0,
      totalCost: 0,
      totalProfit: 0,
      totalDiscount: 0,
      cancelledInvoices: 0,
      cancelledAmount: 0,
    );
  }
}

/// بيانات المبيعات اليومية
class DailySalesData {
  final DateTime date;
  final int invoiceCount;
  final double sales;
  final double profit;

  const DailySalesData({
    required this.date,
    required this.invoiceCount,
    required this.sales,
    required this.profit,
  });
}

/// تقرير المخزون
class InventoryReport {
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int totalVariants;
  final int totalStock;
  final double totalStockValue;
  final double totalStockCost;
  final int lowStockProducts;
  final int outOfStockProducts;
  final List<CategoryStock> categoryStocks;

  const InventoryReport({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.totalVariants,
    required this.totalStock,
    required this.totalStockValue,
    required this.totalStockCost,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    this.categoryStocks = const [],
  });

  /// الربح المحتمل
  double get potentialProfit => totalStockValue - totalStockCost;

  factory InventoryReport.empty() {
    return const InventoryReport(
      totalProducts: 0,
      activeProducts: 0,
      inactiveProducts: 0,
      totalVariants: 0,
      totalStock: 0,
      totalStockValue: 0,
      totalStockCost: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
    );
  }
}

/// مخزون الفئة
class CategoryStock {
  final String categoryId;
  final String categoryName;
  final int productCount;
  final int totalStock;
  final double stockValue;

  const CategoryStock({
    required this.categoryId,
    required this.categoryName,
    required this.productCount,
    required this.totalStock,
    required this.stockValue,
  });
}

/// المنتج الأكثر مبيعاً
class TopSellingProduct {
  final String productId;
  final String productName;
  final String? productImage;
  final String categoryName;
  final int quantitySold;
  final double totalSales;
  final double totalProfit;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.categoryName,
    required this.quantitySold,
    required this.totalSales,
    required this.totalProfit,
  });
}

/// ملخص لوحة التحكم
class DashboardSummary {
  final double todaySales;
  final double todayProfit;
  final int todayInvoices;
  final double weekSales;
  final double monthSales;
  final double monthProfit;
  final int lowStockCount;
  final int outOfStockCount;
  final List<TopSellingProduct> topProducts;
  final List<DailySalesData> weeklyTrend;

  const DashboardSummary({
    required this.todaySales,
    required this.todayProfit,
    required this.todayInvoices,
    required this.weekSales,
    required this.monthSales,
    required this.monthProfit,
    required this.lowStockCount,
    required this.outOfStockCount,
    this.topProducts = const [],
    this.weeklyTrend = const [],
  });

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      todaySales: 0,
      todayProfit: 0,
      todayInvoices: 0,
      weekSales: 0,
      monthSales: 0,
      monthProfit: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
    );
  }
}

/// فترة التقرير
enum ReportPeriod {
  today('today', 'اليوم'),
  yesterday('yesterday', 'أمس'),
  thisWeek('this_week', 'هذا الأسبوع'),
  lastWeek('last_week', 'الأسبوع الماضي'),
  thisMonth('this_month', 'هذا الشهر'),
  lastMonth('last_month', 'الشهر الماضي'),
  custom('custom', 'فترة مخصصة');

  final String value;
  final String arabicName;

  const ReportPeriod(this.value, this.arabicName);

  /// الحصول على تواريخ الفترة
  ({DateTime start, DateTime end}) get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return (start: today, end: today.add(const Duration(days: 1)));

      case ReportPeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (start: yesterday, end: today);

      case ReportPeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 6)); // السبت
        return (start: weekStart, end: today.add(const Duration(days: 1)));

      case ReportPeriod.lastWeek:
        final thisWeekStart = today.subtract(Duration(days: today.weekday - 6));
        final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
        return (start: lastWeekStart, end: thisWeekStart);

      case ReportPeriod.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return (start: monthStart, end: today.add(const Duration(days: 1)));

      case ReportPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final thisMonthStart = DateTime(now.year, now.month, 1);
        return (start: lastMonth, end: thisMonthStart);

      case ReportPeriod.custom:
        return (start: today, end: today.add(const Duration(days: 1)));
    }
  }
}
