import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../features/products/domain/entities/product_entity.dart';
import '../data/hive/hive_adapters.dart';

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
  final _pendingCountController = StreamController<int>.broadcast();
  final _productsUpdateController = StreamController<void>.broadcast();

  StreamSubscription? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isInitialized = false;

  /// Stream لحالة الاتصال
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Stream لحالة المزامنة
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Stream لعدد العمليات المعلقة
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  /// Stream لتحديثات المنتجات المحلية
  Stream<void> get productsUpdateStream => _productsUpdateController.stream;

  /// هل متصل بالإنترنت
  bool get isOnline => _isOnline;

  /// هل يتم المزامنة حالياً
  bool get isSyncing => _isSyncing;

  /// هل تم التهيئة
  bool get isInitialized => _isInitialized;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // التأكد من تهيئة Hive
      await Hive.initFlutter();

      // تسجيل TypeAdapters
      registerHiveAdapters();

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

      _isInitialized = true;
      _notifyPendingCount();
      _logger.i('OfflineService initialized successfully');

      // مزامنة البيانات المعلقة إذا كان هناك اتصال
      await _syncPendingOnStartup();
    } catch (e) {
      _logger.e('Error initializing OfflineService: $e');
      rethrow;
    }
  }

  /// مزامنة البيانات المعلقة عند بدء التطبيق
  Future<void> _syncPendingOnStartup() async {
    if (!_isOnline) {
      _logger.d('📴 Offline on startup, skipping sync');
      return;
    }

    final pendingCount = _pendingBox?.length ?? 0;
    if (pendingCount == 0) {
      _logger.d('✅ No pending operations to sync');
      return;
    }

    _logger.i('🔄 Found $pendingCount pending operations, starting sync...');

    // تأخير قليل للسماح للـ callbacks بالتسجيل
    await Future.delayed(const Duration(seconds: 2));

    // بدء المزامنة
    final result = await syncPendingOperations();
    _logger.i('📊 Startup sync result: ${result.message}');
  }

  /// التأكد من التهيئة قبل أي عملية
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'OfflineService not initialized. Call initialize() first.');
    }
  }

  void _updateConnectivity(List<ConnectivityResult> result) {
    final wasOnline = _isOnline;
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);

    _connectivityController.add(_isOnline);

    _logger.d('Connectivity changed: $_isOnline (was: $wasOnline)');

    // إذا عاد الاتصال، ابدأ المزامنة
    if (!wasOnline && _isOnline && _isInitialized) {
      _logger.i('Connection restored, starting sync in 3 seconds...');
      Future.delayed(const Duration(seconds: 3), () {
        if (_isOnline && !_isSyncing) {
          syncPendingOperations();
        }
      });
    }
  }

  /// إخطار بتغيير عدد العمليات المعلقة
  void _notifyPendingCount() {
    if (_pendingBox != null) {
      _pendingCountController.add(_pendingBox!.length);
    }
  }

  /// إخطار بتحديث المنتجات المحلية
  void _notifyProductsUpdate() {
    _productsUpdateController.add(null);
    _logger.d('📢 Notified products update');
  }

  // ==================== إدارة العمليات المعلقة ====================

  /// إضافة عملية معلقة
  Future<void> addPendingOperation(PendingOperation operation) async {
    _ensureInitialized();
    if (_pendingBox == null) return;

    try {
      // تحويل البيانات إلى شكل قابل للتخزين
      final encodableData =
          _convertToJsonEncodable(operation.data) as Map<String, dynamic>;
      final encodableOperation = PendingOperation(
        id: operation.id,
        type: operation.type,
        data: encodableData,
        createdAt: operation.createdAt,
        retryCount: operation.retryCount,
      );
      await _pendingBox!
          .put(operation.id, jsonEncode(encodableOperation.toJson()));
      _notifyPendingCount();
      _logger.d('Added pending operation: ${operation.type} - ${operation.id}');
    } catch (e) {
      _logger.e('Error adding pending operation: $e');
    }
  }

  /// الحصول على جميع العمليات المعلقة
  List<PendingOperation> getPendingOperations() {
    if (_pendingBox == null || !_isInitialized) return [];

    try {
      return _pendingBox!.values.map((json) {
        return PendingOperation.fromJson(jsonDecode(json));
      }).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      _logger.e('Error getting pending operations: $e');
      return [];
    }
  }

  /// حذف عملية معلقة
  Future<void> removePendingOperation(String id) async {
    if (_pendingBox == null) return;

    try {
      await _pendingBox!.delete(id);
      _notifyPendingCount();
      _logger.d('Removed pending operation: $id');
    } catch (e) {
      _logger.e('Error removing pending operation: $e');
    }
  }

  /// عدد العمليات المعلقة
  int get pendingOperationsCount => _pendingBox?.length ?? 0;

  // ==================== مزامنة البيانات ====================

  /// مزامنة العمليات المعلقة
  Future<SyncResult> syncPendingOperations() async {
    if (!_isOnline) {
      return SyncResult(
        success: false,
        message: 'لا يوجد اتصال بالإنترنت',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'المزامنة قيد التنفيذ بالفعل',
      );
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    _logger.i('Starting sync of pending operations...');

    final operations = getPendingOperations();
    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    for (final op in operations) {
      if (!_isOnline) {
        _logger.w('Connection lost during sync, stopping...');
        break;
      }

      try {
        final success = await _executeOperation(op);
        if (success) {
          await removePendingOperation(op.id);
          successCount++;
          _logger.d('Synced operation: ${op.type} - ${op.id}');
        } else {
          op.retryCount++;
          if (op.retryCount >= 5) {
            errors.add(
                'فشل ${op.type.name}: تجاوز الحد الأقصى للمحاولات (${op.id})');
            await removePendingOperation(op.id);
            _logger.w('Removed failed operation after max retries: ${op.id}');
          } else {
            // تحديث عدد المحاولات
            await _pendingBox!.put(op.id, jsonEncode(op.toJson()));
          }
          failedCount++;
        }
      } catch (e) {
        _logger.e('Sync error for ${op.type}: $e');
        failedCount++;
        errors.add('خطأ في ${op.type.name}: $e');

        op.retryCount++;
        if (op.retryCount < 5) {
          await _pendingBox!.put(op.id, jsonEncode(op.toJson()));
        } else {
          await removePendingOperation(op.id);
        }
      }
    }

    _isSyncing = false;
    _notifyPendingCount();

    final status = failedCount > 0 ? SyncStatus.error : SyncStatus.completed;
    _syncStatusController.add(status);

    // إعادة الحالة إلى idle بعد فترة
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isSyncing) {
        _syncStatusController.add(SyncStatus.idle);
      }
    });

    final result = SyncResult(
      success: failedCount == 0,
      syncedCount: successCount,
      failedCount: failedCount,
      errors: errors,
      message:
          'تمت مزامنة $successCount عملية${failedCount > 0 ? '، فشل $failedCount' : ''}',
    );

    _logger.i('Sync completed: ${result.message}');
    return result;
  }

  Future<bool> _executeOperation(PendingOperation op) async {
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
    _logger.w('Invoice sync callback not registered, will retry later');
    return false;
  }

  Future<bool> _syncProductUpdate(Map<String, dynamic> data) async {
    _logger.d('Syncing product update: ${data['id']}');
    if (onSyncProductUpdate != null) {
      return await onSyncProductUpdate!(data);
    }
    _logger.w('Product update sync callback not registered');
    return false;
  }

  Future<bool> _syncStockUpdate(Map<String, dynamic> data) async {
    _logger.d('Syncing stock update: ${data['productId']}');
    if (onSyncStockUpdate != null) {
      return await onSyncStockUpdate!(data);
    }
    _logger.w('Stock update sync callback not registered');
    return false;
  }

  Future<bool> _syncNewProduct(Map<String, dynamic> data) async {
    _logger.d('Syncing new product: ${data['id']}');
    if (onSyncNewProduct != null) {
      return await onSyncNewProduct!(data);
    }
    _logger.w('New product sync callback not registered');
    return false;
  }

  Future<bool> _syncProductDeletion(Map<String, dynamic> data) async {
    _logger.d('Syncing product deletion: ${data['id']}');
    if (onSyncProductDeletion != null) {
      return await onSyncProductDeletion!(data);
    }
    _logger.w('Product deletion sync callback not registered');
    return false;
  }

  // ==================== التخزين المؤقت ====================

  /// تخزين البيانات مؤقتاً
  Future<void> cacheData(String key, dynamic data) async {
    if (_cacheBox == null) return;

    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _cacheBox!.put(key, jsonEncode(cacheEntry));
    } catch (e) {
      _logger.e('Error caching data: $e');
    }
  }

  /// استرجاع البيانات المخزنة
  T? getCachedData<T>(String key, T Function(dynamic) fromJson,
      {Duration? maxAge}) {
    if (_cacheBox == null) return null;

    try {
      final json = _cacheBox!.get(key);
      if (json == null) return null;

      final cacheEntry = jsonDecode(json) as Map<String, dynamic>;

      // التحقق من صلاحية الكاش
      if (maxAge != null) {
        final timestamp = DateTime.parse(cacheEntry['timestamp']);
        if (DateTime.now().difference(timestamp) > maxAge) {
          _cacheBox!.delete(key);
          return null;
        }
      }

      return fromJson(cacheEntry['data']);
    } catch (e) {
      _logger.e('Error getting cached data: $e');
      return null;
    }
  }

  /// حذف البيانات المخزنة
  Future<void> clearCache([String? key]) async {
    if (_cacheBox == null) return;

    try {
      if (key != null) {
        await _cacheBox!.delete(key);
      } else {
        await _cacheBox!.clear();
      }
    } catch (e) {
      _logger.e('Error clearing cache: $e');
    }
  }

  // ==================== الفواتير المحلية ====================

  /// حفظ فاتورة محلياً
  Future<void> saveOfflineInvoice(Map<String, dynamic> invoice) async {
    if (_invoicesBox == null) return;

    try {
      final id = invoice['id'] as String? ?? 'unknown';
      await _invoicesBox!.put(id, jsonEncode(invoice));
      _logger.d('Saved offline invoice: $id');
    } catch (e) {
      _logger.e('Error saving offline invoice: $e');
    }
  }

  /// الحصول على الفواتير المحلية
  List<Map<String, dynamic>> getOfflineInvoices() {
    if (_invoicesBox == null) return [];

    try {
      return _invoicesBox!.values.map((json) {
        return Map<String, dynamic>.from(jsonDecode(json));
      }).toList();
    } catch (e) {
      _logger.e('Error getting offline invoices: $e');
      return [];
    }
  }

  /// الحصول على فاتورة محلية واحدة بواسطة ID
  Map<String, dynamic>? getOfflineInvoiceById(String id) {
    if (_invoicesBox == null) return null;

    try {
      final json = _invoicesBox!.get(id);
      if (json == null) return null;
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      _logger.e('Error getting offline invoice: $e');
      return null;
    }
  }

  /// حذف فاتورة محلية
  Future<void> removeOfflineInvoice(String id) async {
    if (_invoicesBox == null) return;

    try {
      await _invoicesBox!.delete(id);
      _logger.d('Removed offline invoice: $id');
    } catch (e) {
      _logger.e('Error removing offline invoice: $e');
    }
  }

  /// تخزين فاتورة من السيرفر للاستخدام في الأوفلاين
  Future<void> cacheServerInvoice(Map<String, dynamic> invoice) async {
    if (_invoicesBox == null) return;

    try {
      final id = invoice['id'] as String? ?? 'unknown';
      // تجاهل الفواتير المحلية (التي تبدأ بـ offline_)
      if (id.startsWith('offline_')) return;

      final encodableInvoice =
          _convertToJsonEncodable(invoice) as Map<String, dynamic>;
      await _invoicesBox!.put(id, jsonEncode(encodableInvoice));
    } catch (e) {
      _logger.e('Error caching server invoice: $e');
    }
  }

  /// تخزين قائمة فواتير من السيرفر
  Future<void> cacheServerInvoices(List<Map<String, dynamic>> invoices) async {
    if (_invoicesBox == null) return;

    try {
      for (final invoice in invoices) {
        final id = invoice['id'] as String? ?? 'unknown';
        if (id.startsWith('offline_')) continue;

        final encodableInvoice =
            _convertToJsonEncodable(invoice) as Map<String, dynamic>;
        await _invoicesBox!.put(id, jsonEncode(encodableInvoice));
      }
      _logger.d('✅ Cached ${invoices.length} server invoices');
    } catch (e) {
      _logger.e('Error caching server invoices: $e');
    }
  }

  /// مسح الفواتير المخزنة من السيرفر (ليس المحلية)
  Future<void> clearCachedServerInvoices() async {
    if (_invoicesBox == null) return;

    try {
      final keysToRemove = _invoicesBox!.keys
          .where((key) => !key.toString().startsWith('offline_'))
          .toList();

      for (final key in keysToRemove) {
        await _invoicesBox!.delete(key);
      }
      _logger.d('Cleared ${keysToRemove.length} cached server invoices');
    } catch (e) {
      _logger.e('Error clearing cached server invoices: $e');
    }
  }

  // ==================== المنتجات المحلية ====================

  /// تحويل قيمة إلى شكل قابل للتخزين في JSON
  dynamic _convertToJsonEncodable(dynamic value) {
    if (value == null) return null;

    // تجاهل FieldValue (serverTimestamp, increment, etc.)
    final typeName = value.runtimeType.toString();
    if (typeName.contains('FieldValue')) {
      // استبدال FieldValue.serverTimestamp() بالوقت الحالي
      return DateTime.now().millisecondsSinceEpoch;
    }

    // تحويل Timestamp إلى milliseconds
    if (typeName.contains('Timestamp')) {
      try {
        return (value as dynamic).millisecondsSinceEpoch;
      } catch (_) {
        return null;
      }
    }

    // تحويل DateTime
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    // تحويل Map
    if (value is Map) {
      return value
          .map((k, v) => MapEntry(k.toString(), _convertToJsonEncodable(v)));
    }

    // تحويل List
    if (value is List) {
      return value.map((e) => _convertToJsonEncodable(e)).toList();
    }

    return value;
  }

  /// حفظ منتج محلياً
  Future<void> cacheProduct(Map<String, dynamic> product) async {
    if (_productsBox == null) return;

    try {
      final id = product['id'] as String? ?? 'unknown';
      // تحويل البيانات إلى شكل قابل للتخزين
      final encodableProduct =
          _convertToJsonEncodable(product) as Map<String, dynamic>;
      await _productsBox!.put(id, jsonEncode(encodableProduct));
      _logger.d('✅ Cached product: $id');
      // إشعار بتحديث المنتجات
      _notifyProductsUpdate();
    } catch (e) {
      _logger.e('Error caching product: $e');
    }
  }

  /// حفظ قائمة منتجات
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    if (_productsBox == null) return;

    try {
      for (final product in products) {
        final id = product['id'] as String? ?? 'unknown';
        final encodableProduct =
            _convertToJsonEncodable(product) as Map<String, dynamic>;
        await _productsBox!.put(id, jsonEncode(encodableProduct));
      }
      _logger.d('Cached ${products.length} products');
      // إشعار بتحديث المنتجات
      _notifyProductsUpdate();
    } catch (e) {
      _logger.e('Error caching products: $e');
    }
  }

  /// الحصول على المنتجات المخزنة
  List<Map<String, dynamic>> getCachedProducts() {
    if (_productsBox == null) return [];

    try {
      return _productsBox!.values.map((json) {
        return Map<String, dynamic>.from(jsonDecode(json));
      }).toList();
    } catch (e) {
      _logger.e('Error getting cached products: $e');
      return [];
    }
  }

  /// الحصول على منتج مخزن بواسطة ID
  Map<String, dynamic>? getCachedProductById(String id) {
    if (_productsBox == null) return null;

    try {
      final json = _productsBox!.get(id);
      if (json == null) return null;
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      _logger.e('Error getting cached product: $e');
      return null;
    }
  }

  /// الحصول على منتج كـ Entity (باستخدام TypeAdapter)
  ProductEntity? getCachedProductAsEntity(String id) {
    final map = getCachedProductById(id);
    if (map == null) return null;

    try {
      final cached = CachedProduct.fromMap(map);
      return cached.toEntity();
    } catch (e) {
      _logger.e('Error converting cached product to entity: $e');
      return null;
    }
  }

  /// الحصول على جميع المنتجات كـ Entity
  List<ProductEntity> getCachedProductsAsEntities() {
    try {
      return getCachedProducts()
          .map((map) => CachedProduct.fromMap(map).toEntity())
          .toList();
    } catch (e) {
      _logger.e('Error converting cached products to entities: $e');
      return [];
    }
  }

  /// تحديث منتج محلياً
  Future<void> updateCachedProduct(
      String id, Map<String, dynamic> updates) async {
    if (_productsBox == null) return;

    try {
      final existing = _productsBox!.get(id);
      if (existing != null) {
        final product = Map<String, dynamic>.from(jsonDecode(existing));
        // تحويل التحديثات إلى شكل قابل للتخزين
        final encodableUpdates =
            _convertToJsonEncodable(updates) as Map<String, dynamic>;
        product.addAll(encodableUpdates);
        await _productsBox!.put(id, jsonEncode(product));
        _logger.d('Updated cached product: $id');
        // إشعار بتحديث المنتجات
        _notifyProductsUpdate();
      }
    } catch (e) {
      _logger.e('Error updating cached product: $e');
    }
  }

  /// حذف منتج من الكاش
  Future<void> removeCachedProduct(String id) async {
    if (_productsBox == null) return;

    try {
      await _productsBox!.delete(id);
      _logger.d('Removed cached product: $id');
      // إشعار بتحديث المنتجات
      _notifyProductsUpdate();
    } catch (e) {
      _logger.e('Error removing cached product: $e');
    }
  }

  /// مسح جميع المنتجات المخزنة
  Future<void> clearCachedProducts() async {
    if (_productsBox == null) return;

    try {
      await _productsBox!.clear();
      _logger.d('Cleared all cached products');
    } catch (e) {
      _logger.e('Error clearing cached products: $e');
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
    _pendingCountController.close();
    await _pendingBox?.close();
    await _cacheBox?.close();
    await _invoicesBox?.close();
    await _productsBox?.close();
    _isInitialized = false;
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
                StreamBuilder<int>(
                  stream: OfflineService().pendingCountStream,
                  initialData: OfflineService().pendingOperationsCount,
                  builder: (context, countSnapshot) {
                    final pendingCount = countSnapshot.data ?? 0;
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
