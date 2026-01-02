// ═══════════════════════════════════════════════════════════════════════════
// Products Header Widget
// Top section with back button, title, and add button
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/services/export/export_button.dart';

class ProductsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int totalProducts;
  final VoidCallback onAddProduct;
  final void Function(ExportType type)? onExport;
  final bool isExporting;

  const ProductsHeader({
    super.key,
    required this.onBack,
    required this.totalProducts,
    required this.onAddProduct,
    this.onExport,
    this.isExporting = false,
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

          // Export Menu Button (Unified)
          if (onExport != null)
            ExportMenuButton(
              onExport: onExport!,
              isLoading: isExporting,
              tooltip: 'تصدير ومشاركة',
              enabledOptions: const {
                ExportType.excel,
                ExportType.pdf,
                ExportType.sharePdf,
                ExportType.shareExcel,
              },
            ),
        ],
      ),
    );
  }
}
