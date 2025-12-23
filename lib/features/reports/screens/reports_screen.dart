// lib/features/reports/screens/reports_screen.dart
// شاشة التقارير - تصميم حديث

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../products/providers/product_provider.dart';
import '../../sales/providers/sale_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateSelector(),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSalesReport(),
              _buildProductsReport(),
              _buildInventoryReport(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final fmt = DateFormat('dd/MM/yyyy', 'ar');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _dateBox(fmt.format(_startDate), () => _selectDate(true)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          Expanded(
            child: _dateBox(fmt.format(_endDate), () => _selectDate(false)),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null)
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'المبيعات'),
          Tab(text: 'المنتجات'),
          Tab(text: 'المخزون'),
        ],
      ),
    );
  }

  Widget _buildSalesReport() {
    return Consumer<SaleProvider>(
      builder: (_, provider, __) {
        final sales = provider.allSales
            .where(
              (s) =>
                  s.saleDate.isAfter(
                    _startDate.subtract(const Duration(days: 1)),
                  ) &&
                  s.saleDate.isBefore(_endDate.add(const Duration(days: 1))),
            )
            .toList();
        final total = sales.fold<double>(0, (sum, s) => sum + s.total);
        final completed = sales.where((s) => s.status == 'مكتمل').length;
        final cancelled = sales.where((s) => s.status == 'ملغي').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'إجمالي المبيعات',
                      '${total.toStringAsFixed(0)} ر.س',
                      Icons.trending_up_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'الفواتير',
                      '${sales.length}',
                      Icons.receipt_long_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'مكتملة',
                      '$completed',
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'ملغية',
                      '$cancelled',
                      Icons.cancel_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('تفاصيل المبيعات'),
              const SizedBox(height: 12),
              sales.isEmpty
                  ? _emptyState(Icons.receipt_long_outlined, 'لا توجد مبيعات')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sales.length,
                      itemBuilder: (_, i) {
                        final s = sales[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    s.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.receipt_outlined,
                                  color: _statusColor(s.status),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.invoiceNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd/MM - hh:mm a',
                                      ).format(s.saleDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${s.total.toStringAsFixed(0)} ر.س',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    s.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _statusColor(s.status),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsReport() {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final products = provider.allProducts;
        final sorted = List.of(products)
          ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'المنتجات',
                      '${products.length}',
                      Icons.inventory_2_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'الفئات',
                      '${provider.categories.length}',
                      Icons.category_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('حسب الفئة'),
              const SizedBox(height: 12),
              ...provider.categories.map((c) {
                final count = products
                    .where((p) => p.category == c.name)
                    .length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          color: Color(0xFF8B5CF6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$count منتج',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              _sectionTitle('أعلى مخزون'),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.take(10).length,
                itemBuilder: (_, i) {
                  final p = sorted[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                p.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${p.totalQuantity}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryReport() {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final low = provider.lowStockProducts;
        final out = provider.outOfStockProducts;
        final total = provider.allProducts.fold<int>(
          0,
          (sum, p) => sum + p.totalQuantity,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'إجمالي',
                      '$total قطعة',
                      Icons.inventory_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'منخفض',
                      '${low.length}',
                      Icons.warning_rounded,
                      const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _statCard(
                'نفذ',
                '${out.length}',
                Icons.error_rounded,
                const Color(0xFFEF4444),
              ),
              if (out.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('نفذ المخزون'),
                const SizedBox(height: 12),
                ...out.map((p) => _stockItem(p, true)),
              ],
              if (low.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('مخزون منخفض'),
                const SizedBox(height: 12),
                ...low.map((p) => _stockItem(p, false)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stockItem(dynamic p, bool isOut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706))
            .withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706))
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOut ? Icons.error_outline : Icons.warning_amber_rounded,
              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  p.category,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOut ? 'نفذ' : '${p.totalQuantity}',
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

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'مكتمل':
        return const Color(0xFF10B981);
      case 'ملغي':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFD97706);
    }
  }
}
