// ═══════════════════════════════════════════════════════════════════════════
// Category Chips Widget
// Horizontal scrollable category filter chips
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

class CategoryChips extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryId = category['id'] as String;
          final isSelected = categoryId == selectedCategoryId;

          return Padding(
            padding: EdgeInsets.only(
              right: index < categories.length - 1 ? AppSpacing.sm : 0,
            ),
            child: _CategoryChip(
              name: category['name'] as String,
              count: category['count'] as int,
              isSelected: isSelected,
              onTap: () => onCategorySelected(categoryId),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
