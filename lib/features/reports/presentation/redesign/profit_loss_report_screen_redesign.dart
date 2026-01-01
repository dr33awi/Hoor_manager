/// ═══════════════════════════════════════════════════════════════════════════
/// Profit Loss Report Screen - Redesigned
/// Modern Profit and Loss Report Interface
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

class ProfitLossReportScreenRedesign extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const ProfitLossReportScreenRedesign({super.key, this.dateRange});

  @override
  ConsumerState<ProfitLossReportScreenRedesign> createState() =>
      _ProfitLossReportScreenRedesignState();
}

class _ProfitLossReportScreenRedesignState
    extends ConsumerState<ProfitLossReportScreenRedesign> {
  final _db = getIt<AppDatabase>();
  final _currencyService = getIt<CurrencyService>();

  late DateTimeRange _dateRange;

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
  }

  Future<Map<String, dynamic>> _calculateProfitLoss() async {
    final invoices =
        await _db.getInvoicesByDateRange(_dateRange.start, _dateRange.end);
    final movements =
        await _db.getCashMovementsByDateRange(_dateRange.start, _dateRange.end);

    double totalSales = 0;
    double totalSalesUsd = 0;
    double totalCost = 0;
    double totalCostUsd = 0;
    double totalReturns = 0;
    double totalReturnsUsd = 0;

    for (final invoice in invoices) {
      if (invoice.type == 'sale') {
        totalSales += invoice.total;
        totalSalesUsd += _currencyService.sypToUsd(invoice.total);
        // Cost from invoice items
        final items = await _db.getInvoiceItems(invoice.id);
        for (final item in items) {
          totalCost += item.purchasePrice * item.quantity;
        }
      } else if (invoice.type == 'return') {
        totalReturns += invoice.total;
        totalReturnsUsd += _currencyService.sypToUsd(invoice.total);
      }
    }

    totalCostUsd = _currencyService.sypToUsd(totalCost);

    // Expenses from cash movements
    double totalExpenses = 0;
    double totalExpensesUsd = 0;
    for (final movement in movements) {
      if (movement.type == 'expense') {
        totalExpenses += movement.amount;
        totalExpensesUsd += _currencyService.sypToUsd(movement.amount);
      }
    }

    final grossProfit = totalSales - totalCost - totalReturns;
    final grossProfitUsd = totalSalesUsd - totalCostUsd - totalReturnsUsd;
    final netProfit = grossProfit - totalExpenses;
    final netProfitUsd = grossProfitUsd - totalExpensesUsd;
    final profitMargin = totalSales > 0 ? (netProfit / totalSales) * 100 : 0;

    return {
      'totalSales': totalSales,
      'totalSalesUsd': totalSalesUsd,
      'totalCost': totalCost,
      'totalCostUsd': totalCostUsd,
      'totalExpenses': totalExpenses,
      'totalExpensesUsd': totalExpensesUsd,
      'totalReturns': totalReturns,
      'totalReturnsUsd': totalReturnsUsd,
      'grossProfit': grossProfit,
      'grossProfitUsd': grossProfitUsd,
      'netProfit': netProfit,
      'netProfitUsd': netProfitUsd,
      'profitMargin': profitMargin,
      'invoiceCount': invoices.where((i) => i.type == 'sale').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title:
            Text('تقرير الأرباح والخسائر', style: HoorTypography.headlineSmall),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _calculateProfitLoss(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: HoorColors.primary),
            );
          }

          final data = snapshot.data!;
          return CustomScrollView(
            slivers: [
              // Date Range Header
              SliverToBoxAdapter(
                child: _buildDateRangeHeader(),
              ),

              // Net Profit Card
              SliverPadding(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildNetProfitCard(data),
                ),
              ),

              // Summary Cards
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildSummaryCards(data),
                ),
              ),

              // Breakdown Section
              SliverPadding(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildBreakdownCard(data),
                ),
              ),

              // Chart
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildChartCard(data),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.only(bottom: HoorSpacing.xl.h),
                sliver: const SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
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

  Widget _buildNetProfitCard(Map<String, dynamic> data) {
    final netProfit = data['netProfit'] as double;
    final netProfitUsd = data['netProfitUsd'] as double;
    final profitMargin = data['profitMargin'] as double;
    final isPositive = netProfit >= 0;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [HoorColors.success, HoorColors.success.withValues(alpha: 0.8)]
              : [HoorColors.error, HoorColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? HoorColors.success : HoorColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPositive ? 'صافي الربح' : 'صافي الخسارة',
                    style: HoorTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  Text(
                    _formatPrice(netProfit.abs()),
                    style: HoorTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${netProfitUsd.abs().toStringAsFixed(2)}',
                    style: HoorTypography.titleSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(HoorRadius.full),
                ),
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.sm.w,
                  vertical: HoorSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.percent_rounded, color: Colors.white, size: 14),
                    SizedBox(width: HoorSpacing.xxs.w),
                    Text(
                      'هامش الربح: ${profitMargin.toStringAsFixed(1)}%',
                      style: HoorTypography.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.sm.w,
                  vertical: HoorSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: HoorSpacing.xxs.w),
                    Text(
                      '${data['invoiceCount']} فاتورة',
                      style: HoorTypography.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.trending_up_rounded,
                title: 'المبيعات',
                value: data['totalSales'],
                valueUsd: data['totalSalesUsd'],
                color: HoorColors.success,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.shopping_cart_rounded,
                title: 'التكلفة',
                value: data['totalCost'],
                valueUsd: data['totalCostUsd'],
                color: HoorColors.warning,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'إجمالي الربح',
                value: data['grossProfit'],
                valueUsd: data['grossProfitUsd'],
                color: HoorColors.info,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildSummaryItem(
                icon: Icons.money_off_rounded,
                title: 'المصروفات',
                value: data['totalExpenses'],
                valueUsd: data['totalExpensesUsd'],
                color: HoorColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required double value,
    required double valueUsd,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: HoorSpacing.xxs.w),
              Text(
                title,
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            _formatPrice(value),
            style: HoorTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '\$${valueUsd.toStringAsFixed(2)}',
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(Map<String, dynamic> data) {
    final items = [
      {
        'label': 'إجمالي المبيعات',
        'value': data['totalSales'],
        'color': HoorColors.success,
        'isPositive': true
      },
      {
        'label': 'تكلفة البضاعة المباعة',
        'value': data['totalCost'],
        'color': HoorColors.warning,
        'isPositive': false
      },
      {
        'label': 'المرتجعات',
        'value': data['totalReturns'],
        'color': HoorColors.error,
        'isPositive': false
      },
      {
        'label': 'إجمالي الربح',
        'value': data['grossProfit'],
        'color': HoorColors.info,
        'isPositive': true,
        'isBold': true
      },
      {
        'label': 'المصروفات التشغيلية',
        'value': data['totalExpenses'],
        'color': HoorColors.error,
        'isPositive': false
      },
      {
        'label': 'صافي الربح',
        'value': data['netProfit'],
        'color': (data['netProfit'] as double) >= 0
            ? HoorColors.success
            : HoorColors.error,
        'isPositive': (data['netProfit'] as double) >= 0,
        'isBold': true
      },
    ];

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
              Icon(Icons.calculate_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'تفاصيل الحساب',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            final isBold = item['isBold'] == true;

            return Column(
              children: [
                if (isBold && entry.key > 0)
                  Divider(color: HoorColors.border, height: HoorSpacing.md.h),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: HoorSpacing.xs.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label'] as String,
                        style: isBold
                            ? HoorTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : HoorTypography.bodyMedium,
                      ),
                      Text(
                        '${item['isPositive'] == false && (item['value'] as double) > 0 ? '-' : ''}${_formatPrice((item['value'] as double).abs())}',
                        style: (isBold
                                ? HoorTypography.titleSmall
                                : HoorTypography.bodyMedium)
                            .copyWith(
                          color: item['color'] as Color,
                          fontWeight: isBold ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast && !isBold)
                  Divider(
                      color: HoorColors.border.withValues(alpha: 0.5),
                      height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, dynamic> data) {
    final totalSales = data['totalSales'] as double;
    final totalCost = data['totalCost'] as double;
    final totalExpenses = data['totalExpenses'] as double;
    final totalReturns = data['totalReturns'] as double;

    if (totalSales == 0 &&
        totalCost == 0 &&
        totalExpenses == 0 &&
        totalReturns == 0) {
      return const SizedBox();
    }

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
              Icon(Icons.pie_chart_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'توزيع الإيرادات والمصاريف',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50.r,
                sections: [
                  PieChartSectionData(
                    value: totalSales,
                    title: '',
                    color: HoorColors.success,
                    radius: 50.r,
                  ),
                  PieChartSectionData(
                    value: totalCost,
                    title: '',
                    color: HoorColors.warning,
                    radius: 50.r,
                  ),
                  PieChartSectionData(
                    value: totalExpenses,
                    title: '',
                    color: HoorColors.error,
                    radius: 50.r,
                  ),
                  if (totalReturns > 0)
                    PieChartSectionData(
                      value: totalReturns,
                      title: '',
                      color: HoorColors.info,
                      radius: 50.r,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: HoorSpacing.md.h),
          Wrap(
            spacing: HoorSpacing.md.w,
            runSpacing: HoorSpacing.xs.h,
            children: [
              _buildLegendItem('المبيعات', HoorColors.success),
              _buildLegendItem('التكلفة', HoorColors.warning),
              _buildLegendItem('المصروفات', HoorColors.error),
              if (totalReturns > 0)
                _buildLegendItem('المرتجعات', HoorColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: HoorSpacing.xxs.w),
        Text(
          label,
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
      ],
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
