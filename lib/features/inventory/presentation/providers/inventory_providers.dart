import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Provider للمستودع
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl();
});

// ============ المستودعات ============

/// Provider لقائمة المستودعات
final warehousesProvider = StreamProvider<List<WarehouseEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchWarehouses();
});

/// Provider للمستودعات النشطة
final activeWarehousesProvider = StreamProvider<List<WarehouseEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchActiveWarehouses();
});

/// Provider لمستودع محدد
final warehouseProvider =
    FutureProvider.family<WarehouseEntity?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getWarehouseById(id);
  return result.valueOrNull;
});

// ============ حركات المخزون ============

/// Provider لقائمة الحركات
final stockMovementsProvider = StreamProvider<List<StockMovementEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchMovements();
});

/// Provider لحركات مستودع
final warehouseMovementsProvider =
    StreamProvider.family<List<StockMovementEntity>, String>(
        (ref, warehouseId) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchMovementsByWarehouse(warehouseId);
});

/// Provider لحركات منتج
final productMovementsProvider =
    StreamProvider.family<List<StockMovementEntity>, String>((ref, productId) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchMovementsByProduct(productId);
});

/// Provider لحركة محددة
final stockMovementProvider =
    FutureProvider.family<StockMovementEntity?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getMovementById(id);
  return result.valueOrNull;
});

// ============ الجرد ============

/// Provider لقائمة الجرد
final stockTakesProvider = StreamProvider<List<StockTakeEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchStockTakes();
});

/// Provider لجرد مستودع
final warehouseStockTakesProvider =
    StreamProvider.family<List<StockTakeEntity>, String>((ref, warehouseId) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchStockTakesByWarehouse(warehouseId);
});

/// Provider لجرد محدد
final stockTakeProvider =
    FutureProvider.family<StockTakeEntity?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getStockTakeById(id);
  return result.valueOrNull;
});

// ============ أرصدة المخزون ============

/// Provider لأرصدة المخزون
final stockBalancesProvider = StreamProvider<List<StockBalanceEntity>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchStockBalances();
});

/// Provider لأرصدة مستودع
final warehouseStockBalancesProvider =
    StreamProvider.family<List<StockBalanceEntity>, String>((ref, warehouseId) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchStockBalancesByWarehouse(warehouseId);
});

/// Provider لأرصدة منتج
final productStockBalancesProvider =
    FutureProvider.family<List<StockBalanceEntity>, String>(
        (ref, productId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getProductStockBalances(productId);
  return result.valueOrNull ?? [];
});

// ============ الإحصائيات ============

/// Provider لإحصائيات المخزون
final inventoryStatsProvider = FutureProvider<InventoryStats>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getInventoryStats();
  return result.valueOrNull ?? InventoryStats.empty();
});

/// Provider للمنتجات منخفضة المخزون
final lowStockProductsProvider =
    FutureProvider<List<StockBalanceEntity>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getLowStockProducts();
  return result.valueOrNull ?? [];
});

/// Provider للمنتجات النافذة
final outOfStockProductsProvider =
    FutureProvider<List<StockBalanceEntity>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.getOutOfStockProducts();
  return result.valueOrNull ?? [];
});

// ============ البحث ============

/// Provider للبحث في الحركات
final searchMovementsProvider =
    FutureProvider.family<List<StockMovementEntity>, String>(
        (ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.searchMovements(query);
  return result.valueOrNull ?? [];
});

/// Provider للبحث في المستودعات
final searchWarehousesProvider =
    FutureProvider.family<List<WarehouseEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(inventoryRepositoryProvider);
  final result = await repository.searchWarehouses(query);
  return result.valueOrNull ?? [];
});

// ============ Notifiers ============

/// Notifier لإدارة المستودعات
class WarehouseNotifier extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;

  WarehouseNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<WarehouseEntity?> createWarehouse(WarehouseEntity warehouse) async {
    state = const AsyncValue.loading();
    final result = await _repository.createWarehouse(warehouse);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateWarehouse(WarehouseEntity warehouse) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateWarehouse(warehouse);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteWarehouse(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteWarehouse(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> setDefaultWarehouse(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.setDefaultWarehouse(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }
}

/// Provider لـ WarehouseNotifier
final warehouseNotifierProvider =
    StateNotifierProvider<WarehouseNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return WarehouseNotifier(repository);
});

/// Notifier لإدارة حركات المخزون
class StockMovementNotifier extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;

  StockMovementNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<StockMovementEntity?> createMovement(
      StockMovementEntity movement) async {
    state = const AsyncValue.loading();
    final result = await _repository.createMovement(movement);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateMovement(StockMovementEntity movement) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateMovement(movement);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> approveMovement({
    required String id,
    required String approvedBy,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.approveMovement(
      id: id,
      approvedBy: approvedBy,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> cancelMovement(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.cancelMovement(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteMovement(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteMovement(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<String> generateMovementNumber(StockMovementType type) async {
    return await _repository.generateMovementNumber(type);
  }
}

/// Provider لـ StockMovementNotifier
final stockMovementNotifierProvider =
    StateNotifierProvider<StockMovementNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return StockMovementNotifier(repository);
});

/// Notifier لإدارة الجرد
class StockTakeNotifier extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;

  StockTakeNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<StockTakeEntity?> createStockTake(StockTakeEntity stockTake) async {
    state = const AsyncValue.loading();
    final result = await _repository.createStockTake(stockTake);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateStockTake(StockTakeEntity stockTake) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateStockTake(stockTake);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> completeStockTake({
    required String id,
    required String completedBy,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.completeStockTake(
      id: id,
      completedBy: completedBy,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> cancelStockTake(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.cancelStockTake(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteStockTake(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteStockTake(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<String> generateStockTakeNumber() async {
    return await _repository.generateStockTakeNumber();
  }
}

/// Provider لـ StockTakeNotifier
final stockTakeNotifierProvider =
    StateNotifierProvider<StockTakeNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return StockTakeNotifier(repository);
});
