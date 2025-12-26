import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/customer_repository.dart';

/// Provider للمستودع
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});

/// Provider لقائمة العملاء
final customersProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomers();
});

/// Provider للعملاء الذين عليهم مستحقات
final customersWithDuesProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomersWithDues();
});

/// Provider للعملاء حسب النوع
final customersByTypeProvider =
    StreamProvider.family<List<CustomerEntity>, CustomerType>((ref, type) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomersByType(type);
});

/// Provider للبحث عن العملاء
final customerSearchProvider =
    FutureProvider.family<List<CustomerEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.searchCustomers(query);
  return result.valueOrNull ?? [];
});

/// Provider لعميل محدد
final customerProvider =
    FutureProvider.family<CustomerEntity?, String>((ref, id) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomerById(id);
  return result.valueOrNull;
});

/// Provider لآخر سعر للعميل
final lastPriceForCustomerProvider =
    FutureProvider.family<double?, ({String customerId, String productId})>(
        (ref, params) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getLastPriceForCustomer(
    customerId: params.customerId,
    productId: params.productId,
  );
  return result.valueOrNull;
});

/// Provider لإحصائيات العملاء
final customerStatsProvider = Provider<CustomerStats>((ref) {
  final customersAsync = ref.watch(customersProvider);
  return customersAsync.when(
    data: (customers) => CustomerStats.fromCustomers(customers),
    loading: () => CustomerStats.empty(),
    error: (_, __) => CustomerStats.empty(),
  );
});

/// إحصائيات العملاء
class CustomerStats {
  final int totalCustomers;
  final int activeCustomers;
  final int vipCustomers;
  final int wholesaleCustomers;
  final double totalDues;
  final int customersWithDues;

  const CustomerStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.vipCustomers,
    required this.wholesaleCustomers,
    required this.totalDues,
    required this.customersWithDues,
  });

  factory CustomerStats.empty() {
    return const CustomerStats(
      totalCustomers: 0,
      activeCustomers: 0,
      vipCustomers: 0,
      wholesaleCustomers: 0,
      totalDues: 0,
      customersWithDues: 0,
    );
  }

  factory CustomerStats.fromCustomers(List<CustomerEntity> customers) {
    return CustomerStats(
      totalCustomers: customers.length,
      activeCustomers: customers.where((c) => c.isActive).length,
      vipCustomers: customers.where((c) => c.isVip).length,
      wholesaleCustomers: customers.where((c) => c.isWholesale).length,
      totalDues: customers.fold(0, (sum, c) => sum + c.amountDue),
      customersWithDues: customers.where((c) => c.amountDue > 0).length,
    );
  }
}

/// Notifier لإدارة العملاء
class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.data(null));

  /// إضافة عميل
  Future<bool> addCustomer(CustomerEntity customer) async {
    state = const AsyncValue.loading();
    final result = await _repository.addCustomer(customer);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// تحديث عميل
  Future<bool> updateCustomer(CustomerEntity customer) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCustomer(customer);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// حذف عميل
  Future<bool> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteCustomer(id);
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
final customerNotifierProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerNotifier(repository);
});
