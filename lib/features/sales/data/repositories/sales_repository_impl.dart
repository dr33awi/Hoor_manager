import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/sales_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المبيعات
class SalesRepositoryImpl implements SalesRepository {
  final FirebaseFirestore _firestore;
  final ProductRepository _productRepository;

  SalesRepositoryImpl({
    FirebaseFirestore? firestore,
    required ProductRepository productRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _productRepository = productRepository;

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _countersCollection =>
      _firestore.collection('counters');

  @override
  Future<Result<InvoiceEntity>> createInvoice(InvoiceEntity invoice) async {
    try {
      return _firestore.runTransaction((transaction) async {
        // 1. خصم المخزون لكل عنصر
        for (final item in invoice.items) {
          await _productRepository.deductStock(
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
          );
        }

        // 2. حفظ الفاتورة
        final model = InvoiceModel.fromEntity(invoice);
        final docRef = _salesCollection.doc();
        transaction.set(docRef, model.toMap());

        // 3. تحديث العداد
        final counterRef = _countersCollection.doc('invoices');
        final counterSnap = await transaction.get(counterRef);
        final currentCount = counterSnap.exists 
            ? (counterSnap.data()?['count'] ?? 0) 
            : 0;
        transaction.set(counterRef, {'count': currentCount + 1}, SetOptions(merge: true));

        return Success(model.copyWith(id: docRef.id));
      });
    } catch (e) {
      return Failure('فشل إنشاء الفاتورة: $e');
    }
  }

  @override
  Future<Result<InvoiceEntity>> getInvoiceById(String id) async {
    try {
      final doc = await _salesCollection.doc(id).get();
      if (!doc.exists) {
        return const Failure('الفاتورة غير موجودة');
      }
      return Success(InvoiceModel.fromDocument(doc));
    } catch (e) {
      return Failure('فشل جلب الفاتورة: $e');
    }
  }

  @override
  Future<Result<InvoiceEntity>> getInvoiceByNumber(String invoiceNumber) async {
    try {
      final snapshot = await _salesCollection
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Failure('الفاتورة غير موجودة');
      }

      return Success(InvoiceModel.fromDocument(snapshot.docs.first));
    } catch (e) {
      return Failure('فشل البحث عن الفاتورة: $e');
    }
  }

  @override
  Future<Result<List<InvoiceEntity>>> getInvoices({
    DateTime? startDate,
    DateTime? endDate,
    InvoiceStatus? status,
    String? soldBy,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _salesCollection;

      if (startDate != null) {
        query = query.where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      if (soldBy != null) {
        query = query.where('soldBy', isEqualTo: soldBy);
      }

      query = query.orderBy('saleDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromDocument(doc))
          .toList();

      return Success(invoices);
    } catch (e) {
      return Failure('فشل جلب الفواتير: $e');
    }
  }

  @override
  Future<Result<List<InvoiceEntity>>> getTodayInvoices() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getInvoices(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Future<Result<void>> cancelInvoice({
    required String invoiceId,
    required String cancelledBy,
    String? reason,
  }) async {
    try {
      return _firestore.runTransaction((transaction) async {
        final docRef = _salesCollection.doc(invoiceId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('الفاتورة غير موجودة');
        }

        final invoice = InvoiceModel.fromDocument(snapshot);

        if (invoice.isCancelled) {
          throw Exception('الفاتورة ملغاة بالفعل');
        }

        // 1. استرجاع المخزون
        for (final item in invoice.items) {
          await _productRepository.addStock(
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
          );
        }

        // 2. تحديث حالة الفاتورة
        transaction.update(docRef, {
          'status': InvoiceStatus.cancelled.value,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': cancelledBy,
          'cancellationReason': reason,
        });

        return const Success(null);
      });
    } catch (e) {
      return Failure('فشل إلغاء الفاتورة: $e');
    }
  }

  @override
  Future<Result<String>> generateInvoiceNumber() async {
    try {
      final now = DateTime.now();
      final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // الحصول على عدد فواتير اليوم
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _salesCollection
          .where('saleDateDay', isEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final todayCount = snapshot.docs.length + 1;
      final invoiceNumber = 'INV-$datePrefix-${todayCount.toString().padLeft(4, '0')}';

      return Success(invoiceNumber);
    } catch (e) {
      // في حالة الخطأ، نولد رقم عشوائي
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return Success('INV-$timestamp');
    }
  }

  @override
  Stream<List<InvoiceEntity>> watchInvoices({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _salesCollection;

    if (startDate != null) {
      query = query.where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('saleDate', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => InvoiceModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Stream<List<InvoiceEntity>> watchTodayInvoices() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _salesCollection
        .where('saleDateDay', isEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvoiceModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Future<Result<DailySalesStats>> getDailySalesStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      
      final snapshot = await _salesCollection
          .where('saleDateDay', isEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromDocument(doc))
          .toList();

      return Success(DailySalesStats.fromInvoices(date, invoices));
    } catch (e) {
      return Failure('فشل جلب إحصائيات اليوم: $e');
    }
  }

  @override
  Future<Result<MonthlySalesStats>> getMonthlySalesStats(int year, int month) async {
    try {
      final monthStr = '$year-${month.toString().padLeft(2, '0')}';
      
      final snapshot = await _salesCollection
          .where('saleMonth', isEqualTo: monthStr)
          .get();

      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromDocument(doc))
          .toList();

      final completedInvoices = invoices.where((i) => i.isCompleted).toList();
      final cancelledInvoices = invoices.where((i) => i.isCancelled).toList();

      // تجميع الإحصائيات اليومية
      final Map<int, List<InvoiceEntity>> dailyInvoices = {};
      for (final invoice in invoices) {
        final day = invoice.saleDate.day;
        dailyInvoices[day] = [...(dailyInvoices[day] ?? []), invoice];
      }

      final dailyStats = dailyInvoices.entries.map((entry) {
        final date = DateTime(year, month, entry.key);
        return DailySalesStats.fromInvoices(date, entry.value);
      }).toList();

      return Success(MonthlySalesStats(
        year: year,
        month: month,
        invoiceCount: completedInvoices.length,
        itemCount: completedInvoices.fold(0, (sum, i) => sum + i.itemCount),
        totalSales: completedInvoices.fold(0, (sum, i) => sum + i.total),
        totalCost: completedInvoices.fold(0, (sum, i) => sum + i.totalCost),
        totalProfit: completedInvoices.fold(0, (sum, i) => sum + i.profit),
        totalDiscount: completedInvoices.fold(0, (sum, i) => sum + i.discountAmount),
        cancelledCount: cancelledInvoices.length,
        dailyStats: dailyStats,
      ));
    } catch (e) {
      return Failure('فشل جلب إحصائيات الشهر: $e');
    }
  }
}
