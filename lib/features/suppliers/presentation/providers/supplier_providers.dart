import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/supplier_repository.dart';

/// Provider للمستودع
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepositoryImpl();
});

/// Provider لقائمة الموردين
final suppliersProvider = StreamProvider<List<SupplierEntity>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.watchSuppliers();
});

/// Provider للموردين النشطين
final activeSuppliersProvider = StreamProvider<List<SupplierEntity>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.watchActiveSuppliers();
});

/// Provider للموردين الذين لهم مستحقات
final suppliersWithDuesProvider = StreamProvider<List<SupplierEntity>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return repository.watchSuppliersWithDues();
});

/// Provider للبحث عن الموردين
final supplierSearchProvider =
    FutureProvider.family<List<SupplierEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(supplierRepositoryProvider);
  final result = await repository.searchSuppliers(query);
  return result.valueOrNull ?? [];
});

/// Provider لمورد محدد
final supplierProvider =
    FutureProvider.family<SupplierEntity?, String>((ref, id) async {
  final repository = ref.watch(supplierRepositoryProvider);
  final result = await repository.getSupplierById(id);
  return result.valueOrNull;
});

/// Provider لإحصائيات الموردين
final supplierStatsProvider = Provider<SupplierStats>((ref) {
  final suppliersAsync = ref.watch(suppliersProvider);
  return suppliersAsync.when(
    data: (suppliers) => SupplierStats.fromSuppliers(suppliers),
    loading: () => SupplierStats.empty(),
    error: (_, __) => SupplierStats.empty(),
  );
});

/// إحصائيات الموردين
class SupplierStats {
  final int totalSuppliers;
  final int activeSuppliers;
  final double totalDues;
  final int suppliersWithDues;

  const SupplierStats({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.totalDues,
    required this.suppliersWithDues,
  });

  factory SupplierStats.empty() {
    return const SupplierStats(
      totalSuppliers: 0,
      activeSuppliers: 0,
      totalDues: 0,
      suppliersWithDues: 0,
    );
  }

  factory SupplierStats.fromSuppliers(List<SupplierEntity> suppliers) {
    return SupplierStats(
      totalSuppliers: suppliers.length,
      activeSuppliers: suppliers.where((s) => s.isActive).length,
      totalDues: suppliers.fold(0, (sum, s) => sum + s.amountDue),
      suppliersWithDues: suppliers.where((s) => s.amountDue > 0).length,
    );
  }
}

/// Notifier لإدارة الموردين
class SupplierNotifier extends StateNotifier<AsyncValue<void>> {
  final SupplierRepository _repository;

  SupplierNotifier(this._repository) : super(const AsyncValue.data(null));

  /// إضافة مورد
  Future<bool> addSupplier(SupplierEntity supplier) async {
    state = const AsyncValue.loading();
    final result = await _repository.addSupplier(supplier);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// تحديث مورد
  Future<bool> updateSupplier(SupplierEntity supplier) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateSupplier(supplier);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// حذف مورد
  Future<bool> deleteSupplier(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteSupplier(id);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// تصدير إلى Excel
  Future<String?> exportToExcel() async {
    state = const AsyncValue.loading();
    final result = await _repository.exportToExcel();
    state = const AsyncValue.data(null);
    return result.valueOrNull;
  }

  /// استيراد من Excel
  Future<int?> importFromExcel(String filePath) async {
    state = const AsyncValue.loading();
    final result = await _repository.importFromExcel(filePath);
    state = const AsyncValue.data(null);
    return result.valueOrNull;
  }
}

/// Provider لـ Notifier
final supplierNotifierProvider =
    StateNotifierProvider<SupplierNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return SupplierNotifier(repository);
});
