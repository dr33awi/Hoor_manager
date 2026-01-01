import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/currency_service.dart';
import '../../core/di/injection.dart';
import 'base_repository.dart';

class CashRepository
    extends BaseRepository<CashMovement, CashMovementsCompanion> {
  StreamSubscription? _cashFirestoreSubscription;

  CashRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.cashMovementsCollection);

  // ==================== Local Operations ====================

  Future<List<CashMovement>> getMovementsByShift(String shiftId) =>
      database.getCashMovementsByShift(shiftId);

  Stream<List<CashMovement>> watchMovementsByShift(String shiftId) =>
      database.watchCashMovementsByShift(shiftId);

  /// Add income/revenue
  Future<String> addIncome({
    required String shiftId,
    required double amount,
    required String description,
    String? category,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();

    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('income'),
      amount: Value(amount),
      description: Value(description),
      category: Value(category),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);

    return id;
  }

  /// Add expense
  Future<String> addExpense({
    required String shiftId,
    required double amount,
    required String description,
    String? category,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();

    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('expense'),
      amount: Value(amount),
      description: Value(description),
      category: Value(category),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);

    return id;
  }

  /// Record sale cash movement
  Future<void> recordSale({
    required String shiftId,
    required double amount,
    required String invoiceId,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('sale'),
      amount: Value(amount),
      description: const Value('مبيعات'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);
  }

  /// Record purchase cash movement
  Future<void> recordPurchase({
    required String shiftId,
    required double amount,
    required String invoiceId,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('purchase'),
      amount: Value(amount),
      description: const Value('مشتريات'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);
  }

  /// Record sale return cash movement (مرتجع مبيعات - يخصم من الصندوق)
  Future<void> recordSaleReturn({
    required String shiftId,
    required double amount,
    required String invoiceId,
    required String invoiceNumber,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('sale_return'), // نوع مخصص للمرتجعات
      amount: Value(amount),
      description: Value('مرتجع مبيعات - فاتورة: $invoiceNumber'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);
  }

  /// Record purchase return cash movement (مرتجع مشتريات - يضاف للصندوق)
  Future<void> recordPurchaseReturn({
    required String shiftId,
    required double amount,
    required String invoiceId,
    required String invoiceNumber,
    String paymentMethod = 'cash',
  }) async {
    final id = generateId();
    final currencyService = getIt<CurrencyService>();
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('purchase_return'), // نوع مخصص للمرتجعات
      amount: Value(amount),
      description: Value('مرتجع مشتريات - فاتورة: $invoiceNumber'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      exchangeRate: Value(currencyService.exchangeRate),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    // Sync immediately to Firestore
    _syncCashMovementToFirestore(id);
  }

  /// Get cash summary for a shift (يشمل جميع أنواع الحركات)
  Future<Map<String, double>> getShiftCashSummary(String shiftId) async {
    final movements = await database.getCashMovementsByShift(shiftId);

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
        // الإيرادات
        case 'income':
          totalIncome += movement.amount;
          break;
        case 'sale':
          totalSales += movement.amount;
          break;
        case 'voucher_receipt':
          totalVoucherReceipts += movement.amount;
          totalIncome += movement.amount;
          break;
        case 'purchase_return':
          totalPurchaseReturns += movement.amount;
          totalIncome += movement.amount;
          break;

        // المصروفات
        case 'expense':
          totalExpense += movement.amount;
          break;
        case 'purchase':
          totalPurchases += movement.amount;
          break;
        case 'voucher_payment':
          totalVoucherPayments += movement.amount;
          totalExpense += movement.amount;
          break;
        case 'sale_return':
        case 'return':
          totalSaleReturns += movement.amount;
          totalExpense += movement.amount;
          break;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'totalVoucherReceipts': totalVoucherReceipts,
      'totalVoucherPayments': totalVoucherPayments,
      'totalSaleReturns': totalSaleReturns,
      'totalPurchaseReturns': totalPurchaseReturns,
      'netCash': totalSales + totalIncome - totalPurchases - totalExpense,
    };
  }

  /// Watch cash summary for a shift (real-time updates) - يشمل جميع أنواع الحركات
  Stream<Map<String, double>> watchShiftCashSummary(String shiftId) {
    return database.watchCashMovementsByShift(shiftId).map((movements) {
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
          // الإيرادات
          case 'income':
            totalIncome += movement.amount;
            break;
          case 'sale':
            totalSales += movement.amount;
            break;
          case 'voucher_receipt':
            totalVoucherReceipts += movement.amount;
            totalIncome += movement.amount;
            break;
          case 'purchase_return':
            totalPurchaseReturns += movement.amount;
            totalIncome += movement.amount;
            break;

          // المصروفات
          case 'expense':
            totalExpense += movement.amount;
            break;
          case 'purchase':
            totalPurchases += movement.amount;
            break;
          case 'voucher_payment':
            totalVoucherPayments += movement.amount;
            totalExpense += movement.amount;
            break;
          case 'sale_return':
          case 'return':
            totalSaleReturns += movement.amount;
            totalExpense += movement.amount;
            break;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'totalSales': totalSales,
        'totalPurchases': totalPurchases,
        'totalVoucherReceipts': totalVoucherReceipts,
        'totalVoucherPayments': totalVoucherPayments,
        'totalSaleReturns': totalSaleReturns,
        'totalPurchaseReturns': totalPurchaseReturns,
        'netCash': totalSales + totalIncome - totalPurchases - totalExpense,
      };
    });
  }

  // ==================== Cloud Sync ====================

  /// Sync a single cash movement to Firestore immediately
  Future<void> _syncCashMovementToFirestore(String movementId) async {
    try {
      final movement = await database.getCashMovementById(movementId);
      if (movement != null) {
        await collection.doc(movementId).set(toFirestore(movement));
        await database.updateCashMovementSyncStatus(movementId, 'synced');
        debugPrint('Cash movement $movementId synced to Firestore');
      }
    } catch (e) {
      debugPrint('Error syncing cash movement $movementId: $e');
    }
  }

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingCashMovements();

    for (final movement in pending) {
      try {
        await collection.doc(movement.id).set(toFirestore(movement));
        // Update sync status to synced
        await database.updateCashMovementSyncStatus(movement.id, 'synced');
      } catch (e) {
        debugPrint('Error syncing cash movement ${movement.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    // Cash movements are typically not pulled back
  }

  @override
  Map<String, dynamic> toFirestore(CashMovement entity) {
    return {
      'shiftId': entity.shiftId,
      'type': entity.type,
      'amount': entity.amount,
      'description': entity.description,
      'category': entity.category,
      'referenceId': entity.referenceId,
      'referenceType': entity.referenceType,
      'paymentMethod': entity.paymentMethod,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }

  @override
  CashMovementsCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(data['shiftId'] as String),
      type: Value(data['type'] as String),
      amount: Value((data['amount'] as num).toDouble()),
      description: Value(data['description'] as String),
      category: Value(data['category'] as String?),
      referenceId: Value(data['referenceId'] as String?),
      referenceType: Value(data['referenceType'] as String?),
      paymentMethod: Value(data['paymentMethod'] as String? ?? 'cash'),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _cashFirestoreSubscription?.cancel();
    _cashFirestoreSubscription = collection.snapshots().listen((snapshot) {
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

  @override
  void stopRealtimeSync() {
    _cashFirestoreSubscription?.cancel();
    _cashFirestoreSubscription = null;
  }

  Future<void> _handleRemoteChange(Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getCashMovementById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertCashMovement(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudCreatedAt = (data['createdAt'] as Timestamp).toDate();
        if (cloudCreatedAt.isAfter(existing.createdAt)) {
          // Cash movements don't have updatedAt, so we use createdAt
          // Typically cash movements shouldn't be modified
        }
      }
    } catch (e) {
      debugPrint('Error handling remote cash movement change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getCashMovementById(id);
      if (existing != null) {
        await database.deleteCashMovement(id);
        debugPrint('Deleted cash movement from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote cash movement delete: $e');
    }
  }
}
