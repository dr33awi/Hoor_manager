// ═══════════════════════════════════════════════════════════════════════════
// Product Card Pro Widget
// Modern product card with grid and list view support
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/pro/design_tokens.dart';

class ProductCardPro extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isListView;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ProductCardPro({
    super.key,
    required this.product,
    this.isListView = false,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return isListView ? _buildListCard(context) : _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image / Placeholder
              _buildImageSection(),

              // Product Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        product['name'],
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      // SKU
                      Text(
                        product['sku'],
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),

                      const Spacer(),

                      // Price & Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product['price'].toStringAsFixed(0)} ر.س',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          _buildStockBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Image
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: product['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          product['image'],
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textTertiary,
                        size: AppIconSize.lg,
                      ),
              ),
              SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStockBadge(),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          product['sku'],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          '•',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          product['category'],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          '${product['price'].toStringAsFixed(0)} ر.س',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Text(
                          'التكلفة: ${product['cost'].toStringAsFixed(0)} ر.س',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    onTap: onEdit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: AppIconSize.sm),
                        SizedBox(width: AppSpacing.sm),
                        const Text('تعديل'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined, size: AppIconSize.sm),
                        SizedBox(width: AppSpacing.sm),
                        const Text('نسخ'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: AppIconSize.sm, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('حذف', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg - 1),
              ),
            ),
            child: product['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg - 1),
                    ),
                    child: Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textTertiary,
                    size: 48.sp,
                  ),
          ),

          // Status Badge
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _buildStatusBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge() {
    final stock = product['stock'] as int;
    final minStock = product['minStock'] as int;

    Color bgColor;
    Color textColor;
    String text;

    if (stock == 0) {
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      text = 'نفد';
    } else if (stock < minStock) {
      bgColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.warning;
      text = '$stock';
    } else {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      text = '$stock';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = product['status'] as String;

    IconData icon;
    Color color;

    switch (status) {
      case 'out_of_stock':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'low_stock':
        icon = Icons.inventory_rounded;
        color = AppColors.warning;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: AppIconSize.xs,
      ),
    );
  }
}
