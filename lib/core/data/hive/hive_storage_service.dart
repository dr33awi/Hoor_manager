import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../features/products/domain/entities/product_entity.dart';
import '../../../features/products/domain/entities/category_entity.dart';
import 'hive_adapters.dart';

/// خدمة التخزين المحلي المحسّنة باستخدام Hive TypeAdapters
class HiveStorageService {
  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  HiveStorageService._internal();

  final _logger = Logger();

  // أسماء الصناديق
  static const String _productsBoxName = 'cached_products_v2';
  static const String _categoriesBoxName = 'cached_categories_v2';

  // صناديق Hive
  Box<CachedProduct>? _productsBox;
  Box<CategoryEntity>? _categoriesBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تسجيل الـ Adapters
      registerHiveAdapters();

      // فتح صناديق Hive
      _productsBox = await Hive.openBox<CachedProduct>(_productsBoxName);
      _categoriesBox = await Hive.openBox<CategoryEntity>(_categoriesBoxName);

      _isInitialized = true;
      _logger.i('✅ HiveStorageService initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize HiveStorageService: $e');
      rethrow;
    }
  }

  // ==================== المنتجات ====================

  /// حفظ منتج
  Future<void> saveProduct(ProductEntity product) async {
    if (_productsBox == null) {
      _logger.w('Products box not initialized');
      return;
    }

    try {
      final cached = CachedProduct.fromEntity(product);
      await _productsBox!.put(product.id, cached);
      _logger.d('✅ Saved product: ${product.id}');
    } catch (e) {
      _logger.e('❌ Error saving product: $e');
    }
  }

  /// حفظ قائمة منتجات
  Future<void> saveProducts(List<ProductEntity> products) async {
    if (_productsBox == null) return;

    try {
      final Map<String, CachedProduct> entries = {
        for (final p in products) p.id: CachedProduct.fromEntity(p)
      };
      await _productsBox!.putAll(entries);
      _logger.d('✅ Saved ${products.length} products');
    } catch (e) {
      _logger.e('❌ Error saving products: $e');
    }
  }

  /// حفظ منتج من Map (للتوافق مع الكود القديم)
  Future<void> saveProductFromMap(Map<String, dynamic> productMap) async {
    if (_productsBox == null) return;

    try {
      final cached = CachedProduct.fromMap(productMap);
      await _productsBox!.put(cached.id, cached);
      _logger.d('✅ Saved product from map: ${cached.id}');
    } catch (e) {
      _logger.e('❌ Error saving product from map: $e');
    }
  }

  /// الحصول على جميع المنتجات
  List<ProductEntity> getAllProducts() {
    if (_productsBox == null) return [];

    try {
      return _productsBox!.values.map((c) => c.toEntity()).toList();
    } catch (e) {
      _logger.e('❌ Error getting all products: $e');
      return [];
    }
  }

  /// الحصول على منتج بالـ ID
  ProductEntity? getProductById(String id) {
    if (_productsBox == null) return null;

    try {
      final cached = _productsBox!.get(id);
      return cached?.toEntity();
    } catch (e) {
      _logger.e('❌ Error getting product by id: $e');
      return null;
    }
  }

  /// الحصول على منتج بالباركود
  ProductEntity? getProductByBarcode(String barcode) {
    if (_productsBox == null) return null;

    try {
      // البحث في الباركود الرئيسي
      for (final cached in _productsBox!.values) {
        if (cached.barcode == barcode) {
          return cached.toEntity();
        }
        // البحث في باركود المتغيرات
        for (final variant in cached.variants) {
          if (variant.barcode == barcode) {
            return cached.toEntity();
          }
        }
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error getting product by barcode: $e');
      return null;
    }
  }

  /// تحديث منتج
  Future<void> updateProduct(String id, ProductEntity product) async {
    if (_productsBox == null) return;

    try {
      final cached = CachedProduct.fromEntity(product);
      await _productsBox!.put(id, cached);
      _logger.d('✅ Updated product: $id');
    } catch (e) {
      _logger.e('❌ Error updating product: $e');
    }
  }

  /// حذف منتج
  Future<void> deleteProduct(String id) async {
    if (_productsBox == null) return;

    try {
      await _productsBox!.delete(id);
      _logger.d('✅ Deleted product: $id');
    } catch (e) {
      _logger.e('❌ Error deleting product: $e');
    }
  }

  /// مسح جميع المنتجات
  Future<void> clearProducts() async {
    if (_productsBox == null) return;

    try {
      await _productsBox!.clear();
      _logger.d('✅ Cleared all products');
    } catch (e) {
      _logger.e('❌ Error clearing products: $e');
    }
  }

  /// عدد المنتجات المخزنة
  int get productsCount => _productsBox?.length ?? 0;

  // ==================== الفئات ====================

  /// حفظ فئة
  Future<void> saveCategory(CategoryEntity category) async {
    if (_categoriesBox == null) return;

    try {
      await _categoriesBox!.put(category.id, category);
      _logger.d('✅ Saved category: ${category.id}');
    } catch (e) {
      _logger.e('❌ Error saving category: $e');
    }
  }

  /// حفظ قائمة فئات
  Future<void> saveCategories(List<CategoryEntity> categories) async {
    if (_categoriesBox == null) return;

    try {
      final Map<String, CategoryEntity> entries = {
        for (final c in categories) c.id: c
      };
      await _categoriesBox!.putAll(entries);
      _logger.d('✅ Saved ${categories.length} categories');
    } catch (e) {
      _logger.e('❌ Error saving categories: $e');
    }
  }

  /// الحصول على جميع الفئات
  List<CategoryEntity> getAllCategories() {
    if (_categoriesBox == null) return [];

    try {
      return _categoriesBox!.values.toList();
    } catch (e) {
      _logger.e('❌ Error getting all categories: $e');
      return [];
    }
  }

  /// الحصول على فئة بالـ ID
  CategoryEntity? getCategoryById(String id) {
    if (_categoriesBox == null) return null;

    try {
      return _categoriesBox!.get(id);
    } catch (e) {
      _logger.e('❌ Error getting category by id: $e');
      return null;
    }
  }

  /// حذف فئة
  Future<void> deleteCategory(String id) async {
    if (_categoriesBox == null) return;

    try {
      await _categoriesBox!.delete(id);
      _logger.d('✅ Deleted category: $id');
    } catch (e) {
      _logger.e('❌ Error deleting category: $e');
    }
  }

  /// مسح جميع الفئات
  Future<void> clearCategories() async {
    if (_categoriesBox == null) return;

    try {
      await _categoriesBox!.clear();
      _logger.d('✅ Cleared all categories');
    } catch (e) {
      _logger.e('❌ Error clearing categories: $e');
    }
  }

  /// عدد الفئات المخزنة
  int get categoriesCount => _categoriesBox?.length ?? 0;

  // ==================== أدوات مساعدة ====================

  /// مسح جميع البيانات المخزنة
  Future<void> clearAllData() async {
    await clearProducts();
    await clearCategories();
    _logger.i('✅ Cleared all cached data');
  }

  /// الحصول على حجم البيانات المخزنة (تقريبي)
  Map<String, int> getStorageStats() {
    return {
      'products': productsCount,
      'categories': categoriesCount,
    };
  }

  /// إغلاق الخدمة
  Future<void> close() async {
    await _productsBox?.close();
    await _categoriesBox?.close();
    _isInitialized = false;
    _logger.i('HiveStorageService closed');
  }
}
