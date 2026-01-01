// ═══════════════════════════════════════════════════════════════════════════
// Products Screen Pro - Professional Design System
// Modern Products Management Interface with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';
import '../../core/providers/app_providers.dart';
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
  String _selectedCategory = 'الكل';
  String _sortBy = 'name';
  bool _isGridView = true;
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

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
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
      // Category filter is handled separately via categories
      return matchesSearch;
    }).toList();
  }

  List<Product> _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'name':
        return products..sort((a, b) => a.name.compareTo(b.name));
      case 'price_asc':
        return products..sort((a, b) => a.salePrice.compareTo(b.salePrice));
      case 'price_desc':
        return products..sort((a, b) => b.salePrice.compareTo(a.salePrice));
      case 'stock':
        return products..sort((a, b) => a.quantity.compareTo(b.quantity));
      default:
        return products;
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
              ),
              error: (_, __) => ProductsHeader(
                onBack: () => context.go('/'),
                totalProducts: 0,
                onAddProduct: () => context.push('/products/add'),
              ),
              data: (products) => ProductsHeader(
                onBack: () => context.go('/'),
                totalProducts: products.length,
                onAddProduct: () => context.push('/products/add'),
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
                final categoryList = [
                  {'id': 'all', 'name': 'الكل', 'count': 0},
                  ...categories.map((c) => {
                        'id': c.id,
                        'name': c.name,
                        'count': 0,
                      }),
                ];
                return CategoryChips(
                  categories: categoryList,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) =>
                      setState(() => _selectedCategory = category),
                );
              },
            ),

            // ═══════════════════════════════════════════════════════════════
            // Products Grid/List
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child: productsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
                data: (products) {
                  // Filter by category
                  var filteredProducts = _selectedCategory == 'الكل'
                      ? products
                      : products
                          .where((p) => p.categoryId == _selectedCategory)
                          .toList();

                  // Apply search filter
                  filteredProducts = _filterProducts(filteredProducts);

                  // Apply sorting
                  filteredProducts = _sortProducts(filteredProducts);

                  if (filteredProducts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(activeProductsStreamProvider);
                      },
                      child: _isGridView
                          ? _buildGridView(filteredProducts)
                          : _buildListView(filteredProducts),
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

  Widget _buildGridView(List<Product> products) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md.w,
        mainAxisSpacing: AppSpacing.md.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCardPro(
          product: _productToMap(product),
          onTap: () => context.push('/products/${product.id}'),
          onEdit: () => context.push('/products/${product.id}/edit'),
        );
      },
    );
  }

  Widget _buildListView(List<Product> products) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCardPro(
          product: _productToMap(product),
          onTap: () => context.push('/products/${product.id}'),
          onEdit: () => context.push('/products/${product.id}/edit'),
        );
      },
    );
  }

  Map<String, dynamic> _productToMap(Product product) {
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
      'category': product.categoryId ?? '',
      'image': product.imageUrl,
      'status': status,
      'isActive': product.isActive,
    };
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md.w,
        mainAxisSpacing: AppSpacing.md.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80.sp,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text(
            'لا توجد منتجات',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            'أضف منتجات جديدة للبدء',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/products/add'),
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl.w,
                vertical: AppSpacing.md.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: AppColors.expense,
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text(
            'حدث خطأ',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.expense,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            error,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl.h),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(activeProductsStreamProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
