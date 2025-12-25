import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/offline_service.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';

// ==================== Offline Service Provider ====================

/// مزود خدمة الأوفلاين
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

/// مزود حالة الاتصال
final isOnlineProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectivityStream;
});

/// مزود عدد العمليات المعلقة
final pendingOperationsCountProvider = Provider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingOperationsCount;
});

// ==================== Repository Providers ====================

/// مزود مستودع المنتجات
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return ProductRepositoryImpl(offlineService: offlineService);
});

/// مزود مستودع الفئات
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

// ==================== Category Providers ====================

/// مزود قائمة الفئات
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories(isActive: true);
  return result.valueOrNull ?? [];
});

/// مزود مراقبة الفئات (Stream)
final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

/// مزود الفئة المحددة
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ==================== Product Providers ====================

/// مزود قائمة المنتجات
final productsProvider = FutureProvider.family<List<ProductEntity>, String?>(
  (ref, categoryId) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProducts(
      categoryId: categoryId,
      isActive: true,
    );
    return result.valueOrNull ?? [];
  },
);

/// مزود جميع المنتجات
final allProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProducts();
  return result.valueOrNull ?? [];
});

/// مزود مراقبة جميع المنتجات (Stream) - للتحديث التلقائي
final allProductsStreamProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts();
});

/// مزود مراقبة المنتجات (Stream)
final productsStreamProvider =
    StreamProvider.family<List<ProductEntity>, String?>(
  (ref, categoryId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchProducts(categoryId: categoryId);
  },
);

/// مزود منتج واحد
final productProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, productId) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductById(productId);
    return result.valueOrNull;
  },
);

/// مزود مراقبة منتج واحد
final productStreamProvider = StreamProvider.family<ProductEntity?, String>(
  (ref, productId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchProduct(productId);
  },
);

/// مزود البحث عن منتج بالباركود
final productByBarcodeProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, barcode) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductByBarcode(barcode);
    return result.valueOrNull;
  },
);

/// مزود المنتجات منخفضة المخزون
final lowStockProductsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getLowStockProducts();
  return result.valueOrNull ?? [];
});

/// مزود المنتجات منخفضة المخزون (Stream - للتحديث التلقائي)
final lowStockProductsStreamProvider =
    StreamProvider<List<ProductEntity>>((ref) {
  // الحفاظ على الـ Stream في الذاكرة لتحميل أسرع
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchLowStockProducts();
});

/// مزود المنتجات النافدة
final outOfStockProductsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getOutOfStockProducts();
  return result.valueOrNull ?? [];
});

/// مزود المنتجات النافدة (Stream - للتحديث التلقائي)
final outOfStockProductsStreamProvider =
    StreamProvider<List<ProductEntity>>((ref) {
  // الحفاظ على الـ Stream في الذاكرة لتحميل أسرع
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchOutOfStockProducts();
});

// ==================== Search & Filter Providers ====================

/// مزود نص البحث
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// مزود المنتجات المفلترة
final filteredProductsProvider = Provider<List<ProductEntity>>((ref) {
  final categoryId = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final productsAsync = ref.watch(productsStreamProvider(categoryId));

  return productsAsync.when(
    data: (products) {
      if (searchQuery.isEmpty) return products;

      final query = searchQuery.toLowerCase();
      return products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.barcode?.contains(searchQuery) ?? false) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ==================== Product Actions Notifier ====================

/// إدارة عمليات المنتجات مع دعم الأوفلاين
class ProductActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;
  final Ref _ref;

  ProductActionsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// التحقق من حالة الاتصال
  bool get isOnline => OfflineService().isOnline;

  /// إضافة منتج (يعمل أوفلاين)
  Future<bool> addProduct(ProductEntity product) async {
    state = const AsyncValue.loading();
    final result = await _repository.addProduct(product);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(allProductsProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تحديث منتج (يعمل أوفلاين)
  Future<bool> updateProduct(ProductEntity product) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateProduct(product);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(productProvider(product.id));
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteProduct(productId);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(allProductsProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تبديل حالة المنتج
  Future<bool> toggleStatus(String productId, bool isActive) async {
    final result = await _repository.toggleProductStatus(productId, isActive);
    if (result.isSuccess) {
      _ref.invalidate(productProvider(productId));
    }
    return result.isSuccess;
  }
}

/// مزود إدارة عمليات المنتجات
final productActionsProvider =
    StateNotifierProvider<ProductActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductActionsNotifier(repository, ref);
});

// ==================== Category Actions Notifier ====================

/// إدارة عمليات الفئات
class CategoryActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;
  final Ref _ref;

  CategoryActionsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// إضافة فئة
  Future<bool> addCategory(CategoryEntity category) async {
    state = const AsyncValue.loading();
    final result = await _repository.addCategory(category);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(categoriesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تحديث فئة
  Future<bool> updateCategory(CategoryEntity category) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCategory(category);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(categoriesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// حذف فئة
  Future<bool> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteCategory(categoryId);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _ref.invalidate(categoriesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }
}

/// مزود إدارة عمليات الفئات
final categoryActionsProvider =
    StateNotifierProvider<CategoryActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryActionsNotifier(repository, ref);
});
