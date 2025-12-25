import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/stock_entities.dart';

/// خدمة إدارة المخزون المتقدمة
class StockManagementService {
  static final StockManagementService _instance =
      StockManagementService._internal();
  factory StockManagementService() => _instance;
  StockManagementService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _logger = Logger();

  // ==================== حركات المخزون ====================

  /// تسجيل حركة مخزون
  Future<Result<StockMovement>> recordStockMovement({
    required String productId,
    required String productName,
    String? variantId,
    String? color,
    String? size,
    required StockMovementType type,
    required StockMovementReason reason,
    required int quantity,
    required int previousStock,
    required int newStock,
    String? referenceId,
    String? notes,
    required String performedBy,
    String? performedByName,
  }) async {
    try {
      final movement = StockMovement(
        id: _firestore.collection('stock_movements').doc().id,
        productId: productId,
        productName: productName,
        variantId: variantId,
        color: color,
        size: size,
        type: type,
        reason: reason,
        quantity: quantity,
        previousStock: previousStock,
        newStock: newStock,
        referenceId: referenceId,
        notes: notes,
        performedBy: performedBy,
        performedByName: performedByName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('stock_movements')
          .doc(movement.id)
          .set(movement.toJson());

      _logger.i('Stock movement recorded: ${movement.id}');

      // التحقق من تنبيهات المخزون
      await _checkStockAlerts(productId, productName, newStock);

      return Success(movement);
    } catch (e) {
      _logger.e('Error recording stock movement: $e');
      return Failure('فشل في تسجيل حركة المخزون');
    }
  }

  /// الحصول على حركات منتج
  Future<Result<List<StockMovement>>> getProductMovements(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('stock_movements')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final movements = snapshot.docs
          .map((doc) =>
              StockMovement.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return Success(movements);
    } catch (e) {
      _logger.e('Error getting product movements: $e');
      return Failure('فشل في جلب حركات المخزون');
    }
  }

  /// مراقبة حركات المخزون
  Stream<List<StockMovement>> watchStockMovements({
    String? productId,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('stock_movements')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              StockMovement.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // ==================== تنبيهات المخزون ====================

  Future<void> _checkStockAlerts(
      String productId, String productName, int currentStock) async {
    try {
      // جلب إعدادات المنتج
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return;

      final minStock = productDoc.data()?['minStock'] ?? 5;

      // التحقق من نفاد المخزون
      if (currentStock == 0) {
        await _createStockAlert(
          productId: productId,
          productName: productName,
          type: StockAlertType.outOfStock,
          currentStock: currentStock,
          threshold: minStock,
          message: 'نفد مخزون المنتج "$productName"',
        );
      }
      // التحقق من انخفاض المخزون
      else if (currentStock <= minStock) {
        await _createStockAlert(
          productId: productId,
          productName: productName,
          type: StockAlertType.lowStock,
          currentStock: currentStock,
          threshold: minStock,
          message:
              'المخزون منخفض للمنتج "$productName" (المتبقي: $currentStock)',
        );
      }
    } catch (e) {
      _logger.e('Error checking stock alerts: $e');
    }
  }

  Future<void> _createStockAlert({
    required String productId,
    required String productName,
    required StockAlertType type,
    required int currentStock,
    required int threshold,
    String? message,
  }) async {
    // التحقق من عدم وجود تنبيه مماثل غير مقروء
    final existing = await _firestore
        .collection('stock_alerts')
        .where('productId', isEqualTo: productId)
        .where('type', isEqualTo: type.index)
        .where('isRead', isEqualTo: false)
        .get();

    if (existing.docs.isNotEmpty) return;

    final alert = StockAlert(
      id: _firestore.collection('stock_alerts').doc().id,
      productId: productId,
      productName: productName,
      type: type,
      currentStock: currentStock,
      threshold: threshold,
      message: message,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('stock_alerts')
        .doc(alert.id)
        .set(alert.toJson());
  }

  /// الحصول على التنبيهات غير المقروءة
  Future<Result<List<StockAlert>>> getUnreadAlerts() async {
    try {
      final snapshot = await _firestore
          .collection('stock_alerts')
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final alerts =
          snapshot.docs.map((doc) => StockAlert.fromJson(doc.data())).toList();

      return Success(alerts);
    } catch (e) {
      _logger.e('Error getting stock alerts: $e');
      return Failure('فشل في جلب التنبيهات');
    }
  }

  /// مراقبة التنبيهات
  Stream<List<StockAlert>> watchStockAlerts({bool unreadOnly = true}) {
    Query query = _firestore
        .collection('stock_alerts')
        .orderBy('createdAt', descending: true);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StockAlert.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// تعليم تنبيه كمقروء
  Future<void> markAlertAsRead(String alertId) async {
    await _firestore.collection('stock_alerts').doc(alertId).update({
      'isRead': true,
    });
  }

  /// تعليم جميع التنبيهات كمقروءة
  Future<void> markAllAlertsAsRead() async {
    final batch = _firestore.batch();
    final alerts = await _firestore
        .collection('stock_alerts')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in alerts.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ==================== اقتراحات إعادة الطلب ====================

  /// الحصول على اقتراحات إعادة الطلب
  Future<Result<List<ReorderSuggestion>>> getReorderSuggestions() async {
    try {
      // جلب المنتجات منخفضة المخزون
      final productsSnapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final suggestions = <ReorderSuggestion>[];
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final productId = doc.id;
        final currentStock = data['totalStock'] ?? 0;
        final minStock = data['minStock'] ?? 5;
        final costPrice = (data['costPrice'] ?? 0).toDouble();
        final productName = data['name'] ?? '';

        // تخطي المنتجات ذات المخزون الكافي
        if (currentStock > minStock * 2) continue;

        // حساب متوسط المبيعات الشهرية
        final salesSnapshot = await _firestore
            .collection('invoices')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
            .get();

        int totalSold = 0;
        for (final invoice in salesSnapshot.docs) {
          final items = invoice.data()['items'] as List? ?? [];
          for (final item in items) {
            if (item['productId'] == productId) {
              totalSold += (item['quantity'] ?? 0) as int;
            }
          }
        }

        final avgDailySales = totalSold / 30;
        final daysUntilOutOfStock =
            avgDailySales > 0 ? (currentStock / avgDailySales).round() : 999;

        // حساب الكمية المقترحة (تغطية شهر + حد أمان)
        final suggestedQuantity =
            ((avgDailySales * 30) + minStock - currentStock).round();

        if (suggestedQuantity > 0) {
          suggestions.add(ReorderSuggestion(
            productId: productId,
            productName: productName,
            currentStock: currentStock,
            minStock: minStock,
            avgMonthlySales: totalSold,
            suggestedQuantity: suggestedQuantity,
            estimatedCost: suggestedQuantity.toDouble() * costPrice,
            daysUntilOutOfStock: daysUntilOutOfStock,
          ));
        }
      }

      // ترتيب حسب الأولوية
      suggestions.sort((a, b) {
        final priorityCompare = a.priority.index.compareTo(b.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return a.daysUntilOutOfStock.compareTo(b.daysUntilOutOfStock);
      });

      return Success(suggestions);
    } catch (e) {
      _logger.e('Error getting reorder suggestions: $e');
      return Failure('فشل في جلب اقتراحات إعادة الطلب');
    }
  }

  // ==================== جرد المخزون ====================

  /// إنشاء جلسة جرد جديدة
  Future<Result<InventoryCountSession>> startInventoryCount({
    required String name,
    required String startedBy,
  }) async {
    try {
      final session = InventoryCountSession(
        id: _firestore.collection('inventory_counts').doc().id,
        name: name,
        startedAt: DateTime.now(),
        startedBy: startedBy,
        status: InventoryCountStatus.inProgress,
      );

      await _firestore.collection('inventory_counts').doc(session.id).set({
        'id': session.id,
        'name': session.name,
        'startedAt': Timestamp.fromDate(session.startedAt),
        'startedBy': session.startedBy,
        'status': session.status.index,
        'results': [],
      });

      return Success(session);
    } catch (e) {
      _logger.e('Error starting inventory count: $e');
      return Failure('فشل في بدء جلسة الجرد');
    }
  }

  /// تسجيل نتيجة جرد منتج
  Future<Result<InventoryCountResult>> recordInventoryCount({
    required String sessionId,
    required String productId,
    required String productName,
    String? variantId,
    String? color,
    String? size,
    required int systemStock,
    required int actualStock,
    required String countedBy,
    String? notes,
  }) async {
    try {
      final result = InventoryCountResult(
        id: _firestore.collection('inventory_count_results').doc().id,
        productId: productId,
        productName: productName,
        variantId: variantId,
        color: color,
        size: size,
        systemStock: systemStock,
        actualStock: actualStock,
        countedBy: countedBy,
        countedAt: DateTime.now(),
        notes: notes,
      );

      // حفظ النتيجة
      await _firestore
          .collection('inventory_count_results')
          .doc(result.id)
          .set(result.toJson());

      // إضافة النتيجة للجلسة
      await _firestore.collection('inventory_counts').doc(sessionId).update({
        'results': FieldValue.arrayUnion([result.id]),
      });

      return Success(result);
    } catch (e) {
      _logger.e('Error recording inventory count: $e');
      return Failure('فشل في تسجيل الجرد');
    }
  }

  /// اعتماد نتيجة الجرد وتحديث المخزون
  Future<Result<void>> approveInventoryCount({
    required String resultId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    try {
      // جلب نتيجة الجرد
      final doc = await _firestore
          .collection('inventory_count_results')
          .doc(resultId)
          .get();
      if (!doc.exists) return Failure('نتيجة الجرد غير موجودة');

      final result = InventoryCountResult.fromJson(doc.data()!);

      if (result.hasDifference) {
        // تحديث المخزون
        // هذا يعتمد على بنية المنتج في قاعدة البيانات

        // تسجيل حركة مخزون
        await recordStockMovement(
          productId: result.productId,
          productName: result.productName,
          variantId: result.variantId,
          color: result.color,
          size: result.size,
          type: result.difference > 0
              ? StockMovementType.adjustment
              : StockMovementType.adjustment,
          reason: StockMovementReason.inventoryCount,
          quantity: result.difference.abs(),
          previousStock: result.systemStock,
          newStock: result.actualStock,
          referenceId: resultId,
          notes: 'تعديل جرد: ${result.notes ?? ""}',
          performedBy: approvedBy,
          performedByName: approvedByName,
        );
      }

      // تحديث حالة الاعتماد
      await _firestore
          .collection('inventory_count_results')
          .doc(resultId)
          .update({
        'isApproved': true,
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.now(),
      });

      return Success(null);
    } catch (e) {
      _logger.e('Error approving inventory count: $e');
      return Failure('فشل في اعتماد الجرد');
    }
  }

  /// إنهاء جلسة الجرد
  Future<Result<void>> completeInventoryCount({
    required String sessionId,
    required String completedBy,
  }) async {
    try {
      await _firestore.collection('inventory_counts').doc(sessionId).update({
        'completedAt': Timestamp.now(),
        'completedBy': completedBy,
        'status': InventoryCountStatus.completed.index,
      });

      return Success(null);
    } catch (e) {
      _logger.e('Error completing inventory count: $e');
      return Failure('فشل في إنهاء جلسة الجرد');
    }
  }

  /// الحصول على جلسات الجرد
  Future<Result<List<InventoryCountSession>>> getInventoryCountSessions({
    InventoryCountStatus? status,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('inventory_counts')
          .orderBy('startedAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.index);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final sessions = <InventoryCountSession>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        sessions.add(InventoryCountSession(
          id: data['id'],
          name: data['name'],
          startedAt: (data['startedAt'] as Timestamp).toDate(),
          completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
          startedBy: data['startedBy'],
          completedBy: data['completedBy'],
          status: InventoryCountStatus.values[data['status'] ?? 0],
        ));
      }

      return Success(sessions);
    } catch (e) {
      _logger.e('Error getting inventory count sessions: $e');
      return Failure('فشل في جلب جلسات الجرد');
    }
  }
}
