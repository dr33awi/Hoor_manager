import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../providers/reports_providers.dart';
import '../widgets/widgets.dart';

/// شاشة التقارير الرئيسية
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'القائمة',
        ),
        title: const Text(AppStrings.reports),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ملخص لوحة التحكم
              _buildDashboardSummary(context, ref),

              const SizedBox(height: AppSizes.lg),

              // الوصول السريع للتقارير
              Text(
                'التقارير',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.md),

              _buildReportCards(context),

              const SizedBox(height: AppSizes.lg),

              // المنتجات الأكثر مبيعاً
              _buildTopProductsSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSummary(BuildContext context, WidgetRef ref) {
    // استخدام StreamProvider للتحديث التلقائي
    final summaryAsync = ref.watch(dashboardSummaryStreamProvider);

    return summaryAsync.when(
      data: (summary) => Column(
        children: [
          // بطاقات الإحصائيات الرئيسية
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'مبيعات اليوم',
                  value: summary.todaySales.toCurrency(),
                  icon: Icons.today,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'أرباح اليوم',
                  value: summary.todayProfit.toCurrency(),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'فواتير اليوم',
                  value: '${summary.todayInvoices}',
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'مبيعات الشهر',
                  value: summary.monthSales.toCurrency(),
                  icon: Icons.calendar_month,
                  color: AppColors.secondary,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // تنبيهات المخزون
          if (summary.lowStockCount > 0 || summary.outOfStockCount > 0)
            Card(
              color: AppColors.warning.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تنبيهات المخزون',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${summary.lowStockCount} منتج منخفض • ${summary.outOfStockCount} نفد',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/reports/inventory'),
                      child: const Text('عرض'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSizes.md),

          // الرسم البياني للأسبوع
          if (summary.weeklyTrend.isNotEmpty)
            SalesChart(data: summary.weeklyTrend, title: 'مبيعات الأسبوع'),
        ],
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text('خطأ في تحميل البيانات: $e'),
        ),
      ),
    );
  }

  Widget _buildReportCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.sm,
      mainAxisSpacing: AppSizes.sm,
      childAspectRatio: 1.5,
      children: [
        _ReportCard(
          title: 'تقرير المبيعات',
          subtitle: 'يومي / شهري',
          icon: Icons.point_of_sale,
          color: AppColors.primary,
          onTap: () => context.push('/reports/sales'),
        ),
        _ReportCard(
          title: 'تقرير الأرباح',
          subtitle: 'تحليل الربحية',
          icon: Icons.trending_up,
          color: AppColors.success,
          onTap: () => context.push('/reports/profits'),
        ),
        _ReportCard(
          title: 'تقرير المخزون',
          subtitle: 'حالة المخزون',
          icon: Icons.inventory_2,
          color: AppColors.info,
          onTap: () => context.push('/reports/inventory'),
        ),
        _ReportCard(
          title: 'الأكثر مبيعاً',
          subtitle: 'أفضل المنتجات',
          icon: Icons.star,
          color: AppColors.warning,
          onTap: () => context.push('/reports/top-products'),
        ),
      ],
    );
  }

  Widget _buildTopProductsSection(BuildContext context, WidgetRef ref) {
    // استخدام StreamProvider للتحديث التلقائي
    final topProductsAsync = ref.watch(monthlyTopProductsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الأكثر مبيعاً هذا الشهر',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push('/reports/top-products'),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        topProductsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Center(
                    child: Text(
                      'لا توجد مبيعات هذا الشهر',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: products.take(5).map((product) {
                return TopProductTile(product: product);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('خطأ: $e'),
        ),
      ],
    );
  }
}

/// بطاقة تقرير
class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSizes.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
