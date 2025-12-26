import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

/// تنفيذ مستودع الحسابات
class AccountRepositoryImpl implements AccountRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مراجع المجموعات
  CollectionReference<Map<String, dynamic>> get _accountsRef =>
      _firestore.collection('accounts');

  CollectionReference<Map<String, dynamic>> get _journalEntriesRef =>
      _firestore.collection('journal_entries');

  CollectionReference<Map<String, dynamic>> get _costCentersRef =>
      _firestore.collection('cost_centers');

  // ============ شجرة الحسابات ============

  @override
  Stream<List<AccountEntity>> watchAccounts() {
    return _accountsRef.orderBy('code').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Stream<List<AccountEntity>> watchAccountsByType(AccountType type) {
    return _accountsRef
        .where('type', isEqualTo: type.name)
        .orderBy('code')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<AccountEntity>> watchChildAccounts(String parentId) {
    return _accountsRef
        .where('parentId', isEqualTo: parentId)
        .orderBy('code')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<AccountEntity>> watchPostableAccounts() {
    return _accountsRef
        .where('canPost', isEqualTo: true)
        .where('status', isEqualTo: AccountStatus.active.name)
        .orderBy('code')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<AccountEntity?>> getAccountById(String id) async {
    try {
      final doc = await _accountsRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(AccountModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب الحساب: $e');
    }
  }

  @override
  Future<Result<AccountEntity?>> getAccountByCode(String code) async {
    try {
      final snapshot =
          await _accountsRef.where('code', isEqualTo: code).limit(1).get();
      if (snapshot.docs.isEmpty) return Success(null);
      return Success(AccountModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id));
    } catch (e) {
      return Failure('فشل في جلب الحساب: $e');
    }
  }

  @override
  Future<Result<AccountEntity>> createAccount(AccountEntity account) async {
    try {
      // التحقق من عدم تكرار الكود
      final existing = await getAccountByCode(account.code);
      if (existing.isSuccess && existing.valueOrNull != null) {
        return Failure('كود الحساب موجود مسبقاً');
      }

      final model = AccountModel.fromEntity(account);
      final docRef = await _accountsRef.add(model.toMap());

      // إذا كان له أب، تحديث الأب ليصبح isParent = true
      if (account.parentId != null) {
        await _accountsRef.doc(account.parentId).update({
          'isParent': true,
          'canPost': false,
        });
      }

      return Success(model.copyWith(id: docRef.id) as AccountEntity);
    } catch (e) {
      return Failure('فشل في إنشاء الحساب: $e');
    }
  }

  @override
  Future<Result<void>> updateAccount(AccountEntity account) async {
    try {
      final model = AccountModel.fromEntity(account);
      await _accountsRef.doc(account.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث الحساب: $e');
    }
  }

  @override
  Future<Result<void>> deleteAccount(String id) async {
    try {
      // التحقق من عدم وجود حسابات فرعية
      final children =
          await _accountsRef.where('parentId', isEqualTo: id).limit(1).get();
      if (children.docs.isNotEmpty) {
        return Failure('لا يمكن حذف حساب له حسابات فرعية');
      }

      // التحقق من عدم وجود قيود
      final entries = await _journalEntriesRef
          .where('lines', arrayContains: {'accountId': id})
          .limit(1)
          .get();
      if (entries.docs.isNotEmpty) {
        return Failure('لا يمكن حذف حساب له قيود');
      }

      await _accountsRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف الحساب: $e');
    }
  }

  @override
  Future<Result<void>> updateAccountBalance({
    required String accountId,
    required double amount,
    required bool isDebit,
  }) async {
    try {
      final accountResult = await getAccountById(accountId);
      if (!accountResult.isSuccess || accountResult.valueOrNull == null) {
        return Failure('الحساب غير موجود');
      }

      final account = accountResult.valueOrNull!;
      double newBalance;

      if (account.type.isDebitNature) {
        newBalance = isDebit
            ? account.currentBalance + amount
            : account.currentBalance - amount;
      } else {
        newBalance = isDebit
            ? account.currentBalance - amount
            : account.currentBalance + amount;
      }

      await _accountsRef.doc(accountId).update({
        'currentBalance': newBalance,
        'updatedAt': Timestamp.now(),
      });

      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث رصيد الحساب: $e');
    }
  }

  // ============ القيود اليومية ============

  @override
  Stream<List<JournalEntryEntity>> watchJournalEntries() {
    return _journalEntriesRef
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<JournalEntryEntity>> watchJournalEntriesByStatus(
      JournalEntryStatus status) {
    return _journalEntriesRef
        .where('status', isEqualTo: status.name)
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<List<JournalEntryEntity>>> getJournalEntriesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _journalEntriesRef
          .where('entryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('entryDate', descending: true)
          .get();
      return Success(snapshot.docs
          .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
          .toList());
    } catch (e) {
      return Failure('فشل في جلب القيود: $e');
    }
  }

  @override
  Future<Result<JournalEntryEntity?>> getJournalEntryById(String id) async {
    try {
      final doc = await _journalEntriesRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(JournalEntryModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب القيد: $e');
    }
  }

  @override
  Future<Result<JournalEntryEntity>> createJournalEntry(
      JournalEntryEntity entry) async {
    try {
      // التحقق من توازن القيد
      if (!entry.isBalanced) {
        return Failure('القيد غير متوازن');
      }

      final model = JournalEntryModel.fromEntity(entry);
      final docRef = await _journalEntriesRef.add(model.toMap());
      return Success(model.copyWith(id: docRef.id) as JournalEntryEntity);
    } catch (e) {
      return Failure('فشل في إنشاء القيد: $e');
    }
  }

  @override
  Future<Result<void>> updateJournalEntry(JournalEntryEntity entry) async {
    try {
      // التحقق من أن القيد مسودة
      final existingResult = await getJournalEntryById(entry.id);
      if (existingResult.isSuccess &&
          existingResult.valueOrNull?.status != JournalEntryStatus.draft) {
        return Failure('لا يمكن تعديل قيد مرحّل');
      }

      // التحقق من التوازن
      if (!entry.isBalanced) {
        return Failure('القيد غير متوازن');
      }

      final model = JournalEntryModel.fromEntity(entry);
      await _journalEntriesRef.doc(entry.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث القيد: $e');
    }
  }

  @override
  Future<Result<void>> deleteJournalEntry(String id) async {
    try {
      // التحقق من أن القيد مسودة
      final existingResult = await getJournalEntryById(id);
      if (existingResult.isSuccess &&
          existingResult.valueOrNull?.status != JournalEntryStatus.draft) {
        return Failure('لا يمكن حذف قيد مرحّل');
      }

      await _journalEntriesRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف القيد: $e');
    }
  }

  @override
  Future<Result<void>> postJournalEntry({
    required String id,
    required String postedBy,
  }) async {
    try {
      final entryResult = await getJournalEntryById(id);
      if (!entryResult.isSuccess || entryResult.valueOrNull == null) {
        return Failure('القيد غير موجود');
      }

      final entry = entryResult.valueOrNull!;

      if (entry.status != JournalEntryStatus.draft) {
        return Failure('القيد ليس مسودة');
      }

      if (!entry.isBalanced) {
        return Failure('القيد غير متوازن');
      }

      // تحديث حالة القيد
      await _journalEntriesRef.doc(id).update({
        'status': JournalEntryStatus.posted.name,
        'postedBy': postedBy,
        'postedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // تحديث أرصدة الحسابات
      for (final line in entry.lines) {
        if (line.debit > 0) {
          await updateAccountBalance(
            accountId: line.accountId,
            amount: line.debit,
            isDebit: true,
          );
        }
        if (line.credit > 0) {
          await updateAccountBalance(
            accountId: line.accountId,
            amount: line.credit,
            isDebit: false,
          );
        }
      }

      return Success(null);
    } catch (e) {
      return Failure('فشل في ترحيل القيد: $e');
    }
  }

  @override
  Future<Result<JournalEntryEntity>> reverseJournalEntry({
    required String id,
    required String reversedBy,
    String? reason,
  }) async {
    try {
      final entryResult = await getJournalEntryById(id);
      if (!entryResult.isSuccess || entryResult.valueOrNull == null) {
        return Failure('القيد غير موجود');
      }

      final entry = entryResult.valueOrNull!;

      if (entry.status != JournalEntryStatus.posted) {
        return Failure('يمكن عكس القيود المرحّلة فقط');
      }

      // إنشاء قيد عكسي
      final reversalNumber = await generateEntryNumber();
      final reversalLines = entry.lines.map((line) {
        return JournalEntryLineEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          debit: line.credit, // عكس المدين والدائن
          credit: line.debit,
          description: line.description,
          costCenterId: line.costCenterId,
          costCenterName: line.costCenterName,
        );
      }).toList();

      final reversalEntry = JournalEntryEntity(
        id: '',
        entryNumber: reversalNumber,
        entryDate: DateTime.now(),
        status: JournalEntryStatus.posted,
        description:
            'عكس قيد: ${entry.entryNumber}${reason != null ? ' - $reason' : ''}',
        referenceType: 'reversal',
        referenceId: entry.id,
        referenceNumber: entry.entryNumber,
        lines: reversalLines,
        totalDebit: entry.totalCredit,
        totalCredit: entry.totalDebit,
        notes: reason,
        createdBy: reversedBy,
        postedBy: reversedBy,
        postedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ القيد العكسي
      final model = JournalEntryModel.fromEntity(reversalEntry);
      final docRef = await _journalEntriesRef.add(model.toMap());

      // تحديث القيد الأصلي
      await _journalEntriesRef.doc(id).update({
        'status': JournalEntryStatus.reversed.name,
        'reversedBy': reversedBy,
        'reversedAt': Timestamp.now(),
        'reversalEntryId': docRef.id,
        'updatedAt': Timestamp.now(),
      });

      // عكس أرصدة الحسابات
      for (final line in entry.lines) {
        if (line.debit > 0) {
          await updateAccountBalance(
            accountId: line.accountId,
            amount: line.debit,
            isDebit: false, // عكس
          );
        }
        if (line.credit > 0) {
          await updateAccountBalance(
            accountId: line.accountId,
            amount: line.credit,
            isDebit: true, // عكس
          );
        }
      }

      return Success(model.copyWith(id: docRef.id) as JournalEntryEntity);
    } catch (e) {
      return Failure('فشل في عكس القيد: $e');
    }
  }

  @override
  Future<String> generateEntryNumber() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final todayStart = DateTime(now.year, now.month, now.day);
    final count = await _journalEntriesRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final sequence = ((count.count ?? 0) + 1).toString().padLeft(4, '0');
    return 'JV-$dateStr-$sequence';
  }

  // ============ مراكز التكلفة ============

  @override
  Stream<List<CostCenterEntity>> watchCostCenters() {
    return _costCentersRef.orderBy('code').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => CostCenterModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Result<CostCenterEntity?>> getCostCenterById(String id) async {
    try {
      final doc = await _costCentersRef.doc(id).get();
      if (!doc.exists) return Success(null);
      return Success(CostCenterModel.fromMap(doc.data()!, doc.id));
    } catch (e) {
      return Failure('فشل في جلب مركز التكلفة: $e');
    }
  }

  @override
  Future<Result<CostCenterEntity>> createCostCenter(
      CostCenterEntity center) async {
    try {
      final model = CostCenterModel.fromEntity(center);
      final docRef = await _costCentersRef.add(model.toMap());
      return Success(model.copyWith(id: docRef.id) as CostCenterEntity);
    } catch (e) {
      return Failure('فشل في إنشاء مركز التكلفة: $e');
    }
  }

  @override
  Future<Result<void>> updateCostCenter(CostCenterEntity center) async {
    try {
      final model = CostCenterModel.fromEntity(center);
      await _costCentersRef.doc(center.id).update(model.toMap());
      return Success(null);
    } catch (e) {
      return Failure('فشل في تحديث مركز التكلفة: $e');
    }
  }

  @override
  Future<Result<void>> deleteCostCenter(String id) async {
    try {
      await _costCentersRef.doc(id).delete();
      return Success(null);
    } catch (e) {
      return Failure('فشل في حذف مركز التكلفة: $e');
    }
  }

  // ============ التقارير ============

  @override
  Future<Result<AccountStats>> getAccountStats() async {
    try {
      final accountsSnapshot = await _accountsRef.get();
      final activeAccountsSnapshot = await _accountsRef
          .where('status', isEqualTo: AccountStatus.active.name)
          .get();
      final entriesSnapshot = await _journalEntriesRef.get();
      final draftEntriesSnapshot = await _journalEntriesRef
          .where('status', isEqualTo: JournalEntryStatus.draft.name)
          .get();
      final postedEntriesSnapshot = await _journalEntriesRef
          .where('status', isEqualTo: JournalEntryStatus.posted.name)
          .get();

      double totalAssets = 0;
      double totalLiabilities = 0;
      double totalEquity = 0;
      double totalRevenue = 0;
      double totalExpenses = 0;

      for (final doc in accountsSnapshot.docs) {
        final account = AccountModel.fromMap(doc.data(), doc.id);
        switch (account.type) {
          case AccountType.asset:
            totalAssets += account.currentBalance;
            break;
          case AccountType.liability:
            totalLiabilities += account.currentBalance;
            break;
          case AccountType.equity:
            totalEquity += account.currentBalance;
            break;
          case AccountType.revenue:
            totalRevenue += account.currentBalance;
            break;
          case AccountType.expense:
            totalExpenses += account.currentBalance;
            break;
        }
      }

      return Success(AccountStats(
        totalAccounts: accountsSnapshot.docs.length,
        activeAccounts: activeAccountsSnapshot.docs.length,
        totalJournalEntries: entriesSnapshot.docs.length,
        draftEntries: draftEntriesSnapshot.docs.length,
        postedEntries: postedEntriesSnapshot.docs.length,
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        totalEquity: totalEquity,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
      ));
    } catch (e) {
      return Failure('فشل في جلب الإحصائيات: $e');
    }
  }

  @override
  Future<Result<List<AccountBalanceEntity>>> getTrialBalance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final accounts =
          await _accountsRef.where('canPost', isEqualTo: true).get();
      final balances = <AccountBalanceEntity>[];

      for (final doc in accounts.docs) {
        final account = AccountModel.fromMap(doc.data(), doc.id);

        // حساب أرصدة الحساب
        double periodDebit = 0;
        double periodCredit = 0;

        var query = _journalEntriesRef.where('status',
            isEqualTo: JournalEntryStatus.posted.name);

        if (startDate != null) {
          query = query.where('entryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        if (endDate != null) {
          query = query.where('entryDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }

        final entries = await query.get();

        for (final entryDoc in entries.docs) {
          final entry = JournalEntryModel.fromMap(entryDoc.data(), entryDoc.id);
          for (final line in entry.lines) {
            if (line.accountId == account.id) {
              periodDebit += line.debit;
              periodCredit += line.credit;
            }
          }
        }

        final openingDebit =
            account.type.isDebitNature ? account.openingBalance.abs() : 0.0;
        final openingCredit =
            !account.type.isDebitNature ? account.openingBalance.abs() : 0.0;

        balances.add(AccountBalanceEntity(
          accountId: account.id,
          accountCode: account.code,
          accountName: account.name,
          accountType: account.type,
          openingDebit: openingDebit,
          openingCredit: openingCredit,
          periodDebit: periodDebit,
          periodCredit: periodCredit,
          closingDebit: openingDebit + periodDebit,
          closingCredit: openingCredit + periodCredit,
        ));
      }

      return Success(balances);
    } catch (e) {
      return Failure('فشل في جلب ميزان المراجعة: $e');
    }
  }

  @override
  Future<Result<List<JournalEntryLineEntity>>> getAccountLedger({
    required String accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _journalEntriesRef
          .where('status', isEqualTo: JournalEntryStatus.posted.name)
          .orderBy('entryDate');

      if (startDate != null) {
        query = query.where('entryDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('entryDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final entries = await query.get();
      final ledgerLines = <JournalEntryLineEntity>[];

      for (final doc in entries.docs) {
        final entry = JournalEntryModel.fromMap(doc.data(), doc.id);
        for (final line in entry.lines) {
          if (line.accountId == accountId) {
            ledgerLines.add(line);
          }
        }
      }

      return Success(ledgerLines);
    } catch (e) {
      return Failure('فشل في جلب كشف الحساب: $e');
    }
  }

  // ============ البحث ============

  @override
  Future<Result<List<AccountEntity>>> searchAccounts(String query) async {
    try {
      final snapshot = await _accountsRef.get();
      final results = snapshot.docs
          .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
          .where((account) =>
              account.code.toLowerCase().contains(query.toLowerCase()) ||
              account.name.toLowerCase().contains(query.toLowerCase()) ||
              (account.nameEn?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
      return Success(results);
    } catch (e) {
      return Failure('فشل في البحث: $e');
    }
  }

  @override
  Future<Result<List<JournalEntryEntity>>> searchJournalEntries(
      String query) async {
    try {
      final snapshot = await _journalEntriesRef.get();
      final results = snapshot.docs
          .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
          .where((entry) =>
              entry.entryNumber.toLowerCase().contains(query.toLowerCase()) ||
              entry.description.toLowerCase().contains(query.toLowerCase()) ||
              (entry.referenceNumber
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();
      return Success(results);
    } catch (e) {
      return Failure('فشل في البحث: $e');
    }
  }
}
