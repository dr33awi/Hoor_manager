import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع الفئات
class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  @override
  Future<Result<List<CategoryEntity>>> getCategories({bool? isActive}) async {
    try {
      Query<Map<String, dynamic>> query = _categoriesCollection;

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      query = query.orderBy('order');

      final snapshot = await query.get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromDocument(doc))
          .toList();

      return Success(categories);
    } catch (e) {
      return Failure('فشل جلب الفئات: $e');
    }
  }

  @override
  Future<Result<CategoryEntity>> getCategoryById(String id) async {
    try {
      final doc = await _categoriesCollection.doc(id).get();
      if (!doc.exists) {
        return const Failure('الفئة غير موجودة');
      }
      return Success(CategoryModel.fromDocument(doc));
    } catch (e) {
      return Failure('فشل جلب الفئة: $e');
    }
  }

  @override
  Future<Result<CategoryEntity>> addCategory(CategoryEntity category) async {
    try {
      // الحصول على أعلى ترتيب
      final snapshot = await _categoriesCollection
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      int newOrder = 0;
      if (snapshot.docs.isNotEmpty) {
        newOrder = (snapshot.docs.first.data()['order'] ?? 0) + 1;
      }

      final model = CategoryModel.fromEntity(category).copyWith(order: newOrder);
      final docRef = await _categoriesCollection.add(model.toMap());

      final newCategory = model.copyWith(id: docRef.id);
      return Success(newCategory);
    } catch (e) {
      return Failure('فشل إضافة الفئة: $e');
    }
  }

  @override
  Future<Result<CategoryEntity>> updateCategory(CategoryEntity category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      await _categoriesCollection.doc(category.id).update(model.toMap());
      return Success(model);
    } catch (e) {
      return Failure('فشل تحديث الفئة: $e');
    }
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    try {
      // التحقق من وجود منتجات في هذه الفئة
      final productsSnapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: id)
          .limit(1)
          .get();

      if (productsSnapshot.docs.isNotEmpty) {
        return const Failure('لا يمكن حذف فئة تحتوي على منتجات');
      }

      await _categoriesCollection.doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure('فشل حذف الفئة: $e');
    }
  }

  @override
  Future<Result<void>> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await _categoriesCollection.doc(id).update({'isActive': isActive});
      return const Success(null);
    } catch (e) {
      return Failure('فشل تغيير حالة الفئة: $e');
    }
  }

  @override
  Future<Result<void>> reorderCategories(List<String> categoryIds) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categoryIds.length; i++) {
        final docRef = _categoriesCollection.doc(categoryIds[i]);
        batch.update(docRef, {'order': i});
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure('فشل إعادة ترتيب الفئات: $e');
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _categoriesCollection
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromDocument(doc))
          .toList();
    });
  }
}
