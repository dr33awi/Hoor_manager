import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع المنتجات
abstract class ProductRepository {
  /// الحصول على جميع المنتجات
  Future<Result<List<ProductEntity>>> getProducts({
    String? categoryId,
    bool? isActive,
    String? searchQuery,
  });

  /// الحصول على منتج بالمعرف
  Future<Result<ProductEntity>> getProductById(String id);

  /// الحصول على منتج بالباركود
  Future<Result<ProductEntity>> getProductByBarcode(String barcode);

  /// إضافة منتج جديد
  Future<Result<ProductEntity>> addProduct(ProductEntity product);

  /// تحديث منتج
  Future<Result<ProductEntity>> updateProduct(ProductEntity product);

  /// حذف منتج
  Future<Result<void>> deleteProduct(String id);

  /// تفعيل/تعطيل منتج
  Future<Result<void>> toggleProductStatus(String id, bool isActive);

  /// تحديث مخزون متغير
  Future<Result<void>> updateVariantStock({
    required String productId,
    required String variantId,
    required int newQuantity,
  });

  /// خصم من المخزون (عند البيع)
  Future<Result<void>> deductStock({
    required String productId,
    required String variantId,
    required int quantity,
  });

  /// إضافة للمخزون
  Future<Result<void>> addStock({
    required String productId,
    required String variantId,
    required int quantity,
  });

  /// الحصول على المنتجات منخفضة المخزون
  Future<Result<List<ProductEntity>>> getLowStockProducts();

  /// الحصول على المنتجات النافدة
  Future<Result<List<ProductEntity>>> getOutOfStockProducts();

  /// مراقبة المنتجات (Stream)
  Stream<List<ProductEntity>> watchProducts({String? categoryId});

  /// مراقبة منتج واحد
  Stream<ProductEntity?> watchProduct(String id);
}

/// واجهة مستودع الفئات
abstract class CategoryRepository {
  /// الحصول على جميع الفئات
  Future<Result<List<CategoryEntity>>> getCategories({bool? isActive});

  /// الحصول على فئة بالمعرف
  Future<Result<CategoryEntity>> getCategoryById(String id);

  /// إضافة فئة جديدة
  Future<Result<CategoryEntity>> addCategory(CategoryEntity category);

  /// تحديث فئة
  Future<Result<CategoryEntity>> updateCategory(CategoryEntity category);

  /// حذف فئة
  Future<Result<void>> deleteCategory(String id);

  /// تفعيل/تعطيل فئة
  Future<Result<void>> toggleCategoryStatus(String id, bool isActive);

  /// إعادة ترتيب الفئات
  Future<Result<void>> reorderCategories(List<String> categoryIds);

  /// مراقبة الفئات
  Stream<List<CategoryEntity>> watchCategories();
}
