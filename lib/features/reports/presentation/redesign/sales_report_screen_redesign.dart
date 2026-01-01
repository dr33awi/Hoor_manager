/// ═══════════════════════════════════════════════════════════════════════════
/// Sales Report Screen - Redesigned
/// Modern Sales Report Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';

class SalesReportScreenRedesign extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const SalesReportScreenRedesign({super.key, this.dateRange});

  @override
  ConsumerState<SalesReportScreenRedesign> createState() =>
      _SalesReportScreenRedesignState();
}

class _SalesReportScreenRedesignState
    extends ConsumerState<SalesReportScreenRedesign> {
  final _db = getIt<AppDatabase>();
  final _currencyService = getIt<CurrencyService>();

  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('تقرير المبيعات', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.date_range_rounded,
                  color: HoorColors.primary, size: 20),
            ),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: _db.watchSalesSummary(_dateRange.start, _dateRange.end),
        builder: (context, summarySnapshot) {
          return StreamBuilder<List<Invoice>>(
            stream:
                _db.watchInvoicesByDateRange(_dateRange.start, _dateRange.end),
            builder: (context, invoicesSnapshot) {
              if (!summarySnapshot.hasData || !invoicesSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: HoorColors.primary),
                );
              }

              final summary = summarySnapshot.data!;
              final allInvoices = invoicesSnapshot.data!;
              final invoices =
                  allInvoices.where((i) => i.type == 'sale').toList();

              return CustomScrollView(
                slivers: [
                  // Date Range Header
                  SliverToBoxAdapter(
                    child: _buildDateRangeHeader(),
                  ),

                  // Summary Cards
                  SliverPadding(
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    sliver: SliverToBoxAdapter(
                      child: _buildSummaryCards(summary),
                    ),
                  ),

                  // Chart
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                    sliver: SliverToBoxAdapter(
                      child: _buildChartCard(invoices),
                    ),
                  ),

                  // Payment Methods
                  SliverPadding(
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    sliver: SliverToBoxAdapter(
                      child: _buildPaymentMethodsCard(invoices),
                    ),
                  ),

                  // Recent Invoices Header
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'أحدث الفواتير',
                            style: HoorTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: HoorSpacing.sm.w,
                              vertical: HoorSpacing.xxs.h,
                            ),
                            decoration: BoxDecoration(
                              color: HoorColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(HoorRadius.sm),
                            ),
                            child: Text(
                              '${invoices.length} فاتورة',
                              style: HoorTypography.labelMedium.copyWith(
                                color: HoorColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Invoices List
                  SliverPadding(
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final invoice = invoices[index];
                          return _buildInvoiceCard(invoice);
                        },
                        childCount: invoices.take(10).length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      color: HoorColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 16, color: HoorColors.textSecondary),
          SizedBox(width: HoorSpacing.xs.w),
          Text(
            '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, double> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                title: 'إجمالي المبيعات',
                value: summary['totalSales'] ?? 0,
                color: HoorColors.success,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.receipt_long_rounded,
                title: 'عدد الفواتير',
                value: summary['invoiceCount'] ?? 0,
                color: HoorColors.primary,
                isCount: true,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.analytics_rounded,
                title: 'متوسط الفاتورة',
                value: summary['averageInvoice'] ?? 0,
                color: HoorColors.info,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.assignment_return_rounded,
                title: 'المرتجعات',
                value: summary['totalReturns'] ?? 0,
                color: HoorColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required double value,
    required Color color,
    bool isCount = false,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                title,
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Text(
            isCount ? '${value.toInt()}' : _currencyService.formatSyp(value),
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (!isCount) ...[
            SizedBox(height: HoorSpacing.xxs.h),
            Text(
              '\$${_currencyService.sypToUsd(value).toStringAsFixed(2)}',
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(List<Invoice> invoices) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'المبيعات اليومية',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          SizedBox(
            height: 200.h,
            child: _buildChart(invoices),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Invoice> invoices) {
    // Group invoices by day
    final Map<String, double> dailySales = {};
    for (final invoice in invoices) {
      final day = DateFormat('dd/MM').format(invoice.createdAt);
      dailySales[day] = (dailySales[day] ?? 0) + invoice.total;
    }

    if (dailySales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 48, color: HoorColors.textSecondary),
            SizedBox(height: HoorSpacing.sm.h),
            Text(
              'لا توجد بيانات',
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final spots = dailySales.entries.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: dailySales.values.isNotEmpty
              ? dailySales.values.reduce((a, b) => a > b ? a : b) / 4
              : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: HoorColors.border,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dailySales.length) {
                  final keys = dailySales.keys.toList();
                  if (index % 5 == 0) {
                    return Padding(
                      padding: EdgeInsets.only(top: HoorSpacing.xs.h),
                      child: Text(
                        keys[index],
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: HoorColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HoorColors.primary.withValues(alpha: 0.3),
                  HoorColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard(List<Invoice> invoices) {
    final Map<String, double> paymentTotals = {};
    for (final invoice in invoices) {
      final method = invoice.paymentMethod;
      paymentTotals[method] = (paymentTotals[method] ?? 0) + invoice.total;
    }

    final total = paymentTotals.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'طرق الدفع',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          ...paymentTotals.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0;
            return _buildPaymentMethodRow(
              entry.key,
              entry.value,
              percentage.toDouble(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
      String method, double value, double percentage) {
    final methodInfo = _getPaymentMethodInfo(method);

    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Column(
        children: [
          Row(
            children: [
              Icon(methodInfo['icon'] as IconData,
                  size: 18, color: methodInfo['color'] as Color),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: Text(
                  methodInfo['label'] as String,
                  style: HoorTypography.bodyMedium,
                ),
              ),
              Text(
                _currencyService.formatSyp(value),
                style: HoorTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Stack(
            children: [
              Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: HoorColors.background,
                  borderRadius: BorderRadius.circular(HoorRadius.full),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: methodInfo['color'] as Color,
                    borderRadius: BorderRadius.circular(HoorRadius.full),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPaymentMethodInfo(String method) {
    switch (method) {
      case 'cash':
        return {
          'icon': Icons.money_rounded,
          'label': 'نقدي',
          'color': HoorColors.success,
        };
      case 'credit':
        return {
          'icon': Icons.schedule_rounded,
          'label': 'آجل',
          'color': HoorColors.warning,
        };
      case 'card':
        return {
          'icon': Icons.credit_card_rounded,
          'label': 'بطاقة',
          'color': HoorColors.info,
        };
      default:
        return {
          'icon': Icons.payment_rounded,
          'label': method,
          'color': HoorColors.textSecondary,
        };
    }
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/invoices/${invoice.id}'),
        leading: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: HoorColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: Icon(Icons.receipt_long_rounded,
              color: HoorColors.success, size: 20),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: HoorTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('yyyy/MM/dd - HH:mm').format(invoice.createdAt),
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        trailing: Text(
          _currencyService.formatSyp(invoice.total),
          style: HoorTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: HoorColors.success,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HoorColors.primary,
              onPrimary: Colors.white,
              surface: HoorColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }
}
