import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع السندات المالية
class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

  PaymentRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _firestore.collection('payments');

  @override
  Stream<List<PaymentVoucherEntity>> watchPayments() {
    return _paymentsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentVoucherModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<PaymentVoucherEntity>> getPaymentById(String id) async {
    try {
      final doc = await _paymentsCollection.doc(id).get();
      if (!doc.exists) {
        return Failure('السند غير موجود');
      }
      return Success(PaymentVoucherModel.fromDocument(doc));
    } catch (e) {
      _logger.e('Error getting payment: $e');
      return Failure('خطأ في جلب السند');
    }
  }

  @override
  Stream<List<PaymentVoucherEntity>> watchPaymentsByCustomer(
      String customerId) {
    return _paymentsCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentVoucherModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<PaymentVoucherEntity>> watchPaymentsBySupplier(
      String supplierId) {
    return _paymentsCollection
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentVoucherModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<PaymentVoucherEntity>> watchReceipts() {
    return _paymentsCollection
        .where('type', isEqualTo: PaymentVoucherType.receipt.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentVoucherModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<PaymentVoucherEntity>> watchPaymentVouchers() {
    return _paymentsCollection
        .where('type', isEqualTo: PaymentVoucherType.payment.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentVoucherModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<List<PaymentVoucherEntity>>> searchPayments(
      String query) async {
    try {
      final snapshot = await _paymentsCollection
          .where('voucherNumber', isGreaterThanOrEqualTo: query)
          .where('voucherNumber', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentVoucherModel.fromDocument(doc))
          .toList();
      return Success(payments);
    } catch (e) {
      _logger.e('Error searching payments: $e');
      return Failure('خطأ في البحث');
    }
  }

  @override
  Future<Result<List<PaymentVoucherEntity>>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    PaymentVoucherType? type,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _paymentsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      final payments = snapshot.docs
          .map((doc) => PaymentVoucherModel.fromDocument(doc))
          .toList();
      return Success(payments);
    } catch (e) {
      _logger.e('Error getting payments by date: $e');
      return Failure('خطأ في جلب السندات');
    }
  }

  @override
  Future<Result<PaymentVoucherEntity>> createPayment(
      PaymentVoucherEntity payment) async {
    try {
      final model = PaymentVoucherModel.fromEntity(payment);
      final docRef = await _paymentsCollection.add(model.toMap());

      final newPayment = payment.copyWith(id: docRef.id);
      _logger.i('Payment created: ${docRef.id}');
      return Success(newPayment);
    } catch (e) {
      _logger.e('Error creating payment: $e');
      return Failure('خطأ في إنشاء السند');
    }
  }

  @override
  Future<Result<PaymentVoucherEntity>> updatePayment(
      PaymentVoucherEntity payment) async {
    try {
      final model = PaymentVoucherModel.fromEntity(payment);
      await _paymentsCollection.doc(payment.id).update(model.toMap());

      _logger.i('Payment updated: ${payment.id}');
      return Success(payment);
    } catch (e) {
      _logger.e('Error updating payment: $e');
      return Failure('خطأ في تحديث السند');
    }
  }

  @override
  Future<Result<void>> deletePayment(String id) async {
    try {
      await _paymentsCollection.doc(id).delete();
      _logger.i('Payment deleted: $id');
      return Success(null);
    } catch (e) {
      _logger.e('Error deleting payment: $e');
      return Failure('خطأ في حذف السند');
    }
  }

  @override
  Future<Result<void>> updatePaymentStatus({
    required String id,
    required PaymentVoucherStatus status,
    String? approvedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == PaymentVoucherStatus.approved && approvedBy != null) {
        updateData['approvedBy'] = approvedBy;
        updateData['approvedAt'] = FieldValue.serverTimestamp();
      }

      await _paymentsCollection.doc(id).update(updateData);
      return Success(null);
    } catch (e) {
      _logger.e('Error updating status: $e');
      return Failure('خطأ في تحديث الحالة');
    }
  }

  @override
  Future<String> generateVoucherNumber(PaymentVoucherType type) async {
    try {
      final now = DateTime.now();
      final prefix = type == PaymentVoucherType.receipt ? 'RCV' : 'PAY';
      final datePrefix =
          '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}';

      final snapshot = await _paymentsCollection
          .where('voucherNumber', isGreaterThanOrEqualTo: datePrefix)
          .where('voucherNumber', isLessThanOrEqualTo: '$datePrefix\uf8ff')
          .orderBy('voucherNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastNumber =
            snapshot.docs.first.data()['voucherNumber'] as String;
        final parts = lastNumber.split('-');
        if (parts.length >= 2) {
          nextNumber = (int.tryParse(parts.last) ?? 0) + 1;
        }
      }

      return '$datePrefix-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      _logger.e('Error generating voucher number: $e');
      final prefix = type == PaymentVoucherType.receipt ? 'RCV' : 'PAY';
      return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  Future<Result<PaymentStats>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _paymentsCollection.where('status',
          isEqualTo: PaymentVoucherStatus.posted.name);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final payments = snapshot.docs
          .map((doc) => PaymentVoucherModel.fromDocument(doc))
          .toList();

      final receipts = payments.where((p) => p.isReceipt).toList();
      final paymentVouchers = payments.where((p) => p.isPayment).toList();

      final receiptsAmount = receipts.fold(0.0, (sum, p) => sum + p.amount);
      final paymentsAmount =
          paymentVouchers.fold(0.0, (sum, p) => sum + p.amount);

      final stats = PaymentStats(
        totalReceipts: receipts.length,
        totalPayments: paymentVouchers.length,
        receiptsAmount: receiptsAmount,
        paymentsAmount: paymentsAmount,
        netCashFlow: receiptsAmount - paymentsAmount,
      );

      return Success(stats);
    } catch (e) {
      _logger.e('Error getting stats: $e');
      return Failure('خطأ في جلب الإحصائيات');
    }
  }
}
