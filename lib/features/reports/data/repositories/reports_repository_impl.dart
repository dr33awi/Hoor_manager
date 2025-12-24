import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../../products/data/models/models.dart';
import '../../../sales/data/models/models.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reports_repository.dart';

/// تنفيذ مستودع التقارير
class ReportsRepositoryImpl implements ReportsRepository {
  final FirebaseFirestore _firestore;

  ReportsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  @override
  Future<Result<DashboardSummary>> getDashboardSummary() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 6));
      final monthStart = DateTime(now.year, now.month, 1);

      // جلب فواتير اليوم
      final todayInvoices = await _getInvoicesForPeriod(
        today,
        today.add(const Duration(days: 1)),
      );

      // جلب فواتير الأسبوع
      final weekInvoices = await _getInvoicesForPeriod(
        weekStart,
        today.add(const Duration(days: 1)),
      );

      // جلب فواتير الشهر
      final monthInvoices = await _getInvoicesForPeriod(
        monthStart,
        today.add(const Duration(days: 1)),
      );

      // جلب المنتجات منخفضة المخزون
      final lowStockSnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('isLowStock', isEqualTo: true)
          .get();

      // جلب المنتجات نفدت من المخزون
      final outOfStockSnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('isOutOfStock', isEqualTo: true)
          .get();

      // حساب إحصائيات اليوم
      final todayCompleted = todayInvoices.where((i) => i.isCompleted).toList();
      final todaySales = todayCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final todayProfit = todayCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // حساب إحصائيات الأسبوع
      final weekCompleted = weekInvoices.where((i) => i.isCompleted).toList();
      final weekSales = weekCompleted.fold<double>(0, (sum, i) => sum + i.total);

      // حساب إحصائيات الشهر
      final monthCompleted = monthInvoices.where((i) => i.isCompleted).toList();
      final monthSales = monthCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final monthProfit = monthCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // المنتجات الأكثر مبيعاً
      final topProducts = await _calculateTopProducts(monthInvoices, 5);

      // بيانات الأسبوع للرسم البياني
      final weeklyTrend = _calculateDailyData(weekInvoices, weekStart, today);

      return Success(DashboardSummary(
        todaySales: todaySales,
        todayProfit: todayProfit,
        todayInvoices: todayCompleted.length,
        weekSales: weekSales,
        monthSales: monthSales,
        monthProfit: monthProfit,
        lowStockCount: lowStockSnapshot.docs.length,
        outOfStockCount: outOfStockSnapshot.docs.length,
        topProducts: topProducts,
        weeklyTrend: weeklyTrend,
      ));
    } catch (e) {
      return Failure('فشل جلب ملخص لوحة التحكم: $e');
    }
  }

  @override
  Future<Result<SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final invoices = await _getInvoicesForPeriod(startDate, endDate);

      final completed = invoices.where((i) => i.isCompleted).toList();
      final cancelled = invoices.where((i) => i.isCancelled).toList();

      final dailyData = _calculateDailyData(invoices, startDate, endDate);

      return Success(SalesReport(
        startDate: startDate,
        endDate: endDate,
        totalInvoices: completed.length,
        totalItems: completed.fold(0, (sum, i) => sum + i.itemCount),
        totalSales: completed.fold(0, (sum, i) => sum + i.total),
        totalCost: completed.fold(0, (sum, i) => sum + i.totalCost),
        totalProfit: completed.fold(0, (sum, i) => sum + i.profit),
        totalDiscount: completed.fold(0, (sum, i) => sum + i.discountAmount),
        cancelledInvoices: cancelled.length,
        cancelledAmount: cancelled.fold(0, (sum, i) => sum + i.total),
        dailyData: dailyData,
      ));
    } catch (e) {
      return Failure('فشل جلب تقرير المبيعات: $e');
    }
  }

  @override
  Future<Result<InventoryReport>> getInventoryReport() async {
    try {
      final productsSnapshot = await _productsCollection.get();
      final categoriesSnapshot = await _categoriesCollection.get();

      final products = productsSnapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

      final categories = {
        for (var doc in categoriesSnapshot.docs)
          doc.id: CategoryModel.fromDocument(doc)
      };

      int totalVariants = 0;
      int totalStock = 0;
      double totalStockValue = 0;
      double totalStockCost = 0;
      int lowStockProducts = 0;
      int outOfStockProducts = 0;

      final categoryStocksMap = <String, CategoryStock>{};

      for (final product in products) {
        totalVariants += product.variants.length;
        totalStock += product.totalStock;
        totalStockValue += product.totalStock * product.price;
        totalStockCost += product.totalStock * product.cost;

        if (product.isLowStock) lowStockProducts++;
        if (product.isOutOfStock) outOfStockProducts++;

        // تجميع حسب الفئة
        final categoryId = product.categoryId;
        final categoryName = categories[categoryId]?.name ?? 'بدون فئة';

        if (categoryStocksMap.containsKey(categoryId)) {
          final existing = categoryStocksMap[categoryId]!;
          categoryStocksMap[categoryId] = CategoryStock(
            categoryId: categoryId,
            categoryName: categoryName,
            productCount: existing.productCount + 1,
            totalStock: existing.totalStock + product.totalStock,
            stockValue: existing.stockValue + (product.totalStock * product.price),
          );
        } else {
          categoryStocksMap[categoryId] = CategoryStock(
            categoryId: categoryId,
            categoryName: categoryName,
            productCount: 1,
            totalStock: product.totalStock,
            stockValue: product.totalStock * product.price,
          );
        }
      }

      return Success(InventoryReport(
        totalProducts: products.length,
        activeProducts: products.where((p) => p.isActive).length,
        inactiveProducts: products.where((p) => !p.isActive).length,
        totalVariants: totalVariants,
        totalStock: totalStock,
        totalStockValue: totalStockValue,
        totalStockCost: totalStockCost,
        lowStockProducts: lowStockProducts,
        outOfStockProducts: outOfStockProducts,
        categoryStocks: categoryStocksMap.values.toList(),
      ));
    } catch (e) {
      return Failure('فشل جلب تقرير المخزون: $e');
    }
  }

  @override
  Future<Result<List<TopSellingProduct>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final invoices = await _getInvoicesForPeriod(startDate, endDate);
      final topProducts = await _calculateTopProducts(invoices, limit);
      return Success(topProducts);
    } catch (e) {
      return Failure('فشل جلب المنتجات الأكثر مبيعاً: $e');
    }
  }

  @override
  Future<Result<List<DailySalesData>>> getDailySalesData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final invoices = await _getInvoicesForPeriod(startDate, endDate);
      final dailyData = _calculateDailyData(invoices, startDate, endDate);
      return Success(dailyData);
    } catch (e) {
      return Failure('فشل جلب بيانات المبيعات اليومية: $e');
    }
  }

  // ==================== Private Methods ====================

  Future<List<InvoiceModel>> _getInvoicesForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _salesCollection
        .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('saleDate', isLessThan: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => InvoiceModel.fromDocument(doc))
        .toList();
  }

  List<DailySalesData> _calculateDailyData(
    List<InvoiceModel> invoices,
    DateTime start,
    DateTime end,
  ) {
    final Map<String, DailySalesData> dailyMap = {};

    // تهيئة جميع الأيام
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      final key = '${current.year}-${current.month}-${current.day}';
      dailyMap[key] = DailySalesData(
        date: current,
        invoiceCount: 0,
        sales: 0,
        profit: 0,
      );
      current = current.add(const Duration(days: 1));
    }

    // تجميع البيانات
    for (final invoice in invoices) {
      if (!invoice.isCompleted) continue;

      final date = invoice.saleDate;
      final key = '${date.year}-${date.month}-${date.day}';

      if (dailyMap.containsKey(key)) {
        final existing = dailyMap[key]!;
        dailyMap[key] = DailySalesData(
          date: existing.date,
          invoiceCount: existing.invoiceCount + 1,
          sales: existing.sales + invoice.total,
          profit: existing.profit + invoice.profit,
        );
      }
    }

    return dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TopSellingProduct>> _calculateTopProducts(
    List<InvoiceModel> invoices,
    int limit,
  ) async {
    final Map<String, Map<String, dynamic>> productSales = {};

    // تجميع المبيعات حسب المنتج
    for (final invoice in invoices) {
      if (!invoice.isCompleted) continue;

      for (final item in invoice.items) {
        if (productSales.containsKey(item.productId)) {
          productSales[item.productId]!['quantitySold'] += item.quantity;
          productSales[item.productId]!['totalSales'] += item.totalPrice;
          productSales[item.productId]!['totalProfit'] +=
              (item.unitPrice - item.unitCost) * item.quantity;
        } else {
          productSales[item.productId] = {
            'productId': item.productId,
            'productName': item.productName,
            'productImage': item.productImage,
            'quantitySold': item.quantity,
            'totalSales': item.totalPrice,
            'totalProfit': (item.unitPrice - item.unitCost) * item.quantity,
          };
        }
      }
    }

    // ترتيب حسب الكمية المباعة
    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));

    // جلب أسماء الفئات
    final topList = sorted.take(limit).toList();
    final List<TopSellingProduct> result = [];

    for (final item in topList) {
      String categoryName = '';
      try {
        final productDoc = await _productsCollection.doc(item['productId']).get();
        if (productDoc.exists) {
          final categoryId = productDoc.data()?['categoryId'];
          if (categoryId != null) {
            final categoryDoc = await _categoriesCollection.doc(categoryId).get();
            categoryName = categoryDoc.data()?['name'] ?? '';
          }
        }
      } catch (_) {}

      result.add(TopSellingProduct(
        productId: item['productId'],
        productName: item['productName'],
        productImage: item['productImage'],
        categoryName: categoryName,
        quantitySold: item['quantitySold'],
        totalSales: item['totalSales'],
        totalProfit: item['totalProfit'],
      ));
    }

    return result;
  }
}
