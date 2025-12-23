// lib/features/reports/screens/reports_screen.dart
// شاشة التقارير

import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../sales/services/sale_service.dart';
import '../../products/providers/product_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  SalesReport? _salesReport;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final saleProvider = context.read<SaleProvider>();
    final report = await saleProvider.getSalesReport(
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _salesReport = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // اختيار الفترة
        _buildDateRangeSelector(),

        // التبويبات
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'المبيعات', icon: Icon(Icons.attach_money)),
            Tab(text: 'المخزون', icon: Icon(Icons.inventory)),
            Tab(text: 'الأرباح', icon: Icon(Icons.trending_up)),
          ],
        ),

        // المحتوى
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesReport(),
                    _buildInventoryReport(),
                    _buildProfitReport(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormatter = DateFormat('dd/MM/yyyy', 'ar');

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.grey300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFormatter.format(_startDate)} - ${dateFormatter.format(_endDate)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
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
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  Widget _buildSalesReport() {
    final formatter = NumberFormat('#,##0.00', 'ar');

    if (_salesReport == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقات الإحصائيات
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'إجمالي المبيعات',
                  value: '${formatter.format(_salesReport!.totalRevenue)} ر.س',
                  icon: Icons.attach_money,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'عدد الطلبات',
                  value: '${_salesReport!.totalOrders}',
                  icon: Icons.receipt,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'عدد المنتجات المباعة',
                  value: '${_salesReport!.totalItems}',
                  icon: Icons.inventory,
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'متوسط قيمة الطلب',
                  value:
                      '${formatter.format(_salesReport!.averageOrderValue)} ر.س',
                  icon: Icons.analytics,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // المنتجات الأكثر مبيعاً
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Text(
                        'المنتجات الأكثر مبيعاً',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_salesReport!.topProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('لا توجد بيانات')),
                    )
                  else
                    ...List.generate(
                      _salesReport!.topProducts.length.clamp(0, 5),
                      (index) {
                        final entry = _salesReport!.topProducts.entries
                            .elementAt(index);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(entry.key),
                          trailing: Text(
                            '${entry.value} قطعة',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // المبيعات حسب طريقة الدفع
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'المبيعات حسب طريقة الدفع',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_salesReport!.salesByPaymentMethod.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('لا توجد بيانات')),
                    )
                  else
                    ..._salesReport!.salesByPaymentMethod.entries.map((entry) {
                      return ListTile(
                        leading: Icon(
                          _getPaymentIcon(entry.key),
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(entry.key),
                        trailing: Text(
                          '${formatter.format(entry.value)} ر.س',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryReport() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final activeProducts = provider.allProducts
            .where((p) => p.isActive)
            .toList();
        final totalQuantity = activeProducts.fold(
          0,
          (sum, p) => sum + p.totalQuantity,
        );
        final totalValue = activeProducts.fold(
          0.0,
          (sum, p) => sum + (p.costPrice * p.totalQuantity),
        );
        final lowStock = provider.lowStockProducts;
        final outOfStock = provider.outOfStockProducts;

        final formatter = NumberFormat('#,##0.00', 'ar');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // بطاقات الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'إجمالي المنتجات',
                      value: '${activeProducts.length}',
                      icon: Icons.inventory_2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'إجمالي القطع',
                      value: '$totalQuantity',
                      icon: Icons.numbers,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'قيمة المخزون',
                      value: '${formatter.format(totalValue)} ر.س',
                      icon: Icons.attach_money,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'منخفض المخزون',
                      value: '${lowStock.length}',
                      icon: Icons.warning,
                      color: lowStock.isEmpty
                          ? AppTheme.grey600
                          : AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // منتجات نفذت
              if (outOfStock.isNotEmpty)
                Card(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: AppTheme.errorColor),
                            const SizedBox(width: 8),
                            Text(
                              'منتجات نفذت من المخزون (${outOfStock.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorColor,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...outOfStock
                            .take(5)
                            .map(
                              (p) => ListTile(
                                title: Text(p.name),
                                subtitle: Text(p.brand),
                                dense: true,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // منتجات منخفضة المخزون
              if (lowStock.isNotEmpty)
                Card(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'منتجات منخفضة المخزون (${lowStock.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...lowStock
                            .take(5)
                            .map(
                              (p) => ListTile(
                                title: Text(p.name),
                                subtitle: Text(p.brand),
                                trailing: Text(
                                  '${p.totalQuantity} قطعة',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                                dense: true,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfitReport() {
    final formatter = NumberFormat('#,##0.00', 'ar');

    if (_salesReport == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final profit = _salesReport!.totalProfit;
    final profitMargin = _salesReport!.totalRevenue > 0
        ? (profit / _salesReport!.totalRevenue) * 100
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقات الإحصائيات
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'إجمالي الإيرادات',
                  value: '${formatter.format(_salesReport!.totalRevenue)} ر.س',
                  icon: Icons.trending_up,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'إجمالي التكاليف',
                  value: '${formatter.format(_salesReport!.totalCost)} ر.س',
                  icon: Icons.trending_down,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'صافي الربح',
                  value: '${formatter.format(profit)} ر.س',
                  icon: Icons.account_balance_wallet,
                  color: profit >= 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'هامش الربح',
                  value: '${profitMargin.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // تفاصيل إضافية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملخص الفترة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'إجمالي الإيرادات',
                    '${formatter.format(_salesReport!.totalRevenue)} ر.س',
                  ),
                  _buildDetailRow(
                    'إجمالي التكاليف',
                    '- ${formatter.format(_salesReport!.totalCost)} ر.س',
                    color: AppTheme.errorColor,
                  ),
                  if (_salesReport!.totalDiscount > 0)
                    _buildDetailRow(
                      'إجمالي الخصومات',
                      '- ${formatter.format(_salesReport!.totalDiscount)} ر.س',
                      color: AppTheme.errorColor,
                    ),
                  if (_salesReport!.totalTax > 0)
                    _buildDetailRow(
                      'إجمالي الضرائب المحصلة',
                      '${formatter.format(_salesReport!.totalTax)} ر.س',
                    ),
                  const Divider(),
                  _buildDetailRow(
                    'صافي الربح',
                    '${formatter.format(profit)} ر.س',
                    isBold: true,
                    color: profit >= 0
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'نقدي':
        return Icons.payments;
      case 'بطاقة':
        return Icons.credit_card;
      case 'آجل':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }
}

/// بطاقة الإحصائيات
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppTheme.grey600),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
