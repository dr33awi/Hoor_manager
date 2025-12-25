import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/offline_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المنتجات مع دعم الأوفلاين
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;
  final OfflineService _offlineService;

  ProductRepositoryImpl({
    FirebaseFirestore? firestore,
    OfflineService? offlineService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _offlineService = offlineService ?? OfflineService() {
    // تسجيل callbacks للمزامنة
    _setupSyncCallbacks();
  }

  /// تسجيل callbacks المزامنة
  void _setupSyncCallbacks() {
    _offlineService.onSyncNewProduct = _syncNewProductToFirestore;
    _offlineService.onSyncProductUpdate = _syncProductUpdateToFirestore;
    _offlineService.onSyncStockUpdate = _syncStockUpdateToFirestore;
    _offlineService.onSyncProductDeletion = _syncProductDeletionToFirestore;
  }

  /// مزامنة منتج جديد إلى Firestore
  Future<bool> _syncNewProductToFirestore(Map<String, dynamic> data) async {
    try {
      final productData = Map<String, dynamic>.from(data);
      final localId = productData['id'] as String;
      productData.remove('id'); // إزالة الـ id المحلي
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['syncedAt'] = FieldValue.serverTimestamp();

      await _productsCollection.add(productData);

      // حذف المنتج من التخزين المحلي المعلق
      await _offlineService.removePendingOperation(localId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// مزامنة تحديث منتج إلى Firestore
  Future<bool> _syncProductUpdateToFirestore(Map<String, dynamic> data) async {
    try {
      final id = data['id'] as String;
      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('id');
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      updateData['syncedAt'] = FieldValue.serverTimestamp();

      await _productsCollection.doc(id).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// مزامنة تحديث مخزون إلى Firestore
  Future<bool> _syncStockUpdateToFirestore(Map<String, dynamic> data) async {
    try {
      final productId = data['productId'] as String;
      final variantId = data['variantId'] as String;
      final newQuantity = data['newQuantity'] as int;

      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return false;

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
      return true;
    } catch (e) {
      return false;
    }
  }

  /// مزامنة حذف منتج إلى Firestore
  Future<bool> _syncProductDeletionToFirestore(
      Map<String, dynamic> data) async {
    try {
      final id = data['id'] as String;
      await _productsCollection.doc(id).delete();
      return true;
    } catch (e) {
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
      final cachedProducts = _offlineService.getCachedProducts();
      List<ProductEntity> products = cachedProducts.map((data) {
        return ProductModel.fromMap(data, data['id'] ?? '');
      }).toList();

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
      final cachedProducts = _offlineService.getCachedProducts();
      final productData = cachedProducts.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (productData.isEmpty) {
        return const Failure('المنتج غير موجود');
      }

      return Success(ProductModel.fromMap(productData, id));
    } catch (e) {
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
      final cachedProducts = _offlineService.getCachedProducts();

      for (final data in cachedProducts) {
        // البحث في الباركود الرئيسي
        if (data['barcode'] == barcode) {
          return Success(ProductModel.fromMap(data, data['id'] ?? ''));
        }

        // البحث في باركود المتغيرات
        final variants = data['variants'] as List<dynamic>? ?? [];
        for (final variant in variants) {
          if (variant['barcode'] == barcode) {
            return Success(ProductModel.fromMap(data, data['id'] ?? ''));
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

        // حذف من الكاش المحلي (للمنتجات المحلية فقط)
        // المنتجات المتزامنة تبقى في الكاش حتى المزامنة
        return const Success(null);
      }

      await _productsCollection.doc(id).delete();
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
    Query<Map<String, dynamic>> query = _productsCollection;

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Stream<ProductEntity?> watchProduct(String id) {
    return _productsCollection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ProductModel.fromDocument(snapshot);
    });
  }
}
