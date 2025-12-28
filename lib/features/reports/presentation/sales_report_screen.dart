import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const SalesReportScreen({super.key, this.dateRange});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  final _db = getIt<AppDatabase>();

  late DateTimeRange _dateRange;
  Map<String, double> _summary = {};
  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await _db.getSalesSummary(_dateRange.start, _dateRange.end);
    final allInvoices = await _db.getInvoicesByDateRange(
      _dateRange.start,
      _dateRange.end,
    );
    final invoices = allInvoices.where((i) => i.type == 'sale').toList();

    setState(() {
      _summary = summary;
      _invoices = invoices;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المبيعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Date Range
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي المبيعات',
                        value: _summary['totalSales'] ?? 0,
                        icon: Icons.trending_up,
                        color: AppColors.success,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatCard(
                        title: 'عدد الفواتير',
                        value: (_summary['invoiceCount'] ?? 0),
                        icon: Icons.receipt,
                        color: AppColors.primary,
                        isCurrency: false,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'متوسط الفاتورة',
                        value: _summary['averageInvoice'] ?? 0,
                        icon: Icons.analytics,
                        color: AppColors.accent,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatCard(
                        title: 'المرتجعات',
                        value: _summary['totalReturns'] ?? 0,
                        icon: Icons.assignment_return,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Gap(24.h),

                // Chart
                Text(
                  'المبيعات اليومية',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(12.h),
                Container(
                  height: 200.h,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: _buildChart(),
                ),
                Gap(24.h),

                // Payment Methods
                Text(
                  'طرق الدفع',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(12.h),
                _PaymentMethodsCard(invoices: _invoices),
                Gap(24.h),

                // Recent Invoices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أحدث الفواتير',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_invoices.length} فاتورة',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                ..._invoices.take(10).map((i) => _InvoiceItem(invoice: i)),
              ],
            ),
    );
  }

  Widget _buildChart() {
    // Group invoices by day
    final Map<String, double> dailySales = {};
    for (final invoice in _invoices) {
      final day = DateFormat('dd/MM').format(invoice.createdAt);
      dailySales[day] = (dailySales[day] ?? 0) + invoice.total;
    }

    if (dailySales.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final spots = dailySales.entries.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
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
                    return Text(
                      keys[index],
                      style: TextStyle(fontSize: 10.sp),
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
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
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
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _isLoading = true;
      });
      _loadData();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.sp),
                Gap(8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Text(
              isCurrency
                  ? '${value.toStringAsFixed(2)} ر.س'
                  : value.toInt().toString(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final List<Invoice> invoices;

  const _PaymentMethodsCard({required this.invoices});

  @override
  Widget build(BuildContext context) {
    // Calculate payment method totals
    double cash = 0;
    double card = 0;
    double transfer = 0;
    double credit = 0;

    for (final invoice in invoices) {
      switch (invoice.paymentMethod) {
        case 'cash':
          cash += invoice.total;
          break;
        case 'card':
          card += invoice.total;
          break;
        case 'bank_transfer':
          transfer += invoice.total;
          break;
        case 'credit':
          credit += invoice.total;
          break;
      }
    }

    final total = cash + card + transfer + credit;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _PaymentMethodRow(
              label: 'نقداً',
              amount: cash,
              percentage: total > 0 ? (cash / total * 100) : 0,
              color: AppColors.success,
            ),
            Gap(8.h),
            _PaymentMethodRow(
              label: 'بطاقة',
              amount: card,
              percentage: total > 0 ? (card / total * 100) : 0,
              color: AppColors.primary,
            ),
            Gap(8.h),
            _PaymentMethodRow(
              label: 'تحويل بنكي',
              amount: transfer,
              percentage: total > 0 ? (transfer / total * 100) : 0,
              color: AppColors.accent,
            ),
            Gap(8.h),
            _PaymentMethodRow(
              label: 'آجل',
              amount: credit,
              percentage: total > 0 ? (credit / total * 100) : 0,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String label;
  final double amount;
  final double percentage;
  final Color color;

  const _PaymentMethodRow({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${amount.toStringAsFixed(2)} ر.س (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Gap(4.h),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.1),
          color: color,
        ),
      ],
    );
  }
}

class _InvoiceItem extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.sales.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.receipt, color: AppColors.sales),
        ),
        title: Text(invoice.invoiceNumber),
        subtitle:
            Text(DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt)),
        trailing: Text(
          '${invoice.total.toStringAsFixed(2)} ر.س',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}
