import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// إحصائيات المخزون
class InventoryStats {
  final int totalWarehouses;
  final int activeWarehouses;
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalMovements;
  final int pendingMovements;

  const InventoryStats({
    this.totalWarehouses = 0,
    this.activeWarehouses = 0,
    this.totalProducts = 0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
    this.totalMovements = 0,
    this.pendingMovements = 0,
  });

  factory InventoryStats.empty() => const InventoryStats();
}

/// واجهة مستودع المخزون
abstract class InventoryRepository {
  // ============ المستودعات ============

  /// جلب جميع المستودعات
  Stream<List<WarehouseEntity>> watchWarehouses();

  /// جلب المستودعات النشطة
  Stream<List<WarehouseEntity>> watchActiveWarehouses();

  /// جلب مستودع بالمعرف
  Future<Result<WarehouseEntity?>> getWarehouseById(String id);

  /// إنشاء مستودع
  Future<Result<WarehouseEntity>> createWarehouse(WarehouseEntity warehouse);

  /// تحديث مستودع
  Future<Result<void>> updateWarehouse(WarehouseEntity warehouse);

  /// حذف مستودع
  Future<Result<void>> deleteWarehouse(String id);

  /// تعيين المستودع الافتراضي
  Future<Result<void>> setDefaultWarehouse(String id);

  // ============ حركات المخزون ============

  /// جلب جميع الحركات
  Stream<List<StockMovementEntity>> watchMovements();

  /// جلب حركات مستودع معين
  Stream<List<StockMovementEntity>> watchMovementsByWarehouse(
      String warehouseId);

  /// جلب حركات منتج معين
  Stream<List<StockMovementEntity>> watchMovementsByProduct(String productId);

  /// جلب حركة بالمعرف
  Future<Result<StockMovementEntity?>> getMovementById(String id);

  /// إنشاء حركة مخزون
  Future<Result<StockMovementEntity>> createMovement(
      StockMovementEntity movement);

  /// تحديث حركة مخزون
  Future<Result<void>> updateMovement(StockMovementEntity movement);

  /// اعتماد حركة مخزون
  Future<Result<void>> approveMovement({
    required String id,
    required String approvedBy,
  });

  /// إلغاء حركة مخزون
  Future<Result<void>> cancelMovement(String id);

  /// حذف حركة مخزون
  Future<Result<void>> deleteMovement(String id);

  /// توليد رقم حركة
  Future<String> generateMovementNumber(StockMovementType type);

  // ============ الجرد ============

  /// جلب جميع عمليات الجرد
  Stream<List<StockTakeEntity>> watchStockTakes();

  /// جلب عمليات جرد مستودع معين
  Stream<List<StockTakeEntity>> watchStockTakesByWarehouse(String warehouseId);

  /// جلب عملية جرد بالمعرف
  Future<Result<StockTakeEntity?>> getStockTakeById(String id);

  /// إنشاء عملية جرد
  Future<Result<StockTakeEntity>> createStockTake(StockTakeEntity stockTake);

  /// تحديث عملية جرد
  Future<Result<void>> updateStockTake(StockTakeEntity stockTake);

  /// إكمال عملية جرد
  Future<Result<void>> completeStockTake({
    required String id,
    required String completedBy,
  });

  /// إلغاء عملية جرد
  Future<Result<void>> cancelStockTake(String id);

  /// حذف عملية جرد
  Future<Result<void>> deleteStockTake(String id);

  /// توليد رقم جرد
  Future<String> generateStockTakeNumber();

  // ============ أرصدة المخزون ============

  /// جلب أرصدة المخزون
  Stream<List<StockBalanceEntity>> watchStockBalances();

  /// جلب أرصدة مستودع معين
  Stream<List<StockBalanceEntity>> watchStockBalancesByWarehouse(
      String warehouseId);

  /// جلب رصيد منتج معين
  Future<Result<List<StockBalanceEntity>>> getProductStockBalances(
      String productId);

  /// جلب رصيد منتج في مستودع معين
  Future<Result<StockBalanceEntity?>> getProductWarehouseBalance({
    required String productId,
    required String warehouseId,
  });

  /// تحديث رصيد المخزون
  Future<Result<void>> updateStockBalance({
    required String productId,
    required String warehouseId,
    required int quantityChange,
    String? reason,
  });

  /// حجز كمية من المخزون
  Future<Result<void>> reserveStock({
    required String productId,
    required String warehouseId,
    required int quantity,
    required String referenceId,
  });

  /// إلغاء حجز المخزون
  Future<Result<void>> releaseReservedStock({
    required String productId,
    required String warehouseId,
    required int quantity,
    required String referenceId,
  });

  // ============ الإحصائيات ============

  /// جلب إحصائيات المخزون
  Future<Result<InventoryStats>> getInventoryStats();

  /// جلب المنتجات منخفضة المخزون
  Future<Result<List<StockBalanceEntity>>> getLowStockProducts({
    int threshold = 10,
  });

  /// جلب المنتجات نفذت من المخزون
  Future<Result<List<StockBalanceEntity>>> getOutOfStockProducts();

  // ============ البحث ============

  /// البحث في الحركات
  Future<Result<List<StockMovementEntity>>> searchMovements(String query);

  /// البحث في المستودعات
  Future<Result<List<WarehouseEntity>>> searchWarehouses(String query);
}
