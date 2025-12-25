import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/offline_service.dart';
import '../../../../core/utils/result.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/sales_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المبيعات مع دعم الأوفلاين
class SalesRepositoryImpl implements SalesRepository {
  final FirebaseFirestore _firestore;
  final ProductRepository _productRepository;
  final OfflineService _offlineService;

  SalesRepositoryImpl({
    FirebaseFirestore? firestore,
    required ProductRepository productRepository,
    OfflineService? offlineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _productRepository = productRepository,
        _offlineService = offlineService ?? OfflineService() {
    // تسجيل callback المزامنة
    _offlineService.onSyncInvoice = _syncInvoiceToFirestore;
  }

  /// مزامنة فاتورة إلى Firestore
  Future<bool> _syncInvoiceToFirestore(Map<String, dynamic> data) async {
    try {
      final invoiceData = Map<String, dynamic>.from(data);
      final localId = invoiceData['id'] as String;
      invoiceData.remove('id');

      // تحديث التاريخ
      invoiceData['saleDate'] = Timestamp.fromDate(
        DateTime.parse(invoiceData['saleDate']),
      );
      invoiceData['syncedAt'] = FieldValue.serverTimestamp();

      // إنشاء الفاتورة في Firestore
      await _salesCollection.add(invoiceData);

      // حذف الفاتورة من التخزين المحلي
      await _offlineService.removeOfflineInvoice(localId);

      return true;
    } catch (e) {
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _salesCollection =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _countersCollection =>
      _firestore.collection('counters');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Future<Result<InvoiceEntity>> createInvoice(InvoiceEntity invoice) async {
    try {
      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        return _createOfflineInvoice(invoice);
      }

      return await _firestore.runTransaction((transaction) async {
        // ========== مرحلة القراءة (يجب أن تكون أولاً) ==========

        // 1. قراءة جميع المنتجات
        final Map<String, DocumentSnapshot<Map<String, dynamic>>>
            productSnapshots = {};
        for (final item in invoice.items) {
          final productRef = _productsCollection.doc(item.productId);
          productSnapshots[item.productId] = await transaction.get(productRef);
        }

        // 2. قراءة العداد
        final counterRef = _countersCollection.doc('invoices');
        final counterSnap = await transaction.get(counterRef);

        // ========== مرحلة التحقق ==========

        // 3. التحقق من المخزون وتجهيز التحديثات
        final Map<String, Map<String, dynamic>> productUpdates = {};

        for (final item in invoice.items) {
          final productSnap = productSnapshots[item.productId]!;

          if (!productSnap.exists) {
            throw Exception('المنتج ${item.productName} غير موجود');
          }

          final productData = productSnap.data()!;
          final variants =
              List<Map<String, dynamic>>.from(productData['variants'] ?? []);
          final variantIndex =
              variants.indexWhere((v) => v['id'] == item.variantId);

          if (variantIndex == -1) {
            throw Exception('المتغير غير موجود للمنتج ${item.productName}');
          }

          final currentQty = variants[variantIndex]['quantity'] as int? ?? 0;
          if (currentQty < item.quantity) {
            throw Exception(
                'الكمية المطلوبة (${item.quantity}) غير متوفرة للمنتج ${item.productName}. المتوفر: $currentQty');
          }

          // تجهيز التحديث
          variants[variantIndex]['quantity'] = currentQty - item.quantity;
          productUpdates[item.productId] = {'variants': variants};
        }

        // ========== مرحلة الكتابة ==========

        // 4. تحديث المخزون لجميع المنتجات
        for (final entry in productUpdates.entries) {
          final productRef = _productsCollection.doc(entry.key);
          transaction.update(productRef, {
            'variants': entry.value['variants'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 5. حفظ الفاتورة
        final model = InvoiceModel.fromEntity(invoice);
        final docRef = _salesCollection.doc();
        transaction.set(docRef, model.toMap());

        // 6. تحديث العداد
        final currentCount =
            counterSnap.exists ? (counterSnap.data()?['count'] ?? 0) : 0;
        transaction.set(
            counterRef, {'count': currentCount + 1}, SetOptions(merge: true));

        return Success(model.copyWith(id: docRef.id));
      });
    } catch (e) {
      // في حالة فشل الاتصال، جرب الحفظ أوفلاين
      if (e.toString().contains('network') ||
          e.toString().contains('unavailable') ||
          e.toString().contains('UNAVAILABLE')) {
        return _createOfflineInvoice(invoice);
      }
      return Failure('فشل إنشاء الفاتورة: $e');
    }
  }

  /// إنشاء فاتورة أوفلاين
  Future<Result<InvoiceEntity>> _createOfflineInvoice(
      InvoiceEntity invoice) async {
    try {
      // توليد ID محلي
      final localId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

      // التحقق من المخزون محلياً وخصمه
      for (final item in invoice.items) {
        final cachedProducts = _offlineService.getCachedProducts();
        final productIndex =
            cachedProducts.indexWhere((p) => p['id'] == item.productId);

        if (productIndex == -1) {
          // المنتج غير موجود في الكاش، تابع (ربما يكون منتج محلي)
          continue;
        }

        final productData =
            Map<String, dynamic>.from(cachedProducts[productIndex]);
        final variants =
            List<Map<String, dynamic>>.from(productData['variants'] ?? []);
        final variantIndex =
            variants.indexWhere((v) => v['id'] == item.variantId);

        if (variantIndex != -1) {
          final currentQty = variants[variantIndex]['quantity'] as int? ?? 0;
          if (currentQty < item.quantity) {
            return Failure(
                'الكمية المطلوبة (${item.quantity}) غير متوفرة للمنتج ${item.productName}. المتوفر: $currentQty');
          }

          // خصم الكمية محلياً
          variants[variantIndex]['quantity'] = currentQty - item.quantity;
          productData['variants'] = variants;
          await _offlineService.cacheProduct(productData);
        }
      }

      // إنشاء الفاتورة محلياً
      final offlineInvoice = InvoiceModel.fromEntity(invoice).copyWith(
        id: localId,
      );

      // حفظ الفاتورة محلياً - استخدام toOfflineMap بدلاً من toMap
      final invoiceMap = InvoiceModel.fromEntity(offlineInvoice).toOfflineMap();
      invoiceMap['id'] = localId;
      invoiceMap['isOffline'] = true;

      await _offlineService.saveOfflineInvoice(invoiceMap);

      // إضافة عملية معلقة للمزامنة
      await _offlineService.addPendingOperation(
        PendingOperation(
          id: localId,
          type: PendingOperationType.createInvoice,
          data: invoiceMap,
          createdAt: DateTime.now(),
        ),
      );

      return Success(offlineInvoice);
    } catch (e) {
      return Failure('فشل إنشاء الفاتورة أوفلاين: $e');
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
      List<InvoiceEntity> allInvoices = [];

      // التحقق من حالة الاتصال
      if (_offlineService.isOnline) {
        Query<Map<String, dynamic>> query = _salesCollection;

        if (startDate != null) {
          query = query.where('saleDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }

        if (endDate != null) {
          query = query.where('saleDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));
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
        allInvoices =
            snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();
      }

      // إضافة الفواتير المحلية (الأوفلاين)
      final offlineInvoices = _offlineService.getOfflineInvoices();
      for (final invoiceData in offlineInvoices) {
        try {
          final saleDate = DateTime.tryParse(invoiceData['saleDate'] ?? '');

          // تطبيق الفلاتر
          if (startDate != null &&
              saleDate != null &&
              saleDate.isBefore(startDate)) continue;
          if (endDate != null && saleDate != null && saleDate.isAfter(endDate))
            continue;
          if (status != null && invoiceData['status'] != status.value) continue;
          if (soldBy != null && invoiceData['soldBy'] != soldBy) continue;

          // إنشاء نسخة من البيانات مع تاريخ صحيح
          final processedData = Map<String, dynamic>.from(invoiceData);
          if (saleDate != null) {
            processedData['saleDate'] = Timestamp.fromDate(saleDate);
          }

          final offlineInvoice = InvoiceModel.fromMap(
            processedData,
            invoiceData['id'] ?? '',
          );
          allInvoices.add(offlineInvoice);
        } catch (e) {
          // تجاهل الفواتير التالفة
          continue;
        }
      }

      // ترتيب جميع الفواتير
      allInvoices.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      // تطبيق الحد
      if (limit != null && allInvoices.length > limit) {
        allInvoices = allInvoices.take(limit).toList();
      }

      return Success(allInvoices);
    } catch (e) {
      // في حالة الخطأ، استخدم الفواتير المحلية فقط
      return _getOfflineInvoicesOnly(
        startDate: startDate,
        endDate: endDate,
        status: status,
        soldBy: soldBy,
        limit: limit,
      );
    }
  }

  /// الحصول على الفواتير المحلية فقط
  Result<List<InvoiceEntity>> _getOfflineInvoicesOnly({
    DateTime? startDate,
    DateTime? endDate,
    InvoiceStatus? status,
    String? soldBy,
    int? limit,
  }) {
    try {
      final offlineInvoices = _offlineService.getOfflineInvoices();
      List<InvoiceEntity> invoices = [];

      for (final invoiceData in offlineInvoices) {
        try {
          final saleDate = DateTime.tryParse(invoiceData['saleDate'] ?? '');

          // تطبيق الفلاتر
          if (startDate != null &&
              saleDate != null &&
              saleDate.isBefore(startDate)) continue;
          if (endDate != null && saleDate != null && saleDate.isAfter(endDate))
            continue;
          if (status != null && invoiceData['status'] != status.value) continue;
          if (soldBy != null && invoiceData['soldBy'] != soldBy) continue;

          final processedData = Map<String, dynamic>.from(invoiceData);
          if (saleDate != null) {
            processedData['saleDate'] = Timestamp.fromDate(saleDate);
          }

          final offlineInvoice = InvoiceModel.fromMap(
            processedData,
            invoiceData['id'] ?? '',
          );
          invoices.add(offlineInvoice);
        } catch (e) {
          continue;
        }
      }

      invoices.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      if (limit != null && invoices.length > limit) {
        invoices = invoices.take(limit).toList();
      }

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
      // التحقق إذا كانت فاتورة أوفلاين
      if (invoiceId.startsWith('offline_')) {
        // حذف الفاتورة المحلية
        await _offlineService.removeOfflineInvoice(invoiceId);
        await _offlineService.removePendingOperation(invoiceId);

        // استرجاع المخزون المحلي
        final offlineInvoices = _offlineService.getOfflineInvoices();
        final invoiceData = offlineInvoices.firstWhere(
          (inv) => inv['id'] == invoiceId,
          orElse: () => <String, dynamic>{},
        );

        if (invoiceData.isNotEmpty) {
          final items = invoiceData['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final productId = item['productId'] as String?;
            final variantId = item['variantId'] as String?;
            final quantity = item['quantity'] as int? ?? 0;

            if (productId != null && variantId != null) {
              await _productRepository.addStock(
                productId: productId,
                variantId: variantId,
                quantity: quantity,
              );
            }
          }
        }

        return const Success(null);
      }

      // فاتورة عادية - تحتاج اتصال
      if (!_offlineService.isOnline) {
        return const Failure('لا يمكن إلغاء فاتورة متزامنة بدون اتصال');
      }

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
      final datePrefix =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        // توليد رقم فاتورة محلي
        final offlineInvoices = _offlineService.getOfflineInvoices();
        final todayOfflineCount = offlineInvoices.where((inv) {
          final saleDate = DateTime.tryParse(inv['saleDate'] ?? '');
          return saleDate != null &&
              saleDate.year == now.year &&
              saleDate.month == now.month &&
              saleDate.day == now.day;
        }).length;

        final offlineNumber =
            'OFF-$datePrefix-${(todayOfflineCount + 1).toString().padLeft(4, '0')}';
        return Success(offlineNumber);
      }

      // الحصول على عدد فواتير اليوم
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _salesCollection
          .where('saleDateDay', isEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final todayCount = snapshot.docs.length + 1;
      final invoiceNumber =
          'INV-$datePrefix-${todayCount.toString().padLeft(4, '0')}';

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
      query = query.where('saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('saleDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
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
  Stream<InvoiceEntity?> watchInvoice(String invoiceId) {
    return _salesCollection.doc(invoiceId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return InvoiceModel.fromDocument(snapshot);
    });
  }

  @override
  Future<Result<DailySalesStats>> getDailySalesStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);

      final snapshot = await _salesCollection
          .where('saleDateDay', isEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final invoices =
          snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();

      return Success(DailySalesStats.fromInvoices(date, invoices));
    } catch (e) {
      return Failure('فشل جلب إحصائيات اليوم: $e');
    }
  }

  @override
  Future<Result<MonthlySalesStats>> getMonthlySalesStats(
      int year, int month) async {
    try {
      final monthStr = '$year-${month.toString().padLeft(2, '0')}';

      final snapshot =
          await _salesCollection.where('saleMonth', isEqualTo: monthStr).get();

      final invoices =
          snapshot.docs.map((doc) => InvoiceModel.fromDocument(doc)).toList();

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
        totalDiscount:
            completedInvoices.fold(0, (sum, i) => sum + i.discountAmount),
        cancelledCount: cancelledInvoices.length,
        dailyStats: dailyStats,
      ));
    } catch (e) {
      return Failure('فشل جلب إحصائيات الشهر: $e');
    }
  }
}
