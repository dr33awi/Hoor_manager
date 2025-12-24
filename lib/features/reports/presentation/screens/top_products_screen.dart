import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';
import '../providers/reports_providers.dart';
import '../widgets/widgets.dart';

/// شاشة المنتجات الأكثر مبيعاً
class TopProductsScreen extends ConsumerStatefulWidget {
  const TopProductsScreen({super.key});

  @override
  ConsumerState<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends ConsumerState<TopProductsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final range = _selectedPeriod.dateRange;
    final topProductsAsync = ref.watch(
      topSellingProductsProvider((start: range.start, end: range.end, limit: 20)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات الأكثر مبيعاً'),
      ),
      body: Column(
        children: [
          // اختيار الفترة
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ReportPeriod.today,
                  ReportPeriod.thisWeek,
                  ReportPeriod.thisMonth,
                  ReportPeriod.lastMonth,
                ].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSizes.xs),
                    child: ChoiceChip(
                      label: Text(period.arabicName),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedPeriod = period);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // قائمة المنتجات
          Expanded(
            child: topProductsAsync.when(
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'لا توجد مبيعات في هذه الفترة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<TopSellingProduct> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, product, index + 1);
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    TopSellingProduct product,
    int rank,
  ) {
    Color? badgeColor;
    IconData? badgeIcon;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // ذهبي
      badgeIcon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // فضي
      badgeIcon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // برونزي
      badgeIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            // الترتيب
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeColor?.withOpacity(0.2) ?? AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badgeIcon != null
                    ? Icon(badgeIcon, color: badgeColor, size: 24)
                    : Text(
                        '$rank',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.md),

            // صورة المنتج
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: product.productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: Image.network(product.productImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image, color: AppColors.textHint),
            ),
            const SizedBox(width: AppSizes.md),

            // معلومات المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.categoryName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // الإحصائيات
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.quantitySold}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Text(
                  product.totalSales.toCurrency(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'ربح: ${product.totalProfit.toCurrency()}',
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
}
