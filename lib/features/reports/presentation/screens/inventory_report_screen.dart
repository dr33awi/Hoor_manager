import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/reports_providers.dart';
import '../widgets/widgets.dart';

/// شاشة تقرير المخزون
class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // استخدام StreamProvider للتحديث التلقائي
    final reportAsync = ref.watch(inventoryReportStreamProvider);

    // تحميل مسبق لبيانات المخزون لتسريع عرضها لاحقاً
    ref.watch(lowStockProductsStreamProvider);
    ref.watch(outOfStockProductsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المخزون'),
      ),
      body: reportAsync.when(
        data: (report) => _buildReportContent(context, ref, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    WidgetRef ref,
    InventoryReport report,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص المخزون
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'إجمالي المنتجات',
                  value: '${report.totalProducts}',
                  icon: Icons.inventory_2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'إجمالي المخزون',
                  value: '${report.totalStock}',
                  icon: Icons.category,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'قيمة المخزون',
                  value: report.totalStockValue.toCurrency(),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'الربح المتوقع',
                  value: report.potentialProfit.toCurrency(),
                  icon: Icons.trending_up,
                  color: AppColors.secondary,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // تنبيهات المخزون
          if (report.lowStockProducts > 0 || report.outOfStockProducts > 0)
            _buildAlerts(context, ref, report),

          const SizedBox(height: AppSizes.lg),

          // حالة المنتجات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة المنتجات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    context,
                    'منتجات نشطة',
                    report.activeProducts,
                    AppColors.success,
                  ),
                  _buildStatusRow(
                    context,
                    'منتجات غير نشطة',
                    report.inactiveProducts,
                    AppColors.textSecondary,
                  ),
                  _buildStatusRow(
                    context,
                    'إجمالي المتغيرات',
                    report.totalVariants,
                    AppColors.info,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // المخزون حسب الفئة
          if (report.categoryStocks.isNotEmpty) ...[
            Text(
              'المخزون حسب الفئة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            ...report.categoryStocks.map((category) {
              return _buildCategoryCard(context, category);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAlerts(
    BuildContext context,
    WidgetRef ref,
    InventoryReport report,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تنبيهات المخزون',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.sm),

        // منتجات نفدت
        if (report.outOfStockProducts > 0)
          _buildAlertCard(
            context,
            title: 'نفد من المخزون',
            count: report.outOfStockProducts,
            icon: Icons.error_outline,
            color: AppColors.error,
            onTap: () => _showOutOfStockProducts(context, ref),
          ),

        // منتجات منخفضة
        if (report.lowStockProducts > 0)
          _buildAlertCard(
            context,
            title: 'مخزون منخفض',
            count: report.lowStockProducts,
            icon: Icons.warning_amber,
            color: AppColors.warning,
            onTap: () => _showLowStockProducts(context, ref),
          ),
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text('$count منتج'),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(label),
            ],
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryStock category) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${category.productCount} منتج',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${category.totalStock}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  category.stockValue.toCurrency(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOutOfStockProducts(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          // استخدام StreamProvider للتحديث التلقائي وتحميل أسرع
          final productsAsync = ref.watch(outOfStockProductsStreamProvider);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  'منتجات نفدت من المخزون',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  data: (products) => ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(product.categoryName ?? ''),
                        trailing: const Icon(
                          Icons.error,
                          color: AppColors.error,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/products/${product.id}');
                        },
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLowStockProducts(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          // استخدام StreamProvider للتحديث التلقائي وتحميل أسرع
          final productsAsync = ref.watch(lowStockProductsStreamProvider);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  'منتجات مخزونها منخفض',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  data: (products) => ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(product.categoryName ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${product.totalStock}',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            const Icon(
                              Icons.warning,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/products/${product.id}');
                        },
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
