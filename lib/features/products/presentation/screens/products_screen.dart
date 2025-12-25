import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/services/barcode_service.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';
import '../providers/product_providers.dart';
import '../widgets/widgets.dart';

/// شاشة قائمة المنتجات
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final products = ref.watch(filteredProductsProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.products),
        actions: [
          // زر البحث بالباركود
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(),
            tooltip: 'مسح باركود',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(productSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // شريط الفئات
          categoriesAsync.when(
            data: (categories) =>
                _buildCategoriesBar(categories, selectedCategory),
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // قائمة المنتجات
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : _buildProductsList(products),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products_fab',
        onPressed: () => context.push(AppRoutes.addProduct),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriesBar(
      List<CategoryEntity> categories, String? selectedId) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // خيار "الكل"
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.xs),
              child: ChoiceChip(
                label: const Text('الكل'),
                selected: selectedId == null,
                onSelected: (_) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                },
              ),
            );
          }

          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs),
            child: ChoiceChip(
              label: Text(category.name),
              selected: selectedId == category.id,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).state = category.id;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(List<ProductEntity> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => context.push('/products/${product.id}'),
          onEdit: () => context.push('/products/edit/${product.id}'),
          onDelete: () => _confirmDelete(product),
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
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.noProducts,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'اضغط على + لإضافة منتج جديد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerService.scan(context);

    if (barcode != null && barcode.isNotEmpty && mounted) {
      // البحث عن المنتج بالباركود
      final productAsync =
          await ref.read(productByBarcodeProvider(barcode).future);

      if (mounted) {
        if (productAsync != null) {
          context.push('/products/${productAsync.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لم يتم العثور على منتج بالباركود: $barcode'),
              action: SnackBarAction(
                label: 'إضافة منتج',
                onPressed: () => context.push('/products/add'),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(ProductEntity product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content:
            Text('هل تريد حذف "${product.name}"؟\n${AppStrings.deleteWarning}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(productActionsProvider.notifier)
          .deleteProduct(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف المنتج' : 'فشل حذف المنتج'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
