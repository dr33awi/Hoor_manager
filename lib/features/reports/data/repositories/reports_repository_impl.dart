import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/offline_service.dart';
import '../../../../core/utils/result.dart';
import '../../../products/data/models/models.dart';
import '../../../sales/data/models/models.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reports_repository.dart';

/// تنفيذ مستودع التقارير مع دعم الأوفلاين
class ReportsRepositoryImpl implements ReportsRepository {
  final FirebaseFirestore _firestore;
  final OfflineService _offlineService;
  final Logger _logger = Logger();

  static const String _dashboardCacheKey = 'dashboard_summary_cache';
  static const String _dashboardCacheTimeKey = 'dashboard_summary_cache_time';
  static const String _salesReportCacheKey = 'sales_report_cache';
  static const String _inventoryReportCacheKey = 'inventory_report_cache';

  ReportsRepositoryImpl({
    FirebaseFirestore? firestore,
    OfflineService? offlineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _offlineService = offlineService ?? OfflineService();

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  @override
  Future<Result<DashboardSummary>> getDashboardSummary() async {
    // في وضع الأوفلاين - استخدم البيانات المحلية
    if (!_offlineService.isOnline) {
      _logger.d('📊 Getting dashboard summary from offline data');
      return _getDashboardSummaryOffline();
    }

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
      final todaySales =
          todayCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final todayProfit =
          todayCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // حساب إحصائيات الأسبوع
      final weekCompleted = weekInvoices.where((i) => i.isCompleted).toList();
      final weekSales =
          weekCompleted.fold<double>(0, (sum, i) => sum + i.total);

      // حساب إحصائيات الشهر
      final monthCompleted = monthInvoices.where((i) => i.isCompleted).toList();
      final monthSales =
          monthCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final monthProfit =
          monthCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // المنتجات الأكثر مبيعاً
      final topProducts = await _calculateTopProducts(monthInvoices, 5);

      // بيانات الأسبوع للرسم البياني
      final weeklyTrend = _calculateDailyData(weekInvoices, weekStart, today);

      final summary = DashboardSummary(
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
      );

      // حفظ في الكاش
      await _cacheDashboardSummary(summary);

      return Success(summary);
    } catch (e) {
      // في حالة الخطأ، محاولة قراءة الكاش
      final cached = await _getCachedDashboardSummary();
      if (cached != null) {
        return Success(cached);
      }
      return Failure('فشل جلب ملخص لوحة التحكم: $e');
    }
  }

  /// حفظ ملخص لوحة التحكم في الكاش
  Future<void> _cacheDashboardSummary(DashboardSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'todaySales': summary.todaySales,
        'todayProfit': summary.todayProfit,
        'todayInvoices': summary.todayInvoices,
        'weekSales': summary.weekSales,
        'monthSales': summary.monthSales,
        'monthProfit': summary.monthProfit,
        'lowStockCount': summary.lowStockCount,
        'outOfStockCount': summary.outOfStockCount,
        'topProducts': summary.topProducts
            .map((p) => {
                  'productId': p.productId,
                  'productName': p.productName,
                  'categoryName': p.categoryName,
                  'quantitySold': p.quantitySold,
                  'totalSales': p.totalSales,
                  'totalProfit': p.totalProfit,
                })
            .toList(),
        'weeklyTrend': summary.weeklyTrend
            .map((d) => {
                  'date': d.date.toIso8601String(),
                  'sales': d.sales,
                  'profit': d.profit,
                  'invoiceCount': d.invoiceCount,
                })
            .toList(),
      };
      await prefs.setString(_dashboardCacheKey, jsonEncode(data));
      await prefs.setInt(
          _dashboardCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// قراءة ملخص لوحة التحكم من الكاش
  Future<DashboardSummary?> _getCachedDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_dashboardCacheKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final topProducts = (data['topProducts'] as List?)
              ?.map((p) => TopSellingProduct(
                    productId: p['productId'] ?? '',
                    productName: p['productName'] ?? '',
                    categoryName: p['categoryName'] ?? '',
                    quantitySold: p['quantitySold'] ?? 0,
                    totalSales: (p['totalSales'] ?? 0).toDouble(),
                    totalProfit: (p['totalProfit'] ?? 0).toDouble(),
                  ))
              .toList() ??
          <TopSellingProduct>[];

      final weeklyTrend = (data['weeklyTrend'] as List?)
              ?.map((d) => DailySalesData(
                    date: DateTime.parse(d['date']),
                    sales: (d['sales'] ?? 0).toDouble(),
                    profit: (d['profit'] ?? 0).toDouble(),
                    invoiceCount: d['invoiceCount'] ?? 0,
                  ))
              .toList() ??
          <DailySalesData>[];

      return DashboardSummary(
        todaySales: (data['todaySales'] ?? 0).toDouble(),
        todayProfit: (data['todayProfit'] ?? 0).toDouble(),
        todayInvoices: data['todayInvoices'] ?? 0,
        weekSales: (data['weekSales'] ?? 0).toDouble(),
        monthSales: (data['monthSales'] ?? 0).toDouble(),
        monthProfit: (data['monthProfit'] ?? 0).toDouble(),
        lowStockCount: data['lowStockCount'] ?? 0,
        outOfStockCount: data['outOfStockCount'] ?? 0,
        topProducts: topProducts,
        weeklyTrend: weeklyTrend,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<DashboardSummary> watchDashboardSummary() {
    final controller = StreamController<DashboardSummary>.broadcast();
    StreamSubscription? salesSubscription;
    StreamSubscription? productsSubscription;
    StreamSubscription? connectivitySubscription;

    void updateDashboard() async {
      try {
        final result = await getDashboardSummary();
        if (!controller.isClosed) {
          controller.add(result.valueOrNull ?? DashboardSummary.empty());
        }
      } catch (_) {}
    }

    () async {
      // أولاً: إرسال البيانات المخزنة فوراً
      final cached = await _getCachedDashboardSummary();
      if (cached != null && !controller.isClosed) {
        controller.add(cached);
      }

      // ثانياً: جلب البيانات الجديدة
      updateDashboard();

      // ثالثاً: مراقبة التغييرات في المبيعات
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      salesSubscription = _salesCollection
          .where('saleDateDay', isEqualTo: Timestamp.fromDate(today))
          .snapshots()
          .listen(
            (_) => updateDashboard(),
            onError: (_) {}, // تجاهل أخطاء الأوفلاين
          );

      // رابعاً: مراقبة تغييرات المنتجات (للمخزون)
      productsSubscription = _offlineService.productsUpdateStream.listen(
        (_) => updateDashboard(),
      );

      // خامساً: مراقبة تغييرات الاتصال
      connectivitySubscription = _offlineService.connectivityStream.listen(
        (_) => updateDashboard(),
      );
    }();

    // تنظيف عند إغلاق الـ stream
    controller.onCancel = () {
      salesSubscription?.cancel();
      productsSubscription?.cancel();
      connectivitySubscription?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<Result<SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // في وضع الأوفلاين - استخدم البيانات المحلية
    if (!_offlineService.isOnline) {
      _logger.d('📊 Getting sales report from offline data');
      return _getSalesReportOffline(startDate, endDate);
    }

    try {
      final invoices = await _getInvoicesForPeriod(startDate, endDate);

      final completed = invoices.where((i) => i.isCompleted).toList();
      final cancelled = invoices.where((i) => i.isCancelled).toList();

      final dailyData = _calculateDailyData(invoices, startDate, endDate);

      final report = SalesReport(
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
      );

      // حفظ في الكاش
      await _cacheSalesReport(report);

      return Success(report);
    } catch (e) {
      // محاولة استخدام الكاش
      final cached = await _getCachedSalesReport(startDate, endDate);
      if (cached != null) {
        return Success(cached);
      }
      return Failure('فشل جلب تقرير المبيعات: $e');
    }
  }

  @override
  Stream<SalesReport> watchSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // مراقبة فواتير الفترة المحددة
    return _salesCollection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate', isLessThan: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      final invoices =
          snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();

      final completed = invoices.where((i) => i.isCompleted).toList();
      final cancelled = invoices.where((i) => i.isCancelled).toList();
      final dailyData = _calculateDailyData(invoices, startDate, endDate);

      return SalesReport(
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
      );
    });
  }

  @override
  Future<Result<InventoryReport>> getInventoryReport() async {
    // في وضع الأوفلاين - استخدم المنتجات المحلية
    if (!_offlineService.isOnline) {
      _logger.d('📊 Getting inventory report from offline data');
      return _getInventoryReportOffline();
    }

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
            stockValue:
                existing.stockValue + (product.totalStock * product.price),
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

      final report = InventoryReport(
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
      );

      // حفظ في الكاش
      await _cacheInventoryReport(report);

      return Success(report);
    } catch (e) {
      // محاولة استخدام الكاش
      final cached = await _getCachedInventoryReport();
      if (cached != null) {
        return Success(cached);
      }
      return Failure('فشل جلب تقرير المخزون: $e');
    }
  }

  @override
  Stream<InventoryReport> watchInventoryReport() {
    // مراقبة المنتجات للتحديث التلقائي
    return _productsCollection.snapshots().asyncMap((snapshot) async {
      try {
        final result = await getInventoryReport();
        return result.valueOrNull ?? InventoryReport.empty();
      } catch (e) {
        return InventoryReport.empty();
      }
    });
  }

  @override
  Future<Result<List<TopSellingProduct>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    // في وضع الأوفلاين - استخدم البيانات المحلية
    if (!_offlineService.isOnline) {
      _logger.d('📊 Getting top selling products from offline data');
      return _getTopSellingProductsOffline(startDate, endDate, limit);
    }

    try {
      final invoices = await _getInvoicesForPeriod(startDate, endDate);
      final topProducts = await _calculateTopProducts(invoices, limit);
      return Success(topProducts);
    } catch (e) {
      return Failure('فشل جلب المنتجات الأكثر مبيعاً: $e');
    }
  }

  @override
  Stream<List<TopSellingProduct>> watchTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) {
    // مراقبة فواتير الفترة المحددة
    return _salesCollection
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('saleDate', isLessThan: Timestamp.fromDate(endDate))
        .snapshots()
        .asyncMap((snapshot) async {
      final invoices =
          snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();
      return await _calculateTopProducts(invoices, limit);
    });
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

    final invoices =
        snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();

    // تخزين الفواتير في الكاش للاستخدام في الأوفلاين
    final invoicesData = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    await _offlineService.cacheServerInvoices(invoicesData);

    return invoices;
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

    return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
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
      ..sort((a, b) =>
          (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));

    // جلب أسماء الفئات
    final topList = sorted.take(limit).toList();
    final List<TopSellingProduct> result = [];

    for (final item in topList) {
      String categoryName = '';
      try {
        final productDoc =
            await _productsCollection.doc(item['productId']).get();
        if (productDoc.exists) {
          final categoryId = productDoc.data()?['categoryId'];
          if (categoryId != null) {
            final categoryDoc =
                await _categoriesCollection.doc(categoryId).get();
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

  // ==================== دوال الأوفلاين ====================

  /// الحصول على ملخص لوحة التحكم من البيانات المحلية
  Future<Result<DashboardSummary>> _getDashboardSummaryOffline() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 6));
      final monthStart = DateTime(now.year, now.month, 1);

      // الحصول على الفواتير المحلية
      final allInvoices = _getOfflineInvoicesAsModels();

      // فلترة الفواتير حسب الفترات
      final todayInvoices = allInvoices
          .where((i) =>
              i.saleDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
              i.saleDate.isBefore(today.add(const Duration(days: 1))))
          .toList();

      final weekInvoices = allInvoices
          .where((i) =>
              i.saleDate
                  .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              i.saleDate.isBefore(today.add(const Duration(days: 1))))
          .toList();

      final monthInvoices = allInvoices
          .where((i) =>
              i.saleDate
                  .isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
              i.saleDate.isBefore(today.add(const Duration(days: 1))))
          .toList();

      // الحصول على المنتجات المحلية
      final products = _offlineService.getCachedProductsAsEntities();
      final lowStockCount =
          products.where((p) => p.isActive && p.isLowStock).length;
      final outOfStockCount =
          products.where((p) => p.isActive && p.isOutOfStock).length;

      // حساب إحصائيات اليوم
      final todayCompleted = todayInvoices.where((i) => i.isCompleted).toList();
      final todaySales =
          todayCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final todayProfit =
          todayCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // حساب إحصائيات الأسبوع
      final weekCompleted = weekInvoices.where((i) => i.isCompleted).toList();
      final weekSales =
          weekCompleted.fold<double>(0, (sum, i) => sum + i.total);

      // حساب إحصائيات الشهر
      final monthCompleted = monthInvoices.where((i) => i.isCompleted).toList();
      final monthSales =
          monthCompleted.fold<double>(0, (sum, i) => sum + i.total);
      final monthProfit =
          monthCompleted.fold<double>(0, (sum, i) => sum + i.profit);

      // المنتجات الأكثر مبيعاً
      final topProducts =
          _calculateTopProductsOffline(monthInvoices, 5, products);

      // بيانات الأسبوع للرسم البياني
      final weeklyTrend = _calculateDailyData(weekInvoices, weekStart, today);

      final summary = DashboardSummary(
        todaySales: todaySales,
        todayProfit: todayProfit,
        todayInvoices: todayCompleted.length,
        weekSales: weekSales,
        monthSales: monthSales,
        monthProfit: monthProfit,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        topProducts: topProducts,
        weeklyTrend: weeklyTrend,
      );

      // تحديث الكاش
      await _cacheDashboardSummary(summary);

      _logger.i('📊 Dashboard summary loaded from offline data');
      return Success(summary);
    } catch (e) {
      _logger.e('❌ Error getting offline dashboard: $e');
      // محاولة استخدام الكاش القديم
      final cached = await _getCachedDashboardSummary();
      if (cached != null) {
        return Success(cached);
      }
      return Failure('فشل جلب ملخص لوحة التحكم: $e');
    }
  }

  /// الحصول على تقرير المبيعات من البيانات المحلية
  Future<Result<SalesReport>> _getSalesReportOffline(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allInvoices = _getOfflineInvoicesAsModels();

      // فلترة الفواتير حسب الفترة
      final invoices = allInvoices
          .where((i) =>
              i.saleDate
                  .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              i.saleDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final completed = invoices.where((i) => i.isCompleted).toList();
      final cancelled = invoices.where((i) => i.isCancelled).toList();
      final dailyData = _calculateDailyData(invoices, startDate, endDate);

      final report = SalesReport(
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
      );

      _logger.i('📊 Sales report loaded from offline data');
      return Success(report);
    } catch (e) {
      _logger.e('❌ Error getting offline sales report: $e');
      return Failure('فشل جلب تقرير المبيعات: $e');
    }
  }

  /// الحصول على تقرير المخزون من البيانات المحلية
  Future<Result<InventoryReport>> _getInventoryReportOffline() async {
    try {
      final products = _offlineService.getCachedProductsAsEntities();

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
        final categoryName = product.categoryName ?? 'بدون فئة';

        if (categoryStocksMap.containsKey(categoryId)) {
          final existing = categoryStocksMap[categoryId]!;
          categoryStocksMap[categoryId] = CategoryStock(
            categoryId: categoryId,
            categoryName: categoryName,
            productCount: existing.productCount + 1,
            totalStock: existing.totalStock + product.totalStock,
            stockValue:
                existing.stockValue + (product.totalStock * product.price),
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

      final report = InventoryReport(
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
      );

      _logger.i('📊 Inventory report loaded from offline data');
      return Success(report);
    } catch (e) {
      _logger.e('❌ Error getting offline inventory report: $e');
      return Failure('فشل جلب تقرير المخزون: $e');
    }
  }

  /// الحصول على المنتجات الأكثر مبيعاً من البيانات المحلية
  Future<Result<List<TopSellingProduct>>> _getTopSellingProductsOffline(
    DateTime startDate,
    DateTime endDate,
    int limit,
  ) async {
    try {
      final allInvoices = _getOfflineInvoicesAsModels();
      final products = _offlineService.getCachedProductsAsEntities();

      // فلترة الفواتير حسب الفترة
      final invoices = allInvoices
          .where((i) =>
              i.saleDate
                  .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              i.saleDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final topProducts =
          _calculateTopProductsOffline(invoices, limit, products);

      _logger.i('📊 Top selling products loaded from offline data');
      return Success(topProducts);
    } catch (e) {
      _logger.e('❌ Error getting offline top products: $e');
      return Failure('فشل جلب المنتجات الأكثر مبيعاً: $e');
    }
  }

  /// تحويل الفواتير المحلية إلى InvoiceModel
  List<InvoiceModel> _getOfflineInvoicesAsModels() {
    final offlineInvoices = _offlineService.getOfflineInvoices();
    return offlineInvoices
        .map((data) {
          try {
            final id = data['id'] as String? ?? '';
            return InvoiceModel.fromMap(data, id);
          } catch (e) {
            _logger.e('Error parsing offline invoice: $e');
            return null;
          }
        })
        .whereType<InvoiceModel>()
        .toList();
  }

  /// حساب المنتجات الأكثر مبيعاً من البيانات المحلية
  List<TopSellingProduct> _calculateTopProductsOffline(
    List<InvoiceModel> invoices,
    int limit,
    List<dynamic> products,
  ) {
    final Map<String, Map<String, dynamic>> productSales = {};

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
      ..sort((a, b) =>
          (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));

    // جلب أسماء الفئات من المنتجات المحلية
    final productMap = {for (var p in products) p.id: p};

    return sorted.take(limit).map((item) {
      final product = productMap[item['productId']];
      return TopSellingProduct(
        productId: item['productId'],
        productName: item['productName'],
        productImage: item['productImage'],
        categoryName: product?.categoryName ?? '',
        quantitySold: item['quantitySold'],
        totalSales: item['totalSales'],
        totalProfit: item['totalProfit'],
      );
    }).toList();
  }

  // ==================== كاش التقارير ====================

  /// حفظ تقرير المبيعات في الكاش
  Future<void> _cacheSalesReport(SalesReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'startDate': report.startDate.toIso8601String(),
        'endDate': report.endDate.toIso8601String(),
        'totalInvoices': report.totalInvoices,
        'totalItems': report.totalItems,
        'totalSales': report.totalSales,
        'totalCost': report.totalCost,
        'totalProfit': report.totalProfit,
        'totalDiscount': report.totalDiscount,
        'cancelledInvoices': report.cancelledInvoices,
        'cancelledAmount': report.cancelledAmount,
        'dailyData': report.dailyData
            .map((d) => {
                  'date': d.date.toIso8601String(),
                  'sales': d.sales,
                  'profit': d.profit,
                  'invoiceCount': d.invoiceCount,
                })
            .toList(),
      };
      await prefs.setString(_salesReportCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  /// قراءة تقرير المبيعات من الكاش
  Future<SalesReport?> _getCachedSalesReport(
      DateTime startDate, DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_salesReportCacheKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final dailyData = (data['dailyData'] as List?)
              ?.map((d) => DailySalesData(
                    date: DateTime.parse(d['date']),
                    sales: (d['sales'] ?? 0).toDouble(),
                    profit: (d['profit'] ?? 0).toDouble(),
                    invoiceCount: d['invoiceCount'] ?? 0,
                  ))
              .toList() ??
          <DailySalesData>[];

      return SalesReport(
        startDate: DateTime.parse(data['startDate']),
        endDate: DateTime.parse(data['endDate']),
        totalInvoices: data['totalInvoices'] ?? 0,
        totalItems: data['totalItems'] ?? 0,
        totalSales: (data['totalSales'] ?? 0).toDouble(),
        totalCost: (data['totalCost'] ?? 0).toDouble(),
        totalProfit: (data['totalProfit'] ?? 0).toDouble(),
        totalDiscount: (data['totalDiscount'] ?? 0).toDouble(),
        cancelledInvoices: data['cancelledInvoices'] ?? 0,
        cancelledAmount: (data['cancelledAmount'] ?? 0).toDouble(),
        dailyData: dailyData,
      );
    } catch (_) {
      return null;
    }
  }

  /// حفظ تقرير المخزون في الكاش
  Future<void> _cacheInventoryReport(InventoryReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'totalProducts': report.totalProducts,
        'activeProducts': report.activeProducts,
        'inactiveProducts': report.inactiveProducts,
        'totalVariants': report.totalVariants,
        'totalStock': report.totalStock,
        'totalStockValue': report.totalStockValue,
        'totalStockCost': report.totalStockCost,
        'lowStockProducts': report.lowStockProducts,
        'outOfStockProducts': report.outOfStockProducts,
        'categoryStocks': report.categoryStocks
            .map((c) => {
                  'categoryId': c.categoryId,
                  'categoryName': c.categoryName,
                  'productCount': c.productCount,
                  'totalStock': c.totalStock,
                  'stockValue': c.stockValue,
                })
            .toList(),
      };
      await prefs.setString(_inventoryReportCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  /// قراءة تقرير المخزون من الكاش
  Future<InventoryReport?> _getCachedInventoryReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_inventoryReportCacheKey);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final categoryStocks = (data['categoryStocks'] as List?)
              ?.map((c) => CategoryStock(
                    categoryId: c['categoryId'] ?? '',
                    categoryName: c['categoryName'] ?? '',
                    productCount: c['productCount'] ?? 0,
                    totalStock: c['totalStock'] ?? 0,
                    stockValue: (c['stockValue'] ?? 0).toDouble(),
                  ))
              .toList() ??
          <CategoryStock>[];

      return InventoryReport(
        totalProducts: data['totalProducts'] ?? 0,
        activeProducts: data['activeProducts'] ?? 0,
        inactiveProducts: data['inactiveProducts'] ?? 0,
        totalVariants: data['totalVariants'] ?? 0,
        totalStock: data['totalStock'] ?? 0,
        totalStockValue: (data['totalStockValue'] ?? 0).toDouble(),
        totalStockCost: (data['totalStockCost'] ?? 0).toDouble(),
        lowStockProducts: data['lowStockProducts'] ?? 0,
        outOfStockProducts: data['outOfStockProducts'] ?? 0,
        categoryStocks: categoryStocks,
      );
    } catch (_) {
      return null;
    }
  }
}
