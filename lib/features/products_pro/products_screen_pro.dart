// ═══════════════════════════════════════════════════════════════════════════
// Products Screen Pro - Professional Design System
// Modern Products Management Interface with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/export/export_button.dart';
import '../../core/services/export/products_export_service.dart';
import '../../data/database/app_database.dart';
import 'widgets/product_card_pro.dart';
import 'widgets/products_header.dart';
import 'widgets/products_filter_bar.dart';
import 'widgets/category_chips.dart';

class ProductsScreenPro extends ConsumerStatefulWidget {
  const ProductsScreenPro({super.key});

  @override
  ConsumerState<ProductsScreenPro> createState() => _ProductsScreenProState();
}

class _ProductsScreenProState extends ConsumerState<ProductsScreenPro>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedCategoryId = 'all';
  String _sortBy = 'name';
  bool _isGridView = true;
  bool _isExporting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(
      List<Product> products, List<Category> categories) {
    return products.where((product) {
      // فلتر البحث
      final matchesSearch = _searchController.text.isEmpty ||
          product.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          (product.sku
                  ?.toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ??
              false) ||
          (product.barcode
                  ?.toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ??
              false);

      // فلتر التصنيف
      final matchesCategory = _selectedCategoryId == 'all' ||
          product.categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> _sortProducts(List<Product> products) {
    final sorted = List<Product>.from(products);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case 'stock':
        sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'recent':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  Future<void> _handleExport(ExportType type, List<Product> products) async {
    if (products.isEmpty) {
      ProSnackbar.warning(context, 'لا توجد منتجات للتصدير');
      return;
    }

    setState(() => _isExporting = true);

    try {
      switch (type) {
        case ExportType.excel:
          final filePath = await ProductsExportService.exportToExcel(
            products: products,
            fileName: 'products_list',
          );
          if (mounted) {
            ProSnackbar.success(
              context,
              'تم تصدير ${products.length} منتج إلى Excel',
            );
          }
          break;
        case ExportType.pdf:
          final bytes = await ProductsExportService.generatePdf(
            products: products,
          );
          final filePath =
              await ProductsExportService.savePdf(bytes, 'products_list');
          if (mounted) {
            ProSnackbar.success(
              context,
              'تم تصدير ${products.length} منتج إلى PDF',
            );
          }
          break;
        case ExportType.sharePdf:
          final bytes = await ProductsExportService.generatePdf(
            products: products,
          );
          await ProductsExportService.sharePdfBytes(
            bytes,
            fileName: 'products_list',
            subject: 'قائمة المنتجات',
          );
          break;
        case ExportType.shareExcel:
          final filePath = await ProductsExportService.exportToExcel(
            products: products,
            fileName: 'products_list',
          );
          await ProductsExportService.shareFile(
            filePath,
            subject: 'قائمة المنتجات',
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ProSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // Header
            // ═══════════════════════════════════════════════════════════════
            productsAsync.when(
              loading: () => ProductsHeader(
                onBack: () => context.go('/'),
                totalProducts: 0,
                onAddProduct: () => context.push('/products/add'),
                isExporting: _isExporting,
              ),
              error: (_, __) => ProductsHeader(
                onBack: () => context.go('/'),
                totalProducts: 0,
                onAddProduct: () => context.push('/products/add'),
                isExporting: _isExporting,
              ),
              data: (products) => ProductsHeader(
                onBack: () => context.go('/'),
                totalProducts: products.length,
                onAddProduct: () => context.push('/products/add'),
                onExport: (type) => _handleExport(type, products),
                isExporting: _isExporting,
              ),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Search & Filter Bar
            // ═══════════════════════════════════════════════════════════════
            ProductsFilterBar(
              searchController: _searchController,
              onSearchChanged: (value) => setState(() {}),
              isGridView: _isGridView,
              onViewToggle: () => setState(() => _isGridView = !_isGridView),
              sortBy: _sortBy,
              onSortChanged: (value) =>
                  setState(() => _sortBy = value ?? _sortBy),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Category Chips
            // ═══════════════════════════════════════════════════════════════
            categoriesAsync.when(
              loading: () => const SizedBox(height: 50),
              error: (_, __) => const SizedBox(height: 50),
              data: (categories) {
                // حساب عدد المنتجات لكل تصنيف
                final products = productsAsync.asData?.value ?? [];
                final allCount = products.length;

                final categoryList = [
                  {'id': 'all', 'name': 'الكل', 'count': allCount},
                  ...categories.map((c) {
                    final count =
                        products.where((p) => p.categoryId == c.id).length;
                    return {
                      'id': c.id,
                      'name': c.name,
                      'count': count,
                    };
                  }),
                ];

                return CategoryChips(
                  categories: categoryList,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (categoryId) =>
                      setState(() => _selectedCategoryId = categoryId),
                );
              },
            ),

            // ═══════════════════════════════════════════════════════════════
            // Products Grid/List
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child: productsAsync.when(
                loading: () => ProLoadingState.grid(),
                error: (error, _) => ProEmptyState.error(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(activeProductsStreamProvider),
                ),
                data: (products) {
                  final categories = categoriesAsync.asData?.value ?? [];

                  // Apply filters and sorting
                  var filteredProducts = _filterProducts(products, categories);
                  filteredProducts = _sortProducts(filteredProducts);

                  if (filteredProducts.isEmpty) {
                    final hasFilter = _searchController.text.isNotEmpty ||
                        _selectedCategoryId != 'all';
                    return hasFilter
                        ? ProEmptyState.noResults(
                            onClear: () {
                              setState(() {
                                _searchController.clear();
                                _selectedCategoryId = 'all';
                              });
                            },
                          )
                        : ProEmptyState.list(
                            itemName: 'منتج',
                            onAdd: () => context.push('/products/add'),
                          );
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(activeProductsStreamProvider);
                      },
                      child: _isGridView
                          ? _buildGridView(filteredProducts, categories)
                          : _buildListView(filteredProducts, categories),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'منتج جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGridView(List<Product> products, List<Category> categories) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final category =
            categories.where((c) => c.id == product.categoryId).firstOrNull;
        return ProductCardPro(
          product: _productToMap(product, category),
          isListView: false,
          onTap: () => context.push('/products/${product.id}'),
          onEdit: () => context.push('/products/edit/${product.id}'),
        );
      },
    );
  }

  Widget _buildListView(List<Product> products, List<Category> categories) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = products[index];
        final category =
            categories.where((c) => c.id == product.categoryId).firstOrNull;
        return ProductCardPro(
          product: _productToMap(product, category),
          isListView: true,
          onTap: () => context.push('/products/${product.id}'),
          onEdit: () => context.push('/products/edit/${product.id}'),
        );
      },
    );
  }

  Map<String, dynamic> _productToMap(Product product, Category? category) {
    String status = 'active';
    if (product.quantity <= 0) {
      status = 'out_of_stock';
    } else if (product.quantity <= product.minQuantity) {
      status = 'low_stock';
    }

    return {
      'id': product.id,
      'name': product.name,
      'sku': product.sku ?? '',
      'barcode': product.barcode ?? '',
      'price': product.salePrice,
      'cost': product.purchasePrice,
      'stock': product.quantity,
      'minStock': product.minQuantity,
      'category': category?.name ?? 'بدون تصنيف',
      'categoryId': product.categoryId,
      'image': product.imageUrl,
      'status': status,
      'isActive': product.isActive,
    };
  }
}
