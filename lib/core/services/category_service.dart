// lib/features/products/services/category_service.dart
// خدمة الفئات

import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';
import 'firebase_service.dart';
import '../../features/products/models/category_model.dart';

class CategoryService extends BaseService {
  final FirebaseService _firebase = FirebaseService();
  final String _collection = AppConstants.categoriesCollection;

  // Singleton
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// إضافة فئة جديدة
  Future<ServiceResult<CategoryModel>> addCategory(
    CategoryModel category,
  ) async {
    try {
      final id = const Uuid().v4();
      final newCategory = category.copyWith(id: id, createdAt: DateTime.now());

      final result = await _firebase.set(_collection, id, newCategory.toMap());
      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }

      return ServiceResult.success(newCategory);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// تحديث فئة
  Future<ServiceResult<void>> updateCategory(CategoryModel category) async {
    try {
      return await _firebase.update(_collection, category.id, category.toMap());
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// حذف فئة
  Future<ServiceResult<void>> deleteCategory(String categoryId) async {
    try {
      return await _firebase.delete(_collection, categoryId);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// الحصول على جميع الفئات
  Future<ServiceResult<List<CategoryModel>>> getAllCategories({
    bool activeOnly = true,
  }) async {
    try {
      final result = await _firebase.getAll(
        _collection,
        queryBuilder: (ref) {
          return ref.orderBy('order');
        },
      );

      if (!result.success) {
        return ServiceResult.failure(result.error!);
      }

      var categories = result.data!.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      if (activeOnly) {
        categories = categories.where((c) => c.isActive).toList();
      }

      return ServiceResult.success(categories);
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }

  /// Stream للفئات
  Stream<List<CategoryModel>> streamCategories({bool activeOnly = true}) {
    return _firebase
        .streamCollection(
          _collection,
          queryBuilder: (ref) {
            return ref.orderBy('order');
          },
        )
        .map((snapshot) {
          var categories = snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();

          if (activeOnly) {
            categories = categories.where((c) => c.isActive).toList();
          }

          return categories;
        });
  }

  /// إضافة فئات افتراضية
  Future<ServiceResult<void>> addDefaultCategories() async {
    try {
      final defaults = ['رياضي', 'رسمي', 'كاجوال', 'أطفال', 'نسائي', 'صنادل'];

      for (int i = 0; i < defaults.length; i++) {
        await addCategory(
          CategoryModel(
            id: '',
            name: defaults[i],
            order: i,
            createdAt: DateTime.now(),
          ),
        );
      }

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(handleError(e));
    }
  }
}
