import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';

/// بطاقة عرض المنتج
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              _buildImage(),
              const SizedBox(width: AppSizes.md),

              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم وحالة المخزون
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStockBadge(context),
                      ],
                    ),

                    const SizedBox(height: AppSizes.xs),

                    // الفئة
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),

                    const SizedBox(height: AppSizes.sm),

                    // السعر والمخزون
                    Row(
                      children: [
                        // السعر
                        Text(
                          product.price.toCurrency(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        // المخزون
                        Icon(
                          Icons.inventory_2_outlined,
                          size: AppSizes.iconSm,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '${product.totalStock}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // الألوان المتوفرة
                    _buildColorDots(),
                  ],
                ),
              ),

              // قائمة الإجراءات
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: AppSizes.sm),
                        Text(AppStrings.edit),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSizes.sm),
                        Text(AppStrings.delete,
                            style: TextStyle(color: AppColors.error)),
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

  Widget _buildImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _buildStockBadge(BuildContext context) {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Text(
          AppStrings.outOfStock,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Text(
          AppStrings.lowStock,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildColorDots() {
    final colors = product.allColors.take(5).toList();
    final hasMore = product.allColors.length > 5;

    return Row(
      children: [
        ...colors.map((colorName) {
          final colorCode = CommonColors.getColorCode(colorName);
          return Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: _hexToColor(colorCode),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
          );
        }),
        if (hasMore)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
