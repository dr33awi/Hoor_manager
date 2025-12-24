import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';
import '../providers/reports_providers.dart';
import '../widgets/widgets.dart';

/// شاشة تقرير المبيعات
class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportStateProvider);
    final reportAsync = ref.watch(salesReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المبيعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(salesReportProvider),
          ),
        ],
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
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ReportPeriod.values
                  .where((p) => p != ReportPeriod.custom)
                  .map((period) {
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
          const SizedBox(height: AppSizes.sm),
          // زر الفترة المخصصة
          OutlinedButton.icon(
            onPressed: () => _showDateRangePicker(context, ref),
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              state.period == ReportPeriod.custom
                  ? '${state.customStartDate?.toArabicDate()} - ${state.customEndDate?.toArabicDate()}'
                  : 'فترة مخصصة',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, SalesReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // فترة التقرير
          Text(
            'من ${report.startDate.toArabicDate()} إلى ${report.endDate.toArabicDate()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: AppSizes.md),

          // الإحصائيات الرئيسية
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'إجمالي المبيعات',
                  value: report.totalSales.toCurrency(),
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'صافي الربح',
                  value: report.totalProfit.toCurrency(),
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
                  title: 'عدد الفواتير',
                  value: '${report.totalInvoices}',
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: 'عدد المنتجات',
                  value: '${report.totalItems}',
                  icon: Icons.shopping_bag,
                  color: AppColors.secondary,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // تفاصيل إضافية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل التقرير',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  _buildDetailRow(context, 'إجمالي التكلفة', report.totalCost.toCurrency()),
                  _buildDetailRow(context, 'إجمالي الخصومات', report.totalDiscount.toCurrency()),
                  _buildDetailRow(context, 'نسبة الربح', '${report.profitMargin.toStringAsFixed(1)}%'),
                  _buildDetailRow(context, 'متوسط الفاتورة', report.averageInvoiceValue.toCurrency()),
                  _buildDetailRow(context, 'متوسط المبيعات اليومية', report.averageDailySales.toCurrency()),
                  if (report.cancelledInvoices > 0) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'الفواتير الملغاة',
                      '${report.cancelledInvoices}',
                      valueColor: AppColors.error,
                    ),
                    _buildDetailRow(
                      context,
                      'قيمة الملغاة',
                      report.cancelledAmount.toCurrency(),
                      valueColor: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // الرسم البياني
          if (report.dailyData.isNotEmpty)
            SalesChart(
              data: report.dailyData,
              title: 'المبيعات اليومية',
              showProfit: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ar'),
      helpText: 'اختر فترة التقرير',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      saveText: 'حفظ',
    );

    if (result != null) {
      ref.read(salesReportStateProvider.notifier).setCustomRange(
            result.start,
            result.end.add(const Duration(days: 1)),
          );
    }
  }
}
