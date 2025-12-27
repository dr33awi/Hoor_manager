import 'package:drift/drift.dart';
import '../database.dart';
import '../../app/constants/app_constants.dart';

/// مستودع الأطراف (العملاء والموردين)
class PartyRepository {
  final AppDatabase _db;
  
  PartyRepository(this._db);
  
  /// الحصول على جميع الأطراف
  Future<List<Party>> getAllParties({String? type, bool activeOnly = true}) {
    final query = _db.select(_db.parties);
    if (type != null) {
      query.where((p) => p.type.equals(type));
    }
    if (activeOnly) {
      query.where((p) => p.isActive.equals(true));
    }
    query.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.get();
  }
  
  /// الحصول على العملاء
  Future<List<Party>> getCustomers() {
    return getAllParties(type: AppConstants.partyTypeCustomer);
  }
  
  /// الحصول على الموردين
  Future<List<Party>> getSuppliers() {
    return getAllParties(type: AppConstants.partyTypeSupplier);
  }
  
  /// الحصول على طرف بالمعرف
  Future<Party?> getPartyById(int id) {
    return (_db.select(_db.parties)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }
  
  /// البحث في الأطراف
  Future<List<Party>> searchParties(String query, {String? type}) {
    final q = _db.select(_db.parties)
      ..where((p) => p.name.like('%$query%') | p.phone.like('%$query%'));
    
    if (type != null) {
      q.where((p) => p.type.equals(type));
    }
    
    return q.get();
  }
  
  /// إضافة طرف جديد
  Future<int> insertParty(PartiesCompanion party) {
    return _db.into(_db.parties).insert(party);
  }
  
  /// تحديث طرف
  Future<bool> updateParty(Party party) {
    return _db.update(_db.parties).replace(party);
  }
  
  /// حذف طرف (soft delete)
  Future<int> deleteParty(int id) {
    return (_db.update(_db.parties)..where((p) => p.id.equals(id)))
        .write(const PartiesCompanion(isActive: Value(false)));
  }
  
  /// تحديث رصيد الطرف
  Future<void> updatePartyBalance(int partyId, double amount, {bool add = true}) async {
    final party = await getPartyById(partyId);
    if (party == null) return;
    
    final newBalance = add ? party.balance + amount : party.balance - amount;
    
    await (_db.update(_db.parties)..where((p) => p.id.equals(partyId)))
        .write(PartiesCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  /// الحصول على العملاء المدينين
  Future<List<Party>> getDebtors() {
    return (_db.select(_db.parties)
          ..where((p) =>
              p.type.equals(AppConstants.partyTypeCustomer) &
              p.balance.isBiggerThanValue(0) &
              p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.balance)]))
        .get();
  }
  
  /// الحصول على الموردين الدائنين
  Future<List<Party>> getCreditors() {
    return (_db.select(_db.parties)
          ..where((p) =>
              p.type.equals(AppConstants.partyTypeSupplier) &
              p.balance.isBiggerThanValue(0) &
              p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.balance)]))
        .get();
  }
  
  /// إجمالي الديون
  Future<double> getTotalDebts() async {
    final debtors = await getDebtors();
    return debtors.fold<double>(0, (sum, p) => sum + p.balance);
  }
  
  /// إجمالي المستحقات
  Future<double> getTotalPayables() async {
    final creditors = await getCreditors();
    return creditors.fold<double>(0, (sum, p) => sum + p.balance);
  }
  
  /// مراقبة الأطراف
  Stream<List<Party>> watchParties({String? type}) {
    final query = _db.select(_db.parties)..where((p) => p.isActive.equals(true));
    if (type != null) {
      query.where((p) => p.type.equals(type));
    }
    query.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch();
  }
}

/// مستودع السندات
class VoucherRepository {
  final AppDatabase _db;
  
  VoucherRepository(this._db);
  
  /// الحصول على جميع السندات
  Future<List<Voucher>> getAllVouchers({String? type}) {
    final query = _db.select(_db.vouchers);
    if (type != null) {
      query.where((v) => v.type.equals(type));
    }
    query.orderBy([(v) => OrderingTerm.desc(v.createdAt)]);
    return query.get();
  }
  
  /// الحصول على سند بالمعرف
  Future<Voucher?> getVoucherById(int id) {
    return (_db.select(_db.vouchers)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }
  
  /// الحصول على سندات طرف
  Future<List<Voucher>> getPartyVouchers(int partyId) {
    return (_db.select(_db.vouchers)
          ..where((v) => v.partyId.equals(partyId))
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .get();
  }
  
  /// الحصول على سندات اليوم
  Future<List<Voucher>> getTodayVouchers({String? type}) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final query = _db.select(_db.vouchers)
      ..where((v) =>
          v.createdAt.isBiggerOrEqualValue(startOfDay) &
          v.createdAt.isSmallerThanValue(endOfDay));
    
    if (type != null) {
      query.where((v) => v.type.equals(type));
    }
    
    return query.get();
  }
  
  /// إنشاء سند جديد
  Future<int> createVoucher({
    required String type,
    int? partyId,
    required double amount,
    String paymentMethod = 'CASH',
    int? cashAccountId,
    int? invoiceId,
    String? note,
  }) async {
    return _db.transaction(() async {
      // توليد رقم السند
      final voucherNumber = await generateVoucherNumber(type);
      
      // إضافة السند
      final voucherId = await _db.into(_db.vouchers).insert(
        VouchersCompanion.insert(
          number: voucherNumber,
          type: type,
          partyId: Value(partyId),
          amount: amount,
          paymentMethod: Value(paymentMethod),
          cashAccountId: Value(cashAccountId),
          invoiceId: Value(invoiceId),
          note: Value(note),
        ),
      );
      
      // تحديث رصيد الطرف
      if (partyId != null) {
        final party = await (_db.select(_db.parties)
              ..where((p) => p.id.equals(partyId)))
            .getSingle();
        
        double newBalance;
        if (type == AppConstants.voucherTypeReceipt) {
          // سند قبض: ينقص رصيد العميل (الدين)
          newBalance = party.balance - amount;
        } else {
          // سند صرف: ينقص رصيد المورد (المستحق)
          newBalance = party.balance - amount;
        }
        
        await (_db.update(_db.parties)..where((p) => p.id.equals(partyId)))
            .write(PartiesCompanion(balance: Value(newBalance)));
      }
      
      // تحديث رصيد الصندوق
      if (cashAccountId != null) {
        final cashAccount = await (_db.select(_db.cashAccounts)
              ..where((c) => c.id.equals(cashAccountId)))
            .getSingle();
        
        final balanceBefore = cashAccount.balance;
        double balanceAfter;
        String movementType;
        
        if (type == AppConstants.voucherTypeReceipt) {
          balanceAfter = balanceBefore + amount;
          movementType = 'IN';
        } else {
          balanceAfter = balanceBefore - amount;
          movementType = 'OUT';
        }
        
        // تحديث الرصيد
        await (_db.update(_db.cashAccounts)..where((c) => c.id.equals(cashAccountId)))
            .write(CashAccountsCompanion(balance: Value(balanceAfter)));
        
        // إضافة حركة الصندوق
        await _db.into(_db.cashMovements).insert(
          CashMovementsCompanion.insert(
            cashAccountId: cashAccountId,
            type: movementType,
            amount: amount,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            refType: const Value('VOUCHER'),
            refId: Value(voucherId),
          ),
        );
      }
      
      return voucherId;
    });
  }
  
  /// توليد رقم سند جديد
  Future<String> generateVoucherNumber(String type) async {
    final prefix = type == AppConstants.voucherTypeReceipt ? 'RCV' : 'PAY';
    
    final today = DateTime.now();
    final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    final count = await (_db.select(_db.vouchers)
          ..where((v) => v.number.like('$prefix-$dateStr-%')))
        .get();
    
    final sequence = (count.length + 1).toString().padLeft(4, '0');
    return '$prefix-$dateStr-$sequence';
  }
  
  /// إحصائيات السندات اليومية
  Future<Map<String, double>> getDailyVoucherStats() async {
    final receipts = await getTodayVouchers(type: AppConstants.voucherTypeReceipt);
    final payments = await getTodayVouchers(type: AppConstants.voucherTypePayment);
    
    return {
      'totalReceipts': receipts.fold<double>(0, (sum, v) => sum + v.amount),
      'totalPayments': payments.fold<double>(0, (sum, v) => sum + v.amount),
      'receiptsCount': receipts.length.toDouble(),
      'paymentsCount': payments.length.toDouble(),
    };
  }
  
  /// مراقبة السندات
  Stream<List<Voucher>> watchVouchers({String? type}) {
    final query = _db.select(_db.vouchers);
    if (type != null) {
      query.where((v) => v.type.equals(type));
    }
    query.orderBy([(v) => OrderingTerm.desc(v.createdAt)]);
    return query.watch();
  }
}

/// مستودع الصناديق والبنوك
class CashAccountRepository {
  final AppDatabase _db;
  
  CashAccountRepository(this._db);
  
  /// الحصول على جميع الصناديق
  Future<List<CashAccount>> getAllCashAccounts({bool activeOnly = true}) {
    final query = _db.select(_db.cashAccounts);
    if (activeOnly) {
      query.where((c) => c.isActive.equals(true));
    }
    return query.get();
  }
  
  /// الحصول على صندوق بالمعرف
  Future<CashAccount?> getCashAccountById(int id) {
    return (_db.select(_db.cashAccounts)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }
  
  /// الحصول على الصندوق الافتراضي
  Future<CashAccount?> getDefaultCashAccount() {
    return (_db.select(_db.cashAccounts)
          ..where((c) => c.isDefault.equals(true) & c.isActive.equals(true)))
        .getSingleOrNull();
  }
  
  /// إضافة صندوق جديد
  Future<int> insertCashAccount(CashAccountsCompanion account) {
    return _db.into(_db.cashAccounts).insert(account);
  }
  
  /// تحديث صندوق
  Future<bool> updateCashAccount(CashAccount account) {
    return _db.update(_db.cashAccounts).replace(account);
  }
  
  /// حذف صندوق
  Future<int> deleteCashAccount(int id) {
    return (_db.update(_db.cashAccounts)..where((c) => c.id.equals(id)))
        .write(const CashAccountsCompanion(isActive: Value(false)));
  }
  
  /// تعيين صندوق كافتراضي
  Future<void> setDefaultCashAccount(int id) async {
    await _db.transaction(() async {
      // إزالة الافتراضي من الكل
      await _db.update(_db.cashAccounts)
          .write(const CashAccountsCompanion(isDefault: Value(false)));
      
      // تعيين الجديد
      await (_db.update(_db.cashAccounts)..where((c) => c.id.equals(id)))
          .write(const CashAccountsCompanion(isDefault: Value(true)));
    });
  }
  
  /// الحصول على حركات صندوق
  Future<List<CashMovement>> getCashMovements(int cashAccountId) {
    return (_db.select(_db.cashMovements)
          ..where((m) => m.cashAccountId.equals(cashAccountId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }
  
  /// الحصول على حركات بفترة
  Future<List<CashMovement>> getCashMovementsByDateRange(
    int cashAccountId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (_db.select(_db.cashMovements)
          ..where((m) =>
              m.cashAccountId.equals(cashAccountId) &
              m.createdAt.isBiggerOrEqualValue(startDate) &
              m.createdAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }
  
  /// إجمالي أرصدة الصناديق
  Future<double> getTotalCashBalance() async {
    final accounts = await getAllCashAccounts();
    return accounts.fold<double>(0, (sum, a) => sum + a.balance);
  }
  
  /// مراقبة الصناديق
  Stream<List<CashAccount>> watchCashAccounts() {
    return (_db.select(_db.cashAccounts)..where((c) => c.isActive.equals(true)))
        .watch();
  }
}
