import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع المنتجات
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Future<Result<List<ProductEntity>>> getProducts({
    String? categoryId,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _productsCollection;

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      List<ProductEntity> products = snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

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
      return Failure('فشل جلب المنتجات: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> getProductById(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();
      if (!doc.exists) {
        return const Failure('المنتج غير موجود');
      }
      return Success(ProductModel.fromDocument(doc));
    } catch (e) {
      return Failure('فشل جلب المنتج: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> getProductByBarcode(String barcode) async {
    try {
      // البحث في الباركود الرئيسي
      var snapshot = await _productsCollection
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Success(ProductModel.fromDocument(snapshot.docs.first));
      }

      // البحث في باركود المتغيرات
      snapshot = await _productsCollection.get();
      for (final doc in snapshot.docs) {
        final product = ProductModel.fromDocument(doc);
        for (final variant in product.variants) {
          if (variant.barcode == barcode) {
            return Success(product);
          }
        }
      }

      return const Failure('المنتج غير موجود');
    } catch (e) {
      return Failure('فشل البحث بالباركود: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> addProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      final docRef = await _productsCollection.add(model.toMap());
      
      final newProduct = model.copyWith(id: docRef.id);
      return Success(newProduct);
    } catch (e) {
      return Failure('فشل إضافة المنتج: $e');
    }
  }

  @override
  Future<Result<ProductEntity>> updateProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await _productsCollection.doc(product.id).update(model.toUpdateMap());
      return Success(model);
    } catch (e) {
      return Failure('فشل تحديث المنتج: $e');
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
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
        final variantIndex = product.variants.indexWhere((v) => v.id == variantId);
        
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

      final products = snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

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

      final products = snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

      return Success(products);
    } catch (e) {
      return Failure('فشل جلب المنتجات النافدة: $e');
    }
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
