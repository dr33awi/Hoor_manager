import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المشتريات
class PurchaseRepositoryImpl implements PurchaseRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

  PurchaseRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _purchasesCollection =>
      _firestore.collection('purchases');

  @override
  Stream<List<PurchaseInvoiceEntity>> watchPurchases() {
    return _purchasesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<PurchaseInvoiceEntity>> getPurchaseById(String id) async {
    try {
      final doc = await _purchasesCollection.doc(id).get();
      if (!doc.exists) {
        return Failure('الفاتورة غير موجودة');
      }
      return Success(PurchaseInvoiceModel.fromDocument(doc));
    } catch (e) {
      _logger.e('Error getting purchase: $e');
      return Failure('خطأ في جلب الفاتورة');
    }
  }

  @override
  Stream<List<PurchaseInvoiceEntity>> watchPurchasesBySupplier(
      String supplierId) {
    return _purchasesCollection
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<PurchaseInvoiceEntity>> watchPurchasesByStatus(
      PurchaseInvoiceStatus status) {
    return _purchasesCollection
        .where('status', isEqualTo: status.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<PurchaseInvoiceEntity>> watchUnpaidPurchases() {
    return _purchasesCollection
        .where('paymentStatus', whereIn: [
          PurchasePaymentStatus.unpaid.name,
          PurchasePaymentStatus.partiallyPaid.name,
        ])
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<List<PurchaseInvoiceEntity>>> searchPurchases(
      String query) async {
    try {
      // البحث برقم الفاتورة
      final snapshot = await _purchasesCollection
          .where('invoiceNumber', isGreaterThanOrEqualTo: query)
          .where('invoiceNumber', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final purchases = snapshot.docs
          .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
          .toList();
      return Success(purchases);
    } catch (e) {
      _logger.e('Error searching purchases: $e');
      return Failure('خطأ في البحث');
    }
  }

  @override
  Future<Result<List<PurchaseInvoiceEntity>>> getPurchasesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _purchasesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      final purchases = snapshot.docs
          .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
          .toList();
      return Success(purchases);
    } catch (e) {
      _logger.e('Error getting purchases by date: $e');
      return Failure('خطأ في جلب الفواتير');
    }
  }

  @override
  Future<Result<PurchaseInvoiceEntity>> createPurchase(
      PurchaseInvoiceEntity purchase) async {
    try {
      final model = PurchaseInvoiceModel.fromEntity(purchase);
      final docRef = await _purchasesCollection.add(model.toMap());

      final newPurchase = purchase.copyWith(id: docRef.id);
      _logger.i('Purchase created: ${docRef.id}');
      return Success(newPurchase);
    } catch (e) {
      _logger.e('Error creating purchase: $e');
      return Failure('خطأ في إنشاء الفاتورة');
    }
  }

  @override
  Future<Result<PurchaseInvoiceEntity>> updatePurchase(
      PurchaseInvoiceEntity purchase) async {
    try {
      final model = PurchaseInvoiceModel.fromEntity(purchase);
      await _purchasesCollection.doc(purchase.id).update(model.toMap());

      _logger.i('Purchase updated: ${purchase.id}');
      return Success(purchase);
    } catch (e) {
      _logger.e('Error updating purchase: $e');
      return Failure('خطأ في تحديث الفاتورة');
    }
  }

  @override
  Future<Result<void>> deletePurchase(String id) async {
    try {
      await _purchasesCollection.doc(id).delete();
      _logger.i('Purchase deleted: $id');
      return Success(null);
    } catch (e) {
      _logger.e('Error deleting purchase: $e');
      return Failure('خطأ في حذف الفاتورة');
    }
  }

  @override
  Future<Result<void>> updatePurchaseStatus({
    required String id,
    required PurchaseInvoiceStatus status,
  }) async {
    try {
      await _purchasesCollection.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Success(null);
    } catch (e) {
      _logger.e('Error updating status: $e');
      return Failure('خطأ في تحديث الحالة');
    }
  }

  @override
  Future<Result<void>> recordPayment({
    required String purchaseId,
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    try {
      final doc = await _purchasesCollection.doc(purchaseId).get();
      if (!doc.exists) {
        return Failure('الفاتورة غير موجودة');
      }

      final purchase = PurchaseInvoiceModel.fromDocument(doc);
      final newPaidAmount = purchase.paidAmount + amount;

      PurchasePaymentStatus newStatus;
      if (newPaidAmount >= purchase.total) {
        newStatus = PurchasePaymentStatus.paid;
      } else if (newPaidAmount > 0) {
        newStatus = PurchasePaymentStatus.partiallyPaid;
      } else {
        newStatus = PurchasePaymentStatus.unpaid;
      }

      await _purchasesCollection.doc(purchaseId).update({
        'paidAmount': newPaidAmount,
        'paymentStatus': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Success(null);
    } catch (e) {
      _logger.e('Error recording payment: $e');
      return Failure('خطأ في تسجيل الدفعة');
    }
  }

  @override
  Future<Result<void>> receiveItems({
    required String purchaseId,
    required Map<String, int> receivedQuantities,
  }) async {
    try {
      final doc = await _purchasesCollection.doc(purchaseId).get();
      if (!doc.exists) {
        return Failure('الفاتورة غير موجودة');
      }

      final purchase = PurchaseInvoiceModel.fromDocument(doc);
      final updatedItems = purchase.items.map((item) {
        final received = receivedQuantities[item.id] ?? 0;
        return item.copyWith(
          receivedQuantity: item.receivedQuantity + received,
        );
      }).toList();

      // تحديد حالة الفاتورة
      final allReceived = updatedItems.every((item) => item.isFullyReceived);
      final someReceived =
          updatedItems.any((item) => item.receivedQuantity > 0);

      PurchaseInvoiceStatus newStatus;
      if (allReceived) {
        newStatus = PurchaseInvoiceStatus.received;
      } else if (someReceived) {
        newStatus = PurchaseInvoiceStatus.partiallyReceived;
      } else {
        newStatus = purchase.status;
      }

      await _purchasesCollection.doc(purchaseId).update({
        'items': updatedItems
            .map((item) => PurchaseItemModel.fromEntity(item).toMap())
            .toList(),
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Success(null);
    } catch (e) {
      _logger.e('Error receiving items: $e');
      return Failure('خطأ في استلام البضاعة');
    }
  }

  @override
  Future<String> generateInvoiceNumber() async {
    try {
      final now = DateTime.now();
      final prefix = 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}';

      final snapshot = await _purchasesCollection
          .where('invoiceNumber', isGreaterThanOrEqualTo: prefix)
          .where('invoiceNumber', isLessThanOrEqualTo: '$prefix\uf8ff')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastNumber =
            snapshot.docs.first.data()['invoiceNumber'] as String;
        final parts = lastNumber.split('-');
        if (parts.length >= 2) {
          nextNumber = (int.tryParse(parts.last) ?? 0) + 1;
        }
      }

      return '$prefix-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      _logger.e('Error generating invoice number: $e');
      return 'PUR-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  Future<Result<PurchaseStats>> getPurchaseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _purchasesCollection;

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final purchases = snapshot.docs
          .map((doc) => PurchaseInvoiceModel.fromDocument(doc))
          .toList();

      final stats = PurchaseStats(
        totalPurchases: purchases.length,
        totalAmount: purchases.fold(0, (sum, p) => sum + p.total),
        totalPaid: purchases.fold(0, (sum, p) => sum + p.paidAmount),
        totalUnpaid: purchases.fold(0, (sum, p) => sum + p.remainingAmount),
        pendingOrders: purchases
            .where((p) =>
                p.status == PurchaseInvoiceStatus.pending ||
                p.status == PurchaseInvoiceStatus.approved)
            .length,
      );

      return Success(stats);
    } catch (e) {
      _logger.e('Error getting stats: $e');
      return Failure('خطأ في جلب الإحصائيات');
    }
  }
}
