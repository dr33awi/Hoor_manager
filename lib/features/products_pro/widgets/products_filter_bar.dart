// ═══════════════════════════════════════════════════════════════════════════
// Products Filter Bar Widget
// Search field with view toggle and sort options
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

class ProductsFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isGridView;
  final VoidCallback onViewToggle;
  final String sortBy;
  final ValueChanged<String?> onSortChanged;

  const ProductsFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.isGridView,
    required this.onViewToggle,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: AppIconSize.sm,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textTertiary,
                            size: AppIconSize.sm,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildViewButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: isGridView,
                  onTap: isGridView ? null : onViewToggle,
                  isLeft: true,
                ),
                Container(
                  width: 1,
                  height: 24.h,
                  color: AppColors.border,
                ),
                _buildViewButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !isGridView,
                  onTap: !isGridView ? null : onViewToggle,
                  isLeft: false,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Sort Button
          Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortBy,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  color: AppColors.textSecondary,
                  size: AppIconSize.sm,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('الاسم')),
                  DropdownMenuItem(value: 'price_asc', child: Text('السعر ⬆')),
                  DropdownMenuItem(value: 'price_desc', child: Text('السعر ⬇')),
                  DropdownMenuItem(value: 'stock', child: Text('المخزون')),
                  DropdownMenuItem(value: 'recent', child: Text('الأحدث')),
                ],
                onChanged: onSortChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? Radius.circular(AppRadius.sm - 1) : Radius.zero,
        right: isLeft ? Radius.zero : Radius.circular(AppRadius.sm - 1),
      ),
      child: Container(
        width: 40.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        ),
        child: Icon(
          icon,
          size: AppIconSize.sm,
          color: isSelected ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
