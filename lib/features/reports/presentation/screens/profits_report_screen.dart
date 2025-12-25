import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';
import '../providers/reports_providers.dart';

/// شاشة تقرير الأرباح
class ProfitsReportScreen extends ConsumerWidget {
  const ProfitsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportStateProvider);
    // استخدام StreamProvider للتحديث التلقائي
    final reportAsync = ref.watch(salesReportStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الأرباح'),
      ),
      body: Column(
        children: [
          // اختيار الفترة
          _buildPeriodSelector(context, ref, state),

          // محتوى التقرير
          Expanded(
            child: reportAsync.when(
              data: (report) => _buildReportContent(context, report),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    SalesReportState state,
  ) {
    return Container(
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
            final isSelected = state.period == period;
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.xs),
              child: ChoiceChip(
                label: Text(period.arabicName),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(salesReportStateProvider.notifier).setPeriod(period);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, SalesReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة الربح الرئيسية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'صافي الربح',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                Text(
                  report.totalProfit.toCurrency(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'نسبة الربح: ${report.profitMargin.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // تفاصيل الربحية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحليل الربحية',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),

                  // المبيعات
                  _buildProfitRow(
                    context,
                    'إجمالي المبيعات',
                    report.totalSales.toCurrency(),
                    icon: Icons.point_of_sale,
                    color: AppColors.primary,
                  ),

                  // التكلفة
                  _buildProfitRow(
                    context,
                    'إجمالي التكلفة',
                    '- ${report.totalCost.toCurrency()}',
                    icon: Icons.shopping_cart,
                    color: AppColors.error,
                  ),

                  // الخصومات
                  if (report.totalDiscount > 0)
                    _buildProfitRow(
                      context,
                      'الخصومات المقدمة',
                      '- ${report.totalDiscount.toCurrency()}',
                      icon: Icons.local_offer,
                      color: AppColors.warning,
                    ),

                  const Divider(),

                  // صافي الربح
                  _buildProfitRow(
                    context,
                    'صافي الربح',
                    report.totalProfit.toCurrency(),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // إحصائيات إضافية
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  'متوسط الربح للفاتورة',
                  report.totalInvoices > 0
                      ? (report.totalProfit / report.totalInvoices).toCurrency()
                      : '0',
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _buildStatBox(
                  context,
                  'متوسط الربح للمنتج',
                  report.totalItems > 0
                      ? (report.totalProfit / report.totalItems).toCurrency()
                      : '0',
                  Icons.shopping_bag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitRow(
    BuildContext context,
    String label,
    String value, {
    required IconData icon,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : null,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSizes.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
