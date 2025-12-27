import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../data/database.dart';

/// صفحة المنتجات
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _searchQuery = '';
  String _filterType = 'all'; // all, lowStock, outOfStock, active

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final productsAsync = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقات المواد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingSM),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'ابحث عن منتج...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onScan: _scanBarcode,
            ),
          ),

          // التصنيفات
          SizedBox(
            height: 50,
            child: categoriesAsync.when(
              data: (categories) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: const Text('الكل'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() => _selectedCategoryId = null);
                        },
                      ),
                    );
                  }
                  final category = categories[index - 1];
                  final isSelected = _selectedCategoryId == category.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category.id : null;
                        });
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('خطأ: $error')),
            ),
          ),

          const Divider(height: 1),

          // قائمة المنتجات
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد منتجات',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allProductsProvider);
                    ref.invalidate(allCategoriesProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingSM),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        name: product.name,
                        barcode: product.barcode ?? '',
                        price: product.salePrice,
                        qty: product.qty,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.productForm,
                            arguments: product.id.toString(),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('خطأ في تحميل المنتجات',
                        style: TextStyle(color: AppColors.error)),
                    const SizedBox(height: 8),
                    Text('$error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allProductsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, AppRoutes.productForm);
          if (result == true) {
            ref.invalidate(allProductsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
    );
  }

  AsyncValue<List<Product>> _getFilteredProducts() {
    // إذا كان هناك بحث
    if (_searchQuery.isNotEmpty) {
      return ref.watch(productSearchProvider(_searchQuery));
    }

    // إذا كان هناك تصنيف محدد
    if (_selectedCategoryId != null) {
      return ref.watch(productsByCategoryProvider(_selectedCategoryId));
    }

    // إذا كان هناك فلتر
    switch (_filterType) {
      case 'lowStock':
        return ref.watch(lowStockProductsProvider);
      default:
        return ref.watch(allProductsProvider);
    }
  }

  void _scanBarcode() async {
    // TODO: تنفيذ مسح الباركود
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: مسح الباركود')),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'فلترة المنتجات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('جميع المنتجات'),
              selected: _filterType == 'all',
              onTap: () {
                setState(() => _filterType = 'all');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: AppColors.warning),
              title: const Text('كمية منخفضة'),
              selected: _filterType == 'lowStock',
              onTap: () {
                setState(() => _filterType = 'lowStock');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.error, color: AppColors.error),
              title: const Text('نفد المخزون'),
              selected: _filterType == 'outOfStock',
              onTap: () {
                setState(() => _filterType = 'outOfStock');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('المنتجات النشطة'),
              selected: _filterType == 'active',
              onTap: () {
                setState(() => _filterType = 'active');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
