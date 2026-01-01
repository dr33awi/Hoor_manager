// ═══════════════════════════════════════════════════════════════════════════
// Products Header Widget
// Top section with back button, title, and add button
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/pro/design_tokens.dart';

class ProductsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int totalProducts;
  final VoidCallback onAddProduct;

  const ProductsHeader({
    super.key,
    required this.onBack,
    required this.totalProducts,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: AppIconSize.sm,
              color: AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المنتجات',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$totalProducts منتج',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Barcode Scanner
          IconButton(
            onPressed: () {
              // TODO: Implement barcode scanner
            },
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              size: AppIconSize.md,
              color: AppColors.textSecondary,
            ),
            tooltip: 'مسح الباركود',
          ),

          // Import/Export
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: AppIconSize.md,
              color: AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_rounded, size: AppIconSize.sm),
                    SizedBox(width: AppSpacing.sm),
                    const Text('استيراد'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: AppIconSize.sm),
                    SizedBox(width: AppSpacing.sm),
                    const Text('تصدير'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, size: AppIconSize.sm),
                    SizedBox(width: AppSpacing.sm),
                    const Text('طباعة قائمة'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
