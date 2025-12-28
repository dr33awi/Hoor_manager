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

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<bool> updateProduct(ProductsCompanion product) {
    return update(products).replace(Product(
      id: product.id.value,
      name: product.name.value,
      sku: product.sku.value,
      barcode: product.barcode.value,
      categoryId: product.categoryId.value,
      purchasePrice: product.purchasePrice.value,
      salePrice: product.salePrice.value,
      quantity: product.quantity.value,
      minQuantity: product.minQuantity.value,
      taxRate: product.taxRate.value,
      description: product.description.value,
      imageUrl: product.imageUrl.value,
      isActive: product.isActive.value,
      syncStatus: product.syncStatus.value,
      createdAt: product.createdAt.value,
      updatedAt: DateTime.now(),
    ));
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

  Future<int> insertInvoice(InvoicesCompanion invoice) {
    return into(invoices).insert(invoice);
  }

  Future<void> updateInvoice(InvoicesCompanion invoice) {
    return (update(invoices)..where((i) => i.id.equals(invoice.id.value)))
        .write(invoice);
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
