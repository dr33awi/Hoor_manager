import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/services/offline_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المنتجات مع دعم الأوفلاين
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;
  final OfflineService _offlineService;
  final _logger = Logger();
  static bool _callbacksRegistered = false;

  ProductRepositoryImpl({
    FirebaseFirestore? firestore,
    OfflineService? offlineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _offlineService = offlineService ?? OfflineService() {
    // تسجيل callbacks للمزامنة مرة واحدة فقط
    if (!_callbacksRegistered) {
      _setupSyncCallbacks();
      _callbacksRegistered = true;
    }
  }

  /// تسجيل callbacks المزامنة
  void _setupSyncCallbacks() {
    _logger.i('Registering sync callbacks for ProductRepository');
    _offlineService.onSyncNewProduct = _syncNewProductToFirestore;
    _offlineService.onSyncProductUpdate = _syncProductUpdateToFirestore;
    _offlineService.onSyncStockUpdate = _syncStockUpdateToFirestore;
    _offlineService.onSyncProductDeletion = _syncProductDeletionToFirestore;
  }

  /// مزامنة منتج جديد إلى Firestore
  Future<bool> _syncNewProductToFirestore(Map<String, dynamic> data) async {
    try {
      _logger.d('Syncing new product to Firestore: ${data['id']}');
      final productData = Map<String, dynamic>.from(data);
      final localId = productData['id'] as String;

      // إزالة الـ id المحلي
      productData.remove('id');

      // تحويل التواريخ من milliseconds إلى Timestamp
      if (productData['createdAt'] is int) {
        productData['createdAt'] =
            Timestamp.fromMillisecondsSinceEpoch(productData['createdAt']);
      } else {
        productData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (productData['updatedAt'] is int) {
        productData['updatedAt'] =
            Timestamp.fromMillisecondsSinceEpoch(productData['updatedAt']);
      } else {
        productData['updatedAt'] = FieldValue.serverTimestamp();
      }

      productData['syncedAt'] = FieldValue.serverTimestamp();

      final docRef = await _productsCollection.add(productData);

      // تحديث الكاش بالـ ID الجديد من Firestore
      final newProductData = Map<String, dynamic>.from(data);
      newProductData['id'] = docRef.id;
      await _offlineService.removeCachedProduct(localId);
      await _offlineService.cacheProduct(newProductData);

      _logger.i('✅ Product synced successfully: $localId -> ${docRef.id}');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to sync new product: $e');
      return false;
    }
  }

  /// مزامنة تحديث منتج إلى Firestore
  Future<bool> _syncProductUpdateToFirestore(Map<String, dynamic> data) async {
    try {
      final id = data['id'] as String;

      // تجاهل المنتجات المحلية التي لم تُرفع بعد
      // نرجع true لإزالة العملية المعلقة لأن المنتج سيُرفع كمنتج جديد
      if (id.startsWith('local_')) {
        _logger.w(
            '⚠️ Skipping update for local product (will be synced as new): $id');
        return true; // إزالة العملية المعلقة
      }

      // التحقق من وجود المنتج أولاً
      final docSnapshot = await _productsCollection.doc(id).get();
      if (!docSnapshot.exists) {
        _logger
            .w('⚠️ Product not found in Firestore, removing from cache: $id');
        // حذف المنتج من الكاش المحلي لأنه غير موجود في السيرفر
        await _offlineService.removeCachedProduct(id);
        return true; // إزالة العملية المعلقة
      }

      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('id');

      // تحويل التواريخ من milliseconds إلى Timestamp
      if (updateData['createdAt'] is int) {
        updateData['createdAt'] =
            Timestamp.fromMillisecondsSinceEpoch(updateData['createdAt']);
      }

      // تعيين وقت التحديث والمزامنة
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      updateData['syncedAt'] = FieldValue.serverTimestamp();

      await _productsCollection.doc(id).update(updateData);
      _logger.i('✅ Product update synced: $id');
      return true;
    } catch (e) {
      // إذا كان الخطأ بسبب عدم وجود المستند
      if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        final id = data['id'] as String;
        _logger.w('⚠️ Product not found, removing from cache: $id');
        await _offlineService.removeCachedProduct(id);
        return true; // إزالة العملية المعلقة
      }
      _logger.e('❌ Failed to sync product update: $e');
      return false;
    }
  }

  /// مزامنة تحديث مخزون إلى Firestore
  Future<bool> _syncStockUpdateToFirestore(Map<String, dynamic> data) async {
    try {
      final productId = data['productId'] as String;
      final variantId = data['variantId'] as String;
      final newQuantity = data['newQuantity'] as int;

      // تجاهل المنتجات المحلية
      if (productId.startsWith('local_')) {
        _logger.w('⚠️ Skipping stock update for local product: $productId');
        return true;
      }

      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) {
        _logger.w('⚠️ Product not found for stock update: $productId');
        await _offlineService.removeCachedProduct(productId);
        return true; // إزالة العملية المعلقة
      }

      final product = ProductModel.fromDocument(doc);
      final updatedVariants = product.variants.map((v) {
        if (v.id == variantId) {
          return v.copyWith(quantity: newQuantity);
        }
        return v;
      }).toList();

      await _productsCollection.doc(productId).update({
        'variants': updatedVariants
            .map((v) => {
                  'id': v.id,
                  'color': v.color,
                  'colorCode': v.colorCode,
                  'size': v.size,
                  'quantity': v.quantity,
                  'sku': v.sku,
                  'barcode': v.barcode,
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('✅ Stock update synced for: $productId');
      return true;
    } catch (e) {
      if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        final productId = data['productId'] as String;
        _logger.w('⚠️ Product not found: $productId');
        await _offlineService.removeCachedProduct(productId);
        return true;
      }
      _logger.e('❌ Failed to sync stock update: $e');
      return false;
    }
  }

  /// مزامنة حذف منتج إلى Firestore
  Future<bool> _syncProductDeletionToFirestore(
      Map<String, dynamic> data) async {
    try {
      final id = data['id'] as String;

      // المنتجات المحلية التي لم تُرفع - لا حاجة لحذفها من السيرفر
      if (id.startsWith('local_')) {
        _logger.w('⚠️ Skipping deletion for local product: $id');
        return true; // إزالة العملية المعلقة
      }

      await _productsCollection.doc(id).delete();
      _logger.i('✅ Product deletion synced: $id');
      return true;
    } catch (e) {
      // إذا كان المنتج غير موجود أصلاً، نعتبر الحذف ناجحاً
      if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        _logger.w('⚠️ Product already deleted: ${data['id']}');
        return true;
      }
      _logger.e('❌ Failed to sync product deletion: $e');
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Future<Result<List<ProductEntity>>> getProducts({
    String? categoryId,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // التحقق من حالة الاتصال - استخدام الكاش في وضع الأوفلاين
      if (!_offlineService.isOnline) {
        return _getProductsFromCache(
          categoryId: categoryId,
          isActive: isActive,
          searchQuery: searchQuery,
        );
      }

      Query<Map<String, dynamic>> query = _productsCollection;

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      List<ProductEntity> products =
          snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

      // حفظ المنتجات في الكاش للاستخدام offline
      for (final doc in snapshot.docs) {
        await _offlineService.cacheProduct(
          doc.data()..['id'] = doc.id,
        );
      }

      // البحث محلياً إذا كان هناك نص بحث
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(searchLower) ||
              (p.barcode?.contains(searchQuery) ?? false) ||
              (p.description?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      return Success(products);
    } catch (e) {
      // في حالة الخطأ، حاول استخدام الكاش
      return _getProductsFromCache(
        categoryId: categoryId,
        isActive: isActive,
        searchQuery: searchQuery,
      );
    }
  }

  /// الحصول على المنتجات من الكاش المحلي
  Result<List<ProductEntity>> _getProductsFromCache({
    String? categoryId,
    bool? isActive,
    String? searchQuery,
  }) {
    try {
      // استخدام الدالة الجديدة للحصول على Entities مباشرة
      List<ProductEntity> products =
          _offlineService.getCachedProductsAsEntities();

      // تطبيق الفلاتر
      if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      if (isActive != null) {
        products = products.where((p) => p.isActive == isActive).toList();
      }

      // البحث
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(searchLower) ||
              (p.barcode?.contains(searchQuery) ?? false) ||
              (p.description?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      // ترتيب بتاريخ الإنشاء
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Success(products);
    } catch (e) {
      return Failure('فشل جلب المنتجات من الكاش: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> getProductById(String id) async {
    try {
      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        return _getProductByIdFromCache(id);
      }

      final doc = await _productsCollection.doc(id).get();
      if (!doc.exists) {
        // جرب من الكاش
        return _getProductByIdFromCache(id);
      }

      final product = ProductModel.fromDocument(doc);

      // تحديث الكاش
      await _offlineService.cacheProduct(doc.data()!..['id'] = doc.id);

      return Success(product);
    } catch (e) {
      // في حالة الخطأ، جرب من الكاش
      return _getProductByIdFromCache(id);
    }
  }

  /// الحصول على منتج من الكاش بالـ ID
  Result<ProductEntity> _getProductByIdFromCache(String id) {
    try {
      _logger.d('🔍 Getting product from cache with ID: $id');

      // استخدام الدالة الجديدة للحصول على Entity مباشرة
      final productEntity = _offlineService.getCachedProductAsEntity(id);
      _logger.d(
          '📦 Direct cache result: ${productEntity != null ? "found" : "not found"}');

      if (productEntity == null) {
        // في حالة عدم وجود المنتج بالـ ID المباشر، جرب البحث في القائمة
        final cachedProducts = _offlineService.getCachedProductsAsEntities();
        _logger.d('📋 Total cached products: ${cachedProducts.length}');

        final foundProduct =
            cachedProducts.where((p) => p.id == id).firstOrNull;

        if (foundProduct == null) {
          _logger.w('❌ Product not found in cache: $id');
          return const Failure('المنتج غير موجود');
        }

        _logger.d('✅ Found product in list: ${foundProduct.name}');
        return Success(foundProduct);
      }

      _logger.d('✅ Product found directly: ${productEntity.name}');
      return Success(productEntity);
    } catch (e) {
      _logger.e('❌ Error getting product from cache: $e');
      return const Failure('المنتج غير موجود');
    }
  }

  @override
  Future<Result<ProductEntity>> getProductByBarcode(String barcode) async {
    try {
      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        return _getProductByBarcodeFromCache(barcode);
      }

      // البحث في الباركود الرئيسي
      var snapshot = await _productsCollection
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final product = ProductModel.fromDocument(snapshot.docs.first);
        // تحديث الكاش
        await _offlineService.cacheProduct(
          snapshot.docs.first.data()..['id'] = snapshot.docs.first.id,
        );
        return Success(product);
      }

      // البحث في باركود المتغيرات
      snapshot = await _productsCollection.get();
      for (final doc in snapshot.docs) {
        final product = ProductModel.fromDocument(doc);
        // حفظ في الكاش
        await _offlineService.cacheProduct(doc.data()..['id'] = doc.id);

        for (final variant in product.variants) {
          if (variant.barcode == barcode) {
            return Success(product);
          }
        }
      }

      return const Failure('المنتج غير موجود');
    } catch (e) {
      // في حالة الخطأ، جرب من الكاش
      return _getProductByBarcodeFromCache(barcode);
    }
  }

  /// الحصول على منتج من الكاش بالباركود
  Result<ProductEntity> _getProductByBarcodeFromCache(String barcode) {
    try {
      final cachedProducts = _offlineService.getCachedProductsAsEntities();

      for (final product in cachedProducts) {
        // البحث في الباركود الرئيسي
        if (product.barcode == barcode) {
          return Success(product);
        }

        // البحث في باركود المتغيرات
        for (final variant in product.variants) {
          if (variant.barcode == barcode) {
            return Success(product);
          }
        }
      }

      return const Failure('المنتج غير موجود');
    } catch (e) {
      return const Failure('المنتج غير موجود');
    }
  }

  @override
  Future<Result<ProductEntity>> addProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);

      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        // حفظ محلياً في وضع الأوفلاين
        final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        final offlineProduct = model.copyWith(id: localId);

        // حفظ في التخزين المحلي
        await _offlineService
            .cacheProduct(offlineProduct.toMap()..['id'] = localId);

        // إضافة عملية معلقة للمزامنة
        await _offlineService.addPendingOperation(
          PendingOperation(
            id: localId,
            type: PendingOperationType.addProduct,
            data: offlineProduct.toMap()..['id'] = localId,
            createdAt: DateTime.now(),
          ),
        );

        return Success(offlineProduct);
      }

      // الاتصال متوفر - حفظ مباشرة
      final docRef = await _productsCollection.add(model.toMap());
      final newProduct = model.copyWith(id: docRef.id);

      // تحديث الكاش المحلي
      await _offlineService
          .cacheProduct(newProduct.toMap()..['id'] = docRef.id);

      return Success(newProduct);
    } catch (e) {
      return Failure('فشل إضافة المنتج: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> updateProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);

      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        // تحديث محلياً في وضع الأوفلاين
        await _offlineService.updateCachedProduct(
            product.id, model.toUpdateMap());

        // إضافة عملية معلقة للمزامنة
        await _offlineService.addPendingOperation(
          PendingOperation(
            id: 'update_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateProduct,
            data: model.toUpdateMap()..['id'] = product.id,
            createdAt: DateTime.now(),
          ),
        );

        return Success(model);
      }

      // الاتصال متوفر - تحديث مباشرة
      await _productsCollection.doc(product.id).update(model.toUpdateMap());

      // تحديث الكاش المحلي
      await _offlineService.updateCachedProduct(
          product.id, model.toUpdateMap());

      return Success(model);
    } catch (e) {
      return Failure('فشل تحديث المنتج: $e');
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        // إضافة عملية حذف معلقة
        await _offlineService.addPendingOperation(
          PendingOperation(
            id: 'delete_${id}_${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.deleteProduct,
            data: {'id': id},
            createdAt: DateTime.now(),
          ),
        );

        // حذف من الكاش المحلي فوراً لتحديث الواجهة
        await _offlineService.removeCachedProduct(id);

        _logger.d('🗑️ Product deleted locally (offline): $id');
        return const Success(null);
      }

      await _productsCollection.doc(id).delete();

      // حذف من الكاش المحلي أيضاً
      await _offlineService.removeCachedProduct(id);

      return const Success(null);
    } catch (e) {
      return Failure('فشل حذف المنتج: $e');
    }
  }

  @override
  Future<Result<void>> toggleProductStatus(String id, bool isActive) async {
    try {
      await _productsCollection.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('فشل تغيير حالة المنتج: $e');
    }
  }

  @override
  Future<Result<void>> updateVariantStock({
    required String productId,
    required String variantId,
    required int newQuantity,
  }) async {
    try {
      // التحقق من حالة الاتصال
      if (!_offlineService.isOnline) {
        // تحديث محلي في الكاش
        final cachedProducts = _offlineService.getCachedProducts();
        final productIndex =
            cachedProducts.indexWhere((p) => p['id'] == productId);

        if (productIndex != -1) {
          final productData =
              Map<String, dynamic>.from(cachedProducts[productIndex]);
          final variants =
              List<Map<String, dynamic>>.from(productData['variants'] ?? []);
          final variantIndex = variants.indexWhere((v) => v['id'] == variantId);

          if (variantIndex != -1) {
            variants[variantIndex]['quantity'] = newQuantity;
            productData['variants'] = variants;
            await _offlineService.cacheProduct(productData);
          }
        }

        // إضافة عملية معلقة للمزامنة
        await _offlineService.addPendingOperation(
          PendingOperation(
            id: 'stock_${productId}_${variantId}_${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateStock,
            data: {
              'productId': productId,
              'variantId': variantId,
              'newQuantity': newQuantity,
            },
            createdAt: DateTime.now(),
          ),
        );

        return const Success(null);
      }

      final productResult = await getProductById(productId);
      if (productResult.isFailure) {
        return Failure(productResult.errorOrNull!);
      }

      final product = productResult.valueOrNull!;
      final updatedVariants = product.variants.map((v) {
        if (v.id == variantId) {
          return v.copyWith(quantity: newQuantity);
        }
        return v;
      }).toList();

      final updatedProduct = product.copyWith(
        variants: updatedVariants,
        updatedAt: DateTime.now(),
      );

      return updateProduct(updatedProduct).then((_) => const Success(null));
    } catch (e) {
      return Failure('فشل تحديث المخزون: $e');
    }
  }

  @override
  Future<Result<void>> deductStock({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    try {
      return _firestore.runTransaction((transaction) async {
        final docRef = _productsCollection.doc(productId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('المنتج غير موجود');
        }

        final product = ProductModel.fromDocument(snapshot);
        final variantIndex =
            product.variants.indexWhere((v) => v.id == variantId);

        if (variantIndex == -1) {
          throw Exception('المتغير غير موجود');
        }

        final variant = product.variants[variantIndex];
        if (variant.quantity < quantity) {
          throw Exception('الكمية المطلوبة غير متوفرة');
        }

        final updatedVariants = List<ProductVariant>.from(product.variants);
        updatedVariants[variantIndex] = variant.deductStock(quantity);

        final updatedProduct = product.copyWith(variants: updatedVariants);
        final model = ProductModel.fromEntity(updatedProduct);

        transaction.update(docRef, model.toUpdateMap());
      }).then((_) => const Success(null));
    } catch (e) {
      return Failure('فشل خصم المخزون: $e');
    }
  }

  @override
  Future<Result<void>> addStock({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    try {
      final productResult = await getProductById(productId);
      if (productResult.isFailure) {
        return Failure(productResult.errorOrNull!);
      }

      final product = productResult.valueOrNull!;
      final updatedVariants = product.variants.map((v) {
        if (v.id == variantId) {
          return v.addStock(quantity);
        }
        return v;
      }).toList();

      final updatedProduct = product.copyWith(
        variants: updatedVariants,
        updatedAt: DateTime.now(),
      );

      return updateProduct(updatedProduct).then((_) => const Success(null));
    } catch (e) {
      return Failure('فشل إضافة المخزون: $e');
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getLowStockProducts() async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('isLowStock', isEqualTo: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

      return Success(products);
    } catch (e) {
      return Failure('فشل جلب المنتجات منخفضة المخزون: $e');
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getOutOfStockProducts() async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('isOutOfStock', isEqualTo: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();

      return Success(products);
    } catch (e) {
      return Failure('فشل جلب المنتجات النافدة: $e');
    }
  }

  @override
  Stream<List<ProductEntity>> watchLowStockProducts() {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('isLowStock', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Stream<List<ProductEntity>> watchOutOfStockProducts() {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('isOutOfStock', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Stream<List<ProductEntity>> watchProducts({String? categoryId}) {
    final controller = StreamController<List<ProductEntity>>.broadcast();
    StreamSubscription? firestoreSubscription;
    StreamSubscription? localUpdatesSubscription;
    StreamSubscription? connectivitySubscription;

    // دالة لجلب وإرسال البيانات
    void emitProducts() {
      try {
        var products = _offlineService.getCachedProductsAsEntities();

        // تطبيق الفلتر
        if (categoryId != null) {
          products = products.where((p) => p.categoryId == categoryId).toList();
        }

        // ترتيب حسب تاريخ الإنشاء
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (!controller.isClosed) {
          controller.add(products);
          _logger.d('📦 Emitted ${products.length} products');
        }
      } catch (e) {
        _logger.e('Error emitting products: $e');
      }
    }

    // دالة لإعداد Firestore stream
    void setupFirestoreStream() {
      firestoreSubscription?.cancel();

      Query<Map<String, dynamic>> query = _productsCollection;

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      query = query.orderBy('createdAt', descending: true);

      firestoreSubscription = query.snapshots().listen((snapshot) {
        // الحصول على IDs المنتجات الحالية من Firestore
        final currentIds = snapshot.docs.map((doc) => doc.id).toSet();

        // الحصول على IDs المنتجات في الكاش
        final cachedIds = _offlineService
            .getCachedProducts()
            .map((p) => p['id'] as String)
            .where((id) => !id.startsWith('local_'))
            .toSet();

        // حذف المنتجات التي لم تعد موجودة في Firestore
        final deletedIds = cachedIds.difference(currentIds);
        for (final deletedId in deletedIds) {
          _offlineService.removeCachedProduct(deletedId);
          _logger.d('🗑️ Removed deleted product from cache: $deletedId');
        }

        // حفظ/تحديث المنتجات الموجودة
        for (final doc in snapshot.docs) {
          _offlineService.cacheProduct(doc.data()..['id'] = doc.id);
        }

        _logger.d(
            '📦 Synced ${snapshot.docs.length} products, removed ${deletedIds.length} deleted');

        // إرسال البيانات المحدثة
        emitProducts();
      }, onError: (e) {
        _logger.e('Firestore stream error: $e');
        // في حالة الخطأ، أرسل من الكاش
        emitProducts();
      });
    }

    // الاستماع لتحديثات المنتجات المحلية (للتحديث الفوري عند الإضافة/التعديل)
    localUpdatesSubscription = _offlineService.productsUpdateStream.listen((_) {
      _logger.d('📦 Local products update detected');
      emitProducts();
    });

    // الاستماع لتغييرات الاتصال
    connectivitySubscription =
        _offlineService.connectivityStream.listen((isOnline) {
      _logger.d('🌐 Connectivity changed: $isOnline');
      if (isOnline) {
        setupFirestoreStream();
      } else {
        firestoreSubscription?.cancel();
        emitProducts();
      }
    });

    // إعداد أولي
    if (_offlineService.isOnline) {
      setupFirestoreStream();
    } else {
      emitProducts();
    }

    // إرسال البيانات الأولية فوراً
    emitProducts();

    // تنظيف عند إغلاق Stream
    controller.onCancel = () {
      firestoreSubscription?.cancel();
      localUpdatesSubscription?.cancel();
      connectivitySubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// مراقبة المنتجات في وضع الأوفلاين
  Stream<List<ProductEntity>> _watchProductsOffline({String? categoryId}) {
    // إرسال البيانات الأولية ثم الاستماع للتحديثات
    return _offlineService.productsUpdateStream
        .startWith(null) // إرسال قيمة أولية لتحميل البيانات
        .map((_) {
      var products = _offlineService.getCachedProductsAsEntities();

      // تطبيق الفلتر
      if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      // ترتيب حسب تاريخ الإنشاء
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.d('📦 Offline products: ${products.length}');
      return products;
    });
  }

  @override
  Stream<ProductEntity?> watchProduct(String id) {
    final controller = StreamController<ProductEntity?>.broadcast();
    StreamSubscription? firestoreSubscription;
    StreamSubscription? localUpdatesSubscription;
    StreamSubscription? connectivitySubscription;

    // دالة لجلب وإرسال المنتج
    void emitProduct() {
      try {
        final product = _offlineService.getCachedProductAsEntity(id);
        if (!controller.isClosed) {
          controller.add(product);
          _logger.d('📦 Emitted product: ${product?.name ?? "not found"}');
        }
      } catch (e) {
        _logger.e('Error emitting product: $e');
      }
    }

    // دالة لإعداد Firestore stream
    void setupFirestoreStream() {
      firestoreSubscription?.cancel();

      firestoreSubscription =
          _productsCollection.doc(id).snapshots().listen((snapshot) {
        if (!snapshot.exists) {
          if (!controller.isClosed) {
            controller.add(null);
          }
          return;
        }

        // حفظ المنتج في الكاش للاستخدام offline
        _offlineService.cacheProduct(snapshot.data()!..['id'] = snapshot.id);

        emitProduct();
      }, onError: (e) {
        _logger.e('Firestore stream error for product $id: $e');
        emitProduct();
      });
    }

    // الاستماع لتحديثات المنتجات المحلية
    localUpdatesSubscription = _offlineService.productsUpdateStream.listen((_) {
      _logger.d('📦 Local product update detected for $id');
      emitProduct();
    });

    // الاستماع لتغييرات الاتصال
    connectivitySubscription =
        _offlineService.connectivityStream.listen((isOnline) {
      _logger.d('🌐 Connectivity changed for product $id: $isOnline');
      if (isOnline) {
        setupFirestoreStream();
      } else {
        firestoreSubscription?.cancel();
        emitProduct();
      }
    });

    // إعداد أولي
    if (_offlineService.isOnline) {
      setupFirestoreStream();
    }

    // إرسال البيانات الأولية فوراً
    emitProduct();

    // تنظيف عند إغلاق Stream
    controller.onCancel = () {
      firestoreSubscription?.cancel();
      localUpdatesSubscription?.cancel();
      connectivitySubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// مراقبة منتج واحد في وضع الأوفلاين
  Stream<ProductEntity?> _watchProductOffline(String id) {
    return _offlineService.productsUpdateStream.startWith(null).map((_) {
      final product = _offlineService.getCachedProductAsEntity(id);
      _logger.d('📦 Offline product: ${product?.name ?? "not found"}');
      return product;
    });
  }
}
