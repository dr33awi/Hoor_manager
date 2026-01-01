import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/cash_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/voucher_repository.dart';
import '../constants/accounting_exceptions.dart';
import '../di/injection.dart';
import 'currency_service.dart';

// Re-export للاستخدام الخارجي
export '../constants/accounting_exceptions.dart';
export '../../data/repositories/voucher_repository.dart'
    show VoucherType, VoucherTypeExtension;

/// ═══════════════════════════════════════════════════════════════════════════
/// نتيجة العملية المحاسبية
/// ═══════════════════════════════════════════════════════════════════════════
class AccountingResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final AccountingErrorType? errorType;

  AccountingResult.success(this.data)
      : success = true,
        errorMessage = null,
        errorType = null;

  AccountingResult.failure(this.errorMessage, [this.errorType])
      : success = false,
        data = null;

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// أنواع الأخطاء المحاسبية
enum AccountingErrorType {
  insufficientStock, // كمية غير كافية
  noOpenShift, // لا توجد وردية مفتوحة
  invalidCustomer, // عميل غير صالح
  invalidSupplier, // مورد غير صالح
  invalidProduct, // منتج غير صالح
  transactionFailed, // فشل في المعاملة
  balanceError, // خطأ في الرصيد
  unknown, // خطأ غير معروف
}

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة المحاسبة الموحدة
/// تضمن اتساق جميع العمليات المحاسبية
/// ═══════════════════════════════════════════════════════════════════════════
class AccountingService {
  final AppDatabase database;
  final CurrencyService currencyService;

  // Lazy loaded repositories
  InvoiceRepository? _invoiceRepo;
  InventoryRepository? _inventoryRepo;
  CashRepository? _cashRepo;
  CustomerRepository? _customerRepo;
  SupplierRepository? _supplierRepo;
  VoucherRepository? _voucherRepo;

  AccountingService({
    required this.database,
    required this.currencyService,
  });

  // Getters للـ Repositories
  InvoiceRepository get invoiceRepo =>
      _invoiceRepo ??= getIt<InvoiceRepository>();
  InventoryRepository get inventoryRepo =>
      _inventoryRepo ??= getIt<InventoryRepository>();
  CashRepository get cashRepo => _cashRepo ??= getIt<CashRepository>();
  CustomerRepository get customerRepo =>
      _customerRepo ??= getIt<CustomerRepository>();
  SupplierRepository get supplierRepo =>
      _supplierRepo ??= getIt<SupplierRepository>();
  VoucherRepository get voucherRepo =>
      _voucherRepo ??= getIt<VoucherRepository>();

  /// ═══════════════════════════════════════════════════════════════════════════
  /// التحقق من كفاية المخزون
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<bool>> validateStockAvailability({
    required List<Map<String, dynamic>> items,
    required String transactionType,
    String? warehouseId,
  }) async {
    // البيع والمرتجع مشتريات يخصمان من المخزون
    if (transactionType != 'sale' && transactionType != 'purchase_return') {
      return AccountingResult.success(true);
    }

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
        return AccountingResult.failure(
          'الكمية المطلوبة ($requestedQty) من "$productName" أكبر من المتوفر ($availableQty)',
          AccountingErrorType.insufficientStock,
        );
      }
    }

    return AccountingResult.success(true);
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// حساب تأثير الفاتورة على رصيد العميل/المورد
  /// ═══════════════════════════════════════════════════════════════════════════
  double calculateBalanceEffect({
    required String type,
    required double total,
    required double paidAmount,
    required String paymentMethod,
  }) {
    // الفاتورة النقدية لا تؤثر على الرصيد
    if (paymentMethod == 'cash' && paidAmount >= total) {
      return 0;
    }

    final remainingAmount = total - paidAmount;

    switch (type) {
      case 'sale':
        // فاتورة بيع = زيادة دين العميل
        return remainingAmount > 0
            ? remainingAmount
            : (paymentMethod == 'credit' ? total : 0);
      case 'purchase':
        // فاتورة شراء = زيادة دين للمورد
        return remainingAmount > 0
            ? remainingAmount
            : (paymentMethod == 'credit' ? total : 0);
      case 'sale_return':
        // مرتجع بيع = خصم من دين العميل
        return -total;
      case 'purchase_return':
        // مرتجع شراء = خصم من دين المورد
        return -total;
      default:
        return 0;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// تحديث رصيد العميل مع التحقق
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<void>> updateCustomerBalance(
    String? customerId,
    double amount,
  ) async {
    if (customerId == null || amount == 0) {
      return AccountingResult.success(null);
    }

    try {
      final customer = await customerRepo.getCustomerById(customerId);
      if (customer == null) {
        return AccountingResult.failure(
          'العميل غير موجود',
          AccountingErrorType.invalidCustomer,
        );
      }

      await customerRepo.updateBalance(customerId, amount);
      debugPrint('تم تحديث رصيد العميل $customerId بمقدار $amount');
      return AccountingResult.success(null);
    } catch (e) {
      debugPrint('خطأ في تحديث رصيد العميل: $e');
      return AccountingResult.failure(
        'فشل في تحديث رصيد العميل: $e',
        AccountingErrorType.balanceError,
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// تحديث رصيد المورد مع التحقق
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<void>> updateSupplierBalance(
    String? supplierId,
    double amount,
  ) async {
    if (supplierId == null || amount == 0) {
      return AccountingResult.success(null);
    }

    try {
      final supplier = await supplierRepo.getSupplierById(supplierId);
      if (supplier == null) {
        return AccountingResult.failure(
          'المورد غير موجود',
          AccountingErrorType.invalidSupplier,
        );
      }

      await supplierRepo.updateBalance(supplierId, amount);
      debugPrint('تم تحديث رصيد المورد $supplierId بمقدار $amount');
      return AccountingResult.success(null);
    } catch (e) {
      debugPrint('خطأ في تحديث رصيد المورد: $e');
      return AccountingResult.failure(
        'فشل في تحديث رصيد المورد: $e',
        AccountingErrorType.balanceError,
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// عكس تأثير الفاتورة على الأرصدة
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<void> reverseInvoiceBalanceEffect({
    required String type,
    String? customerId,
    String? supplierId,
    required double total,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    final effect = calculateBalanceEffect(
      type: type,
      total: total,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );

    // عكس التأثير
    final reverseEffect = -effect;

    if (reverseEffect == 0) return;

    switch (type) {
      case 'sale':
      case 'sale_return':
        if (customerId != null) {
          await updateCustomerBalance(customerId, reverseEffect);
        }
        break;
      case 'purchase':
      case 'purchase_return':
        if (supplierId != null) {
          await updateSupplierBalance(supplierId, reverseEffect);
        }
        break;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// عكس حركة الصندوق للفاتورة
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<void> reverseCashMovementForInvoice({
    required String invoiceId,
    required String type,
    required double amount,
    required String shiftId,
    required String paymentMethod,
    required String invoiceNumber,
  }) async {
    if (paymentMethod == 'credit') return;

    try {
      switch (type) {
        case 'sale':
          // عكس البيع = مصروف (خصم)
          await cashRepo.addExpense(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء/عكس فاتورة بيع: $invoiceNumber',
            category: 'invoice_reversal',
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase':
          // عكس الشراء = إيراد (إضافة)
          await cashRepo.addIncome(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء/عكس فاتورة شراء: $invoiceNumber',
            category: 'invoice_reversal',
            paymentMethod: paymentMethod,
          );
          break;
        case 'sale_return':
          // عكس مرتجع البيع = إيراد
          await cashRepo.addIncome(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء/عكس مرتجع مبيعات: $invoiceNumber',
            category: 'invoice_reversal',
            paymentMethod: paymentMethod,
          );
          break;
        case 'purchase_return':
          // عكس مرتجع الشراء = مصروف
          await cashRepo.addExpense(
            shiftId: shiftId,
            amount: amount,
            description: 'إلغاء/عكس مرتجع مشتريات: $invoiceNumber',
            category: 'invoice_reversal',
            paymentMethod: paymentMethod,
          );
          break;
      }
    } catch (e) {
      debugPrint('خطأ في عكس حركة الصندوق: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// عكس تأثير السند على الرصيد
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<void> reverseVoucherBalanceEffect({
    required String voucherType,
    required double amount,
    String? customerId,
    String? supplierId,
  }) async {
    switch (voucherType) {
      case 'receipt':
        // سند قبض كان خصم من العميل، العكس = زيادة
        if (customerId != null) {
          await updateCustomerBalance(customerId, amount);
        }
        break;
      case 'payment':
        // سند دفع كان خصم من المورد، العكس = زيادة
        if (supplierId != null) {
          await updateSupplierBalance(supplierId, amount);
        }
        break;
      // سند المصاريف لا يؤثر على العملاء/الموردين
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// حساب ملخص الصندوق الشامل (يشمل السندات)
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, double>> calculateComprehensiveShiftSummary(
    String shiftId,
  ) async {
    final movements = await database.getCashMovementsByShift(shiftId);
    final shift = await database.getShiftById(shiftId);

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSales = 0;
    double totalPurchases = 0;
    double totalVoucherReceipts = 0;
    double totalVoucherPayments = 0;
    double totalSaleReturns = 0;
    double totalPurchaseReturns = 0;

    for (final movement in movements) {
      switch (movement.type) {
        case 'income':
          totalIncome += movement.amount;
          break;
        case 'expense':
          totalExpense += movement.amount;
          break;
        case 'sale':
          totalSales += movement.amount;
          break;
        case 'purchase':
          totalPurchases += movement.amount;
          break;
        case 'voucher_receipt':
          totalVoucherReceipts += movement.amount;
          break;
        case 'voucher_payment':
          totalVoucherPayments += movement.amount;
          break;
        // الحالات الإضافية من الفواتير
        case 'sale_return':
          totalSaleReturns += movement.amount;
          break;
        case 'purchase_return':
          totalPurchaseReturns += movement.amount;
          break;
      }
    }

    final openingBalance = shift?.openingBalance ?? 0;

    // الرصيد المتوقع = الافتتاحي + الإيرادات - المصروفات
    final expectedBalance = openingBalance +
        totalSales +
        totalIncome +
        totalVoucherReceipts +
        totalPurchaseReturns -
        totalPurchases -
        totalExpense -
        totalVoucherPayments -
        totalSaleReturns;

    return {
      'openingBalance': openingBalance,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalVoucherReceipts': totalVoucherReceipts,
      'totalVoucherPayments': totalVoucherPayments,
      'totalSaleReturns': totalSaleReturns,
      'totalPurchaseReturns': totalPurchaseReturns,
      'expectedBalance': expectedBalance,
      'netCash': expectedBalance - openingBalance,
    };
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// تنفيذ عملية محاسبية ضمن transaction واحدة
  /// يضمن أن جميع العمليات تنجح أو تفشل معاً
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<T>> executeInTransaction<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      final result = await database.transaction(() async {
        return await operation();
      });
      return AccountingResult.success(result);
    } catch (e) {
      debugPrint(
          'فشل في تنفيذ العملية المحاسبية${operationName != null ? " ($operationName)" : ""}: $e');

      // تصنيف الخطأ
      AccountingErrorType errorType = AccountingErrorType.transactionFailed;
      String errorMessage = e.toString();

      if (e is InsufficientStockException) {
        errorType = AccountingErrorType.insufficientStock;
        errorMessage = e.message;
      } else if (e is NegativeStockException) {
        errorType = AccountingErrorType.insufficientStock;
        errorMessage = e.message;
      } else if (e is NoOpenShiftException) {
        errorType = AccountingErrorType.noOpenShift;
        errorMessage = e.toString();
      } else if (e is NonZeroBalanceException) {
        errorType = AccountingErrorType.balanceError;
        errorMessage = e.message;
      }

      return AccountingResult.failure(errorMessage, errorType);
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// إنشاء فاتورة كاملة ضمن transaction واحدة
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<String>> createInvoiceWithTransaction({
    required String type,
    String? customerId,
    String? supplierId,
    String? warehouseId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0,
    required String paymentMethod,
    double paidAmount = 0,
    String? notes,
    String? shiftId,
    DateTime? invoiceDate,
    bool validateStock = true,
  }) async {
    return executeInTransaction<String>(
      () async {
        // التحقق من المخزون أولاً
        if (validateStock && (type == 'sale' || type == 'purchase_return')) {
          final stockResult = await validateStockAvailability(
            items: items,
            transactionType: type,
            warehouseId: warehouseId,
          );
          if (stockResult.isFailure) {
            throw Exception(
                stockResult.errorMessage ?? 'خطأ في التحقق من المخزون');
          }
        }

        // إنشاء الفاتورة
        final invoiceId = await invoiceRepo.createInvoice(
          type: type,
          customerId: customerId,
          supplierId: supplierId,
          warehouseId: warehouseId,
          items: items,
          discountAmount: discountAmount,
          paymentMethod: paymentMethod,
          paidAmount: paidAmount,
          notes: notes,
          shiftId: shiftId,
          invoiceDate: invoiceDate,
          validateStock: false, // تم التحقق بالفعل
        );

        return invoiceId;
      },
      operationName: 'إنشاء فاتورة $type',
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// إنشاء سند ضمن transaction واحدة
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<String>> createVoucherWithTransaction({
    required String type,
    required double amount,
    String? categoryId,
    String? description,
    String? customerId,
    String? supplierId,
    String? shiftId,
    DateTime? voucherDate,
  }) async {
    return executeInTransaction<String>(
      () async {
        // تحويل النوع إلى VoucherType
        VoucherType voucherType;
        switch (type) {
          case 'receipt':
            voucherType = VoucherType.receipt;
            break;
          case 'payment':
            voucherType = VoucherType.payment;
            break;
          case 'expense':
            voucherType = VoucherType.expense;
            break;
          default:
            throw Exception('نوع سند غير صالح: $type');
        }

        // إنشاء السند
        final voucherId = await voucherRepo.createVoucher(
          type: voucherType,
          amount: amount,
          categoryId: categoryId,
          description: description,
          customerId: customerId,
          supplierId: supplierId,
          shiftId: shiftId,
          voucherDate: voucherDate,
        );

        return voucherId;
      },
      operationName: 'إنشاء سند $type',
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// حذف فاتورة مع عكس جميع تأثيراتها ضمن transaction
  /// ملاحظة: تستخدم deleteInvoiceWithReverse من InvoiceRepository
  /// ═══════════════════════════════════════════════════════════════════════════
  Future<AccountingResult<void>> deleteInvoiceWithTransaction({
    required String invoiceId,
    String? currentShiftId,
  }) async {
    return executeInTransaction<void>(
      () async {
        // استخدام الدالة الموجودة في InvoiceRepository
        await invoiceRepo.deleteInvoiceWithReverse(invoiceId);
      },
      operationName: 'حذف فاتورة',
    );
  }
}
