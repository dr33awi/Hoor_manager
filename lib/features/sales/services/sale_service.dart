// lib/features/sales/services/sale_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/base_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/logger_service.dart';
import '../models/sale_model.dart';

class SaleService extends BaseService {
  final FirebaseService _firebase = FirebaseService();
  final AuthService _auth = AuthService();
  final AuditService _audit = AuditService();
  final String _collection = AppConstants.salesCollection;

  static final SaleService _instance = SaleService._internal();
  factory SaleService() => _instance;
  SaleService._internal();

  /// إنشاء فاتورة جديدة
  Future<ServiceResult<SaleModel>> createSale(SaleModel sale) async {
    try {
      AppLogger.startOperation('إنشاء فاتورة');

      final invoiceNumber = await _generateInvoiceNumber();

      final newSale = sale.copyWith(
        invoiceNumber: invoiceNumber,
        userId: _auth.currentUserId ?? '',
        userName: _auth.currentUser?.name ?? 'غير معروف',
        createdAt: DateTime.now(),
      );

      final result = await _firebase.runTransaction((transaction) async {
        for (final item in newSale.items) {
          final productRef = _firebase.document(
            AppConstants.productsCollection,
            item.productId,
          );

          final productSnapshot = await transaction.get(productRef);
          if (!productSnapshot.exists) {
            throw Exception('المنتج ${item.productName} غير موجود');
          }

          final productData = productSnapshot.data()!;
          if (productData['isActive'] != true) {
            throw Exception('المنتج ${item.productName} غير متاح');
          }

          final inventoryKey = item.inventoryKey;
          final inventory =
              productData['inventory'] as Map<String, dynamic>? ?? {};
          final currentQty = inventory[inventoryKey] ?? 0;

          if (currentQty < item.quantity) {
            throw Exception(
              'الكمية غير كافية للمنتج ${item.productName} (${item.variant}). '
              'المتوفر: $currentQty، المطلوب: ${item.quantity}',
            );
          }

          transaction.update(productRef, {
            'inventory.$inventoryKey': currentQty - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final saleRef = _firebase.collection(_collection).doc();
        final saleWithId = newSale.copyWith(id: saleRef.id);
        transaction.set(saleRef, saleWithId.toMap());

        return saleWithId;
      });

      if (!result.success) {
        AppLogger.endOperation('إنشاء فاتورة', success: false);
        return ServiceResult.failure(result.error!);
      }

      await _audit.logSale(
        saleId: result.data!.id,
        invoiceNumber: result.data!.invoiceNumber,
        total: result.data!.total,
        itemsCount: result.data!.itemsCount,
      );

      AppLogger.endOperation('إنشاء فاتورة', success: true);
      return ServiceResult.success(result.data);
    } catch (e) {
      AppLogger.e('خطأ في إنشاء الفاتورة', error: e);
      return ServiceResult.failure(handleError(e));
    }
  }

  /// إلغاء فاتورة
  Future<ServiceResult<void>> cancelSale(
    String saleId, {
    String? reason,
  }) async {
    try {
      AppLogger.startOperation('إلغاء فاتورة');

      final result = await _firebase.runTransaction((transaction) async {
        final saleRef = _firebase.document(_collection, saleId);
        final saleSnapshot = await transaction.get(saleRef);

        if (!saleSnapshot.exists) {
          throw Exception('الفاتورة غير موجودة');
        }

        final sale = SaleModel.fromFirestore(saleSnapshot);

        if (sale.isCancelled) {
          throw Exception('الفاتورة ملغية بالفعل');
        }

        for (final item in sale.items) {
          final productRef = _firebase.document(
            AppConstants.productsCollection,
            item.productId,
          );

          final productSnapshot = await transaction.get(productRef);
          if (productSnapshot.exists) {
            final productData = productSnapshot.data()!;
            final inventory =
                productData['inventory'] as Map<String, dynamic>? ?? {};
            final currentQty = inventory[item.inventoryKey] ?? 0;

            transaction.update(productRef, {
              'inventory.${item.inventoryKey}': currentQty + item.quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        transaction.update(saleRef, {
          'status': AppConstants.saleStatusCancelled,
          'refundReason': reason,
          'refundedAt': FieldValue.serverTimestamp(),
          'refundedBy': _auth.currentUserId,
        });
      });

      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }

      await _audit.logCancelSale(
        saleId: saleId,
        invoiceNumber: '',
        reason: reason,
      );
      AppLogger.endOperation('إلغاء فاتورة', success: true);
      return ServiceResult.success();
    } catch (e) {
      AppLogger.e('خطأ في إلغاء الفاتورة', error: e);
      return ServiceResult.failure(handleError(e));
    }
  }

  /// الحصول على جميع المبيعات
  Future<ServiceResult<List<SaleModel>>> getAllSales({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final result = await _firebase.getAll(
        _collection,
        limit: limit ?? 500,
        startAfter: startAfter,
        queryBuilder: (ref) {
          return ref.orderBy('saleDate', descending: true);
        },
      );

      if (!result.success) return ServiceResult.failure(result.error!);

      var sales = result.data!.docs
          .map((doc) => SaleModel.fromFirestore(doc))
          .toList();

      if (startDate != null) {
        sales = sales
            .where(
              (s) =>
                  s.saleDate.isAfter(startDate) ||
                  s.saleDate.isAtSameMomentAs(startDate),
            )
            .toList();
      }
      if (endDate != null) {
        sales = sales
            .where(
              (s) =>
                  s.saleDate.isBefore(endDate) ||
                  s.saleDate.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (status != null) {
        sales = sales.where((s) => s.status == status).toList();
      }

      return ServiceResult.success(sales);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// Stream للمبيعات
  Stream<List<SaleModel>> streamSales({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firebase
        .streamCollection(
          _collection,
          limit: 500,
          queryBuilder: (ref) {
            return ref.orderBy('saleDate', descending: true);
          },
        )
        .map((snapshot) {
          var sales = snapshot.docs
              .map((doc) => SaleModel.fromFirestore(doc))
              .toList();

          if (startDate != null) {
            sales = sales
                .where(
                  (s) =>
                      s.saleDate.isAfter(startDate) ||
                      s.saleDate.isAtSameMomentAs(startDate),
                )
                .toList();
          }
          if (endDate != null) {
            sales = sales
                .where(
                  (s) =>
                      s.saleDate.isBefore(endDate) ||
                      s.saleDate.isAtSameMomentAs(endDate),
                )
                .toList();
          }

          return sales;
        });
  }

  /// تقرير المبيعات
  Future<ServiceResult<SalesReport>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await getAllSales(limit: 1000);

      if (!result.success) return ServiceResult.failure(result.error!);

      final filteredSales = result.data!.where((sale) {
        final isInDateRange =
            (sale.saleDate.isAfter(startDate) ||
                sale.saleDate.isAtSameMomentAs(startDate)) &&
            (sale.saleDate.isBefore(endDate) ||
                sale.saleDate.isAtSameMomentAs(endDate));
        final isCompleted = sale.status == AppConstants.saleStatusCompleted;
        return isInDateRange && isCompleted;
      }).toList();

      return ServiceResult.success(SalesReport.fromSales(filteredSales));
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// توليد رقم فاتورة
  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final prefix = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}';

    try {
      final result = await _firebase.getAll(
        _collection,
        limit: 1,
        queryBuilder: (ref) => ref.orderBy('createdAt', descending: true),
      );

      if (!result.success || result.data!.docs.isEmpty) return '$prefix-0001';

      final lastSale = SaleModel.fromFirestore(result.data!.docs.first);
      final parts = lastSale.invoiceNumber.split('-');
      if (parts.length >= 2) {
        final lastNumber = int.tryParse(parts.last) ?? 0;
        return '$prefix-${(lastNumber + 1).toString().padLeft(4, '0')}';
      }
      return '$prefix-0001';
    } catch (e) {
      return '$prefix-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }
}

/// تقرير المبيعات
class SalesReport {
  final int totalOrders;
  final int totalItems;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final double totalTax;
  final double averageOrderValue;
  final Map<String, int> topProducts;
  final Map<String, double> salesByPaymentMethod;

  SalesReport({
    required this.totalOrders,
    required this.totalItems,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.totalTax,
    required this.averageOrderValue,
    required this.topProducts,
    required this.salesByPaymentMethod,
  });

  factory SalesReport.fromSales(List<SaleModel> sales) {
    if (sales.isEmpty) {
      return SalesReport(
        totalOrders: 0,
        totalItems: 0,
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0,
        totalDiscount: 0,
        totalTax: 0,
        averageOrderValue: 0,
        topProducts: {},
        salesByPaymentMethod: {},
      );
    }

    int totalItems = 0;
    double totalRevenue = 0, totalCost = 0, totalDiscount = 0, totalTax = 0;
    final productCount = <String, int>{};
    final paymentMethods = <String, double>{};

    for (final sale in sales) {
      totalItems += sale.itemsCount;
      totalRevenue += sale.total;
      totalCost += sale.totalCost;
      totalDiscount += sale.discount;
      totalTax += sale.tax;

      for (final item in sale.items) {
        productCount[item.productName] =
            (productCount[item.productName] ?? 0) + item.quantity;
      }
      paymentMethods[sale.paymentMethod] =
          (paymentMethods[sale.paymentMethod] ?? 0) + sale.total;
    }

    final sortedProducts = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SalesReport(
      totalOrders: sales.length,
      totalItems: totalItems,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalRevenue - totalCost,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      averageOrderValue: totalRevenue / sales.length,
      topProducts: Map.fromEntries(sortedProducts.take(10)),
      salesByPaymentMethod: paymentMethods,
    );
  }
}
