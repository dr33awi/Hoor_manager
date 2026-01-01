// ═══════════════════════════════════════════════════════════════════════════
// App Providers - Riverpod Providers for Services & Repositories
// Bridging GetIt services with Riverpod state management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/cash_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/voucher_repository.dart';
import '../../data/repositories/warehouse_repository.dart';
import '../services/sync_service.dart';
import '../services/backup_service.dart';
import '../services/currency_service.dart';
import '../services/accounting_service.dart';
import '../services/connectivity_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CORE SERVICES PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final databaseProvider = Provider<AppDatabase>((ref) => getIt<AppDatabase>());
final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => getIt<ConnectivityService>());
final currencyServiceProvider =
    Provider<CurrencyService>((ref) => getIt<CurrencyService>());
final syncServiceProvider =
    Provider<SyncService>((ref) => getIt<SyncService>());
final backupServiceProvider =
    Provider<BackupService>((ref) => getIt<BackupService>());
final accountingServiceProvider =
    Provider<AccountingService>((ref) => getIt<AccountingService>());

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final productRepositoryProvider =
    Provider<ProductRepository>((ref) => getIt<ProductRepository>());
final categoryRepositoryProvider =
    Provider<CategoryRepository>((ref) => getIt<CategoryRepository>());
final invoiceRepositoryProvider =
    Provider<InvoiceRepository>((ref) => getIt<InvoiceRepository>());
final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => getIt<InventoryRepository>());
final shiftRepositoryProvider =
    Provider<ShiftRepository>((ref) => getIt<ShiftRepository>());
final cashRepositoryProvider =
    Provider<CashRepository>((ref) => getIt<CashRepository>());
final customerRepositoryProvider =
    Provider<CustomerRepository>((ref) => getIt<CustomerRepository>());
final supplierRepositoryProvider =
    Provider<SupplierRepository>((ref) => getIt<SupplierRepository>());
final voucherRepositoryProvider =
    Provider<VoucherRepository>((ref) => getIt<VoucherRepository>());
final warehouseRepositoryProvider =
    Provider<WarehouseRepository>((ref) => getIt<WarehouseRepository>());

// ═══════════════════════════════════════════════════════════════════════════
// STREAM PROVIDERS - Real-time Data
// ═══════════════════════════════════════════════════════════════════════════

/// All Products Stream
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
});

/// Active Products Stream
final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchActiveProducts();
});

/// Low Stock Products Stream
final lowStockProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchLowStockProducts();
});

/// Categories Stream
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAllCategories();
});

/// All Customers Stream
final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAllCustomers();
});

/// All Suppliers Stream
final suppliersStreamProvider = StreamProvider<List<Supplier>>((ref) {
  return ref.watch(supplierRepositoryProvider).watchAllSuppliers();
});

/// All Invoices Stream
final invoicesStreamProvider = StreamProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchAllInvoices();
});

/// Open Shift Stream
final openShiftStreamProvider = StreamProvider<Shift?>((ref) {
  return ref.watch(shiftRepositoryProvider).watchOpenShift();
});

/// All Shifts Stream
final shiftsStreamProvider = StreamProvider<List<Shift>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchAllShifts();
});

/// All Vouchers Stream
final vouchersStreamProvider = StreamProvider<List<Voucher>>((ref) {
  return ref.watch(voucherRepositoryProvider).watchAllVouchers();
});

// ═══════════════════════════════════════════════════════════════════════════
// FILTERED PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Sales Invoices (filtered from all invoices)
final salesInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref.watch(invoicesStreamProvider).whenData(
        (invoices) => invoices.where((i) => i.type == 'sale').toList(),
      );
});

/// Purchase Invoices (filtered from all invoices)
final purchaseInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  return ref.watch(invoicesStreamProvider).whenData(
        (invoices) => invoices.where((i) => i.type == 'purchase').toList(),
      );
});

/// Active Customers (filtered from all customers)
final activeCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  return ref.watch(customersStreamProvider).whenData(
        (customers) => customers.where((c) => c.isActive).toList(),
      );
});

/// Active Suppliers (filtered from all suppliers)
final activeSuppliersProvider = Provider<AsyncValue<List<Supplier>>>((ref) {
  return ref.watch(suppliersStreamProvider).whenData(
        (suppliers) => suppliers.where((s) => s.isActive).toList(),
      );
});

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD STATS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final shiftRepo = ref.watch(shiftRepositoryProvider);

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // Get today's invoices
  final todayInvoices = await db.getInvoicesByDateRange(startOfDay, endOfDay);

  double todaySales = 0;
  double todayPurchases = 0;
  int salesCount = 0;

  for (final invoice in todayInvoices) {
    if (invoice.type == 'sale') {
      todaySales += invoice.total;
      salesCount++;
    } else if (invoice.type == 'purchase') {
      todayPurchases += invoice.total;
    }
  }

  // Get products
  final allProducts = await db.getAllProducts();
  final activeProducts = allProducts.where((p) => p.isActive).toList();
  final lowStockProducts =
      activeProducts.where((p) => p.quantity <= p.minQuantity).toList();

  // Get customers
  final allCustomers = await db.getAllCustomers();

  // Get open shift
  final openShift = await shiftRepo.getOpenShift();

  return DashboardStats(
    todaySales: todaySales,
    todayPurchases: todayPurchases,
    todayProfit: todaySales - todayPurchases,
    totalProducts: activeProducts.length,
    lowStockCount: lowStockProducts.length,
    totalCustomers: allCustomers.length,
    salesCount: salesCount,
    hasOpenShift: openShift != null,
    openShiftId: openShift?.id,
    cashBalance: openShift?.openingBalance ?? 0,
  );
});

/// Monthly Stats Provider
final monthlyStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  final db = ref.watch(databaseProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final monthlyInvoices =
      await db.getInvoicesByDateRange(startOfMonth, endOfMonth);

  double monthlySales = 0;
  double monthlyPurchases = 0;
  int salesCount = 0;
  int purchasesCount = 0;

  for (final invoice in monthlyInvoices) {
    if (invoice.type == 'sale') {
      monthlySales += invoice.total;
      salesCount++;
    } else if (invoice.type == 'purchase') {
      monthlyPurchases += invoice.total;
      purchasesCount++;
    }
  }

  return MonthlyStats(
    totalSales: monthlySales,
    totalPurchases: monthlyPurchases,
    profit: monthlySales - monthlyPurchases,
    salesCount: salesCount,
    purchasesCount: purchasesCount,
    invoiceCount: monthlyInvoices.length,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE PROVIDERS - For UI State
// ═══════════════════════════════════════════════════════════════════════════

// These are in flutter_riverpod, so they work

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class DashboardStats {
  final double todaySales;
  final double todayPurchases;
  final double todayProfit;
  final int totalProducts;
  final int lowStockCount;
  final int totalCustomers;
  final int salesCount;
  final bool hasOpenShift;
  final String? openShiftId;
  final double cashBalance;

  const DashboardStats({
    required this.todaySales,
    required this.todayPurchases,
    required this.todayProfit,
    required this.totalProducts,
    required this.lowStockCount,
    required this.totalCustomers,
    required this.salesCount,
    required this.hasOpenShift,
    this.openShiftId,
    required this.cashBalance,
  });
}

class MonthlyStats {
  final double totalSales;
  final double totalPurchases;
  final double profit;
  final int salesCount;
  final int purchasesCount;
  final int invoiceCount;

  const MonthlyStats({
    required this.totalSales,
    required this.totalPurchases,
    required this.profit,
    required this.salesCount,
    required this.purchasesCount,
    required this.invoiceCount,
  });
}
