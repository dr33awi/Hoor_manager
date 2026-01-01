import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/accounting_exceptions.dart';
import '../../core/services/currency_service.dart';
import '../../core/di/injection.dart';
import 'base_repository.dart';
import 'cash_repository.dart';
import 'customer_repository.dart';
import 'supplier_repository.dart';
import 'inventory_repository.dart';

class InvoiceRepository extends BaseRepository<Invoice, InvoicesCompanion> {
  StreamSubscription? _invoiceFirestoreSubscription;

  // Repositories للتكامل

  // Repositories للتكامل
  CashRepository? _cashRepo;
  CustomerRepository? _customerRepo;
  SupplierRepository? _supplierRepo;
  InventoryRepository? _inventoryRepo;

  InvoiceRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.invoicesCollection);

  /// تعيين الـ Repositories للتكامل (يُستدعى من injection)
  void setIntegrationRepositories({
    CashRepository? cashRepo,
    CustomerRepository? customerRepo,
    SupplierRepository? supplierRepo,
    InventoryRepository? inventoryRepo,
  }) {
    _cashRepo = cashRepo;
    _customerRepo = customerRepo;
    _supplierRepo = supplierRepo;
    _inventoryRepo = inventoryRepo;
  }

  // Lazy getters للـ Repositories
  CashRepository get cashRepo => _cashRepo ?? getIt<CashRepository>();
  CustomerRepository get customerRepo =>
      _customerRepo ?? getIt<CustomerRepository>();
  SupplierRepository get supplierRepo =>
      _supplierRepo ?? getIt<SupplierRepository>();
  InventoryRepository get inventoryRepo =>
      _inventoryRepo ?? getIt<InventoryRepository>();

  // ==================== Local Operations ====================

  Future<List<Invoice>> getAllInvoices() => database.getAllInvoices();

  Stream<List<Invoice>> watchAllInvoices() => database.watchAllInvoices();

  Future<List<Invoice>> getInvoicesByType(String type) =>
      database.getInvoicesByType(type);

  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) =>
      database.getInvoicesByDateRange(start, end);

  Future<List<Invoice>> getInvoicesByShift(String shiftId) =>
      database.getInvoicesByShift(shiftId);

  Future<Invoice?> getInvoiceById(String id) => database.getInvoiceById(id);

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) =>
      database.getInvoiceItems(invoiceId);

  /// Create a complete invoice with items
  /// يُلقي [InsufficientStockException] إذا كانت الكمية غير كافية
  Future<String> createInvoice({
    required String type,
    String? customerId,
    String? supplierId,
    String? warehouseId, // معرف المستودع (جديد)
    required List<Map<String, dynamic>> items,
    double discountAmount = 0,
    required String paymentMethod,
    double paidAmount = 0,
    String? notes,
    String? shiftId,
    DateTime? invoiceDate,
    bool validateStock = true, // للتحقق من المخزون
  }) async {
    // ═══════════════════════════════════════════════════════════════════════════
    // التحقق من كفاية المخزون قبل البيع
    // ═══════════════════════════════════════════════════════════════════════════
    if (validateStock && (type == 'sale' || type == 'purchase_return')) {
      await _validateStockAvailability(items, warehouseId);
    }

    final id = generateId();
    final now = DateTime.now();
    final invoiceNumber = await _generateInvoiceNumber(type);

    // Calculate totals
    double subtotal = 0;

    final invoiceItems = <InvoiceItemsCompanion>[];

    for (final item in items) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      final purchasePrice = item['purchasePrice'] as double? ?? 0;
      final itemDiscount = item['discount'] as double? ?? 0;

      final itemSubtotal = quantity * unitPrice;
      final itemTotal = itemSubtotal - itemDiscount;

      subtotal += itemSubtotal;

      invoiceItems.add(InvoiceItemsCompanion(
        id: Value(generateId()),
        invoiceId: Value(id),
        productId: Value(item['productId'] as String),
        productName: Value(item['productName'] as String),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        purchasePrice: Value(purchasePrice),
        discountAmount: Value(itemDiscount),
        taxAmount: const Value(0),
        total: Value(itemTotal),
        syncStatus: const Value('pending'),
        createdAt: Value(now),
      ));
    }

    final total = subtotal - discountAmount;

    // Insert invoice
    final currencyService = getIt<CurrencyService>();
    await database.insertInvoice(InvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      type: Value(type),
      customerId: Value(customerId),
      supplierId: Value(supplierId),
      warehouseId: Value(warehouseId), // حفظ معرف المستودع
      subtotal: Value(subtotal),
      taxAmount: const Value(0),
      discountAmount: Value(discountAmount),
      total: Value(total),
      paidAmount: Value(paidAmount),
      exchangeRate: Value(currencyService.exchangeRate), // حفظ سعر الصرف الحالي
      paymentMethod: Value(paymentMethod),
      status: const Value('completed'),
      notes: Value(notes),
      shiftId: Value(shiftId),
      syncStatus: const Value('pending'),
      invoiceDate: Value(invoiceDate ?? now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // Insert invoice items
    await database.insertInvoiceItems(invoiceItems);

    // Update inventory based on invoice type (مع دعم المستودعات)
    await _updateInventory(type, items,
        warehouseId: warehouseId, invoiceId: id, invoiceNumber: invoiceNumber);

    // ═══════════════════════════════════════════════════════════════════════════
    // تسجيل حركة الصندوق تلقائياً (إذا كان هناك وردية مفتوحة)
    // ═══════════════════════════════════════════════════════════════════════════
    if (shiftId != null) {
      await _recordCashMovement(
        type: type,
        amount: total,
        invoiceId: id,
        invoiceNumber: invoiceNumber,
        shiftId: shiftId,
        paymentMethod: paymentMethod,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // تحديث رصيد العميل/المورد للفواتير الآجلة
    // ═══════════════════════════════════════════════════════════════════════════
    await _updateCustomerSupplierBalance(
      type: type,
      customerId: customerId,
      supplierId: supplierId,
      total: total,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );

    return id;
  }

  /// تسجيل حركة الصندوق للفاتورة
  Future<void> _recordCashMovement({
    required String type,
    required double amount,
    required String invoiceId,
    required String invoiceNumber,
    required String shiftId,
    required String paymentMethod,
  }) async {
    // لا نسجل حركة للفواتير الآجلة
    if (paymentMethod == 'credit') return;

    try {
      switch (type) {
        case 'sale':
          await cashRepo.recordSale(
            shiftId: shiftId,
            amount: amount,
            invoiceId: invoiceId,
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase':
          await cashRepo.recordPurchase(
            shiftId: shiftId,
            amount: amount,
            invoiceId: invoiceId,
            paymentMethod: paymentMethod,
          );
          break;
        case 'sale_return':
          // مرتجع البيع = خصم من الصندوق (استخدام الدالة المخصصة)
          await cashRepo.recordSaleReturn(
            shiftId: shiftId,
            amount: amount,
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase_return':
          // مرتجع الشراء = إضافة للصندوق (استخدام الدالة المخصصة)
          await cashRepo.recordPurchaseReturn(
            shiftId: shiftId,
            amount: amount,
            invoiceId: invoiceId,
            invoiceNumber: invoiceNumber,
            paymentMethod: paymentMethod,
          );
          break;
      }
    } catch (e) {
      debugPrint('Error recording cash movement for invoice: $e');
    }
  }

  /// تحديث رصيد العميل/المورد
  /// [isAdjustment] إذا كان تعديل على فاتورة موجودة
  /// [isIncrease] إذا كان التعديل زيادة أو نقصان
  Future<void> _updateCustomerSupplierBalance({
    required String type,
    String? customerId,
    String? supplierId,
    required double total,
    required double paidAmount,
    required String paymentMethod,
    bool isAdjustment = false,
    bool isIncrease = true,
  }) async {
    try {
      // حساب المبلغ المتبقي (الدين)
      final remainingAmount = total - paidAmount;

      // في حالة التعديل، نستخدم المبلغ مباشرة
      double amountToUpdate;
      if (isAdjustment) {
        amountToUpdate = isIncrease ? total : -total;
      } else {
        amountToUpdate = remainingAmount > 0 ? remainingAmount : total;
      }

      switch (type) {
        case 'sale':
          // فاتورة بيع آجلة = زيادة رصيد العميل (دين على العميل)
          if (customerId != null &&
              (paymentMethod == 'credit' ||
                  remainingAmount > 0 ||
                  isAdjustment)) {
            await customerRepo.updateBalance(customerId, amountToUpdate);
          }
          break;
        case 'purchase':
          // فاتورة شراء آجلة = زيادة رصيد المورد (دين للمورد)
          if (supplierId != null &&
              (paymentMethod == 'credit' ||
                  remainingAmount > 0 ||
                  isAdjustment)) {
            await supplierRepo.updateBalance(supplierId, amountToUpdate);
          }
          break;
        case 'sale_return':
          // مرتجع بيع = خصم من رصيد العميل
          if (customerId != null) {
            await customerRepo.updateBalance(customerId, -total);
          }
          break;
        case 'purchase_return':
          // مرتجع شراء = خصم من رصيد المورد
          if (supplierId != null) {
            await supplierRepo.updateBalance(supplierId, -total);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error updating customer/supplier balance: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// التحقق من كفاية المخزون قبل البيع
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<void> _validateStockAvailability(
    List<Map<String, dynamic>> items,
    String? warehouseId,
  ) async {
    for (final item in items) {
      final productId = item['productId'] as String;
      final requestedQty = item['quantity'] as int;
      final productName = item['productName'] as String? ?? 'منتج';

      int availableQty;

      if (warehouseId != null) {
        // التحقق من مخزون المستودع
        final stock = await database.getWarehouseStockByProductAndWarehouse(
          productId,
          warehouseId,
        );
        availableQty = stock?.quantity ?? 0;
      } else {
        // التحقق من المخزون الإجمالي
        final product = await database.getProductById(productId);
        availableQty = product?.quantity ?? 0;
      }

      if (availableQty < requestedQty) {
        throw InsufficientStockException(
          productId: productId,
          productName: productName,
          requested: requestedQty,
          available: availableQty,
        );
      }
    }
  }

  Future<String> _generateInvoiceNumber(String type) async {
    // جلب البادئة المخصصة من الإعدادات
    final customPrefix = await database.getSetting('invoice_prefix');

    final prefix = switch (type) {
      'sale' => customPrefix ?? 'INV',
      'purchase' => 'PUR',
      'sale_return' => 'SRT',
      'purchase_return' => 'PRT',
      _ => 'DOC',
    };

    final today = DateTime.now();
    final dateStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // Get count for today
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final invoices = await database.getInvoicesByDateRange(start, end);
    final count = invoices.where((i) => i.type == type).length + 1;

    return '$prefix-$dateStr-${count.toString().padLeft(4, '0')}';
  }

  Future<void> _updateInventory(String type, List<Map<String, dynamic>> items,
      {String? warehouseId, String? invoiceId, String? invoiceNumber}) async {
    for (final item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;

      await inventoryRepo.updateStockForTransaction(
        productId: productId,
        quantity: quantity,
        transactionType: type,
        warehouseId: warehouseId,
        referenceId: invoiceId,
        referenceNumber: invoiceNumber,
      );
    }
  }

  /// عكس تأثير الفاتورة على المخزون (قبل التعديل أو الحذف)
  Future<void> _reverseInventory(String type, List<InvoiceItem> items) async {
    String reverseType;
    switch (type) {
      case 'sale':
        reverseType = 'sale_return';
        break;
      case 'purchase':
        reverseType = 'purchase_return';
        break;
      case 'sale_return':
        reverseType = 'sale';
        break;
      case 'purchase_return':
        reverseType = 'purchase';
        break;
      default:
        return;
    }

    for (final item in items) {
      // نحتاج معرف المستودع إذا كان موجوداً في الفاتورة الأصلية
      // هنا نفترض أننا لا نملك معرف المستودع بسهولة من InvoiceItem
      // لكن يمكننا جلبه إذا لزم الأمر، أو الاعتماد على أن updateStockForTransaction
      // سيعمل بدونه (فقط تحديث الكمية الكلية) إذا لم نمرره.
      // ولكن، إذا كانت الفاتورة مرتبطة بمستودع، يجب عكس المخزون في المستودع أيضاً.

      // الحل: جلب الفاتورة لمعرفة المستودع
      String? warehouseId;
      try {
        final invoice = await database.getInvoiceById(item.invoiceId);
        warehouseId = invoice?.warehouseId;
      } catch (_) {}

      await inventoryRepo.updateStockForTransaction(
        productId: item.productId,
        quantity: item.quantity,
        transactionType: reverseType,
        warehouseId: warehouseId,
        referenceId: item.invoiceId,
        referenceNumber: 'Reversal',
      );
    }
  }

  /// تعديل فاتورة موجودة
  Future<void> updateInvoice({
    required String invoiceId,
    String? customerId,
    String? supplierId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0,
    required String paymentMethod,
    double paidAmount = 0,
    String? notes,
  }) async {
    final now = DateTime.now();

    // جلب الفاتورة القديمة
    final oldInvoice = await database.getInvoiceById(invoiceId);
    if (oldInvoice == null) {
      throw Exception('الفاتورة غير موجودة');
    }

    // جلب العناصر القديمة
    final oldItems = await database.getInvoiceItems(invoiceId);

    // عكس تأثير المخزون للعناصر القديمة
    await _reverseInventory(oldInvoice.type, oldItems);

    // حذف العناصر القديمة
    await database.deleteInvoiceItems(invoiceId);

    // حساب المجاميع الجديدة
    double subtotal = 0;
    final invoiceItems = <InvoiceItemsCompanion>[];

    for (final item in items) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      final purchasePrice = item['purchasePrice'] as double? ?? 0;
      final itemDiscount = item['discount'] as double? ?? 0;

      final itemSubtotal = quantity * unitPrice;
      final itemTotal = itemSubtotal - itemDiscount;

      subtotal += itemSubtotal;

      invoiceItems.add(InvoiceItemsCompanion(
        id: Value(generateId()),
        invoiceId: Value(invoiceId),
        productId: Value(item['productId'] as String),
        productName: Value(item['productName'] as String),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        purchasePrice: Value(purchasePrice),
        discountAmount: Value(itemDiscount),
        taxAmount: const Value(0),
        total: Value(itemTotal),
        syncStatus: const Value('pending'),
        createdAt: Value(now),
      ));
    }

    final total = subtotal - discountAmount;

    // تحديث الفاتورة
    final currencyService = getIt<CurrencyService>();
    await database.updateInvoice(InvoicesCompanion(
      id: Value(invoiceId),
      customerId: Value(customerId),
      supplierId: Value(supplierId),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      total: Value(total),
      paidAmount: Value(paidAmount),
      exchangeRate: Value(currencyService.exchangeRate),
      paymentMethod: Value(paymentMethod),
      notes: Value(notes),
      syncStatus: const Value('pending'),
      updatedAt: Value(now),
    ));

    // إدخال العناصر الجديدة
    await database.insertInvoiceItems(invoiceItems);

    // تحديث المخزون بالعناصر الجديدة
    await _updateInventory(oldInvoice.type, items,
        warehouseId: oldInvoice.warehouseId,
        invoiceId: invoiceId,
        invoiceNumber: oldInvoice.invoiceNumber);

    // ═══════════════════════════════════════════════════════════════════════════
    // تحديث فرق الأرصدة عند تعديل الفاتورة
    // ═══════════════════════════════════════════════════════════════════════════
    final oldTotal = oldInvoice.total;
    final newTotal = total;
    final balanceDifference = newTotal - oldTotal;

    if (balanceDifference != 0) {
      await _updateCustomerSupplierBalance(
        type: oldInvoice.type,
        customerId: customerId ?? oldInvoice.customerId,
        supplierId: supplierId ?? oldInvoice.supplierId,
        total: balanceDifference.abs(),
        paidAmount: 0,
        paymentMethod: paymentMethod,
        isAdjustment: true,
        isIncrease: balanceDifference > 0,
      );
    }
  }

  /// حذف فاتورة مع عكس جميع تأثيراتها (المخزون + الصندوق + الأرصدة)
  Future<void> deleteInvoiceWithReverse(String invoiceId) async {
    // جلب الفاتورة
    final invoice = await database.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw Exception('الفاتورة غير موجودة');
    }

    // جلب عناصر الفاتورة
    final items = await database.getInvoiceItems(invoiceId);

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. عكس تأثير المخزون
    // ═══════════════════════════════════════════════════════════════════════════
    await _reverseInventory(invoice.type, items);

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. عكس تأثير رصيد العميل/المورد
    // ═══════════════════════════════════════════════════════════════════════════
    await _reverseCustomerSupplierBalance(
      type: invoice.type,
      customerId: invoice.customerId,
      supplierId: invoice.supplierId,
      total: invoice.total,
      paidAmount: invoice.paidAmount,
      paymentMethod: invoice.paymentMethod,
    );

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. عكس حركة الصندوق (إذا كانت الفاتورة مرتبطة بوردية)
    // ═══════════════════════════════════════════════════════════════════════════
    if (invoice.shiftId != null && invoice.paymentMethod != 'credit') {
      await _reverseCashMovement(
        type: invoice.type,
        amount: invoice.total,
        invoiceId: invoiceId,
        invoiceNumber: invoice.invoiceNumber,
        shiftId: invoice.shiftId!,
        paymentMethod: invoice.paymentMethod,
      );
    }

    // حذف العناصر
    await database.deleteInvoiceItems(invoiceId);

    // حذف الفاتورة
    await database.deleteInvoice(invoiceId);

    // حذف من Firestore
    try {
      await collection.doc(invoiceId).delete();
    } catch (e) {
      debugPrint('Error deleting invoice from Firestore: $e');
    }
  }

  /// عكس تأثير رصيد العميل/المورد عند حذف الفاتورة
  Future<void> _reverseCustomerSupplierBalance({
    required String type,
    String? customerId,
    String? supplierId,
    required double total,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    try {
      // حساب المبلغ المتبقي (الدين) الذي كان على الفاتورة
      final remainingAmount = total - paidAmount;

      switch (type) {
        case 'sale':
          // فاتورة بيع آجلة كانت زيادة في رصيد العميل، العكس = خصم
          if (customerId != null &&
              (paymentMethod == 'credit' || remainingAmount > 0)) {
            final amountToReverse =
                remainingAmount > 0 ? remainingAmount : total;
            await customerRepo.updateBalance(customerId, -amountToReverse);
            debugPrint(
                'عكس رصيد العميل $customerId بمقدار -$amountToReverse (حذف فاتورة بيع)');
          }
          break;
        case 'purchase':
          // فاتورة شراء آجلة كانت زيادة في رصيد المورد، العكس = خصم
          if (supplierId != null &&
              (paymentMethod == 'credit' || remainingAmount > 0)) {
            final amountToReverse =
                remainingAmount > 0 ? remainingAmount : total;
            await supplierRepo.updateBalance(supplierId, -amountToReverse);
            debugPrint(
                'عكس رصيد المورد $supplierId بمقدار -$amountToReverse (حذف فاتورة شراء)');
          }
          break;
        case 'sale_return':
          // مرتجع بيع كان خصم من رصيد العميل، العكس = زيادة
          if (customerId != null) {
            await customerRepo.updateBalance(customerId, total);
            debugPrint(
                'عكس رصيد العميل $customerId بمقدار +$total (حذف مرتجع بيع)');
          }
          break;
        case 'purchase_return':
          // مرتجع شراء كان خصم من رصيد المورد، العكس = زيادة
          if (supplierId != null) {
            await supplierRepo.updateBalance(supplierId, total);
            debugPrint(
                'عكس رصيد المورد $supplierId بمقدار +$total (حذف مرتجع شراء)');
          }
          break;
      }
    } catch (e) {
      debugPrint('Error reversing customer/supplier balance: $e');
    }
  }

  /// عكس حركة الصندوق عند حذف الفاتورة
  Future<void> _reverseCashMovement({
    required String type,
    required double amount,
    required String invoiceId,
    required String invoiceNumber,
    required String shiftId,
    required String paymentMethod,
  }) async {
    try {
      switch (type) {
        case 'sale':
          // البيع كان إضافة للصندوق، العكس = مصروف
          await cashRepo.addExpense(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء فاتورة بيع: $invoiceNumber',
            category: 'invoice_deletion',
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase':
          // الشراء كان خصم من الصندوق، العكس = إيراد
          await cashRepo.addIncome(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء فاتورة شراء: $invoiceNumber',
            category: 'invoice_deletion',
            paymentMethod: paymentMethod,
          );
          break;
        case 'sale_return':
          // مرتجع البيع كان خصم (مصروف)، العكس = إيراد
          await cashRepo.addIncome(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء مرتجع مبيعات: $invoiceNumber',
            category: 'invoice_deletion',
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase_return':
          // مرتجع الشراء كان إضافة (إيراد)، العكس = مصروف
          await cashRepo.addExpense(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء مرتجع مشتريات: $invoiceNumber',
            category: 'invoice_deletion',
            paymentMethod: paymentMethod,
          );
          break;
      }
      debugPrint('تم عكس حركة الصندوق للفاتورة $invoiceNumber');
    } catch (e) {
      debugPrint('Error reversing cash movement: $e');
    }
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingInvoices();

    for (final invoice in pending) {
      try {
        // Sync invoice
        await collection.doc(invoice.id).set(toFirestore(invoice));

        // Sync invoice items
        final items = await database.getInvoiceItems(invoice.id);
        for (final item in items) {
          await firestore
              .collection(AppConstants.invoiceItemsCollection)
              .doc(item.id)
              .set(_invoiceItemToFirestore(item));
        }

        // Update sync status
        await database.updateInvoice(InvoicesCompanion(
          id: Value(invoice.id),
          syncStatus: const Value('synced'),
        ));
      } catch (e) {
        debugPrint('Error syncing invoice ${invoice.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getInvoiceById(doc.id);
        if (existing == null) {
          await database.insertInvoice(companion);
        }
      }
    } catch (e) {
      debugPrint('Error pulling invoices from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Invoice entity) {
    return {
      'invoiceNumber': entity.invoiceNumber,
      'type': entity.type,
      'customerId': entity.customerId,
      'supplierId': entity.supplierId,
      'subtotal': entity.subtotal,
      'taxAmount': entity.taxAmount,
      'discountAmount': entity.discountAmount,
      'total': entity.total,
      'paidAmount': entity.paidAmount,
      'paymentMethod': entity.paymentMethod,
      'status': entity.status,
      'notes': entity.notes,
      'shiftId': entity.shiftId,
      'invoiceDate': Timestamp.fromDate(entity.invoiceDate),
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  Map<String, dynamic> _invoiceItemToFirestore(InvoiceItem item) {
    return {
      'invoiceId': item.invoiceId,
      'productId': item.productId,
      'productName': item.productName,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'purchasePrice': item.purchasePrice,
      'discountAmount': item.discountAmount,
      'taxAmount': item.taxAmount,
      'total': item.total,
      'createdAt': Timestamp.fromDate(item.createdAt),
    };
  }

  @override
  InvoicesCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return InvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(data['invoiceNumber'] as String),
      type: Value(data['type'] as String),
      customerId: Value(data['customerId'] as String?),
      supplierId: Value(data['supplierId'] as String?),
      subtotal: Value((data['subtotal'] as num).toDouble()),
      taxAmount: Value((data['taxAmount'] as num?)?.toDouble() ?? 0),
      discountAmount: Value((data['discountAmount'] as num?)?.toDouble() ?? 0),
      total: Value((data['total'] as num).toDouble()),
      paidAmount: Value((data['paidAmount'] as num?)?.toDouble() ?? 0),
      paymentMethod: Value(data['paymentMethod'] as String? ?? 'cash'),
      status: Value(data['status'] as String? ?? 'completed'),
      notes: Value(data['notes'] as String?),
      shiftId: Value(data['shiftId'] as String?),
      syncStatus: const Value('synced'),
      invoiceDate: Value((data['invoiceDate'] as Timestamp).toDate()),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _invoiceFirestoreSubscription?.cancel();
    _invoiceFirestoreSubscription = collection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            _handleRemoteChange(data, change.doc.id);
            break;
          case DocumentChangeType.removed:
            _handleRemoteDelete(change.doc.id);
            break;
        }
      }
    });
  }

  Future<void> _handleRemoteChange(Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getInvoiceById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertInvoice(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateInvoice(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote invoice change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getInvoiceById(id);
      if (existing != null) {
        // Delete invoice items first
        await database.deleteInvoiceItems(id);
        // Then delete the invoice
        await database.deleteInvoice(id);
        debugPrint('Deleted invoice from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote invoice delete: $e');
    }
  }
}
