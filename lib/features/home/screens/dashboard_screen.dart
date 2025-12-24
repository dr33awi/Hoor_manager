// lib/features/home/screens/dashboard_screen.dart
// شاشة لوحة التحكم - تصميم محسّن بدون animations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../products/providers/product_provider.dart';
import '../../sales/providers/sale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final productProvider = context.read<ProductProvider>();
    final saleProvider = context.read<SaleProvider>();
    await Future.wait([productProvider.loadAll(), saleProvider.loadSales()]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: Consumer2<SaleProvider, ProductProvider>(
        builder: (context, saleProvider, productProvider, _) {
          final isLoading = saleProvider.isLoading && productProvider.isLoading;

          if (isLoading) {
            return const _DashboardShimmer();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 24),
                _buildTodaySummaryCard(saleProvider),
                const SizedBox(height: 16),
                _buildStatsGrid(saleProvider, productProvider),
                const SizedBox(height: 28),
                _buildLowStockSection(productProvider),
                const SizedBox(height: 28),
                _buildRecentSalesSection(saleProvider),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    Color iconColor;

    if (hour < 12) {
      greeting = 'صباح الخير';
      icon = Icons.wb_sunny_rounded;
      iconColor = Colors.orange;
    } else if (hour < 18) {
      greeting = 'مساء الخير';
      icon = Icons.wb_sunny_outlined;
      iconColor = Colors.amber;
    } else {
      greeting = 'مساء الخير';
      icon = Icons.nightlight_round;
      iconColor = AppColors.primary;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    greeting,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'نظرة عامة على المبيعات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        _TodayDateBadge(),
      ],
    );
  }

  Widget _buildTodaySummaryCard(SaleProvider saleProvider) {
    final formatter = NumberFormat('#,##0.00', 'ar');

    return GradientCard.primary(
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
              const Expanded(
                child: Text(
                  'إجمالي مبيعات اليوم',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${saleProvider.todayOrdersCount} فاتورة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // الأنيميشن محفوظة هنا فقط
          AnimatedNumber(
            value: saleProvider.todayTotal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            formatter: (v) => '${formatter.format(v)} ر.س',
            duration: const Duration(milliseconds: 800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    SaleProvider saleProvider,
    ProductProvider productProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'المنتجات النشطة',
            value: productProvider.allProducts.where((p) => p.isActive).length,
            icon: Icons.inventory_2_rounded,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'منخفض المخزون',
            value: productProvider.lowStockProducts.length,
            icon: Icons.warning_rounded,
            color: productProvider.lowStockProducts.isEmpty
                ? Colors.grey.shade400
                : AppColors.warning,
            showAlert: productProvider.lowStockProducts.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockSection(ProductProvider provider) {
    final lowStock = provider.lowStockProducts;
    if (lowStock.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'منتجات منخفضة المخزون',
          icon: Icons.warning_rounded,
          iconColor: AppColors.warning,
          iconBackgroundColor: AppColors.warningLight,
          trailing: CountBadge(
            count: lowStock.length,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStock.take(5).length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final product = lowStock[index];
              return _LowStockItem(product: product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSalesSection(SaleProvider provider) {
    final recentSales = provider.allSales.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'آخر الفواتير',
          icon: Icons.history_rounded,
          iconColor: AppColors.purple,
          iconBackgroundColor: AppColors.purpleLight,
        ),
        const SizedBox(height: 14),
        ElevatedCard(
          padding: EdgeInsets.zero,
          child: recentSales.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState.sales(),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSales.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    return _RecentSaleItem(sale: recentSales[index]);
                  },
                ),
        ),
      ],
    );
  }
}

// ================= Widgets الداخلية =================

class _TodayDateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayFormatter = DateFormat('d', 'ar');
    final monthFormatter = DateFormat('MMM', 'ar');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            dayFormatter.format(now),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            monthFormatter.format(now),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// نسخة بدون أنيميشن
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool showAlert;

  const _StatCard({
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
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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

class _LowStockItem extends StatelessWidget {
  final dynamic product;

  const _LowStockItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade500,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.brand,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          _StockBadge(
            quantity: product.totalQuantity,
            isOutOfStock: product.isOutOfStock,
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int quantity;
  final bool isOutOfStock;

  const _StockBadge({required this.quantity, required this.isOutOfStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOutOfStock
              ? [AppColors.errorLight, AppColors.error.withValues(alpha: 0.15)]
              : [
                  AppColors.warningLight,
                  AppColors.warning.withValues(alpha: 0.15),
                ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
            size: 14,
            color: isOutOfStock ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isOutOfStock ? 'نفذ' : '$quantity',
            style: TextStyle(
              color: isOutOfStock ? AppColors.error : AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSaleItem extends StatelessWidget {
  final dynamic sale;

  const _RecentSaleItem({required this.sale});

  Color get _statusColor {
    switch (sale.status) {
      case 'مكتمل':
        return AppColors.success;
      case 'ملغي':
        return AppColors.error;
      case 'معلق':
        return AppColors.warning;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd/MM - hh:mm a', 'ar');

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _statusColor.withValues(alpha: 0.15),
                  _statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_outlined, color: _statusColor, size: 22),
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
                const SizedBox(height: 2),
                Text(
                  dateFormatter.format(sale.saleDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(sale.total)} ر.س',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.status,
                  style: TextStyle(
                    fontSize: 10,
                    color: _statusColor,
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

// ================= Shimmer Loading =================

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting shimmer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(width: 80, height: 14),
                    SizedBox(height: 8),
                    ShimmerLoading(width: 180, height: 24),
                  ],
                ),
              ),
              const ShimmerLoading(width: 50, height: 50, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 24),

          // Summary card shimmer
          const ShimmerLoading(height: 120, borderRadius: 16),
          const SizedBox(height: 16),

          // Stats grid shimmer
          Row(
            children: const [
              Expanded(child: ShimmerLoading(height: 80, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 80, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 28),

          // Section shimmer
          const ShimmerLoading(width: 150, height: 20),
          const SizedBox(height: 14),
          ShimmerLoading.list(count: 3),
        ],
      ),
    );
  }
}
