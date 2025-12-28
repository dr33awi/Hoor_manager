import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
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

  /// Withdraw stock from a product
  Future<void> withdrawStock({
    required String productId,
    required int quantity,
    String? reason,
    String? referenceId,
    String? referenceType,
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) return;

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
