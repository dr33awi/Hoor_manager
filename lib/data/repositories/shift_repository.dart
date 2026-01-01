import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class ShiftRepository extends BaseRepository<Shift, ShiftsCompanion> {
  StreamSubscription? _shiftFirestoreSubscription;

  ShiftRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.shiftsCollection);

  // ==================== Local Operations ====================

  Future<List<Shift>> getAllShifts() => database.getAllShifts();

  Stream<List<Shift>> watchAllShifts() => database.watchAllShifts();

  Future<Shift?> getOpenShift() => database.getOpenShift();

  Stream<Shift?> watchOpenShift() => database.watchOpenShift();

  Future<Shift?> getShiftById(String id) => database.getShiftById(id);

  /// Check if there's an open shift
  Future<bool> hasOpenShift() async {
    final shift = await database.getOpenShift();
    return shift != null;
  }

  /// Open a new shift
  Future<String> openShift({
    required double openingBalance,
    String? notes,
  }) async {
    // Check if there's already an open shift
    final existingShift = await database.getOpenShift();
    if (existingShift != null) {
      throw Exception('يوجد وردية مفتوحة بالفعل. يرجى إغلاقها أولاً.');
    }

    final id = generateId();
    final now = DateTime.now();
    final shiftNumber = await _generateShiftNumber();

    await database.insertShift(ShiftsCompanion(
      id: Value(id),
      shiftNumber: Value(shiftNumber),
      openingBalance: Value(openingBalance),
      status: const Value('open'),
      notes: Value(notes),
      syncStatus: const Value('pending'),
      openedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // Record opening balance as cash movement
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(generateId()),
      shiftId: Value(id),
      type: const Value('opening'),
      amount: Value(openingBalance),
      description: const Value('رصيد افتتاحي'),
      paymentMethod: const Value('cash'),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
    ));

    // Sync immediately to Firestore
    _syncShiftToFirestore(id);

    return id;
  }

  /// Close the current shift
  Future<void> closeShift({
    required String shiftId,
    required double closingBalance,
    String? notes,
  }) async {
    final shift = await database.getShiftById(shiftId);
    if (shift == null) {
      throw Exception('الوردية غير موجودة');
    }
    if (shift.status == 'closed') {
      throw Exception('الوردية مغلقة بالفعل');
    }

    // Calculate expected balance (يشمل جميع أنواع الحركات)
    final movements = await database.getCashMovementsByShift(shiftId);
    double expectedBalance = shift.openingBalance;
    double totalSales = 0;
    double totalReturns = 0;
    double totalExpenses = 0;
    double totalIncome = 0;
    // ignore: unused_local_variable
    double totalVoucherReceipts = 0;
    // ignore: unused_local_variable
    double totalVoucherPayments = 0;
    // ignore: unused_local_variable
    double totalPurchases = 0;

    for (final movement in movements) {
      switch (movement.type) {
        // ═══════════════════════════════════════════════════════════════════════════
        // الإيرادات (تضاف للرصيد)
        // ═══════════════════════════════════════════════════════════════════════════
        case 'sale':
          expectedBalance += movement.amount;
          totalSales += movement.amount;
          break;
        case 'income':
          expectedBalance += movement.amount;
          totalIncome += movement.amount;
          break;
        case 'voucher_receipt':
          // سند قبض = إيراد (يضاف للصندوق)
          expectedBalance += movement.amount;
          totalVoucherReceipts += movement.amount;
          totalIncome += movement.amount;
          break;
        case 'purchase_return':
          // مرتجع مشتريات = إيراد (يعود للصندوق)
          expectedBalance += movement.amount;
          totalIncome += movement.amount;
          break;

        // ═══════════════════════════════════════════════════════════════════════════
        // المصروفات (تخصم من الرصيد)
        // ═══════════════════════════════════════════════════════════════════════════
        case 'purchase':
          expectedBalance -= movement.amount;
          totalPurchases += movement.amount;
          totalExpenses += movement.amount;
          break;
        case 'expense':
          expectedBalance -= movement.amount;
          totalExpenses += movement.amount;
          break;
        case 'voucher_payment':
          // سند دفع = مصروف (يخصم من الصندوق)
          expectedBalance -= movement.amount;
          totalVoucherPayments += movement.amount;
          totalExpenses += movement.amount;
          break;
        case 'sale_return':
        case 'return':
          // مرتجع مبيعات = مصروف (يرد للعميل)
          expectedBalance -= movement.amount;
          totalReturns += movement.amount;
          break;

        // ═══════════════════════════════════════════════════════════════════════════
        // حالات أخرى (لا تؤثر على الحساب)
        // ═══════════════════════════════════════════════════════════════════════════
        case 'opening':
        case 'closing':
          // رصيد افتتاحي/إغلاق - لا يؤثر على الحساب
          break;
        default:
          // أي نوع غير معروف - نفترض أنه مصروف للأمان
          if (movement.amount > 0) {
            expectedBalance -= movement.amount;
            totalExpenses += movement.amount;
          }
          break;
      }
    }

    final difference = closingBalance - expectedBalance;
    final now = DateTime.now();

    await database.updateShift(ShiftsCompanion(
      id: Value(shiftId),
      shiftNumber: Value(shift.shiftNumber),
      openingBalance: Value(shift.openingBalance),
      closingBalance: Value(closingBalance),
      expectedBalance: Value(expectedBalance),
      difference: Value(difference),
      totalSales: Value(totalSales),
      totalReturns: Value(totalReturns),
      totalExpenses: Value(totalExpenses),
      totalIncome: Value(totalIncome),
      transactionCount: Value(movements.length),
      status: const Value('closed'),
      notes: Value(notes ?? shift.notes),
      syncStatus: const Value('pending'),
      openedAt: Value(shift.openedAt),
      closedAt: Value(now),
      createdAt: Value(shift.createdAt),
      updatedAt: Value(now),
    ));

    // Record closing balance
    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(generateId()),
      shiftId: Value(shiftId),
      type: const Value('closing'),
      amount: Value(closingBalance),
      description: const Value('رصيد إغلاق'),
      paymentMethod: const Value('cash'),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
    ));

    // Sync immediately to Firestore
    _syncShiftToFirestore(shiftId);
  }

  Future<String> _generateShiftNumber() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final shifts = await database.getAllShifts();
    final todayShifts = shifts
        .where((s) =>
            s.openedAt.year == today.year &&
            s.openedAt.month == today.month &&
            s.openedAt.day == today.day)
        .length;

    return 'SH-$dateStr-${(todayShifts + 1).toString().padLeft(2, '0')}';
  }

  /// Get shift summary
  Future<Map<String, dynamic>> getShiftSummary(String shiftId) async {
    final shift = await database.getShiftById(shiftId);
    if (shift == null) {
      throw Exception('الوردية غير موجودة');
    }

    final movements = await database.getCashMovementsByShift(shiftId);
    final invoices = await database.getInvoicesByShift(shiftId);

    return {
      'shift': shift,
      'movements': movements,
      'invoices': invoices,
      'salesCount': invoices.where((i) => i.type == 'sale').length,
      'returnsCount': invoices.where((i) => i.type == 'sale_return').length,
    };
  }

  // ==================== Cloud Sync ====================

  /// Sync a specific shift to Firestore immediately
  Future<void> _syncShiftToFirestore(String shiftId) async {
    try {
      final shift = await database.getShiftById(shiftId);
      if (shift == null) return;

      await collection.doc(shiftId).set(toFirestore(shift));

      await database.updateShift(ShiftsCompanion(
        id: Value(shift.id),
        shiftNumber: Value(shift.shiftNumber),
        openingBalance: Value(shift.openingBalance),
        closingBalance: Value(shift.closingBalance),
        expectedBalance: Value(shift.expectedBalance),
        difference: Value(shift.difference),
        totalSales: Value(shift.totalSales),
        totalReturns: Value(shift.totalReturns),
        totalExpenses: Value(shift.totalExpenses),
        totalIncome: Value(shift.totalIncome),
        transactionCount: Value(shift.transactionCount),
        status: Value(shift.status),
        notes: Value(shift.notes),
        syncStatus: const Value('synced'),
        openedAt: Value(shift.openedAt),
        closedAt: Value(shift.closedAt),
        createdAt: Value(shift.createdAt),
        updatedAt: Value(shift.updatedAt),
      ));

      debugPrint('Shift $shiftId synced to Firestore');
    } catch (e) {
      debugPrint('Error syncing shift $shiftId to Firestore: $e');
    }
  }

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingShifts();

    for (final shift in pending) {
      try {
        await collection.doc(shift.id).set(toFirestore(shift));

        await database.updateShift(ShiftsCompanion(
          id: Value(shift.id),
          shiftNumber: Value(shift.shiftNumber),
          openingBalance: Value(shift.openingBalance),
          closingBalance: Value(shift.closingBalance),
          expectedBalance: Value(shift.expectedBalance),
          difference: Value(shift.difference),
          totalSales: Value(shift.totalSales),
          totalReturns: Value(shift.totalReturns),
          totalExpenses: Value(shift.totalExpenses),
          totalIncome: Value(shift.totalIncome),
          transactionCount: Value(shift.transactionCount),
          status: Value(shift.status),
          notes: Value(shift.notes),
          syncStatus: const Value('synced'),
          openedAt: Value(shift.openedAt),
          closedAt: Value(shift.closedAt),
          createdAt: Value(shift.createdAt),
          updatedAt: Value(shift.updatedAt),
        ));
      } catch (e) {
        debugPrint('Error syncing shift ${shift.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection
          .orderBy('openedAt', descending: true)
          .limit(100)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getShiftById(doc.id);
        if (existing == null) {
          await database.insertShift(companion);
        }
      }
    } catch (e) {
      debugPrint('Error pulling shifts from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Shift entity) {
    return {
      'shiftNumber': entity.shiftNumber,
      'openingBalance': entity.openingBalance,
      'closingBalance': entity.closingBalance,
      'expectedBalance': entity.expectedBalance,
      'difference': entity.difference,
      'totalSales': entity.totalSales,
      'totalReturns': entity.totalReturns,
      'totalExpenses': entity.totalExpenses,
      'totalIncome': entity.totalIncome,
      'transactionCount': entity.transactionCount,
      'status': entity.status,
      'notes': entity.notes,
      'openedAt': Timestamp.fromDate(entity.openedAt),
      'closedAt':
          entity.closedAt != null ? Timestamp.fromDate(entity.closedAt!) : null,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  @override
  ShiftsCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return ShiftsCompanion(
      id: Value(id),
      shiftNumber: Value(data['shiftNumber'] as String),
      openingBalance: Value((data['openingBalance'] as num).toDouble()),
      closingBalance: Value((data['closingBalance'] as num?)?.toDouble()),
      expectedBalance: Value((data['expectedBalance'] as num?)?.toDouble()),
      difference: Value((data['difference'] as num?)?.toDouble()),
      totalSales: Value((data['totalSales'] as num?)?.toDouble() ?? 0),
      totalReturns: Value((data['totalReturns'] as num?)?.toDouble() ?? 0),
      totalExpenses: Value((data['totalExpenses'] as num?)?.toDouble() ?? 0),
      totalIncome: Value((data['totalIncome'] as num?)?.toDouble() ?? 0),
      transactionCount: Value(data['transactionCount'] as int? ?? 0),
      status: Value(data['status'] as String),
      notes: Value(data['notes'] as String?),
      syncStatus: const Value('synced'),
      openedAt: Value((data['openedAt'] as Timestamp).toDate()),
      closedAt: Value(data['closedAt'] != null
          ? (data['closedAt'] as Timestamp).toDate()
          : null),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _shiftFirestoreSubscription?.cancel();
    _shiftFirestoreSubscription = collection.snapshots().listen((snapshot) {
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
    _shiftFirestoreSubscription?.cancel();
    _shiftFirestoreSubscription = null;
  }

  Future<void> _handleRemoteChange(Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getShiftById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertShift(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateShift(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote shift change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getShiftById(id);
      if (existing != null) {
        // Delete cash movements for this shift first
        await database.deleteCashMovementsByShift(id);
        // Then delete the shift
        await database.deleteShift(id);
        debugPrint('Deleted shift from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote shift delete: $e');
    }
  }
}
