import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/account_repository.dart';

/// Provider لقاعدة البيانات الرئيسية
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ==================== Repositories ====================

/// Provider لمستودع المنتجات
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepository(db);
});

/// Provider لمستودع التصنيفات
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

/// Provider لمستودع حركات المخزون
final inventoryMovementRepositoryProvider =
    Provider<InventoryMovementRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryMovementRepository(db);
});

/// Provider لمستودع الفواتير
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceRepository(db);
});

/// Provider لمستودع الأطراف (العملاء والموردين)
final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PartyRepository(db);
});

/// Provider لمستودع السندات
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VoucherRepository(db);
});

/// Provider لمستودع الحسابات النقدية
final cashAccountRepositoryProvider = Provider<CashAccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CashAccountRepository(db);
});

// ==================== Data Providers ====================

/// Provider لجلب جميع المنتجات
final allProductsProvider = FutureProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllProducts();
});

/// Provider للبحث في المنتجات
final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) {
  final repo = ref.watch(productRepositoryProvider);
  if (query.isEmpty) {
    return repo.getAllProducts();
  }
  return repo.searchProducts(query);
});

/// Provider لجلب منتج بالمعرف
final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(id);
});

/// Provider لجلب منتج بالباركود
final productByBarcodeProvider =
    FutureProvider.family<Product?, String>((ref, barcode) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductByBarcode(barcode);
});

/// Provider لجلب جميع التصنيفات
final allCategoriesProvider = FutureProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAllCategories();
});

/// Provider لجلب المنتجات حسب التصنيف
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, int?>((ref, categoryId) {
  final repo = ref.watch(productRepositoryProvider);
  if (categoryId == null) {
    return repo.getAllProducts();
  }
  return repo.getProductsByCategory(categoryId);
});

/// Provider للمنتجات منخفضة المخزون
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getLowStockProducts();
});

/// Provider لجلب جميع العملاء
final allCustomersProvider = FutureProvider<List<Party>>((ref) {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getCustomers();
});

/// Provider لجلب جميع الموردين
final allSuppliersProvider = FutureProvider<List<Party>>((ref) {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getSuppliers();
});

/// Provider لجلب جميع الفواتير
final allInvoicesProvider = FutureProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices();
});

/// Provider لجلب فواتير المبيعات
final salesInvoicesProvider = FutureProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices(type: 'SALE');
});

/// Provider لجلب فواتير المشتريات
final purchaseInvoicesProvider = FutureProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices(type: 'PURCHASE');
});

/// Provider لجلب الحسابات النقدية
final allCashAccountsProvider = FutureProvider<List<CashAccount>>((ref) {
  final repo = ref.watch(cashAccountRepositoryProvider);
  return repo.getAllCashAccounts();
});

// ==================== Invoice Providers ====================

/// Provider لجلب فواتير اليوم
final todayInvoicesProvider =
    FutureProvider.family<List<Invoice>, String?>((ref, type) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getTodayInvoices(type: type);
});

/// Provider لجلب فاتورة بالمعرف
final invoiceByIdProvider = FutureProvider.family<Invoice?, int>((ref, id) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getInvoiceById(id);
});

/// Provider لجلب بنود فاتورة
final invoiceItemsProvider =
    FutureProvider.family<List<InvoiceItem>, int>((ref, invoiceId) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getInvoiceItems(invoiceId);
});

/// Provider لفواتير عميل/مورد
final partyInvoicesProvider =
    FutureProvider.family<List<Invoice>, int>((ref, partyId) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getPartyInvoices(partyId);
});

/// Provider لمرتجعات المبيعات
final salesReturnsProvider = FutureProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices(type: 'RETURN_SALE');
});

/// Provider لمرتجعات المشتريات
final purchaseReturnsProvider = FutureProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices(type: 'RETURN_PURCHASE');
});

/// Provider للبحث في طرف (عميل/مورد)
final partySearchProvider =
    FutureProvider.family<List<Party>, ({String query, String type})>(
        (ref, params) {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.searchParties(params.query, type: params.type);
});
