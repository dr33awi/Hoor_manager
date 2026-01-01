import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/accounting_exceptions.dart';
import 'base_repository.dart';

class InventoryRepository
    extends BaseRepository<InventoryMovement, InventoryMovementsCompanion> {
  StreamSubscription? _inventoryFirestoreSubscription;

  InventoryRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.inventoryMovementsCollection);

  // ==================== Local Operations ====================

  Future<List<InventoryMovement>> getProductMovements(String productId) =>
      database.getInventoryMovements(productId);

  Future<List<InventoryMovement>> getAllMovements() =>
      database.getAllInventoryMovements();

  Stream<List<InventoryMovement>> watchAllMovements() =>
      database.watchInventoryMovements();

  /// Add stock to a product
  Future<void> addStock({
    required String productId,
    required int quantity,
    String? reason,
    String? referenceId,
    String? referenceType,
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

    final newQuantity = product.quantity + quantity;
    await database.updateProductQuantity(productId, newQuantity);

    await database.insertInventoryMovement(InventoryMovementsCompanion(
      id: Value(generateId()),
      productId: Value(productId),
      type: const Value('add'),
      quantity: Value(quantity),
      previousQuantity: Value(product.quantity),
      newQuantity: Value(newQuantity),
      reason: Value(reason ?? 'إضافة مخزون'),
      referenceId: Value(referenceId),
      referenceType: Value(referenceType),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Withdraw stock from a product (مع التحقق من توفر الكمية)
  Future<void> withdrawStock({
    required String productId,
    required int quantity,
    String? reason,
    String? referenceId,
    String? referenceType,
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

    // التحقق من توفر الكمية المطلوبة
    if (product.quantity < quantity) {
      throw NegativeStockException(
        productId: productId,
        productName: product.name,
        currentQuantity: product.quantity,
        requestedWithdraw: quantity,
      );
    }

    final newQuantity = product.quantity - quantity;
    await database.updateProductQuantity(productId, newQuantity);

    await database.insertInventoryMovement(InventoryMovementsCompanion(
      id: Value(generateId()),
      productId: Value(productId),
      type: const Value('withdraw'),
      quantity: Value(quantity),
      previousQuantity: Value(product.quantity),
      newQuantity: Value(newQuantity),
      reason: Value(reason ?? 'سحب مخزون'),
      referenceId: Value(referenceId),
      referenceType: Value(referenceType),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Adjust stock (for inventory count)
  Future<void> adjustStock({
    required String productId,
    required int actualQuantity,
    String? reason,
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

    final difference = actualQuantity - product.quantity;
    if (difference == 0) return;

    await database.updateProductQuantity(productId, actualQuantity);

    await database.insertInventoryMovement(InventoryMovementsCompanion(
      id: Value(generateId()),
      productId: Value(productId),
      type: const Value('adjustment'),
      quantity: Value(difference.abs()),
      previousQuantity: Value(product.quantity),
      newQuantity: Value(actualQuantity),
      reason: Value(reason ??
          'تعديل جرد: ${difference > 0 ? "زيادة" : "نقص"} $difference'),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Perform full inventory count
  Future<void> performInventoryCount(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      await adjustStock(
        productId: item['productId'] as String,
        actualQuantity: item['actualQuantity'] as int,
        reason: 'جرد مستودع',
      );
    }
  }

  /// Update stock for a transaction (sale, purchase, return)
  /// Handles both global product quantity and warehouse stock
  Future<void> updateStockForTransaction({
    required String productId,
    required int quantity,
    required String
        transactionType, // 'sale', 'purchase', 'sale_return', 'purchase_return'
    String? warehouseId,
    String? referenceId, // invoiceId
    String? referenceNumber, // invoiceNumber
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

    int adjustment;
    String movementType;
    String reason;

    switch (transactionType) {
      case 'sale':
        adjustment = -quantity;
        movementType = 'sale';
        reason = 'Invoice Sale: ${referenceNumber ?? ""}';
        break;
      case 'purchase':
        adjustment = quantity;
        movementType = 'purchase';
        reason = 'Invoice Purchase: ${referenceNumber ?? ""}';
        break;
      case 'sale_return':
        adjustment = quantity;
        movementType = 'return';
        reason = 'Sale Return: ${referenceNumber ?? ""}';
        break;
      case 'purchase_return':
        adjustment = -quantity;
        movementType = 'return';
        reason = 'Purchase Return: ${referenceNumber ?? ""}';
        break;
      default:
        return;
    }

    final newQuantity = product.quantity + adjustment;

    // 1. Update global product quantity
    await database.updateProductQuantity(productId, newQuantity);

    // 2. Update warehouse stock if warehouseId is provided
    if (warehouseId != null) {
      try {
        final warehouseStock =
            await database.getWarehouseStockByProductAndWarehouse(
          productId,
          warehouseId,
        );

        if (warehouseStock != null) {
          final newWarehouseQty = warehouseStock.quantity + adjustment;
          await database.updateWarehouseStock(WarehouseStockCompanion(
            id: Value(warehouseStock.id),
            quantity: Value(newWarehouseQty),
            syncStatus: const Value('pending'),
            updatedAt: Value(DateTime.now()),
          ));
        }
      } catch (e) {
        debugPrint('Error updating warehouse stock: $e');
      }
    }

    // 3. Record inventory movement
    await database.insertInventoryMovement(InventoryMovementsCompanion(
      id: Value(generateId()),
      productId: Value(productId),
      warehouseId: Value(warehouseId),
      type: Value(movementType),
      quantity: Value(quantity),
      previousQuantity: Value(product.quantity),
      newQuantity: Value(newQuantity),
      reason: Value(reason),
      referenceId: Value(referenceId),
      referenceType: const Value('invoice'),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingInventoryMovements();

    for (final movement in pending) {
      try {
        await collection.doc(movement.id).set(toFirestore(movement));
        // Update sync status to synced
        await database.updateInventoryMovementSyncStatus(movement.id, 'synced');
      } catch (e) {
        debugPrint('Error syncing inventory movement ${movement.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    // Inventory movements are typically not pulled back
    // They're historical records created locally
  }

  @override
  Map<String, dynamic> toFirestore(InventoryMovement entity) {
    return {
      'productId': entity.productId,
      'warehouseId': entity.warehouseId,
      'type': entity.type,
      'quantity': entity.quantity,
      'previousQuantity': entity.previousQuantity,
      'newQuantity': entity.newQuantity,
      'reason': entity.reason,
      'referenceId': entity.referenceId,
      'referenceType': entity.referenceType,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }

  @override
  InventoryMovementsCompanion fromFirestore(
      Map<String, dynamic> data, String id) {
    return InventoryMovementsCompanion(
      id: Value(id),
      productId: Value(data['productId'] as String),
      warehouseId: Value(data['warehouseId'] as String?),
      type: Value(data['type'] as String),
      quantity: Value(data['quantity'] as int),
      previousQuantity: Value(data['previousQuantity'] as int),
      newQuantity: Value(data['newQuantity'] as int),
      reason: Value(data['reason'] as String?),
      referenceId: Value(data['referenceId'] as String?),
      referenceType: Value(data['referenceType'] as String?),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _inventoryFirestoreSubscription?.cancel();
    _inventoryFirestoreSubscription = collection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            _handleRemoteChange(data, change.doc.id);
            break;
          case DocumentChangeType.removed:
            // Inventory movements typically shouldn't be deleted
            break;
        }
      }
    });
  }

  Future<void> _handleRemoteChange(Map<String, dynamic> data, String id) async {
    try {
      final movements =
          await database.getInventoryMovements(data['productId'] as String);
      final existing = movements.where((m) => m.id == id).firstOrNull;
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertInventoryMovement(companion);
      }
    } catch (e) {
      debugPrint('Error handling remote inventory movement change: $e');
    }
  }
}
