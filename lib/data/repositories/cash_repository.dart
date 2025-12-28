import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class CashRepository
    extends BaseRepository<CashMovement, CashMovementsCompanion> {
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

    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('income'),
      amount: Value(amount),
      description: Value(description),
      category: Value(category),
      paymentMethod: Value(paymentMethod),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

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

    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      type: const Value('expense'),
      amount: Value(amount),
      description: Value(description),
      category: Value(category),
      paymentMethod: Value(paymentMethod),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));

    return id;
  }

  /// Record sale cash movement
  Future<void> recordSale({
    required String shiftId,
    required double amount,
    required String invoiceId,
    String paymentMethod = 'cash',
  }) async {
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(generateId()),
      shiftId: Value(shiftId),
      type: const Value('sale'),
      amount: Value(amount),
      description: const Value('مبيعات'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Record purchase cash movement
  Future<void> recordPurchase({
    required String shiftId,
    required double amount,
    required String invoiceId,
    String paymentMethod = 'cash',
  }) async {
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(generateId()),
      shiftId: Value(shiftId),
      type: const Value('purchase'),
      amount: Value(amount),
      description: const Value('مشتريات'),
      referenceId: Value(invoiceId),
      referenceType: const Value('invoice'),
      paymentMethod: Value(paymentMethod),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Get cash summary for a shift
  Future<Map<String, double>> getShiftCashSummary(String shiftId) async {
    final movements = await database.getCashMovementsByShift(shiftId);

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSales = 0;
    double totalPurchases = 0;

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
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'netCash': totalIncome + totalSales - totalExpense - totalPurchases,
    };
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingCashMovements();

    for (final movement in pending) {
      try {
        await collection.doc(movement.id).set(toFirestore(movement));
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
}
