import 'package:drift/drift.dart';
import '../database.dart';
import '../../app/constants/app_constants.dart';

/// مستودع المنتجات
class ProductRepository {
  final AppDatabase _db;

  ProductRepository(this._db);

  /// الحصول على جميع المنتجات
  Future<List<Product>> getAllProducts({bool activeOnly = true}) {
    final query = _db.select(_db.products);
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    return query.get();
  }

  /// الحصول على منتج بالمعرف
  Future<Product?> getProductById(int id) {
    return (_db.select(_db.products)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// البحث عن منتج بالباركود
  Future<Product?> getProductByBarcode(String barcode) {
    return (_db.select(_db.products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// البحث عن منتج بـ SKU
  Future<Product?> getProductBySku(String sku) {
    return (_db.select(_db.products)..where((p) => p.sku.equals(sku)))
        .getSingleOrNull();
  }

  /// البحث في المنتجات
  Future<List<Product>> searchProducts(String query) {
    return (_db.select(_db.products)
          ..where((p) =>
              p.name.like('%$query%') |
              p.barcode.like('%$query%') |
              p.sku.like('%$query%')))
        .get();
  }

  /// الحصول على المنتجات حسب التصنيف
  Future<List<Product>> getProductsByCategory(int categoryId) {
    return (_db.select(_db.products)
          ..where((p) => p.categoryId.equals(categoryId)))
        .get();
  }

  /// الحصول على المنتجات منخفضة المخزون
  Future<List<Product>> getLowStockProducts() {
    return (_db.select(_db.products)
          ..where((p) =>
              p.qty.isSmallerOrEqual(p.minQty) & p.trackStock.equals(true)))
        .get();
  }

  /// إضافة منتج جديد
  Future<int> insertProduct(ProductsCompanion product) {
    return _db.into(_db.products).insert(product);
  }

  /// تحديث منتج
  Future<bool> updateProduct(Product product) {
    return _db.update(_db.products).replace(product);
  }

  /// حذف منتج (soft delete)
  Future<int> deleteProduct(int id) {
    return (_db.update(_db.products)..where((p) => p.id.equals(id)))
        .write(const ProductsCompanion(isActive: Value(false)));
  }

  /// تحديث كمية المنتج
  Future<void> updateProductQty(int productId, double newQty) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      qty: Value(newQty),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// تحديث أسعار المنتج
  Future<void> updateProductPrices(
    int productId, {
    double? costPrice,
    double? salePrice,
    double? wholesalePrice,
  }) async {
    final companion = ProductsCompanion(
      costPrice: costPrice != null ? Value(costPrice) : const Value.absent(),
      salePrice: salePrice != null ? Value(salePrice) : const Value.absent(),
      wholesalePrice:
          wholesalePrice != null ? Value(wholesalePrice) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(companion);
  }

  /// تحديث أسعار جماعي (بنسبة مئوية)
  Future<void> bulkUpdatePrices({
    required List<int> productIds,
    double? costPricePercent,
    double? salePricePercent,
  }) async {
    await _db.transaction(() async {
      for (final id in productIds) {
        final product = await getProductById(id);
        if (product != null) {
          double? newCostPrice;
          double? newSalePrice;

          if (costPricePercent != null) {
            newCostPrice = product.costPrice * (1 + costPricePercent / 100);
          }
          if (salePricePercent != null) {
            newSalePrice = product.salePrice * (1 + salePricePercent / 100);
          }

          await updateProductPrices(
            id,
            costPrice: newCostPrice,
            salePrice: newSalePrice,
          );
        }
      }
    });
  }

  /// مراقبة المنتجات (Stream)
  Stream<List<Product>> watchAllProducts() {
    return (_db.select(_db.products)..where((p) => p.isActive.equals(true)))
        .watch();
  }

  /// عدد المنتجات
  Future<int> getProductsCount() async {
    final count = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([count])
      ..where(_db.products.isActive.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// توليد SKU جديد
  Future<String> generateSku() async {
    final count = await getProductsCount();
    return '${AppConstants.skuPrefix}${(count + 1).toString().padLeft(6, '0')}';
  }
}

/// مستودع التصنيفات
class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  /// الحصول على جميع التصنيفات
  Future<List<Category>> getAllCategories() {
    return (_db.select(_db.categories)..where((c) => c.isActive.equals(true)))
        .get();
  }

  /// الحصول على التصنيفات الرئيسية
  Future<List<Category>> getRootCategories() {
    return (_db.select(_db.categories)
          ..where((c) => c.parentId.isNull() & c.isActive.equals(true)))
        .get();
  }

  /// الحصول على التصنيفات الفرعية
  Future<List<Category>> getSubCategories(int parentId) {
    return (_db.select(_db.categories)
          ..where((c) => c.parentId.equals(parentId) & c.isActive.equals(true)))
        .get();
  }

  /// الحصول على تصنيف بالمعرف
  Future<Category?> getCategoryById(int id) {
    return (_db.select(_db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// إضافة تصنيف
  Future<int> insertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  /// تحديث تصنيف
  Future<bool> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  /// حذف تصنيف
  Future<int> deleteCategory(int id) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id)))
        .write(const CategoriesCompanion(isActive: Value(false)));
  }

  /// مراقبة التصنيفات
  Stream<List<Category>> watchAllCategories() {
    return (_db.select(_db.categories)..where((c) => c.isActive.equals(true)))
        .watch();
  }
}

/// مستودع حركات المخزون
class InventoryMovementRepository {
  final AppDatabase _db;

  InventoryMovementRepository(this._db);

  /// إضافة حركة مخزون
  Future<int> addMovement({
    required int productId,
    required String type,
    required double qty,
    double? unitPrice,
    String? refType,
    int? refId,
    String? note,
  }) async {
    // الحصول على الكمية الحالية
    final product = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();

    final qtyBefore = product.qty;
    double qtyAfter;

    // حساب الكمية بعد الحركة
    switch (type) {
      case AppConstants.movementTypeOpening:
      case AppConstants.movementTypePurchase:
      case AppConstants.movementTypeReturnSale:
        qtyAfter = qtyBefore + qty;
        break;
      case AppConstants.movementTypeSale:
      case AppConstants.movementTypeReturnPurchase:
        qtyAfter = qtyBefore - qty;
        break;
      case AppConstants.movementTypeAdjustment:
        qtyAfter = qty; // الكمية الجديدة مباشرة
        break;
      default:
        qtyAfter = qtyBefore + qty;
    }

    return _db.transaction(() async {
      // إضافة الحركة
      final movementId = await _db.into(_db.inventoryMovements).insert(
            InventoryMovementsCompanion.insert(
              productId: productId,
              type: type,
              qty: qty,
              qtyBefore: qtyBefore,
              qtyAfter: qtyAfter,
              unitPrice: Value(unitPrice),
              refType: Value(refType),
              refId: Value(refId),
              note: Value(note),
            ),
          );

      // تحديث كمية المنتج
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(
        qty: Value(qtyAfter),
        updatedAt: Value(DateTime.now()),
      ));

      return movementId;
    });
  }

  /// الحصول على حركات منتج
  Future<List<InventoryMovement>> getProductMovements(int productId) {
    return (_db.select(_db.inventoryMovements)
          ..where((m) => m.productId.equals(productId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  /// الحصول على حركات بتاريخ
  Future<List<InventoryMovement>> getMovementsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.inventoryMovements)
          ..where((m) =>
              m.createdAt.isBiggerOrEqualValue(startOfDay) &
              m.createdAt.isSmallerThanValue(endOfDay))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  /// الحصول على حركات بفترة
  Future<List<InventoryMovement>> getMovementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (_db.select(_db.inventoryMovements)
          ..where((m) =>
              m.createdAt.isBiggerOrEqualValue(startDate) &
              m.createdAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }
}
