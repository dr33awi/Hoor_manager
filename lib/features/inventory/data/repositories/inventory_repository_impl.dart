import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoor_manager/core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_model.dart';

/// تنفيذ مستودع المخزون
class InventoryRepositoryImpl implements InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مراجع المجموعات
  CollectionReference<Map<String, dynamic>> get _warehousesRef =>
      _firestore.collection('warehouses');

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      _firestore.collection('stock_movements');

  CollectionReference<Map<String, dynamic>> get _stockTakesRef =>
      _firestore.collection('stock_takes');

  CollectionReference<Map<String, dynamic>> get _stockBalancesRef =>
      _firestore.collection('stock_balances');

  // ============ المستودعات ============

  @override
  Stream<List<WarehouseEntity>> watchWarehouses() {
    return _warehousesRef.orderBy('name').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => WarehouseModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Stream<List<WarehouseEntity>> watchActiveWarehouses() {
    return _warehousesRef
        .where('status', isEqualTo: WarehouseStatus.active.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WarehouseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<WarehouseEntity?>> getWarehouseById(String id) async {
    try {
      final doc = await _warehousesRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(WarehouseModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب المستودع: $e');
    }
  }

  @override
  Future<Result<WarehouseEntity>> createWarehouse(
      WarehouseEntity warehouse) async {
    try {
      final model = WarehouseModel.fromEntity(warehouse);
      final docRef = await _warehousesRef.add(model.toMap());
      return Success(model.copyWith(id: docRef.id) as WarehouseEntity);
    } catch (e) {
      return Failure('فشل في إنشاء المستودع: $e');
    }
  }

  @override
  Future<Result<void>> updateWarehouse(WarehouseEntity warehouse) async {
    try {
      final model = WarehouseModel.fromEntity(warehouse);
      await _warehousesRef.doc(warehouse.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث المستودع: $e');
    }
  }

  @override
  Future<Result<void>> deleteWarehouse(String id) async {
    try {
      await _warehousesRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف المستودع: $e');
    }
  }

  @override
  Future<Result<void>> setDefaultWarehouse(String id) async {
    try {
      final batch = _firestore.batch();

      // إزالة الافتراضي من المستودعات الأخرى
      final currentDefault =
          await _warehousesRef.where('isDefault', isEqualTo: true).get();
      for (final doc in currentDefault.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // تعيين المستودع الجديد كافتراضي
      batch.update(_warehousesRef.doc(id), {'isDefault': true});

      await batch.commit();
      return Success(null);
    } catch (e) {
      return Failure('فشل في تعيين المستودع الافتراضي: $e');
    }
  }

  // ============ حركات المخزون ============

  @override
  Stream<List<StockMovementEntity>> watchMovements() {
    return _movementsRef
        .orderBy('movementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<StockMovementEntity>> watchMovementsByWarehouse(
      String warehouseId) {
    return _movementsRef
        .where(Filter.or(
          Filter('sourceWarehouseId', isEqualTo: warehouseId),
          Filter('destinationWarehouseId', isEqualTo: warehouseId),
        ))
        .orderBy('movementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<StockMovementEntity>> watchMovementsByProduct(String productId) {
    return _movementsRef
        .where('items', arrayContains: {'productId': productId})
        .orderBy('movementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<StockMovementEntity?>> getMovementById(String id) async {
    try {
      final doc = await _movementsRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(StockMovementModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب الحركة: $e');
    }
  }

  @override
  Future<Result<StockMovementEntity>> createMovement(
      StockMovementEntity movement) async {
    try {
      final model = StockMovementModel.fromEntity(movement);
      final docRef = await _movementsRef.add(model.toMap());
      return Success(model.copyWith(id: docRef.id) as StockMovementEntity);
    } catch (e) {
      return Failure('فشل في إنشاء الحركة: $e');
    }
  }

  @override
  Future<Result<void>> updateMovement(StockMovementEntity movement) async {
    try {
      final model = StockMovementModel.fromEntity(movement);
      await _movementsRef.doc(movement.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث الحركة: $e');
    }
  }

  @override
  Future<Result<void>> approveMovement({
    required String id,
    required String approvedBy,
  }) async {
    try {
      await _movementsRef.doc(id).update({
        'status': StockMovementStatus.approved.name,
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // تحديث أرصدة المخزون بعد الاعتماد
      final movementResult = await getMovementById(id);
      if (movementResult.isSuccess && movementResult.valueOrNull != null) {
        await _applyMovementToStock(movementResult.valueOrNull!);
      }

      return Success(null);
    } catch (e) {
      return Failure('فشل في اعتماد الحركة: $e');
    }
  }

  Future<void> _applyMovementToStock(StockMovementEntity movement) async {
    for (final item in movement.items) {
      // خصم من المصدر
      if (movement.sourceWarehouseId != null) {
        await updateStockBalance(
          productId: item.productId,
          warehouseId: movement.sourceWarehouseId!,
          quantityChange: -item.quantity,
          reason: 'حركة مخزون: ${movement.movementNumber}',
        );
      }

      // إضافة للوجهة
      if (movement.destinationWarehouseId != null) {
        await updateStockBalance(
          productId: item.productId,
          warehouseId: movement.destinationWarehouseId!,
          quantityChange: item.quantity,
          reason: 'حركة مخزون: ${movement.movementNumber}',
        );
      }
    }
  }

  @override
  Future<Result<void>> cancelMovement(String id) async {
    try {
      await _movementsRef.doc(id).update({
        'status': StockMovementStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });
      return Success(null);
    } catch (e) {
      return Failure('فشل في إلغاء الحركة: $e');
    }
  }

  @override
  Future<Result<void>> deleteMovement(String id) async {
    try {
      await _movementsRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف الحركة: $e');
    }
  }

  @override
  Future<String> generateMovementNumber(StockMovementType type) async {
    final prefix = switch (type) {
      StockMovementType.inbound => 'IN',
      StockMovementType.outbound => 'OUT',
      StockMovementType.transfer => 'TR',
      StockMovementType.adjustment => 'ADJ',
      StockMovementType.return_ => 'RET',
    };

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final todayStart = DateTime(now.year, now.month, now.day);
    final count = await _movementsRef
        .where('type', isEqualTo: type.name)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final sequence = ((count.count ?? 0) + 1).toString().padLeft(4, '0');
    return '$prefix-$dateStr-$sequence';
  }

  // ============ الجرد ============

  @override
  Stream<List<StockTakeEntity>> watchStockTakes() {
    return _stockTakesRef
        .orderBy('stockTakeDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockTakeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<StockTakeEntity>> watchStockTakesByWarehouse(String warehouseId) {
    return _stockTakesRef
        .where('warehouseId', isEqualTo: warehouseId)
        .orderBy('stockTakeDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockTakeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<StockTakeEntity?>> getStockTakeById(String id) async {
    try {
      final doc = await _stockTakesRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(StockTakeModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب الجرد: $e');
    }
  }

  @override
  Future<Result<StockTakeEntity>> createStockTake(
      StockTakeEntity stockTake) async {
    try {
      final model = StockTakeModel.fromEntity(stockTake);
      final docRef = await _stockTakesRef.add(model.toMap());
      return Success(model.copyWith(id: docRef.id) as StockTakeEntity);
    } catch (e) {
      return Failure('فشل في إنشاء الجرد: $e');
    }
  }

  @override
  Future<Result<void>> updateStockTake(StockTakeEntity stockTake) async {
    try {
      final model = StockTakeModel.fromEntity(stockTake);
      await _stockTakesRef.doc(stockTake.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث الجرد: $e');
    }
  }

  @override
  Future<Result<void>> completeStockTake({
    required String id,
    required String completedBy,
  }) async {
    try {
      await _stockTakesRef.doc(id).update({
        'status': StockTakeStatus.completed.name,
        'completedBy': completedBy,
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // تحديث أرصدة المخزون بناءً على الجرد
      final stockTakeResult = await getStockTakeById(id);
      if (stockTakeResult.isSuccess && stockTakeResult.valueOrNull != null) {
        await _applyStockTakeAdjustments(stockTakeResult.valueOrNull!);
      }

      return Success(null);
    } catch (e) {
      return Failure('فشل في إكمال الجرد: $e');
    }
  }

  Future<void> _applyStockTakeAdjustments(StockTakeEntity stockTake) async {
    for (final item in stockTake.items) {
      if (item.hasDifference) {
        // إنشاء حركة تعديل
        final movementNumber =
            await generateMovementNumber(StockMovementType.adjustment);
        final movement = StockMovementEntity(
          id: '',
          movementNumber: movementNumber,
          type: StockMovementType.adjustment,
          status: StockMovementStatus.approved,
          destinationWarehouseId:
              item.difference > 0 ? stockTake.warehouseId : null,
          destinationWarehouseName:
              item.difference > 0 ? stockTake.warehouseName : null,
          sourceWarehouseId: item.difference < 0 ? stockTake.warehouseId : null,
          sourceWarehouseName:
              item.difference < 0 ? stockTake.warehouseName : null,
          referenceType: 'stock_take',
          referenceId: stockTake.id,
          referenceNumber: stockTake.stockTakeNumber,
          items: [
            StockMovementItemEntity(
              id: item.id,
              productId: item.productId,
              productName: item.productName,
              productSku: item.productSku,
              quantity: item.difference.abs(),
              notes: 'تعديل من جرد: ${stockTake.stockTakeNumber}',
            ),
          ],
          notes: 'تعديل تلقائي من جرد ${stockTake.stockTakeNumber}',
          createdBy: stockTake.completedBy ?? 'system',
          approvedBy: stockTake.completedBy,
          approvedAt: DateTime.now(),
          movementDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await createMovement(movement);
      }
    }
  }

  @override
  Future<Result<void>> cancelStockTake(String id) async {
    try {
      await _stockTakesRef.doc(id).update({
        'status': StockTakeStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });
      return Success(null);
    } catch (e) {
      return Failure('فشل في إلغاء الجرد: $e');
    }
  }

  @override
  Future<Result<void>> deleteStockTake(String id) async {
    try {
      await _stockTakesRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف الجرد: $e');
    }
  }

  @override
  Future<String> generateStockTakeNumber() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final todayStart = DateTime(now.year, now.month, now.day);
    final count = await _stockTakesRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final sequence = ((count.count ?? 0) + 1).toString().padLeft(4, '0');
    return 'ST-$dateStr-$sequence';
  }

  // ============ أرصدة المخزون ============

  @override
  Stream<List<StockBalanceEntity>> watchStockBalances() {
    return _stockBalancesRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => StockBalanceModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Stream<List<StockBalanceEntity>> watchStockBalancesByWarehouse(
      String warehouseId) {
    return _stockBalancesRef
        .where('warehouseId', isEqualTo: warehouseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockBalanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<List<StockBalanceEntity>>> getProductStockBalances(
      String productId) async {
    try {
      final snapshot = await _stockBalancesRef
          .where('productId', isEqualTo: productId)
          .get();
      return Success(snapshot.docs
          .map((doc) => StockBalanceModel.fromMap(doc.data(), doc.id))
          .toList());
    } catch (e) {
      return Failure('فشل في جلب أرصدة المنتج: $e');
    }
  }

  @override
  Future<Result<StockBalanceEntity?>> getProductWarehouseBalance({
    required String productId,
    required String warehouseId,
  }) async {
    try {
      final snapshot = await _stockBalancesRef
          .where('productId', isEqualTo: productId)
          .where('warehouseId', isEqualTo: warehouseId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return Success(null);
      return Success(StockBalanceModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id));
    } catch (e) {
      return Failure('فشل في جلب رصيد المنتج: $e');
    }
  }

  @override
  Future<Result<void>> updateStockBalance({
    required String productId,
    required String warehouseId,
    required int quantityChange,
    String? reason,
  }) async {
    try {
      final balanceResult = await getProductWarehouseBalance(
        productId: productId,
        warehouseId: warehouseId,
      );

      if (balanceResult.isSuccess && balanceResult.valueOrNull != null) {
        // تحديث الرصيد الموجود
        final currentBalance = balanceResult.valueOrNull!;
        final newQuantity = currentBalance.quantity + quantityChange;

        final snapshot = await _stockBalancesRef
            .where('productId', isEqualTo: productId)
            .where('warehouseId', isEqualTo: warehouseId)
            .limit(1)
            .get();

        await snapshot.docs.first.reference.update({
          'quantity': newQuantity,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // إنشاء رصيد جديد
        await _stockBalancesRef.add({
          'productId': productId,
          'productName': '', // يجب جلبه من المنتج
          'warehouseId': warehouseId,
          'warehouseName': '', // يجب جلبه من المستودع
          'quantity': quantityChange,
          'reservedQuantity': 0,
          'lastUpdated': Timestamp.now(),
        });
      }

      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث رصيد المخزون: $e');
    }
  }

  @override
  Future<Result<void>> reserveStock({
    required String productId,
    required String warehouseId,
    required int quantity,
    required String referenceId,
  }) async {
    try {
      final snapshot = await _stockBalancesRef
          .where('productId', isEqualTo: productId)
          .where('warehouseId', isEqualTo: warehouseId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Failure('لا يوجد رصيد للمنتج في هذا المستودع');
      }

      final doc = snapshot.docs.first;
      final currentReserved = doc.data()['reservedQuantity'] ?? 0;

      await doc.reference.update({
        'reservedQuantity': currentReserved + quantity,
        'lastUpdated': Timestamp.now(),
      });

      return Success(null);
    } catch (e) {
      return Failure('فشل في حجز المخزون: $e');
    }
  }

  @override
  Future<Result<void>> releaseReservedStock({
    required String productId,
    required String warehouseId,
    required int quantity,
    required String referenceId,
  }) async {
    try {
      final snapshot = await _stockBalancesRef
          .where('productId', isEqualTo: productId)
          .where('warehouseId', isEqualTo: warehouseId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Failure('لا يوجد رصيد للمنتج في هذا المستودع');
      }

      final doc = snapshot.docs.first;
      final currentReserved = doc.data()['reservedQuantity'] ?? 0;

      await doc.reference.update({
        'reservedQuantity':
            (currentReserved - quantity).clamp(0, currentReserved),
        'lastUpdated': Timestamp.now(),
      });

      return Success(null);
    } catch (e) {
      return Failure('فشل في إلغاء حجز المخزون: $e');
    }
  }

  // ============ الإحصائيات ============

  @override
  Future<Result<InventoryStats>> getInventoryStats() async {
    try {
      final warehousesSnapshot = await _warehousesRef.get();
      final activeWarehousesSnapshot = await _warehousesRef
          .where('status', isEqualTo: WarehouseStatus.active.name)
          .get();
      final movementsSnapshot = await _movementsRef.get();
      final pendingMovementsSnapshot = await _movementsRef
          .where('status', isEqualTo: StockMovementStatus.pending.name)
          .get();
      final stockBalancesSnapshot = await _stockBalancesRef.get();

      int lowStock = 0;
      int outOfStock = 0;
      for (final doc in stockBalancesSnapshot.docs) {
        final quantity = doc.data()['quantity'] ?? 0;
        if (quantity == 0) {
          outOfStock++;
        } else if (quantity <= 10) {
          lowStock++;
        }
      }

      return Success(InventoryStats(
        totalWarehouses: warehousesSnapshot.docs.length,
        activeWarehouses: activeWarehousesSnapshot.docs.length,
        totalProducts: stockBalancesSnapshot.docs.length,
        lowStockProducts: lowStock,
        outOfStockProducts: outOfStock,
        totalMovements: movementsSnapshot.docs.length,
        pendingMovements: pendingMovementsSnapshot.docs.length,
      ));
    } catch (e) {
      return Failure('فشل في جلب الإحصائيات: $e');
    }
  }

  @override
  Future<Result<List<StockBalanceEntity>>> getLowStockProducts({
    int threshold = 10,
  }) async {
    try {
      final snapshot = await _stockBalancesRef
          .where('quantity', isLessThanOrEqualTo: threshold)
          .where('quantity', isGreaterThan: 0)
          .get();
      return Success(snapshot.docs
          .map((doc) => StockBalanceModel.fromMap(doc.data(), doc.id))
          .toList());
    } catch (e) {
      return Failure('فشل في جلب المنتجات منخفضة المخزون: $e');
    }
  }

  @override
  Future<Result<List<StockBalanceEntity>>> getOutOfStockProducts() async {
    try {
      final snapshot =
          await _stockBalancesRef.where('quantity', isEqualTo: 0).get();
      return Success(snapshot.docs
          .map((doc) => StockBalanceModel.fromMap(doc.data(), doc.id))
          .toList());
    } catch (e) {
      return Failure('فشل في جلب المنتجات النافذة: $e');
    }
  }

  // ============ البحث ============

  @override
  Future<Result<List<StockMovementEntity>>> searchMovements(
      String query) async {
    try {
      final snapshot = await _movementsRef.get();
      final results = snapshot.docs
          .map((doc) => StockMovementModel.fromMap(doc.data(), doc.id))
          .where((movement) =>
              movement.movementNumber
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (movement.notes?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (movement.referenceNumber
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();
      return Success(results);
    } catch (e) {
      return Failure('فشل في البحث: $e');
    }
  }

  @override
  Future<Result<List<WarehouseEntity>>> searchWarehouses(String query) async {
    try {
      final snapshot = await _warehousesRef.get();
      final results = snapshot.docs
          .map((doc) => WarehouseModel.fromMap(doc.data(), doc.id))
          .where((warehouse) =>
              warehouse.name.toLowerCase().contains(query.toLowerCase()) ||
              (warehouse.code?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
      return Success(results);
    } catch (e) {
      return Failure('فشل في البحث: $e');
    }
  }
}
