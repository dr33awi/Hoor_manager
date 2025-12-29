import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Products,
  Categories,
  Invoices,
  InvoiceItems,
  InventoryMovements,
  Shifts,
  CashMovements,
  Customers,
  Suppliers,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here
      },
    );
  }

  // ==================== Products ====================

  Future<List<Product>> getAllProducts() => select(products).get();

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Stream<List<Product>> watchActiveProducts() {
    return (select(products)..where((p) => p.isActive.equals(true))).watch();
  }

  Future<Product?> getProductById(String id) {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return (select(products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) {
    return (select(products)..where((p) => p.categoryId.equals(categoryId)))
        .get();
  }

  Future<List<Product>> getLowStockProducts() {
    return customSelect(
      'SELECT * FROM products WHERE quantity <= min_quantity AND is_active = 1',
      readsFrom: {products},
    )
        .map((row) => Product(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              sku: row.readNullable<String>('sku'),
              barcode: row.readNullable<String>('barcode'),
              categoryId: row.readNullable<String>('category_id'),
              purchasePrice: row.read<double>('purchase_price'),
              salePrice: row.read<double>('sale_price'),
              quantity: row.read<int>('quantity'),
              minQuantity: row.read<int>('min_quantity'),
              taxRate: row.readNullable<double>('tax_rate'),
              description: row.readNullable<String>('description'),
              imageUrl: row.readNullable<String>('image_url'),
              isActive: row.read<bool>('is_active'),
              syncStatus: row.read<String>('sync_status'),
              createdAt: row.read<DateTime>('created_at'),
              updatedAt: row.read<DateTime>('updated_at'),
            ))
        .get();
  }

  Stream<List<Product>> watchLowStockProducts() {
    return customSelect(
      'SELECT * FROM products WHERE quantity <= min_quantity AND is_active = 1',
      readsFrom: {products},
    )
        .map((row) => Product(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              sku: row.readNullable<String>('sku'),
              barcode: row.readNullable<String>('barcode'),
              categoryId: row.readNullable<String>('category_id'),
              purchasePrice: row.read<double>('purchase_price'),
              salePrice: row.read<double>('sale_price'),
              quantity: row.read<int>('quantity'),
              minQuantity: row.read<int>('min_quantity'),
              taxRate: row.readNullable<double>('tax_rate'),
              description: row.readNullable<String>('description'),
              imageUrl: row.readNullable<String>('image_url'),
              isActive: row.read<bool>('is_active'),
              syncStatus: row.read<String>('sync_status'),
              createdAt: row.read<DateTime>('created_at'),
              updatedAt: row.read<DateTime>('updated_at'),
            ))
        .watch();
  }

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<bool> updateProduct(ProductsCompanion product) async {
    final productId = product.id.value;
    if (productId == null) {
      print('Error: Product ID is null');
      return false;
    }

    final rowsAffected = await (update(products)
          ..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      name: product.name,
      sku: product.sku,
      barcode: product.barcode,
      categoryId: product.categoryId,
      purchasePrice: product.purchasePrice,
      salePrice: product.salePrice,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      taxRate: product.taxRate,
      description: product.description,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      syncStatus: product.syncStatus,
      updatedAt: Value(DateTime.now()),
    ));

    print('Update product $productId: $rowsAffected rows affected');
    return rowsAffected > 0;
  }

  Future<int> deleteProduct(String id) {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }

  Future<void> updateProductQuantity(String productId, int newQuantity) {
    return (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      quantity: Value(newQuantity),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending'),
    ));
  }

  /// تحديث جميع أسعار المنتجات بنسبة معينة (عند تغيير سعر الصرف)
  Future<int> updateAllProductPricesByRatio(double ratio) async {
    final allProducts = await getAllProducts();
    int updatedCount = 0;

    for (final product in allProducts) {
      final newPurchasePrice = product.purchasePrice * ratio;
      final newSalePrice = product.salePrice * ratio;

      await (update(products)..where((p) => p.id.equals(product.id)))
          .write(ProductsCompanion(
        purchasePrice: Value(newPurchasePrice),
        salePrice: Value(newSalePrice),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ));
      updatedCount++;
    }

    return updatedCount;
  }

  // ==================== Categories ====================

  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<Category?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(Category(
      id: category.id.value,
      name: category.name.value,
      description: category.description.value,
      parentId: category.parentId.value,
      syncStatus: category.syncStatus.value,
      createdAt: category.createdAt.value,
      updatedAt: DateTime.now(),
    ));
  }

  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  // ==================== Invoices ====================

  Future<List<Invoice>> getAllInvoices() => select(invoices).get();

  Stream<List<Invoice>> watchAllInvoices() {
    return (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  Future<List<Invoice>> getInvoicesByType(String type) {
    return (select(invoices)..where((i) => i.type.equals(type))).get();
  }

  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) {
    return (select(invoices)
          ..where((i) => i.invoiceDate.isBetweenValues(start, end))
          ..orderBy([(i) => OrderingTerm.desc(i.invoiceDate)]))
        .get();
  }

  Future<List<Invoice>> getInvoicesByShift(String shiftId) {
    return (select(invoices)..where((i) => i.shiftId.equals(shiftId))).get();
  }

  Future<Invoice?> getInvoiceById(String id) {
    return (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();
  }

  // الحصول على فواتير العميل
  Future<List<Invoice>> getInvoicesByCustomer(String customerId) {
    return (select(invoices)
          ..where((i) => i.customerId.equals(customerId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  // مراقبة فواتير العميل (Real-time)
  Stream<List<Invoice>> watchInvoicesByCustomer(String customerId) {
    return (select(invoices)
          ..where((i) => i.customerId.equals(customerId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  // الحصول على ملخص العميل (إجمالي المشتريات والمرتجعات)
  Future<Map<String, double>> getCustomerSummary(String customerId) async {
    final result = await customSelect(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'sale' THEN total ELSE 0 END), 0) as total_sales,
        COALESCE(SUM(CASE WHEN type = 'sale_return' THEN total ELSE 0 END), 0) as total_returns,
        COUNT(*) as invoice_count
      FROM invoices
      WHERE customer_id = ?
      ''',
      variables: [Variable.withString(customerId)],
      readsFrom: {invoices},
    ).getSingleOrNull();

    if (result == null) {
      return {'totalSales': 0, 'totalReturns': 0, 'invoiceCount': 0};
    }

    return {
      'totalSales': result.read<double>('total_sales'),
      'totalReturns': result.read<double>('total_returns'),
      'invoiceCount': result.read<int>('invoice_count').toDouble(),
    };
  }

  // الحصول على فواتير المورد
  Future<List<Invoice>> getInvoicesBySupplier(String supplierId) {
    return (select(invoices)
          ..where((i) => i.supplierId.equals(supplierId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  // مراقبة فواتير المورد (Real-time)
  Stream<List<Invoice>> watchInvoicesBySupplier(String supplierId) {
    return (select(invoices)
          ..where((i) => i.supplierId.equals(supplierId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  // الحصول على ملخص المورد (إجمالي المشتريات والمرتجعات)
  Future<Map<String, double>> getSupplierSummary(String supplierId) async {
    final result = await customSelect(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'purchase' THEN total ELSE 0 END), 0) as total_purchases,
        COALESCE(SUM(CASE WHEN type = 'purchase_return' THEN total ELSE 0 END), 0) as total_returns,
        COUNT(*) as invoice_count
      FROM invoices
      WHERE supplier_id = ?
      ''',
      variables: [Variable.withString(supplierId)],
      readsFrom: {invoices},
    ).getSingleOrNull();

    if (result == null) {
      return {'totalPurchases': 0, 'totalReturns': 0, 'invoiceCount': 0};
    }

    return {
      'totalPurchases': result.read<double>('total_purchases'),
      'totalReturns': result.read<double>('total_returns'),
      'invoiceCount': result.read<int>('invoice_count').toDouble(),
    };
  }

  Future<int> insertInvoice(InvoicesCompanion invoice) {
    return into(invoices).insert(invoice);
  }

  Future<void> updateInvoice(InvoicesCompanion invoice) {
    return (update(invoices)..where((i) => i.id.equals(invoice.id.value)))
        .write(invoice);
  }

  Future<int> deleteInvoice(String id) {
    return (delete(invoices)..where((i) => i.id.equals(id))).go();
  }

  Future<int> deleteInvoiceItems(String invoiceId) {
    return (delete(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId)))
        .go();
  }

  // ==================== Invoice Items ====================

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) {
    return (select(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId)))
        .get();
  }

  Future<int> insertInvoiceItem(InvoiceItemsCompanion item) {
    return into(invoiceItems).insert(item);
  }

  Future<void> insertInvoiceItems(List<InvoiceItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAll(invoiceItems, items);
    });
  }

  /// الحصول على إجمالي الكميات المباعة لكل منتج
  Future<Map<String, int>> getProductSoldQuantities() async {
    final result = await customSelect(
      '''
      SELECT ii.product_id, SUM(ii.quantity) as total_sold
      FROM invoice_items ii
      INNER JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.type = 'sale'
      GROUP BY ii.product_id
      ''',
      readsFrom: {invoiceItems, invoices},
    ).get();

    final Map<String, int> soldQuantities = {};
    for (final row in result) {
      final productId = row.read<String>('product_id');
      final totalSold = row.read<int>('total_sold');
      soldQuantities[productId] = totalSold;
    }
    return soldQuantities;
  }

  // ==================== Inventory Movements ====================

  Future<List<InventoryMovement>> getInventoryMovements(String productId) {
    return (select(inventoryMovements)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  Stream<List<InventoryMovement>> watchInventoryMovements() {
    return (select(inventoryMovements)
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .watch();
  }

  Future<int> insertInventoryMovement(InventoryMovementsCompanion movement) {
    return into(inventoryMovements).insert(movement);
  }

  Future<void> updateInventoryMovementSyncStatus(String id, String status) {
    return (update(inventoryMovements)..where((m) => m.id.equals(id)))
        .write(InventoryMovementsCompanion(syncStatus: Value(status)));
  }

  // ==================== Shifts ====================

  Future<List<Shift>> getAllShifts() {
    return (select(shifts)..orderBy([(s) => OrderingTerm.desc(s.openedAt)]))
        .get();
  }

  Stream<List<Shift>> watchAllShifts() {
    return (select(shifts)..orderBy([(s) => OrderingTerm.desc(s.openedAt)]))
        .watch();
  }

  Future<Shift?> getOpenShift() {
    return (select(shifts)..where((s) => s.status.equals('open')))
        .getSingleOrNull();
  }

  Stream<Shift?> watchOpenShift() {
    return (select(shifts)..where((s) => s.status.equals('open')))
        .watchSingleOrNull();
  }

  Future<Shift?> getShiftById(String id) {
    return (select(shifts)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertShift(ShiftsCompanion shift) {
    return into(shifts).insert(shift);
  }

  Future<void> updateShift(ShiftsCompanion shift) {
    return (update(shifts)..where((s) => s.id.equals(shift.id.value)))
        .write(shift);
  }

  Future<int> deleteShift(String id) {
    return (delete(shifts)..where((s) => s.id.equals(id))).go();
  }

  // ==================== Cash Movements ====================

  Future<List<CashMovement>> getCashMovementsByShift(String shiftId) {
    return (select(cashMovements)
          ..where((m) => m.shiftId.equals(shiftId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  Stream<List<CashMovement>> watchCashMovementsByShift(String shiftId) {
    return (select(cashMovements)
          ..where((m) => m.shiftId.equals(shiftId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .watch();
  }

  Future<int> insertCashMovement(CashMovementsCompanion movement) {
    return into(cashMovements).insert(movement);
  }

  Future<void> updateCashMovementSyncStatus(String id, String status) {
    return (update(cashMovements)..where((m) => m.id.equals(id)))
        .write(CashMovementsCompanion(syncStatus: Value(status)));
  }

  Future<int> deleteCashMovement(String id) {
    return (delete(cashMovements)..where((m) => m.id.equals(id))).go();
  }

  Future<int> deleteCashMovementsByShift(String shiftId) {
    return (delete(cashMovements)..where((m) => m.shiftId.equals(shiftId)))
        .go();
  }

  Future<CashMovement?> getCashMovementById(String id) {
    return (select(cashMovements)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  // ==================== Customers ====================

  Future<List<Customer>> getAllCustomers() => select(customers).get();

  Stream<List<Customer>> watchAllCustomers() => select(customers).watch();

  Future<Customer?> getCustomerById(String id) {
    return (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer);
  }

  Future<void> updateCustomer(CustomersCompanion customer) {
    return (update(customers)..where((c) => c.id.equals(customer.id.value)))
        .write(customer);
  }

  Future<int> deleteCustomer(String id) {
    return (delete(customers)..where((c) => c.id.equals(id))).go();
  }

  // ==================== Suppliers ====================

  Future<List<Supplier>> getAllSuppliers() => select(suppliers).get();

  Stream<List<Supplier>> watchAllSuppliers() => select(suppliers).watch();

  Future<Supplier?> getSupplierById(String id) {
    return (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSupplier(SuppliersCompanion supplier) {
    return into(suppliers).insert(supplier);
  }

  Future<void> updateSupplier(SuppliersCompanion supplier) {
    return (update(suppliers)..where((s) => s.id.equals(supplier.id.value)))
        .write(supplier);
  }

  Future<int> deleteSupplier(String id) {
    return (delete(suppliers)..where((s) => s.id.equals(id))).go();
  }

  // ==================== Settings ====================

  Future<String?> getSetting(String key) async {
    final setting = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return setting?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ==================== Pending Sync ====================

  Future<List<Product>> getPendingProducts() {
    return (select(products)..where((p) => p.syncStatus.equals('pending')))
        .get();
  }

  Future<List<Category>> getPendingCategories() {
    return (select(categories)..where((c) => c.syncStatus.equals('pending')))
        .get();
  }

  Future<List<Invoice>> getPendingInvoices() {
    return (select(invoices)..where((i) => i.syncStatus.equals('pending')))
        .get();
  }

  Future<List<InventoryMovement>> getPendingInventoryMovements() {
    return (select(inventoryMovements)
          ..where((m) => m.syncStatus.equals('pending')))
        .get();
  }

  Future<List<Shift>> getPendingShifts() {
    return (select(shifts)..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<CashMovement>> getPendingCashMovements() {
    return (select(cashMovements)..where((m) => m.syncStatus.equals('pending')))
        .get();
  }

  // ==================== Reports ====================

  Future<Map<String, double>> getSalesSummary(
      DateTime start, DateTime end) async {
    final result = await customSelect(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'sale' THEN total ELSE 0 END), 0) as total_sales,
        COALESCE(SUM(CASE WHEN type = 'sale_return' THEN total ELSE 0 END), 0) as total_returns,
        COALESCE(SUM(CASE WHEN type = 'sale' THEN total ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN type = 'sale_return' THEN total ELSE 0 END), 0) as net_sales
      FROM invoices 
      WHERE invoice_date BETWEEN ? AND ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {invoices},
    ).getSingle();

    return {
      'totalSales': result.read<double>('total_sales'),
      'totalReturns': result.read<double>('total_returns'),
      'netSales': result.read<double>('net_sales'),
    };
  }

  // Stream version for real-time updates
  Stream<Map<String, double>> watchSalesSummary(DateTime start, DateTime end) {
    return customSelect(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'sale' THEN total ELSE 0 END), 0) as total_sales,
        COALESCE(SUM(CASE WHEN type = 'sale_return' THEN total ELSE 0 END), 0) as total_returns,
        COALESCE(SUM(CASE WHEN type = 'sale' THEN total ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN type = 'sale_return' THEN total ELSE 0 END), 0) as net_sales,
        COUNT(CASE WHEN type = 'sale' THEN 1 END) as invoice_count
      FROM invoices 
      WHERE invoice_date BETWEEN ? AND ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {invoices},
    ).watchSingle().map((result) => {
          'totalSales': result.read<double>('total_sales'),
          'totalReturns': result.read<double>('total_returns'),
          'netSales': result.read<double>('net_sales'),
          'invoiceCount': result.read<int>('invoice_count').toDouble(),
          'averageInvoice': result.read<int>('invoice_count') > 0
              ? result.read<double>('total_sales') /
                  result.read<int>('invoice_count')
              : 0.0,
        });
  }

  // Watch invoices by date range
  Stream<List<Invoice>> watchInvoicesByDateRange(DateTime start, DateTime end) {
    return (select(invoices)
          ..where((i) => i.invoiceDate.isBetweenValues(start, end))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  // Watch top selling products - returns stream
  Stream<List<Map<String, dynamic>>> watchTopSellingProducts(
      DateTime start, DateTime end, int limit) {
    return customSelect(
      '''
      SELECT 
        p.id, p.name, p.sku,
        COALESCE(SUM(ii.quantity), 0) as total_quantity,
        COALESCE(SUM(ii.total), 0) as total_amount
      FROM products p
      LEFT JOIN invoice_items ii ON ii.product_id = p.id
      LEFT JOIN invoices i ON ii.invoice_id = i.id AND i.type = 'sale' AND i.invoice_date BETWEEN ? AND ?
      GROUP BY p.id
      HAVING total_quantity > 0
      ORDER BY total_quantity DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {invoiceItems, invoices, products},
    ).watch().map((rows) => rows
        .map((row) => {
              'id': row.read<String>('id'),
              'name': row.read<String>('name'),
              'sku': row.readNullable<String>('sku'),
              'quantity': row.read<int>('total_quantity'),
              'total': row.read<double>('total_amount'),
            })
        .toList());
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      DateTime start, DateTime end, int limit) async {
    final result = await customSelect(
      '''
      SELECT 
        p.id, p.name, p.sku,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.total) as total_amount
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      JOIN products p ON ii.product_id = p.id
      WHERE i.type = 'sale' AND i.invoice_date BETWEEN ? AND ?
      GROUP BY p.id
      ORDER BY total_quantity DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {invoiceItems, invoices, products},
    ).get();

    return result
        .map((row) => {
              'id': row.read<String>('id'),
              'name': row.read<String>('name'),
              'sku': row.readNullable<String>('sku'),
              'totalQuantity': row.read<int>('total_quantity'),
              'totalAmount': row.read<double>('total_amount'),
            })
        .toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hoor_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
