/// ═══════════════════════════════════════════════════════════════════════════
/// Inventory Report Screen - Redesigned
/// Modern Inventory Report Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';

class InventoryReportScreenRedesign extends ConsumerStatefulWidget {
  const InventoryReportScreenRedesign({super.key});

  @override
  ConsumerState<InventoryReportScreenRedesign> createState() =>
      _InventoryReportScreenRedesignState();
}

class _InventoryReportScreenRedesignState
    extends ConsumerState<InventoryReportScreenRedesign> {
  final _db = getIt<AppDatabase>();
  final _currencyService = getIt<CurrencyService>();

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('تقرير المخزون', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _db.watchAllProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: HoorColors.primary),
            );
          }

          final allProducts = snapshot.data!;
          final lowStockProducts = allProducts
              .where((p) => p.quantity > 0 && p.quantity <= p.minQuantity)
              .toList();
          final outOfStockProducts =
              allProducts.where((p) => p.quantity <= 0).toList();

          // Calculate inventory value
          double totalCost = 0;
          double totalSale = 0;
          for (final product in allProducts) {
            totalCost += product.purchasePrice * product.quantity;
            totalSale += product.salePrice * product.quantity;
          }

          return CustomScrollView(
            slivers: [
              // Inventory Value Section
              SliverPadding(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildInventoryValueSection(
                    totalCost: totalCost,
                    totalSale: totalSale,
                  ),
                ),
              ),

              // Stock Status Section
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildStockStatusSection(
                    total: allProducts.length,
                    lowStock: lowStockProducts.length,
                    outOfStock: outOfStockProducts.length,
                  ),
                ),
              ),

              // Out of Stock Products
              if (outOfStockProducts.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'منتجات نفذت',
                      count: outOfStockProducts.length,
                      color: HoorColors.error,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = outOfStockProducts[index];
                        return _buildProductCard(product, HoorColors.error);
                      },
                      childCount: outOfStockProducts.take(5).length,
                    ),
                  ),
                ),
              ],

              // Low Stock Products
              if (lowStockProducts.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'نقص مخزون',
                      count: lowStockProducts.length,
                      color: HoorColors.warning,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = lowStockProducts[index];
                        return _buildProductCard(product, HoorColors.warning);
                      },
                      childCount: lowStockProducts.take(5).length,
                    ),
                  ),
                ),
              ],

              // All Products Section
              SliverPadding(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                sliver: SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'جميع المنتجات',
                    count: allProducts.length,
                    color: HoorColors.primary,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = allProducts[index];
                      return _buildProductCard(product, HoorColors.primary);
                    },
                    childCount: allProducts.length,
                  ),
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

  Widget _buildInventoryValueSection({
    required double totalCost,
    required double totalSale,
  }) {
    final potentialProfit = totalSale - totalCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قيمة المخزون',
          style: HoorTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                title: 'قيمة التكلفة',
                value: totalCost,
                color: HoorColors.primary,
                icon: Icons.shopping_cart_rounded,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildValueCard(
                title: 'قيمة البيع',
                value: totalSale,
                color: HoorColors.success,
                icon: Icons.sell_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HoorColors.success.withValues(alpha: 0.1),
                HoorColors.success.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(
              color: HoorColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: HoorColors.success, size: 20),
                      SizedBox(width: HoorSpacing.xs.w),
                      Text(
                        'الربح المتوقع',
                        style: HoorTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(potentialProfit),
                        style: HoorTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HoorColors.success,
                        ),
                      ),
                      Text(
                        '\$${_currencyService.sypToUsd(potentialProfit).toStringAsFixed(2)}',
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: HoorSpacing.sm.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.sm.w,
                  vertical: HoorSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: HoorColors.surface,
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Text(
                  'سعر الصرف: 1\$ = ${_currencyService.exchangeRate.toStringAsFixed(0)} ل.س',
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
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
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '\$${_currencyService.sypToUsd(value).toStringAsFixed(2)}',
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusSection({
    required int total,
    required int lowStock,
    required int outOfStock,
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
              Icon(Icons.inventory_2_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'حالة المخزون',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'إجمالي',
                  count: total,
                  color: HoorColors.primary,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _buildStatusChip(
                  icon: Icons.warning_amber_rounded,
                  label: 'نقص',
                  count: lowStock,
                  color: HoorColors.warning,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _buildStatusChip(
                  icon: Icons.error_outline_rounded,
                  label: 'نفذ',
                  count: outOfStock,
                  color: HoorColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: HoorSpacing.xxs.h),
          Text(
            '$count',
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: HoorTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.sm.w,
            vertical: HoorSpacing.xxs.h,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: Text(
            '$count منتج',
            style: HoorTypography.labelMedium.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, Color accentColor) {
    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: ListTile(
        onTap: () => context.push('/products/${product.id}'),
        leading: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: Icon(Icons.inventory_2_outlined, color: accentColor, size: 20),
        ),
        title: Text(
          product.name,
          style: HoorTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          product.barcode ?? 'بدون باركود',
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.sm.w,
                vertical: HoorSpacing.xxs.h,
              ),
              decoration: BoxDecoration(
                color: (product.quantity <= 0
                        ? HoorColors.error
                        : product.quantity <= product.minQuantity
                            ? HoorColors.warning
                            : HoorColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Text(
                '${product.quantity}',
                style: HoorTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: product.quantity <= 0
                      ? HoorColors.error
                      : product.quantity <= product.minQuantity
                          ? HoorColors.warning
                          : HoorColors.success,
                ),
              ),
            ),
            Text(
              'الحد: ${product.minQuantity}',
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
