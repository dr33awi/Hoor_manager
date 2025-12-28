import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../products/domain/entities/entities.dart';
import '../../../products/presentation/providers/product_providers.dart';

/// فلتر حالة المخزون
enum StockFilter { all, inStock, lowStock, outOfStock }

/// مزود فلتر المخزون
final stockFilterProvider =
    StateProvider<StockFilter>((ref) => StockFilter.all);

/// مزود البحث في المخزون
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

/// مزود ترتيب المخزون
final stockSortProvider = StateProvider<String>((ref) => 'name');

/// مزود المنتجات المفلترة للمخزون
final filteredStockProductsProvider =
    Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final productsAsync = ref.watch(allProductsStreamProvider);
  final filter = ref.watch(stockFilterProvider);
  final searchQuery = ref.watch(stockSearchQueryProvider).toLowerCase();
  final sortBy = ref.watch(stockSortProvider);

  return productsAsync.when(
    data: (products) {
      var filtered = products.toList();

      // فلترة حسب حالة المخزون
      switch (filter) {
        case StockFilter.inStock:
          filtered = filtered
              .where((p) => p.totalStock > p.lowStockThreshold)
              .toList();
          break;
        case StockFilter.lowStock:
          filtered = filtered
              .where((p) =>
                  p.totalStock > 0 && p.totalStock <= p.lowStockThreshold)
              .toList();
          break;
        case StockFilter.outOfStock:
          filtered = filtered.where((p) => p.totalStock == 0).toList();
          break;
        case StockFilter.all:
          break;
      }

      // البحث
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(searchQuery) ||
              (p.barcode?.toLowerCase().contains(searchQuery) ?? false) ||
              (p.categoryName?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }

      // الترتيب
      switch (sortBy) {
        case 'name':
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'stock_asc':
          filtered.sort((a, b) => a.totalStock.compareTo(b.totalStock));
          break;
        case 'stock_desc':
          filtered.sort((a, b) => b.totalStock.compareTo(a.totalStock));
          break;
        case 'value':
          filtered.sort((a, b) =>
              (b.totalStock * b.cost).compareTo(a.totalStock * a.cost));
          break;
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// شاشة إدارة المخزون
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredStockProductsProvider);
    final filter = ref.watch(stockFilterProvider);
    final allProductsAsync = ref.watch(allProductsStreamProvider);

    // حساب الإحصائيات
    final stats = allProductsAsync.whenData((products) {
      final total = products.length;
      final inStock =
          products.where((p) => p.totalStock > p.lowStockThreshold).length;
      final lowStock = products
          .where((p) => p.totalStock > 0 && p.totalStock <= p.lowStockThreshold)
          .length;
      final outOfStock = products.where((p) => p.totalStock == 0).length;
      final totalValue =
          products.fold(0.0, (sum, p) => sum + (p.totalStock * p.cost));
      return (
        total: total,
        inStock: inStock,
        lowStock: lowStock,
        outOfStock: outOfStock,
        totalValue: totalValue
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          // زر الترتيب
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب',
            onSelected: (value) {
              ref.read(stockSortProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('حسب الاسم')),
              const PopupMenuItem(
                  value: 'stock_asc', child: Text('الأقل مخزوناً')),
              const PopupMenuItem(
                  value: 'stock_desc', child: Text('الأكثر مخزوناً')),
              const PopupMenuItem(value: 'value', child: Text('حسب القيمة')),
            ],
          ),
          // زر تقرير المخزون
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/reports/inventory'),
            tooltip: 'تقرير المخزون',
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات سريعة
          stats.whenData((s) => _buildStatsBar(context, s)).value ??
              const SizedBox.shrink(),

          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(stockSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(stockSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // فلاتر حالة المخزون
          _buildFilterChips(filter, stats),

          // قائمة المنتجات
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allProductsStreamProvider);
              },
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildProductsList(products);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
      BuildContext context,
      ({
        int total,
        int inStock,
        int lowStock,
        int outOfStock,
        double totalValue
      }) stats) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              context, 'إجمالي', '${stats.total}', Icons.inventory_2),
          _buildStatItem(context, 'متوفر', '${stats.inStock}',
              Icons.check_circle, AppColors.success),
          _buildStatItem(context, 'منخفض', '${stats.lowStock}', Icons.warning,
              AppColors.warning),
          _buildStatItem(context, 'نفد', '${stats.outOfStock}', Icons.error,
              AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon,
      [Color? iconColor]) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? AppColors.secondary, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
      StockFilter currentFilter,
      AsyncValue<
              ({
                int total,
                int inStock,
                int lowStock,
                int outOfStock,
                double totalValue
              })>
          stats) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        children: [
          _buildFilterChip(
            'الكل',
            StockFilter.all,
            currentFilter,
            stats.value?.total,
          ),
          _buildFilterChip(
            'متوفر',
            StockFilter.inStock,
            currentFilter,
            stats.value?.inStock,
            AppColors.success,
          ),
          _buildFilterChip(
            'منخفض',
            StockFilter.lowStock,
            currentFilter,
            stats.value?.lowStock,
            AppColors.warning,
          ),
          _buildFilterChip(
            'نفد',
            StockFilter.outOfStock,
            currentFilter,
            stats.value?.outOfStock,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, StockFilter filter, StockFilter currentFilter, int? count,
      [Color? color]) {
    final isSelected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.xs),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.textLight
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (_) {
          ref.read(stockFilterProvider.notifier).state = filter;
        },
      ),
    );
  }

  Widget _buildProductsList(List<ProductEntity> products) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSizes.xl),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    final stockStatus = _getStockStatus(product);

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // صورة المنتج أو أيقونة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: stockStatus.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2,
                            color: stockStatus.color,
                          ),
                        ),
                      )
                    : Icon(Icons.inventory_2, color: stockStatus.color),
              ),
              const SizedBox(width: AppSizes.md),

              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.categoryName ?? 'بدون فئة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // شريط حالة المخزون
                    Row(
                      children: [
                        Icon(stockStatus.icon,
                            size: 14, color: stockStatus.color),
                        const SizedBox(width: 4),
                        Text(
                          stockStatus.label,
                          style: TextStyle(
                            color: stockStatus.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // الكمية والقيمة
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockStatus.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      '${product.totalStock}',
                      style: TextStyle(
                        color: stockStatus.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (product.totalStock * product.cost).toCurrency(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, IconData icon, String label}) _getStockStatus(
      ProductEntity product) {
    if (product.totalStock == 0) {
      return (color: AppColors.error, icon: Icons.error, label: 'نفد');
    } else if (product.totalStock <= product.lowStockThreshold) {
      return (color: AppColors.warning, icon: Icons.warning, label: 'منخفض');
    } else {
      return (
        color: AppColors.success,
        icon: Icons.check_circle,
        label: 'متوفر'
      );
    }
  }

  Widget _buildEmptyState() {
    final hasFilters = ref.read(stockFilterProvider) != StockFilter.all ||
        ref.read(stockSearchQueryProvider).isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            hasFilters ? 'لا توجد منتجات مطابقة' : 'لا توجد منتجات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppSizes.sm),
            TextButton.icon(
              onPressed: () {
                ref.read(stockFilterProvider.notifier).state = StockFilter.all;
                ref.read(stockSearchQueryProvider.notifier).state = '';
                _searchController.clear();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('مسح الفلاتر'),
            ),
          ] else ...[
            const SizedBox(height: AppSizes.sm),
            FilledButton.icon(
              onPressed: () => context.push('/products/add'),
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج'),
            ),
          ],
        ],
      ),
    );
  }
}
