import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';
import '../providers/product_providers.dart';

/// شاشة تفاصيل المنتج
class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productStreamProvider(productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('المنتج غير موجود')),
          );
        }
        return _buildContent(context, ref, product);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProductEntity product) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/products/edit/${product.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            _buildImage(product),

            const SizedBox(height: AppSizes.lg),

            // المعلومات الأساسية
            _buildInfoCard(context, product),

            const SizedBox(height: AppSizes.md),

            // السعر والتكلفة
            _buildPricingCard(context, product),

            const SizedBox(height: AppSizes.md),

            // المخزون
            _buildStockSection(context, product),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ProductEntity product) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 64,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ProductEntity product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الحالة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    product.isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      color: product.isActive
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (product.barcode != null)
                  Row(
                    children: [
                      const Icon(Icons.qr_code,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        product.barcode!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),

            const Divider(height: AppSizes.lg),

            // الفئة
            _buildInfoRow(
              context,
              icon: Icons.category_outlined,
              label: 'الفئة',
              value: product.categoryName ?? '-',
            ),

            if (product.description != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(
                'الوصف',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(product.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, ProductEntity product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPriceItem(
                    context,
                    label: 'سعر البيع',
                    value: product.price.toCurrency(),
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _buildPriceItem(
                    context,
                    label: 'التكلفة',
                    value: product.cost.toCurrency(),
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _buildPriceItem(
                    context,
                    label: 'الربح',
                    value: product.profit.toCurrency(),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'نسبة الربح: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${product.profitMargin.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStockSection(BuildContext context, ProductEntity product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'المخزون',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: product.isOutOfStock
                        ? AppColors.error.withOpacity(0.1)
                        : product.isLowStock
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'الإجمالي: ${product.totalStock}',
                    style: TextStyle(
                      color: product.isOutOfStock
                          ? AppColors.error
                          : product.isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: AppSizes.lg),

            // جدول المتغيرات
            if (product.variants.isEmpty)
              const Center(child: Text('لا توجد متغيرات'))
            else
              ...product.variants
                  .map((variant) => _buildVariantRow(context, variant)),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantRow(BuildContext context, ProductVariant variant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          // اللون
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hexToColor(variant.colorCode),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(variant.color),
          const SizedBox(width: AppSizes.md),
          // المقاس
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            ),
            child: Text(variant.size),
          ),
          const Spacer(),
          // الكمية
          Text(
            '${variant.quantity}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: variant.isOutOfStock
                  ? AppColors.error
                  : variant.isLowStock
                      ? AppColors.warning
                      : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
