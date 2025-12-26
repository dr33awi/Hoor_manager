import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/repositories/sales_repository.dart';
import '../providers/sales_providers.dart';
import '../widgets/widgets.dart';

/// شاشة المبيعات
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayInvoicesAsync = ref.watch(todayInvoicesProvider);
    final todayStatsAsync = ref.watch(todayStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'القائمة',
        ),
        title: const Text(AppStrings.sales),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayInvoicesProvider);
          ref.invalidate(todayStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // إحصائيات اليوم
            SliverToBoxAdapter(
              child: todayStatsAsync.when(
                data: (stats) => _buildTodayStats(context, stats),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // عنوان فواتير اليوم
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'فواتير اليوم',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        todayInvoicesAsync
                                .whenData(
                                  (invoices) => Text(
                                    '${invoices.length} فاتورة',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                )
                                .value ??
                            const SizedBox.shrink(),
                        const SizedBox(width: AppSizes.sm),
                        TextButton(
                          onPressed: () => context.push('/invoices'),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // قائمة الفواتير
            todayInvoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(context),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => InvoiceCard(
                      invoice: invoices[index],
                      onTap: () => context.push('/sales/${invoices[index].id}'),
                    ),
                    childCount: invoices.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('خطأ: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'sales_fab',
        onPressed: () => context.push(AppRoutes.newSale),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context, DailySalesStats stats) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إحصائيات اليوم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                DateTime.now().toArabicDate(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight.withOpacity(0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.receipt_long,
                  label: 'الفواتير',
                  value: '${stats.invoiceCount}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.attach_money,
                  label: 'المبيعات',
                  value: stats.totalSales.toCurrency(),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.trending_up,
                  label: 'الأرباح',
                  value: stats.totalProfit.toCurrency(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(height: AppSizes.xs),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'لا توجد فواتير اليوم',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'اضغط على + لإنشاء فاتورة جديدة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}
