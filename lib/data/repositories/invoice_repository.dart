import 'package:drift/drift.dart';
import '../database.dart';
import '../../app/constants/app_constants.dart';

/// مستودع الفواتير
class InvoiceRepository {
  final AppDatabase _db;
  
  InvoiceRepository(this._db);
  
  /// الحصول على جميع الفواتير
  Future<List<Invoice>> getAllInvoices({String? type}) {
    final query = _db.select(_db.invoices);
    if (type != null) {
      query.where((i) => i.type.equals(type));
    }
    query.orderBy([(i) => OrderingTerm.desc(i.createdAt)]);
    return query.get();
  }
  
  /// الحصول على فاتورة بالمعرف
  Future<Invoice?> getInvoiceById(int id) {
    return (_db.select(_db.invoices)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }
  
  /// الحصول على فاتورة بالرقم
  Future<Invoice?> getInvoiceByNumber(String number) {
    return (_db.select(_db.invoices)..where((i) => i.number.equals(number)))
        .getSingleOrNull();
  }
  
  /// الحصول على فواتير عميل/مورد
  Future<List<Invoice>> getPartyInvoices(int partyId) {
    return (_db.select(_db.invoices)
          ..where((i) => i.partyId.equals(partyId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }
  
  /// الحصول على فواتير اليوم
  Future<List<Invoice>> getTodayInvoices({String? type}) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final query = _db.select(_db.invoices)
      ..where((i) =>
          i.createdAt.isBiggerOrEqualValue(startOfDay) &
          i.createdAt.isSmallerThanValue(endOfDay));
    
    if (type != null) {
      query.where((i) => i.type.equals(type));
    }
    
    return query.get();
  }
  
  /// الحصول على فواتير بفترة
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? type,
  }) {
    final query = _db.select(_db.invoices)
      ..where((i) =>
          i.invoiceDate.isBiggerOrEqualValue(startDate) &
          i.invoiceDate.isSmallerOrEqualValue(endDate));
    
    if (type != null) {
      query.where((i) => i.type.equals(type));
    }
    
    query.orderBy([(i) => OrderingTerm.desc(i.invoiceDate)]);
    return query.get();
  }
  
  /// إنشاء فاتورة جديدة مع البنود
  Future<int> createInvoice({
    required String type,
    int? partyId,
    required List<InvoiceItemData> items,
    double discountAmount = 0,
    double discountPercent = 0,
    double taxPercent = 0,
    double paidAmount = 0,
    String paymentMethod = 'CASH',
    int? cashAccountId,
    String? note,
  }) async {
    return _db.transaction(() async {
      // حساب الإجماليات
      double subtotal = 0;
      for (final item in items) {
        subtotal += item.lineTotal;
      }
      
      // حساب الخصم
      double totalDiscount = discountAmount;
      if (discountPercent > 0) {
        totalDiscount += subtotal * discountPercent / 100;
      }
      
      // حساب الضريبة
      final taxableAmount = subtotal - totalDiscount;
      final taxAmount = taxableAmount * taxPercent / 100;
      
      // الإجمالي
      final total = taxableAmount + taxAmount;
      final dueAmount = total - paidAmount;
      
      // توليد رقم الفاتورة
      final invoiceNumber = await generateInvoiceNumber(type);
      
      // إضافة الفاتورة
      final invoiceId = await _db.into(_db.invoices).insert(
        InvoicesCompanion.insert(
          number: invoiceNumber,
          type: type,
          partyId: Value(partyId),
          subtotal: Value(subtotal),
          discountAmount: Value(totalDiscount),
          discountPercent: Value(discountPercent),
          taxAmount: Value(taxAmount),
          taxPercent: Value(taxPercent),
          total: Value(total),
          paidAmount: Value(paidAmount),
          dueAmount: Value(dueAmount),
          paymentMethod: Value(paymentMethod),
          cashAccountId: Value(cashAccountId),
          note: Value(note),
        ),
      );
      
      // إضافة البنود
      for (final item in items) {
        await _db.into(_db.invoiceItems).insert(
          InvoiceItemsCompanion.insert(
            invoiceId: invoiceId,
            productId: item.productId,
            qty: item.qty,
            unitPrice: item.unitPrice,
            costPrice: Value(item.costPrice),
            discountAmount: Value(item.discountAmount),
            discountPercent: Value(item.discountPercent),
            taxAmount: Value(item.taxAmount),
            taxPercent: Value(item.taxPercent),
            lineTotal: item.lineTotal,
            note: Value(item.note),
          ),
        );
        
        // تحديث المخزون
        final movementType = _getMovementType(type);
        if (movementType != null) {
          await _addInventoryMovement(
            productId: item.productId,
            type: movementType,
            qty: item.qty,
            unitPrice: item.unitPrice,
            refType: 'INVOICE',
            refId: invoiceId,
          );
        }
      }
      
      // تحديث رصيد العميل/المورد إذا كان آجل
      if (partyId != null && dueAmount > 0) {
        await _updatePartyBalance(partyId, type, dueAmount);
      }
      
      // تحديث رصيد الصندوق
      if (paidAmount > 0 && cashAccountId != null) {
        await _updateCashBalance(cashAccountId, type, paidAmount, invoiceId);
      }
      
      return invoiceId;
    });
  }
  
  /// الحصول على بنود فاتورة
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) {
    return (_db.select(_db.invoiceItems)
          ..where((i) => i.invoiceId.equals(invoiceId)))
        .get();
  }
  
  /// توليد رقم فاتورة جديد
  Future<String> generateInvoiceNumber(String type) async {
    final prefix = switch (type) {
      AppConstants.invoiceTypeSale => 'SAL',
      AppConstants.invoiceTypePurchase => 'PUR',
      AppConstants.invoiceTypeReturnSale => 'RSL',
      AppConstants.invoiceTypeReturnPurchase => 'RPR',
      _ => 'INV',
    };
    
    final today = DateTime.now();
    final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    
    // الحصول على آخر رقم لهذا اليوم
    final count = await (_db.select(_db.invoices)
          ..where((i) => i.number.like('$prefix-$dateStr-%')))
        .get();
    
    final sequence = (count.length + 1).toString().padLeft(4, '0');
    return '$prefix-$dateStr-$sequence';
  }
  
  /// إلغاء فاتورة
  Future<void> cancelInvoice(int invoiceId) async {
    await _db.transaction(() async {
      // الحصول على الفاتورة
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) return;
      
      // الحصول على البنود
      final items = await getInvoiceItems(invoiceId);
      
      // عكس حركات المخزون
      for (final item in items) {
        final reverseType = _getReverseMovementType(invoice.type);
        if (reverseType != null) {
          await _addInventoryMovement(
            productId: item.productId,
            type: reverseType,
            qty: item.qty,
            unitPrice: item.unitPrice,
            refType: 'CANCEL_INVOICE',
            refId: invoiceId,
          );
        }
      }
      
      // عكس رصيد العميل/المورد
      if (invoice.partyId != null && invoice.dueAmount > 0) {
        await _updatePartyBalance(
          invoice.partyId!,
          invoice.type,
          -invoice.dueAmount,
        );
      }
      
      // تحديث حالة الفاتورة
      await (_db.update(_db.invoices)..where((i) => i.id.equals(invoiceId)))
          .write(const InvoicesCompanion(
            status: Value(AppConstants.invoiceStatusCancelled),
          ));
    });
  }
  
  /// حركات المخزون حسب نوع الفاتورة
  String? _getMovementType(String invoiceType) {
    return switch (invoiceType) {
      AppConstants.invoiceTypeSale => AppConstants.movementTypeSale,
      AppConstants.invoiceTypePurchase => AppConstants.movementTypePurchase,
      AppConstants.invoiceTypeReturnSale => AppConstants.movementTypeReturnSale,
      AppConstants.invoiceTypeReturnPurchase => AppConstants.movementTypeReturnPurchase,
      _ => null,
    };
  }
  
  /// عكس حركات المخزون
  String? _getReverseMovementType(String invoiceType) {
    return switch (invoiceType) {
      AppConstants.invoiceTypeSale => AppConstants.movementTypeReturnSale,
      AppConstants.invoiceTypePurchase => AppConstants.movementTypeReturnPurchase,
      AppConstants.invoiceTypeReturnSale => AppConstants.movementTypeSale,
      AppConstants.invoiceTypeReturnPurchase => AppConstants.movementTypePurchase,
      _ => null,
    };
  }
  
  /// إضافة حركة مخزون
  Future<void> _addInventoryMovement({
    required int productId,
    required String type,
    required double qty,
    required double unitPrice,
    String? refType,
    int? refId,
  }) async {
    final product = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();
    
    final qtyBefore = product.qty;
    final qtyAfter = switch (type) {
      AppConstants.movementTypeSale ||
      AppConstants.movementTypeReturnPurchase =>
        qtyBefore - qty,
      _ => qtyBefore + qty,
    };
    
    await _db.into(_db.inventoryMovements).insert(
      InventoryMovementsCompanion.insert(
        productId: productId,
        type: type,
        qty: qty,
        qtyBefore: qtyBefore,
        qtyAfter: qtyAfter,
        unitPrice: Value(unitPrice),
        refType: Value(refType),
        refId: Value(refId),
      ),
    );
    
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(qty: Value(qtyAfter)));
  }
  
  /// تحديث رصيد العميل/المورد
  Future<void> _updatePartyBalance(int partyId, String invoiceType, double amount) async {
    final party = await (_db.select(_db.parties)..where((p) => p.id.equals(partyId)))
        .getSingle();
    
    double newBalance;
    if (invoiceType == AppConstants.invoiceTypeSale ||
        invoiceType == AppConstants.invoiceTypeReturnPurchase) {
      newBalance = party.balance + amount; // يزيد الدين
    } else {
      newBalance = party.balance - amount; // ينقص الدين
    }
    
    await (_db.update(_db.parties)..where((p) => p.id.equals(partyId)))
        .write(PartiesCompanion(balance: Value(newBalance)));
  }
  
  /// تحديث رصيد الصندوق
  Future<void> _updateCashBalance(int cashAccountId, String invoiceType, double amount, int invoiceId) async {
    final cashAccount = await (_db.select(_db.cashAccounts)
          ..where((c) => c.id.equals(cashAccountId)))
        .getSingle();
    
    final isIncome = invoiceType == AppConstants.invoiceTypeSale ||
        invoiceType == AppConstants.invoiceTypeReturnPurchase;
    
    final balanceBefore = cashAccount.balance;
    final balanceAfter = isIncome ? balanceBefore + amount : balanceBefore - amount;
    
    // تحديث الرصيد
    await (_db.update(_db.cashAccounts)..where((c) => c.id.equals(cashAccountId)))
        .write(CashAccountsCompanion(balance: Value(balanceAfter)));
    
    // إضافة حركة الصندوق
    await _db.into(_db.cashMovements).insert(
      CashMovementsCompanion.insert(
        cashAccountId: cashAccountId,
        type: isIncome ? 'IN' : 'OUT',
        amount: amount,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        refType: const Value('INVOICE'),
        refId: Value(invoiceId),
      ),
    );
  }
  
  /// إحصائيات المبيعات اليومية
  Future<Map<String, double>> getDailySalesStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final sales = await (_db.select(_db.invoices)
          ..where((i) =>
              i.type.equals(AppConstants.invoiceTypeSale) &
              i.createdAt.isBiggerOrEqualValue(startOfDay) &
              i.status.equals(AppConstants.invoiceStatusCompleted)))
        .get();
    
    double totalSales = 0;
    double totalCash = 0;
    double totalCredit = 0;
    int invoiceCount = sales.length;
    
    for (final invoice in sales) {
      totalSales += invoice.total;
      totalCash += invoice.paidAmount;
      totalCredit += invoice.dueAmount;
    }
    
    return {
      'totalSales': totalSales,
      'totalCash': totalCash,
      'totalCredit': totalCredit,
      'invoiceCount': invoiceCount.toDouble(),
    };
  }
  
  /// مراقبة الفواتير
  Stream<List<Invoice>> watchInvoices({String? type}) {
    final query = _db.select(_db.invoices);
    if (type != null) {
      query.where((i) => i.type.equals(type));
    }
    query.orderBy([(i) => OrderingTerm.desc(i.createdAt)]);
    return query.watch();
  }
}

/// بيانات بند الفاتورة
class InvoiceItemData {
  final int productId;
  final double qty;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final double discountPercent;
  final double taxAmount;
  final double taxPercent;
  final double lineTotal;
  final String? note;
  
  InvoiceItemData({
    required this.productId,
    required this.qty,
    required this.unitPrice,
    this.costPrice = 0,
    this.discountAmount = 0,
    this.discountPercent = 0,
    this.taxAmount = 0,
    this.taxPercent = 0,
    required this.lineTotal,
    this.note,
  });
}
