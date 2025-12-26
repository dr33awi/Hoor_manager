import '../../../../core/utils/result.dart';

import '../entities/entities.dart';

/// إحصائيات الحسابات
class AccountStats {
  final int totalAccounts;
  final int activeAccounts;
  final int totalJournalEntries;
  final int draftEntries;
  final int postedEntries;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalRevenue;
  final double totalExpenses;

  const AccountStats({
    this.totalAccounts = 0,
    this.activeAccounts = 0,
    this.totalJournalEntries = 0,
    this.draftEntries = 0,
    this.postedEntries = 0,
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.totalEquity = 0,
    this.totalRevenue = 0,
    this.totalExpenses = 0,
  });

  factory AccountStats.empty() => const AccountStats();

  /// صافي الربح/الخسارة
  double get netIncome => totalRevenue - totalExpenses;
}

/// واجهة مستودع الحسابات
abstract class AccountRepository {
  // ============ شجرة الحسابات ============

  /// جلب جميع الحسابات
  Stream<List<AccountEntity>> watchAccounts();

  /// جلب الحسابات حسب النوع
  Stream<List<AccountEntity>> watchAccountsByType(AccountType type);

  /// جلب الحسابات الفرعية
  Stream<List<AccountEntity>> watchChildAccounts(String parentId);

  /// جلب الحسابات القابلة للترحيل
  Stream<List<AccountEntity>> watchPostableAccounts();

  /// جلب حساب بالمعرف
  Future<Result<AccountEntity?>> getAccountById(String id);

  /// جلب حساب بالكود
  Future<Result<AccountEntity?>> getAccountByCode(String code);

  /// إنشاء حساب
  Future<Result<AccountEntity>> createAccount(AccountEntity account);

  /// تحديث حساب
  Future<Result<void>> updateAccount(AccountEntity account);

  /// حذف حساب
  Future<Result<void>> deleteAccount(String id);

  /// تحديث رصيد حساب
  Future<Result<void>> updateAccountBalance({
    required String accountId,
    required double amount,
    required bool isDebit,
  });

  // ============ القيود اليومية ============

  /// جلب جميع القيود
  Stream<List<JournalEntryEntity>> watchJournalEntries();

  /// جلب القيود حسب الحالة
  Stream<List<JournalEntryEntity>> watchJournalEntriesByStatus(
      JournalEntryStatus status);

  /// جلب القيود حسب الفترة
  Future<Result<List<JournalEntryEntity>>> getJournalEntriesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// جلب قيد بالمعرف
  Future<Result<JournalEntryEntity?>> getJournalEntryById(String id);

  /// إنشاء قيد
  Future<Result<JournalEntryEntity>> createJournalEntry(
      JournalEntryEntity entry);

  /// تحديث قيد
  Future<Result<void>> updateJournalEntry(JournalEntryEntity entry);

  /// حذف قيد
  Future<Result<void>> deleteJournalEntry(String id);

  /// ترحيل قيد
  Future<Result<void>> postJournalEntry({
    required String id,
    required String postedBy,
  });

  /// عكس قيد
  Future<Result<JournalEntryEntity>> reverseJournalEntry({
    required String id,
    required String reversedBy,
    String? reason,
  });

  /// توليد رقم قيد
  Future<String> generateEntryNumber();

  // ============ مراكز التكلفة ============

  /// جلب جميع مراكز التكلفة
  Stream<List<CostCenterEntity>> watchCostCenters();

  /// جلب مركز تكلفة بالمعرف
  Future<Result<CostCenterEntity?>> getCostCenterById(String id);

  /// إنشاء مركز تكلفة
  Future<Result<CostCenterEntity>> createCostCenter(CostCenterEntity center);

  /// تحديث مركز تكلفة
  Future<Result<void>> updateCostCenter(CostCenterEntity center);

  /// حذف مركز تكلفة
  Future<Result<void>> deleteCostCenter(String id);

  // ============ التقارير ============

  /// جلب إحصائيات الحسابات
  Future<Result<AccountStats>> getAccountStats();

  /// جلب ميزان المراجعة
  Future<Result<List<AccountBalanceEntity>>> getTrialBalance({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// جلب حركات حساب
  Future<Result<List<JournalEntryLineEntity>>> getAccountLedger({
    required String accountId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // ============ البحث ============

  /// البحث في الحسابات
  Future<Result<List<AccountEntity>>> searchAccounts(String query);

  /// البحث في القيود
  Future<Result<List<JournalEntryEntity>>> searchJournalEntries(String query);
}
