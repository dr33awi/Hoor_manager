// lib/features/products/providers/product_provider.dart
// مزود المنتجات - بدون صور

import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/category_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<ProductModel> get allProducts => _products;
  List<ProductModel> get products =>
      _filteredProducts.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedCategory == null
      ? _products
      : _filteredProducts;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  /// المنتجات منخفضة المخزون
  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  /// المنتجات النافذة من المخزون
  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  /// تحميل كل البيانات
  Future<void> loadAll() async {
    await Future.wait([loadProducts(), loadCategories()]);
  }

  /// تحميل المنتجات
  Future<void> loadProducts() async {
    _setLoading(true);
    _error = null;

    final result = await _productService.getAllProducts();

    if (result.success) {
      _products = result.data!;
      _applyFilters();
    } else {
      _error = result.error;
    }

    _setLoading(false);
  }

  /// تحميل الفئات
  Future<void> loadCategories() async {
    final result = await _categoryService.getAllCategories();

    if (result.success) {
      _categories = result.data!;
      notifyListeners();
    }
  }

  /// إضافة منتج
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    _error = null;

    final result = await _productService.addProduct(product);

    if (result.success) {
      _products.insert(0, result.data!);
      _applyFilters();
      _setLoading(false);
      return true;
    } else {
      _error = result.error;
      _setLoading(false);
      return false;
    }
  }

  /// تحديث منتج
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    _error = null;

    final result = await _productService.updateProduct(product);

    if (result.success) {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } else {
      _error = result.error;
      _setLoading(false);
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _error = null;

    final result = await _productService.deleteProduct(productId);

    if (result.success) {
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
      _setLoading(false);
      return true;
    } else {
      _error = result.error;
      _setLoading(false);
      return false;
    }
  }

  /// إضافة فئة
  Future<bool> addCategory(String name) async {
    final category = CategoryModel(
      id: '',
      name: name,
      order: _categories.length,
      createdAt: DateTime.now(),
    );

    final result = await _categoryService.addCategory(category);

    if (result.success) {
      _categories.add(result.data!);
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      return false;
    }
  }

  /// تعيين نص البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// البحث (alias for setSearchQuery)
  void search(String query) {
    setSearchQuery(query);
  }

  /// تعيين الفئة المحددة
  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// فلترة حسب الفئة (alias for setSelectedCategory)
  void filterByCategory(String? category) {
    setSelectedCategory(category);
  }

  /// مسح الفلاتر
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _filteredProducts = [];
    notifyListeners();
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    var result = List<ProductModel>.from(_products);

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
      }).toList();
    }

    // فلترة حسب الفئة
    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    _filteredProducts = result;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// الحصول على منتج بالـ ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// تحديث المخزون
  Future<bool> updateInventory(
    String productId,
    String color,
    int size,
    int quantity,
  ) async {
    final result = await _productService.updateInventory(
      productId,
      color,
      size,
      quantity,
    );

    if (result.success) {
      await loadProducts();
      return true;
    }
    return false;
  }
}
