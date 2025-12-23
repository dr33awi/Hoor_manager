// lib/features/home/screens/dashboard_screen.dart
// شاشة لوحة التحكم - مُصححة

import 'package:flutter/material.dart';
import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/providers/product_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ProductProvider>().loadAll();
        await context.read<SaleProvider>().loadSales();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقات الإحصائيات
            _buildStatsCards(context),
            const SizedBox(height: 24),

            // المنتجات منخفضة المخزون
            _buildLowStockSection(context),
            const SizedBox(height: 24),

            // آخر المبيعات
            _buildRecentSalesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Consumer2<SaleProvider, ProductProvider>(
      builder: (context, saleProvider, productProvider, _) {
        final formatter = NumberFormat('#,##0.00', 'ar');

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'مبيعات اليوم',
                    value: '${formatter.format(saleProvider.todayTotal)} ر.س',
                    icon: Icons.attach_money,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'فواتير اليوم',
                    value: '${saleProvider.todayOrdersCount}',
                    icon: Icons.receipt_long,
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
                    title: 'إجمالي المنتجات',
                    value:
                        '${productProvider.allProducts.where((p) => p.isActive).length}',
                    icon: Icons.inventory_2,
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'منخفض المخزون',
                    value: '${productProvider.lowStockProducts.length}',
                    icon: Icons.warning,
                    color: productProvider.lowStockProducts.isEmpty
                        ? AppTheme.grey600
                        : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockSection(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final lowStock = provider.lowStockProducts;

        if (lowStock.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Text(
                      'منتجات منخفضة المخزون',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${lowStock.length}',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStock.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = lowStock[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                      child: Icon(
                        Icons.inventory,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(product.brand),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? AppTheme.errorColor.withOpacity(0.1)
                            : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.isOutOfStock
                            ? 'نفذ'
                            : '${product.totalQuantity} قطعة',
                        style: TextStyle(
                          color: product.isOutOfStock
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildRecentSalesSection(BuildContext context) {
    return Consumer<SaleProvider>(
      builder: (context, provider, _) {
        final recentSales = provider.allSales.take(5).toList();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'آخر الفواتير',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (recentSales.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'لا توجد فواتير بعد',
                      style: TextStyle(color: AppTheme.grey600),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = recentSales[index];
                    final formatter = NumberFormat('#,##0.00', 'ar');
                    final dateFormatter = DateFormat('dd/MM - hh:mm a', 'ar');

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          sale.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          Icons.receipt,
                          color: _getStatusColor(sale.status),
                        ),
                      ),
                      title: Text(sale.invoiceNumber),
                      subtitle: Text(dateFormatter.format(sale.saleDate)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatter.format(sale.total)} ر.س',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            sale.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(sale.status),
                            ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return AppTheme.successColor;
      case 'ملغي':
        return AppTheme.errorColor;
      case 'معلق':
        return AppTheme.warningColor;
      default:
        return AppTheme.grey600;
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
