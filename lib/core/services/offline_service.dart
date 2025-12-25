import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// أنواع العمليات المعلقة
enum PendingOperationType {
  createInvoice,
  updateProduct,
  updateStock,
  addProduct,
  deleteProduct,
}

/// عملية معلقة للمزامنة
class PendingOperation {
  final String id;
  final PendingOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: PendingOperationType.values[json['type']],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// خدمة العمل بدون إنترنت
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final _logger = Logger();
  final _connectivity = Connectivity();

  // Hive boxes
  static const String _pendingOpsBox = 'pending_operations';
  static const String _cachedDataBox = 'cached_data';
  static const String _offlineInvoicesBox = 'offline_invoices';
  static const String _offlineProductsBox = 'offline_products';

  Box<String>? _pendingBox;
  Box<String>? _cacheBox;
  Box<String>? _invoicesBox;
  Box<String>? _productsBox;

  // Stream controllers
  final _connectivityController = StreamController<bool>.broadcast();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  StreamSubscription? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;

  /// Stream لحالة الاتصال
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Stream لحالة المزامنة
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// هل متصل بالإنترنت
  bool get isOnline => _isOnline;

  /// هل يتم المزامنة حالياً
  bool get isSyncing => _isSyncing;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    // فتح صناديق Hive
    _pendingBox = await Hive.openBox<String>(_pendingOpsBox);
    _cacheBox = await Hive.openBox<String>(_cachedDataBox);
    _invoicesBox = await Hive.openBox<String>(_offlineInvoicesBox);
    _productsBox = await Hive.openBox<String>(_offlineProductsBox);

    // التحقق من حالة الاتصال الأولية
    final result = await _connectivity.checkConnectivity();
    _updateConnectivity(result);

    // الاستماع لتغييرات الاتصال
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );

    _logger.i('OfflineService initialized');
  }

  void _updateConnectivity(List<ConnectivityResult> result) {
    final wasOnline = _isOnline;
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);

    _connectivityController.add(_isOnline);

    // إذا عاد الاتصال، ابدأ المزامنة بعد تأخير بسيط لضمان تهيئة callbacks
    if (!wasOnline && _isOnline) {
      _logger.i('Connection restored, starting sync in 2 seconds...');
      Future.delayed(const Duration(seconds: 2), () {
        if (_isOnline) {
          syncPendingOperations();
        }
      });
    }
  }

  // ==================== إدارة العمليات المعلقة ====================

  /// إضافة عملية معلقة
  Future<void> addPendingOperation(PendingOperation operation) async {
    if (_pendingBox == null) return;

    await _pendingBox!.put(operation.id, jsonEncode(operation.toJson()));
    _logger.d('Added pending operation: ${operation.type}');
  }

  /// الحصول على جميع العمليات المعلقة
  List<PendingOperation> getPendingOperations() {
    if (_pendingBox == null) return [];

    return _pendingBox!.values.map((json) {
      return PendingOperation.fromJson(jsonDecode(json));
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// حذف عملية معلقة
  Future<void> removePendingOperation(String id) async {
    if (_pendingBox == null) return;
    await _pendingBox!.delete(id);
  }

  /// عدد العمليات المعلقة
  int get pendingOperationsCount => _pendingBox?.length ?? 0;

  // ==================== مزامنة البيانات ====================

  /// مزامنة العمليات المعلقة
  Future<SyncResult> syncPendingOperations() async {
    if (!_isOnline || _isSyncing) {
      return SyncResult(
        success: false,
        message: _isSyncing ? 'المزامنة قيد التنفيذ' : 'لا يوجد اتصال',
      );
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    final operations = getPendingOperations();
    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    for (final op in operations) {
      try {
        final success = await _executeOperation(op);
        if (success) {
          await removePendingOperation(op.id);
          successCount++;
        } else {
          op.retryCount++;
          if (op.retryCount >= 3) {
            errors.add('فشل ${op.type}: تجاوز الحد الأقصى للمحاولات');
            await removePendingOperation(op.id);
          } else {
            await addPendingOperation(op);
          }
          failedCount++;
        }
      } catch (e) {
        _logger.e('Sync error for ${op.type}: $e');
        failedCount++;
        errors.add('خطأ في ${op.type}: $e');
      }
    }

    _isSyncing = false;
    _syncStatusController.add(
      failedCount > 0 ? SyncStatus.error : SyncStatus.completed,
    );

    return SyncResult(
      success: failedCount == 0,
      syncedCount: successCount,
      failedCount: failedCount,
      errors: errors,
      message: 'تمت مزامنة $successCount عملية، فشل $failedCount',
    );
  }

  Future<bool> _executeOperation(PendingOperation op) async {
    // هنا يتم تنفيذ العملية حسب نوعها
    // سيتم ربطها مع repositories لاحقاً
    switch (op.type) {
      case PendingOperationType.createInvoice:
        return await _syncInvoice(op.data);
      case PendingOperationType.updateProduct:
        return await _syncProductUpdate(op.data);
      case PendingOperationType.updateStock:
        return await _syncStockUpdate(op.data);
      case PendingOperationType.addProduct:
        return await _syncNewProduct(op.data);
      case PendingOperationType.deleteProduct:
        return await _syncProductDeletion(op.data);
    }
  }

  // Callbacks للمزامنة - يتم تعيينها من Repositories
  Future<bool> Function(Map<String, dynamic> data)? onSyncInvoice;
  Future<bool> Function(Map<String, dynamic> data)? onSyncProductUpdate;
  Future<bool> Function(Map<String, dynamic> data)? onSyncStockUpdate;
  Future<bool> Function(Map<String, dynamic> data)? onSyncNewProduct;
  Future<bool> Function(Map<String, dynamic> data)? onSyncProductDeletion;

  Future<bool> _syncInvoice(Map<String, dynamic> data) async {
    _logger.d('Syncing invoice: ${data['id']}');
    if (onSyncInvoice != null) {
      return await onSyncInvoice!(data);
    }
    _logger.w('Invoice sync callback not registered');
    return false; // إرجاع false لإعادة المحاولة لاحقاً
  }

  Future<bool> _syncProductUpdate(Map<String, dynamic> data) async {
    _logger.d('Syncing product update: ${data['id']}');
    if (onSyncProductUpdate != null) {
      return await onSyncProductUpdate!(data);
    }
    _logger.w('Product update sync callback not registered');
    return false; // إرجاع false لإعادة المحاولة لاحقاً
  }

  Future<bool> _syncStockUpdate(Map<String, dynamic> data) async {
    _logger.d('Syncing stock update: ${data['productId']}');
    if (onSyncStockUpdate != null) {
      return await onSyncStockUpdate!(data);
    }
    _logger.w('Stock update sync callback not registered');
    return false; // إرجاع false لإعادة المحاولة لاحقاً
  }

  Future<bool> _syncNewProduct(Map<String, dynamic> data) async {
    _logger.d('Syncing new product: ${data['id']}');
    if (onSyncNewProduct != null) {
      return await onSyncNewProduct!(data);
    }
    _logger.w('New product sync callback not registered');
    return false; // إرجاع false لإعادة المحاولة لاحقاً
  }

  Future<bool> _syncProductDeletion(Map<String, dynamic> data) async {
    _logger.d('Syncing product deletion: ${data['id']}');
    if (onSyncProductDeletion != null) {
      return await onSyncProductDeletion!(data);
    }
    _logger.w('Product deletion sync callback not registered');
    return false; // إرجاع false لإعادة المحاولة لاحقاً
  }

  // ==================== التخزين المؤقت ====================

  /// تخزين البيانات مؤقتاً
  Future<void> cacheData(String key, dynamic data) async {
    if (_cacheBox == null) return;
    await _cacheBox!.put(key, jsonEncode(data));
  }

  /// استرجاع البيانات المخزنة
  T? getCachedData<T>(String key, T Function(dynamic) fromJson) {
    if (_cacheBox == null) return null;
    final json = _cacheBox!.get(key);
    if (json == null) return null;
    return fromJson(jsonDecode(json));
  }

  /// حذف البيانات المخزنة
  Future<void> clearCache([String? key]) async {
    if (_cacheBox == null) return;
    if (key != null) {
      await _cacheBox!.delete(key);
    } else {
      await _cacheBox!.clear();
    }
  }

  // ==================== الفواتير المحلية ====================

  /// حفظ فاتورة محلياً
  Future<void> saveOfflineInvoice(Map<String, dynamic> invoice) async {
    if (_invoicesBox == null) return;
    await _invoicesBox!.put(invoice['id'], jsonEncode(invoice));
  }

  /// الحصول على الفواتير المحلية
  List<Map<String, dynamic>> getOfflineInvoices() {
    if (_invoicesBox == null) return [];
    return _invoicesBox!.values.map((json) {
      return Map<String, dynamic>.from(jsonDecode(json));
    }).toList();
  }

  /// الحصول على فاتورة محلية واحدة بواسطة ID
  Map<String, dynamic>? getOfflineInvoiceById(String id) {
    if (_invoicesBox == null) return null;
    final json = _invoicesBox!.get(id);
    if (json == null) return null;
    return Map<String, dynamic>.from(jsonDecode(json));
  }

  /// حذف فاتورة محلية
  Future<void> removeOfflineInvoice(String id) async {
    if (_invoicesBox == null) return;
    await _invoicesBox!.delete(id);
  }

  // ==================== المنتجات المحلية ====================

  /// حفظ منتج محلياً
  Future<void> cacheProduct(Map<String, dynamic> product) async {
    if (_productsBox == null) return;
    await _productsBox!.put(product['id'], jsonEncode(product));
  }

  /// الحصول على المنتجات المخزنة
  List<Map<String, dynamic>> getCachedProducts() {
    if (_productsBox == null) return [];
    return _productsBox!.values.map((json) {
      return Map<String, dynamic>.from(jsonDecode(json));
    }).toList();
  }

  /// تحديث منتج محلياً
  Future<void> updateCachedProduct(
      String id, Map<String, dynamic> updates) async {
    if (_productsBox == null) return;
    final existing = _productsBox!.get(id);
    if (existing != null) {
      final product = Map<String, dynamic>.from(jsonDecode(existing));
      product.addAll(updates);
      await _productsBox!.put(id, jsonEncode(product));
    }
  }

  // ==================== أدوات مساعدة ====================

  /// عرض مؤشر حالة الاتصال
  static Widget buildConnectivityIndicator() {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                'غير متصل',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// عرض شريط المزامنة
  static Widget buildSyncBanner(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: OfflineService().syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null || status == SyncStatus.idle) {
          return const SizedBox.shrink();
        }

        return MaterialBanner(
          content: Text(_getSyncMessage(status)),
          leading: _getSyncIcon(status),
          backgroundColor: _getSyncColor(status),
          actions: [
            if (status == SyncStatus.error)
              TextButton(
                onPressed: () => OfflineService().syncPendingOperations(),
                child: const Text('إعادة المحاولة'),
              ),
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  static String _getSyncMessage(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return '';
      case SyncStatus.syncing:
        return 'جاري مزامنة البيانات...';
      case SyncStatus.completed:
        return 'تمت المزامنة بنجاح';
      case SyncStatus.error:
        return 'حدث خطأ في المزامنة';
    }
  }

  static Widget _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return const SizedBox.shrink();
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  static Color _getSyncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.transparent;
      case SyncStatus.syncing:
        return Colors.blue.shade50;
      case SyncStatus.completed:
        return Colors.green.shade50;
      case SyncStatus.error:
        return Colors.red.shade50;
    }
  }

  /// إغلاق الخدمة
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivityController.close();
    _syncStatusController.close();
    await _pendingBox?.close();
    await _cacheBox?.close();
    await _invoicesBox?.close();
    await _productsBox?.close();
  }
}

/// شريط مؤشر الاتصال - يظهر عند عدم الاتصال
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        // إخفاء الشريط إذا كان متصل
        if (isOnline) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'أنت غير متصل بالإنترنت',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<SyncStatus>(
                  stream: OfflineService().syncStatusStream,
                  builder: (context, syncSnapshot) {
                    final pendingCount =
                        OfflineService()._pendingBox?.length ?? 0;
                    if (pendingCount == 0) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount عملية معلقة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// حالة المزامنة
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}

/// نتيجة المزامنة
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
  final String message;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    this.message = '',
  });
}
