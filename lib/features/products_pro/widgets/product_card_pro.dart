// ═══════════════════════════════════════════════════════════════════════════
// Product Card Pro Widget
// Modern product card with grid and list view support
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image / Placeholder - حجم أصغر
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.md - 1),
                        ),
                      ),
                      child: product['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.md - 1),
                              ),
                              child: Image.network(
                                product['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              ),
                            )
                          : _buildPlaceholder(),
                    ),
                    // Status Badge
                    if (_shouldShowStatusBadge())
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: _buildStatusBadge(),
                      ),
                  ],
                ),
              ),

              // Product Info - حجم أصغر
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Text(
                        product['name'],
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Price & Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              (product['price'] as double).toStringAsFixed(0),
                              style: AppTypography.labelMedium
                                  .copyWith(
                                    color: AppColors.secondary,
                                  )
                                  .monoBold,
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textTertiary,
        size: 32.sp,
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
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Image
              Container(
                width: 56.w,
                height: 56.w,
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
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textTertiary,
                            size: AppIconSize.md,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textTertiary,
                        size: AppIconSize.md,
                      ),
              ),
              SizedBox(width: AppSpacing.sm),

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
                            style: AppTypography.labelMedium.copyWith(
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
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (product['sku'] != null &&
                            (product['sku'] as String).isNotEmpty) ...[
                          Text(
                            product['sku'],
                            style: AppTypography.labelSmall
                                .copyWith(
                                  color: AppColors.textTertiary,
                                )
                                .mono,
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            product['category'] ?? '',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '${(product['price'] as double).toStringAsFixed(0)} ل.س',
                          style: AppTypography.labelMedium
                              .copyWith(
                                color: AppColors.secondary,
                              )
                              .monoBold,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'التكلفة: ${(product['cost'] as double).toStringAsFixed(0)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Button
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  size: AppIconSize.sm,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
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
      bgColor = AppColors.error.soft;
      textColor = AppColors.error;
      text = 'نفد';
    } else if (stock <= minStock) {
      bgColor = AppColors.warning.soft;
      textColor = AppColors.warning;
      text = '$stock';
    } else {
      bgColor = AppColors.success.soft;
      textColor = AppColors.success;
      text = '$stock';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall
            .copyWith(
              color: textColor,
              fontSize: 10.sp,
            )
            .monoSemibold,
      ),
    );
  }

  bool _shouldShowStatusBadge() {
    final status = product['status'] as String;
    return status == 'out_of_stock' || status == 'low_stock';
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
      padding: EdgeInsets.all(AppSpacing.xs - 2),
      decoration: BoxDecoration(
        color: color.o87,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 12.sp,
      ),
    );
  }
}
