import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Provider للمستودع
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl();
});

/// Provider لقائمة فواتير الشراء
final purchasesProvider = StreamProvider<List<PurchaseInvoiceEntity>>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.watchPurchases();
});

/// Provider للفواتير غير المدفوعة
final unpaidPurchasesProvider =
    StreamProvider<List<PurchaseInvoiceEntity>>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.watchUnpaidPurchases();
});

/// Provider لفواتير مورد معين
final purchasesBySupplierProvider =
    StreamProvider.family<List<PurchaseInvoiceEntity>, String>(
        (ref, supplierId) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.watchPurchasesBySupplier(supplierId);
});

/// Provider لفواتير بحالة معينة
final purchasesByStatusProvider =
    StreamProvider.family<List<PurchaseInvoiceEntity>, PurchaseInvoiceStatus>(
        (ref, status) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.watchPurchasesByStatus(status);
});

/// Provider للبحث
final purchaseSearchProvider =
    FutureProvider.family<List<PurchaseInvoiceEntity>, String>(
        (ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.searchPurchases(query);
  return result.valueOrNull ?? [];
});

/// Provider لفاتورة محددة
final purchaseProvider =
    FutureProvider.family<PurchaseInvoiceEntity?, String>((ref, id) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.getPurchaseById(id);
  return result.valueOrNull;
});

/// Provider لإحصائيات المشتريات
final purchaseStatsProvider = FutureProvider<PurchaseStats>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  final result = await repository.getPurchaseStats();
  return result.valueOrNull ?? PurchaseStats.empty();
});

/// Notifier لإدارة المشتريات
class PurchaseNotifier extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repository;

  PurchaseNotifier(this._repository) : super(const AsyncValue.data(null));

  /// إنشاء فاتورة شراء
  Future<PurchaseInvoiceEntity?> createPurchase(
      PurchaseInvoiceEntity purchase) async {
    state = const AsyncValue.loading();
    final result = await _repository.createPurchase(purchase);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  /// تحديث فاتورة
  Future<bool> updatePurchase(PurchaseInvoiceEntity purchase) async {
    state = const AsyncValue.loading();
    final result = await _repository.updatePurchase(purchase);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// حذف فاتورة
  Future<bool> deletePurchase(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deletePurchase(id);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.isSuccess;
  }

  /// تحديث الحالة
  Future<bool> updateStatus(String id, PurchaseInvoiceStatus status) async {
    state = const AsyncValue.loading();
    final result =
        await _repository.updatePurchaseStatus(id: id, status: status);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  /// تسجيل دفعة
  Future<bool> recordPayment({
    required String purchaseId,
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.recordPayment(
      purchaseId: purchaseId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  /// استلام البضاعة
  Future<bool> receiveItems({
    required String purchaseId,
    required Map<String, int> receivedQuantities,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.receiveItems(
      purchaseId: purchaseId,
      receivedQuantities: receivedQuantities,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  /// توليد رقم فاتورة
  Future<String> generateInvoiceNumber() async {
    return await _repository.generateInvoiceNumber();
  }
}

/// Provider لـ Notifier
final purchaseNotifierProvider =
    StateNotifierProvider<PurchaseNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return PurchaseNotifier(repository);
});
