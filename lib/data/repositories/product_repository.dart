import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class ProductRepository extends BaseRepository<Product, ProductsCompanion> {
  ProductRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.productsCollection);

  // ==================== Local Operations ====================

  Future<List<Product>> getAllProducts() => database.getAllProducts();

  Stream<List<Product>> watchAllProducts() => database.watchAllProducts();

  Stream<List<Product>> watchActiveProducts() => database.watchActiveProducts();

  Future<Product?> getProductById(String id) => database.getProductById(id);

  Future<Product?> getProductByBarcode(String barcode) =>
      database.getProductByBarcode(barcode);

  Future<List<Product>> getProductsByCategory(String categoryId) =>
      database.getProductsByCategory(categoryId);

  Future<List<Product>> getLowStockProducts() => database.getLowStockProducts();

  Future<String> createProduct({
    required String name,
    String? sku,
    String? barcode,
    String? categoryId,
    required double purchasePrice,
    required double salePrice,
    int quantity = 0,
    int minQuantity = 5,
    double? taxRate,
    String? description,
    String? imageUrl,
  }) async {
    final id = generateId();
    final now = DateTime.now();

    await database.insertProduct(ProductsCompanion(
      id: Value(id),
      name: Value(name),
      sku: Value(sku),
      barcode: Value(barcode),
      categoryId: Value(categoryId),
      purchasePrice: Value(purchasePrice),
      salePrice: Value(salePrice),
      quantity: Value(quantity),
      minQuantity: Value(minQuantity),
      taxRate: Value(taxRate),
      description: Value(description),
      imageUrl: Value(imageUrl),
      isActive: const Value(true),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return id;
  }

  Future<void> updateProduct({
    required String id,
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    int? minQuantity,
    double? taxRate,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    final existing = await database.getProductById(id);
    if (existing == null) return;

    await database.updateProduct(ProductsCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      sku: Value(sku ?? existing.sku),
      barcode: Value(barcode ?? existing.barcode),
      categoryId: Value(categoryId ?? existing.categoryId),
      purchasePrice: Value(purchasePrice ?? existing.purchasePrice),
      salePrice: Value(salePrice ?? existing.salePrice),
      quantity: Value(quantity ?? existing.quantity),
      minQuantity: Value(minQuantity ?? existing.minQuantity),
      taxRate: Value(taxRate ?? existing.taxRate),
      description: Value(description ?? existing.description),
      imageUrl: Value(imageUrl ?? existing.imageUrl),
      isActive: Value(isActive ?? existing.isActive),
      syncStatus: const Value('pending'),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateProductQuantity(String productId, int newQuantity) =>
      database.updateProductQuantity(productId, newQuantity);

  Future<void> adjustStock(
      String productId, int adjustment, String reason) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

    final newQuantity = product.quantity + adjustment;
    await database.updateProductQuantity(productId, newQuantity);

    // Record inventory movement
    await database.insertInventoryMovement(InventoryMovementsCompanion(
      id: Value(generateId()),
      productId: Value(productId),
      type: Value(adjustment > 0 ? 'add' : 'withdraw'),
      quantity: Value(adjustment.abs()),
      previousQuantity: Value(product.quantity),
      newQuantity: Value(newQuantity),
      reason: Value(reason),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteProduct(String id) => database.deleteProduct(id);

  Future<void> updateSalePrices(List<Map<String, dynamic>> updates) async {
    for (final update in updates) {
      final id = update['id'] as String;
      final newPrice = update['salePrice'] as double;
      await updateProduct(id: id, salePrice: newPrice);
    }
  }

  Future<void> updatePurchasePrices(List<Map<String, dynamic>> updates) async {
    for (final update in updates) {
      final id = update['id'] as String;
      final newPrice = update['purchasePrice'] as double;
      await updateProduct(id: id, purchasePrice: newPrice);
    }
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingProducts();

    for (final product in pending) {
      try {
        await collection.doc(product.id).set(toFirestore(product));

        // Update sync status
        await database.updateProduct(ProductsCompanion(
          id: Value(product.id),
          name: Value(product.name),
          sku: Value(product.sku),
          barcode: Value(product.barcode),
          categoryId: Value(product.categoryId),
          purchasePrice: Value(product.purchasePrice),
          salePrice: Value(product.salePrice),
          quantity: Value(product.quantity),
          minQuantity: Value(product.minQuantity),
          taxRate: Value(product.taxRate),
          description: Value(product.description),
          imageUrl: Value(product.imageUrl),
          isActive: Value(product.isActive),
          syncStatus: const Value('synced'),
          createdAt: Value(product.createdAt),
          updatedAt: Value(product.updatedAt),
        ));
      } catch (e) {
        debugPrint('Error syncing product ${product.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection
          .orderBy('updatedAt', descending: true)
          .limit(500)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getProductById(doc.id);
        if (existing == null) {
          await database.insertProduct(companion);
        } else if (existing.syncStatus == 'synced') {
          // Only update if local is synced (no pending changes)
          final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
          if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
            await database.updateProduct(companion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error pulling products from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Product entity) {
    return {
      'name': entity.name,
      'sku': entity.sku,
      'barcode': entity.barcode,
      'categoryId': entity.categoryId,
      'purchasePrice': entity.purchasePrice,
      'salePrice': entity.salePrice,
      'quantity': entity.quantity,
      'minQuantity': entity.minQuantity,
      'taxRate': entity.taxRate,
      'description': entity.description,
      'imageUrl': entity.imageUrl,
      'isActive': entity.isActive,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  @override
  ProductsCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(data['name'] as String),
      sku: Value(data['sku'] as String?),
      barcode: Value(data['barcode'] as String?),
      categoryId: Value(data['categoryId'] as String?),
      purchasePrice: Value((data['purchasePrice'] as num).toDouble()),
      salePrice: Value((data['salePrice'] as num).toDouble()),
      quantity: Value(data['quantity'] as int? ?? 0),
      minQuantity: Value(data['minQuantity'] as int? ?? 5),
      taxRate: Value((data['taxRate'] as num?)?.toDouble()),
      description: Value(data['description'] as String?),
      imageUrl: Value(data['imageUrl'] as String?),
      isActive: Value(data['isActive'] as bool? ?? true),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }
}
