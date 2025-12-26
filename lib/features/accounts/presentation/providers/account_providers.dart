import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/account_repository.dart';

/// Provider للمستودع
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl();
});

// ============ شجرة الحسابات ============

/// Provider لقائمة الحسابات
final accountsProvider = StreamProvider<List<AccountEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts();
});

/// Provider للحسابات حسب النوع
final accountsByTypeProvider =
    StreamProvider.family<List<AccountEntity>, AccountType>((ref, type) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccountsByType(type);
});

/// Provider للحسابات الفرعية
final childAccountsProvider =
    StreamProvider.family<List<AccountEntity>, String>((ref, parentId) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchChildAccounts(parentId);
});

/// Provider للحسابات القابلة للترحيل
final postableAccountsProvider = StreamProvider<List<AccountEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchPostableAccounts();
});

/// Provider لحساب محدد
final accountProvider =
    FutureProvider.family<AccountEntity?, String>((ref, id) async {
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.getAccountById(id);
  return result.valueOrNull;
});

// ============ القيود اليومية ============

/// Provider لقائمة القيود
final journalEntriesProvider = StreamProvider<List<JournalEntryEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchJournalEntries();
});

/// Provider للقيود حسب الحالة
final journalEntriesByStatusProvider =
    StreamProvider.family<List<JournalEntryEntity>, JournalEntryStatus>(
        (ref, status) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchJournalEntriesByStatus(status);
});

/// Provider للقيود المسودة
final draftEntriesProvider = StreamProvider<List<JournalEntryEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchJournalEntriesByStatus(JournalEntryStatus.draft);
});

/// Provider للقيود المرحلة
final postedEntriesProvider = StreamProvider<List<JournalEntryEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchJournalEntriesByStatus(JournalEntryStatus.posted);
});

/// Provider لقيد محدد
final journalEntryProvider =
    FutureProvider.family<JournalEntryEntity?, String>((ref, id) async {
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.getJournalEntryById(id);
  return result.valueOrNull;
});

// ============ مراكز التكلفة ============

/// Provider لمراكز التكلفة
final costCentersProvider = StreamProvider<List<CostCenterEntity>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchCostCenters();
});

/// Provider لمركز تكلفة محدد
final costCenterProvider =
    FutureProvider.family<CostCenterEntity?, String>((ref, id) async {
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.getCostCenterById(id);
  return result.valueOrNull;
});

// ============ التقارير ============

/// Provider لإحصائيات الحسابات
final accountStatsProvider = FutureProvider<AccountStats>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.getAccountStats();
  return result.valueOrNull ?? AccountStats.empty();
});

/// Provider لميزان المراجعة
final trialBalanceProvider =
    FutureProvider<List<AccountBalanceEntity>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.getTrialBalance();
  return result.valueOrNull ?? [];
});

// ============ البحث ============

/// Provider للبحث في الحسابات
final searchAccountsProvider =
    FutureProvider.family<List<AccountEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.searchAccounts(query);
  return result.valueOrNull ?? [];
});

/// Provider للبحث في القيود
final searchJournalEntriesProvider =
    FutureProvider.family<List<JournalEntryEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(accountRepositoryProvider);
  final result = await repository.searchJournalEntries(query);
  return result.valueOrNull ?? [];
});

// ============ Notifiers ============

/// Notifier لإدارة الحسابات
class AccountNotifier extends StateNotifier<AsyncValue<void>> {
  final AccountRepository _repository;

  AccountNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<AccountEntity?> createAccount(AccountEntity account) async {
    state = const AsyncValue.loading();
    final result = await _repository.createAccount(account);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateAccount(AccountEntity account) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateAccount(account);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteAccount(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteAccount(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }
}

/// Provider لـ AccountNotifier
final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountNotifier(repository);
});

/// Notifier لإدارة القيود
class JournalEntryNotifier extends StateNotifier<AsyncValue<void>> {
  final AccountRepository _repository;

  JournalEntryNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<JournalEntryEntity?> createEntry(JournalEntryEntity entry) async {
    state = const AsyncValue.loading();
    final result = await _repository.createJournalEntry(entry);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateEntry(JournalEntryEntity entry) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateJournalEntry(entry);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteJournalEntry(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> postEntry({
    required String id,
    required String postedBy,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.postJournalEntry(
      id: id,
      postedBy: postedBy,
    );
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<JournalEntryEntity?> reverseEntry({
    required String id,
    required String reversedBy,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.reverseJournalEntry(
      id: id,
      reversedBy: reversedBy,
      reason: reason,
    );
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<String> generateEntryNumber() async {
    return await _repository.generateEntryNumber();
  }
}

/// Provider لـ JournalEntryNotifier
final journalEntryNotifierProvider =
    StateNotifierProvider<JournalEntryNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return JournalEntryNotifier(repository);
});

/// Notifier لإدارة مراكز التكلفة
class CostCenterNotifier extends StateNotifier<AsyncValue<void>> {
  final AccountRepository _repository;

  CostCenterNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<CostCenterEntity?> createCostCenter(CostCenterEntity center) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCostCenter(center);
    state = result.when(
      success: (_) => const AsyncValue.data(null),
      failure: (message) => AsyncValue.error(message, StackTrace.current),
    );
    return result.valueOrNull;
  }

  Future<bool> updateCostCenter(CostCenterEntity center) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCostCenter(center);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }

  Future<bool> deleteCostCenter(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteCostCenter(id);
    state = const AsyncValue.data(null);
    return result.isSuccess;
  }
}

/// Provider لـ CostCenterNotifier
final costCenterNotifierProvider =
    StateNotifierProvider<CostCenterNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return CostCenterNotifier(repository);
});
