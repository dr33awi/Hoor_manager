// ═══════════════════════════════════════════════════════════════════════════
// Product Details Screen Pro
// View detailed product information
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class ProductDetailsScreenPro extends StatelessWidget {
  final String productId;

  const ProductDetailsScreenPro({
    super.key,
    required this.productId,
  });

  // Sample product data
  Map<String, dynamic> get _product => {
        'id': productId,
        'name': 'لابتوب HP ProBook',
        'sku': 'LAP-001',
        'barcode': '8901234567890',
        'price': 2500.00,
        'cost': 2000.00,
        'stock': 15,
        'minStock': 5,
        'sold': 45,
        'category': 'إلكترونيات',
        'unit': 'قطعة',
        'description': 'لابتوب احترافي بمعالج Intel Core i7 وذاكرة 16GB RAM',
        'isActive': true,
        'isTaxable': true,
        'createdAt': '2024-01-15',
        'updatedAt': '2024-06-20',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ═══════════════════════════════════════════════════════════════════
          // App Bar
          // ═══════════════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 280.h,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: AppIconSize.sm,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/products/edit/$productId'),
                icon: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: AppIconSize.sm,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: AppIconSize.sm,
                    color: AppColors.textPrimary,
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'duplicate', child: Text('نسخ المنتج')),
                  const PopupMenuItem(
                      value: 'print', child: Text('طباعة الباركود')),
                  const PopupMenuItem(
                      value: 'history', child: Text('سجل الحركات')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('حذف', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.background,
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 100.sp,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // Content
          // ═══════════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Category
                  _buildHeader(),
                  SizedBox(height: AppSpacing.lg),

                  // Quick Stats
                  _buildQuickStats(),
                  SizedBox(height: AppSpacing.lg),

                  // Price Info
                  _buildPriceSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Stock Info
                  _buildStockSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Product Details
                  _buildDetailsSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Recent Activity
                  _buildRecentActivity(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _product['category'],
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            if (_product['isActive'])
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'نشط',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          _product['name'],
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              Icons.qr_code_rounded,
              size: AppIconSize.xs,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              _product['sku'],
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            if (_product['barcode'] != null) ...[
              SizedBox(width: AppSpacing.md),
              Icon(
                Icons.view_week_rounded,
                size: AppIconSize.xs,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                _product['barcode'],
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_cart_outlined,
            label: 'المبيعات',
            value: '${_product['sold']}',
            color: AppColors.secondary,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'المخزون',
            value: '${_product['stock']}',
            color: _product['stock'] > _product['minStock']
                ? AppColors.success
                : AppColors.warning,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            label: 'هامش الربح',
            value: '20%',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final profit = _product['price'] - _product['cost'];
    final margin =
        (_product['price'] > 0) ? (profit / _product['price'] * 100) : 0.0;

    return _buildCard(
      title: 'التسعير',
      icon: Icons.attach_money_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            'سعر البيع',
            '${_product['price'].toStringAsFixed(0)} ر.س',
            valueStyle: AppTypography.titleLarge.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Divider(height: AppSpacing.lg, color: AppColors.border),
          _buildInfoRow(
            'سعر التكلفة',
            '${_product['cost'].toStringAsFixed(0)} ر.س',
            valueStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            'الربح لكل وحدة',
            '${profit.toStringAsFixed(0)} ر.س (${margin.toStringAsFixed(1)}%)',
            valueStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection() {
    return _buildCard(
      title: 'المخزون',
      icon: Icons.inventory_outlined,
      child: Column(
        children: [
          _buildInfoRow(
              'الكمية المتوفرة', '${_product['stock']} ${_product['unit']}'),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
              'حد التنبيه', '${_product['minStock']} ${_product['unit']}'),
          SizedBox(height: AppSpacing.md),

          // Stock Status
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _product['stock'] > _product['minStock']
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  _product['stock'] > _product['minStock']
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: _product['stock'] > _product['minStock']
                      ? AppColors.success
                      : AppColors.warning,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _product['stock'] > _product['minStock']
                        ? 'المخزون كافي'
                        : 'المخزون منخفض - يُنصح بإعادة الطلب',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _product['stock'] > _product['minStock']
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return _buildCard(
      title: 'التفاصيل',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_product['description'] != null) ...[
            Text(
              _product['description'],
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.border),
            SizedBox(height: AppSpacing.md),
          ],
          _buildInfoRow('الوحدة', _product['unit']),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            'خاضع للضريبة',
            _product['isTaxable'] ? 'نعم' : 'لا',
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow('تاريخ الإضافة', _product['createdAt']),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow('آخر تحديث', _product['updatedAt']),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return _buildCard(
      title: 'آخر الحركات',
      icon: Icons.history_rounded,
      trailing: TextButton(
        onPressed: () {},
        child: Text(
          'عرض الكل',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ),
      child: Column(
        children: [
          _ActivityItem(
            type: 'sale',
            description: 'بيع 2 وحدات',
            date: 'اليوم 10:30 ص',
          ),
          Divider(height: AppSpacing.lg, color: AppColors.border),
          _ActivityItem(
            type: 'purchase',
            description: 'إضافة 10 وحدات',
            date: 'أمس 3:15 م',
          ),
          Divider(height: AppSpacing.lg, color: AppColors.border),
          _ActivityItem(
            type: 'adjustment',
            description: 'تعديل الكمية (-1)',
            date: '20 يونيو 2024',
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.sm, color: AppColors.textTertiary),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Adjust stock
                },
                icon: const Icon(Icons.inventory_rounded),
                label: const Text('تعديل المخزون'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Add to sale
                },
                icon: const Icon(Icons.shopping_cart_rounded),
                label: const Text('إضافة للبيع'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppIconSize.md, color: color),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String type;
  final String description;
  final String date;

  const _ActivityItem({
    required this.type,
    required this.description,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'sale':
        icon = Icons.arrow_upward_rounded;
        color = AppColors.success;
        break;
      case 'purchase':
        icon = Icons.arrow_downward_rounded;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.edit_rounded;
        color = AppColors.warning;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: AppIconSize.sm, color: color),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                date,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
