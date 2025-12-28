import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/offline_service.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';

// ==================== Service Providers ====================

/// مزود خدمة الأوفلاين
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
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

// ==================== Product Providers ====================

/// مزود جميع المنتجات (Future)
final allProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProducts();
  return result.valueOrNull ?? [];
});

/// مزود جميع المنتجات (Stream - للتحديث التلقائي)
final allProductsStreamProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts();
});

/// مزود منتج واحد بالمعرف
final productByIdProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, productId) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductById(productId);
    return result.valueOrNull;
  },
);

/// مزود منتج واحد بالباركود
final productByBarcodeProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, barcode) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductByBarcode(barcode);
    return result.valueOrNull;
  },
);

/// مزود البحث في المنتجات
final searchProductsProvider =
    FutureProvider.family<List<ProductEntity>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProducts(searchQuery: query);
    return result.valueOrNull ?? [];
  },
);

/// مزود المنتجات منخفضة المخزون
final lowStockProductsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getLowStockProducts();
  return result.valueOrNull ?? [];
});

/// مزود المنتجات منخفضة المخزون (Stream)
final lowStockProductsStreamProvider =
    StreamProvider<List<ProductEntity>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchLowStockProducts();
});

/// مزود المنتجات النافدة من المخزون (Stream)
final outOfStockProductsStreamProvider =
    StreamProvider<List<ProductEntity>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchOutOfStockProducts();
});

/// مزود منتج واحد بالمعرف (Stream - للتحديث التلقائي)
final productStreamProvider = StreamProvider.family<ProductEntity?, String>(
  (ref, productId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.watchProduct(productId);
  },
);

/// مزود منتج واحد (Alias للتوافق مع الشاشات)
final productProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, productId) async {
    final repository = ref.watch(productRepositoryProvider);
    final result = await repository.getProductById(productId);
    return result.valueOrNull;
  },
);

/// مزود البحث في المنتجات (State)
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// مزود الفئة المحددة
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// مزود المنتجات المفلترة
final filteredProductsProvider = Provider<List<ProductEntity>>((ref) {
  final productsAsync = ref.watch(allProductsStreamProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products;

      // فلترة حسب الفئة
      if (selectedCategory != null) {
        filtered =
            filtered.where((p) => p.categoryId == selectedCategory).toList();
      }

      // فلترة حسب البحث
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(query) ||
              (p.barcode?.toLowerCase().contains(query) ?? false) ||
              (p.categoryName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ==================== Category Providers ====================

/// مزود جميع الفئات
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();
  return result.valueOrNull ?? [];
});

/// مزود جميع الفئات (Stream)
final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

/// مزود فئة واحدة بالمعرف
final categoryByIdProvider = FutureProvider.family<CategoryEntity?, String>(
  (ref, categoryId) async {
    final repository = ref.watch(categoryRepositoryProvider);
    final result = await repository.getCategoryById(categoryId);
    return result.valueOrNull;
  },
);

// ==================== Offline Providers ====================

/// مزود عدد العمليات المعلقة
final pendingOperationsCountProvider = Provider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingOperationsCount;
});

/// مزود Stream لعدد العمليات المعلقة
final pendingOperationsStreamProvider = StreamProvider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingCountStream;
});

/// مزود حالة الاتصال
final connectivityProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectivityStream;
});

/// مزود حالة المزامنة
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.syncStatusStream;
});

// ==================== Product Actions ====================

/// إدارة عمليات المنتجات
class ProductActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// إضافة منتج جديد
  Future<bool> addProduct(ProductEntity product) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.addProduct(product);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// إضافة منتج جديد (مع إرجاع الكيان)
  Future<ProductEntity?> addProductWithEntity(ProductEntity product) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.addProduct(product);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      return result.valueOrNull;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return null;
    }
  }

  /// تحديث منتج
  Future<bool> updateProduct(ProductEntity product) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.updateProduct(product);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      ref.invalidate(productByIdProvider(product.id));
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(String productId) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.deleteProduct(productId);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تحديث المخزون
  Future<bool> updateStock({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.updateVariantStock(
      productId: productId,
      variantId: variantId,
      newQuantity: quantity,
    );

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      ref.invalidate(productByIdProvider(productId));
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// إضافة للمخزون
  Future<bool> addStock({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.addStock(
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      _refreshProducts();
      ref.invalidate(productByIdProvider(productId));
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تحديث البيانات
  void _refreshProducts() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(lowStockProductsProvider);
  }

  /// مزامنة البيانات يدوياً
  Future<SyncResult> syncData() async {
    final offlineService = ref.read(offlineServiceProvider);
    final result = await offlineService.syncPendingOperations();
    if (result.success) {
      _refreshProducts();
    }
    return result;
  }
}

/// مزود إدارة عمليات المنتجات
final productActionsProvider =
    NotifierProvider<ProductActionsNotifier, AsyncValue<void>>(() {
  return ProductActionsNotifier();
});

// ==================== Category Actions ====================

/// إدارة عمليات الفئات
class CategoryActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// إضافة فئة جديدة
  Future<bool> addCategory(CategoryEntity category) async {
    final repository = ref.read(categoryRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.addCategory(category);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      ref.invalidate(categoriesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// إضافة فئة جديدة (مع إرجاع الكيان)
  Future<CategoryEntity?> addCategoryWithEntity(CategoryEntity category) async {
    final repository = ref.read(categoryRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.addCategory(category);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      ref.invalidate(categoriesProvider);
      return result.valueOrNull;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return null;
    }
  }

  /// تحديث فئة
  Future<bool> updateCategory(CategoryEntity category) async {
    final repository = ref.read(categoryRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.updateCategory(category);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      ref.invalidate(categoriesProvider);
      ref.invalidate(categoryByIdProvider(category.id));
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// حذف فئة
  Future<bool> deleteCategory(String categoryId) async {
    final repository = ref.read(categoryRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.deleteCategory(categoryId);

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      ref.invalidate(categoriesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }
}

/// مزود إدارة عمليات الفئات
final categoryActionsProvider =
    NotifierProvider<CategoryActionsNotifier, AsyncValue<void>>(() {
  return CategoryActionsNotifier();
});
