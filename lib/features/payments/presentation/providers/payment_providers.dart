import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/payment_repository.dart';

/// Provider للمستودع
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl();
});

/// Provider لقائمة السندات
final paymentsProvider = StreamProvider<List<PaymentVoucherEntity>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPayments();
});

/// Provider لسندات القبض
final receiptsProvider = StreamProvider<List<PaymentVoucherEntity>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchReceipts();
});

/// Provider لسندات الصرف
final paymentVouchersProvider =
    StreamProvider<List<PaymentVoucherEntity>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPaymentVouchers();
});

/// Provider لسندات العميل
final paymentsByCustomerProvider =
    StreamProvider.family<List<PaymentVoucherEntity>, String>(
        (ref, customerId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPaymentsByCustomer(customerId);
});

/// Provider لسندات المورد
final paymentsBySupplierProvider =
    StreamProvider.family<List<PaymentVoucherEntity>, String>(
        (ref, supplierId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchPaymentsBySupplier(supplierId);
});

/// Provider للبحث
final paymentSearchProvider =
    FutureProvider.family<List<PaymentVoucherEntity>, String>(
        (ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(paymentRepositoryProvider);
  final result = await repository.searchPayments(query);
  return result.valueOrNull ?? [];
});

/// Provider لسند محدد
final paymentProvider =
    FutureProvider.family<PaymentVoucherEntity?, String>((ref, id) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final result = await repository.getPaymentById(id);
  return result.valueOrNull;
});

/// Provider لإحصائيات السندات
final paymentStatsProvider = FutureProvider<PaymentStats>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final result = await repository.getPaymentStats();
  return result.valueOrNull ?? PaymentStats.empty();
});

/// Notifier لإدارة السندات
class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const AsyncValue.data(null));

  /// إنشاء سند
  Future<PaymentVoucherEntity?> createPayment(
      PaymentVoucherEntity payment) async {
    state = const AsyncValue.loading();
    final result = await _repository.createPayment(payment);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  /// تحديث سند
  Future<bool> updatePayment(PaymentVoucherEntity payment) async {
    state = const AsyncValue.loading();
    final result = await _repository.updatePayment(payment);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// حذف سند
  Future<bool> deletePayment(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deletePayment(id);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// تحديث الحالة
  Future<bool> updateStatus({
    required String id,
    required PaymentVoucherStatus status,
    String? approvedBy,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.updatePaymentStatus(
      id: id,
      status: status,
      approvedBy: approvedBy,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  /// توليد رقم سند
  Future<String> generateVoucherNumber(PaymentVoucherType type) async {
    return await _repository.generateVoucherNumber(type);
  }
}

/// Provider لـ Notifier
final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentNotifier(repository);
});
