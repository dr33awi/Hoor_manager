// lib/features/reports/screens/reports_screen.dart
// شاشة التقارير - تصميم محسّن

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../products/providers/product_provider.dart';
import '../../sales/providers/sale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    debugPrint('🔄 ReportsScreen: Refreshing data...');
    final productProvider = context.read<ProductProvider>();
    final saleProvider = context.read<SaleProvider>();
    await Future.wait([productProvider.loadAll(), saleProvider.loadSales()]);
    // تأخير بسيط لإظهار مؤشر التحديث
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('✅ ReportsScreen: Data refreshed!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SalesReportTab(
                startDate: _startDate,
                endDate: _endDate,
                onRefresh: _loadData,
              ),
              _ProductsReportTab(onRefresh: _loadData),
              _InventoryReportTab(onRefresh: _loadData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [_buildDateSelector(), _buildTabs()]),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _DateBox(
              date: _startDate,
              label: 'من',
              onTap: () => _selectDate(true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: _DateBox(
              date: _endDate,
              label: 'إلى',
              onTap: () => _selectDate(false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        dividerColor: Colors.grey.shade200,
        tabs: [
          _buildTab('المبيعات', AppColors.success),
          _buildTab('المنتجات', AppColors.purple),
          _buildTab('المخزون', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildTab(String label, Color dotColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

// ================= Date Box =================

class _DateBox extends StatelessWidget {
  final DateTime date;
  final String label;
  final VoidCallback onTap;

  const _DateBox({
    required this.date,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Sales Report Tab =================

class _SalesReportTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Future<void> Function() onRefresh;

  const _SalesReportTab({
    required this.startDate,
    required this.endDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SaleProvider>(
      builder: (_, provider, __) {
        final sales = provider.allSales
            .where(
              (s) =>
                  s.saleDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  s.saleDate.isBefore(endDate.add(const Duration(days: 1))),
            )
            .toList();

        final total = sales.fold<double>(0, (sum, s) => sum + s.total);
        final completed = sales.where((s) => s.status == 'مكتمل').length;
        final pending = sales.where((s) => s.status == 'معلق').length;
        final cancelled = sales.where((s) => s.status == 'ملغي').length;
        final formatter = NumberFormat('#,##0', 'ar');

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary card
                FadeInWidget(
                  child: GradientCard.success(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'إجمالي المبيعات',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedNumber(
                          value: total,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          formatter: (v) => '${formatter.format(v)} ر.س',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      _MiniStatCard(
                        title: 'الفواتير',
                        value: '${sales.length}',
                        icon: Icons.receipt_outlined,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      _MiniStatCard(
                        title: 'مكتملة',
                        value: '$completed',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _MiniStatCard(
                        title: 'معلقة',
                        value: '$pending',
                        icon: Icons.schedule,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _MiniStatCard(
                        title: 'ملغية',
                        value: '$cancelled',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sales list
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'تفاصيل المبيعات',
                        icon: Icons.list_alt_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      sales.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'لا توجد مبيعات',
                            )
                          : ElevatedCard(
                              padding: EdgeInsets.zero,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sales.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                ),
                                itemBuilder: (_, i) =>
                                    _SaleListItem(sale: sales[i]),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= Products Report Tab =================

class _ProductsReportTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _ProductsReportTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final products = provider.allProducts;
        final sorted = List.of(products)
          ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats
                FadeInWidget(
                  child: Row(
                    children: [
                      Expanded(
                        child: _AnimatedStatCardSmall(
                          title: 'المنتجات',
                          value: products.length,
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimatedStatCardSmall(
                          title: 'الفئات',
                          value: provider.categories.length,
                          icon: Icons.category_rounded,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'حسب الفئة',
                        icon: Icons.category_outlined,
                        iconColor: AppColors.purple,
                      ),
                      const SizedBox(height: 12),
                      ElevatedCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.categories.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final c = provider.categories[i];
                            final count = products
                                .where((p) => p.category == c.name)
                                .length;
                            return _CategoryItem(name: c.name, count: count);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top stock
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'أعلى مخزون',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      ElevatedCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sorted.take(10).length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) => _RankedProductItem(
                            product: sorted[i],
                            rank: i + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= Inventory Report Tab =================

class _InventoryReportTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _InventoryReportTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final low = provider.lowStockProducts;
        final out = provider.outOfStockProducts;
        final total = provider.allProducts.fold<int>(
          0,
          (sum, p) => sum + p.totalQuantity,
        );

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats
                FadeInWidget(
                  child: Row(
                    children: [
                      Expanded(
                        child: _AnimatedStatCardSmall(
                          title: 'إجمالي القطع',
                          value: total,
                          icon: Icons.inventory_rounded,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimatedStatCardSmall(
                          title: 'منخفض',
                          value: low.length,
                          icon: Icons.warning_rounded,
                          color: AppColors.warning,
                          showAlert: low.isNotEmpty,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeInWidget(
                  delay: const Duration(milliseconds: 50),
                  child: _AnimatedStatCardSmall(
                    title: 'نفذ المخزون',
                    value: out.length,
                    icon: Icons.error_rounded,
                    color: AppColors.error,
                    showAlert: out.isNotEmpty,
                  ),
                ),

                // Out of stock
                if (out.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: 'نفذ المخزون',
                          icon: Icons.error_outline,
                          iconColor: AppColors.error,
                          iconBackgroundColor: AppColors.errorLight,
                          trailing: CountBadge(
                            count: out.length,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...out.map(
                          (p) =>
                              _StockAlertItem(product: p, isOutOfStock: true),
                        ),
                      ],
                    ),
                  ),
                ],

                // Low stock
                if (low.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 150),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: 'مخزون منخفض',
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.warning,
                          iconBackgroundColor: AppColors.warningLight,
                          trailing: CountBadge(
                            count: low.length,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...low.map(
                          (p) =>
                              _StockAlertItem(product: p, isOutOfStock: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= Helper Widgets =================

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatCardSmall extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool showAlert;

  const _AnimatedStatCardSmall({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (showAlert)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedNumber(
                  value: value.toDouble(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleListItem extends StatelessWidget {
  final dynamic sale;

  const _SaleListItem({required this.sale});

  Color get _color {
    switch (sale.status) {
      case 'مكتمل':
        return AppColors.success;
      case 'ملغي':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_outlined, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd/MM - hh:mm a').format(sale.saleDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sale.total.toStringAsFixed(0)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.status,
                  style: TextStyle(
                    fontSize: 10,
                    color: _color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final int count;

  const _CategoryItem({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          CountBadge(count: count, color: AppColors.purple),
        ],
      ),
    );
  }
}

class _RankedProductItem extends StatelessWidget {
  final dynamic product;
  final int rank;

  const _RankedProductItem({required this.product, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank <= 3
                    ? [AppColors.warning, Colors.orange.shade300]
                    : [Colors.grey.shade300, Colors.grey.shade200],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  product.category,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${product.totalQuantity}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertItem extends StatelessWidget {
  final dynamic product;
  final bool isOutOfStock;

  const _StockAlertItem({required this.product, required this.isOutOfStock});

  @override
  Widget build(BuildContext context) {
    final color = isOutOfStock ? AppColors.error : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  product.category,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              isOutOfStock ? 'نفذ' : '${product.totalQuantity}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
