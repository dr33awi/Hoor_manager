// ═══════════════════════════════════════════════════════════════════════════
// Inventory Count Screen Pro - Professional Design System
// Modern Inventory Count Interface with Barcode Scanner
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';

class InventoryCountScreenPro extends ConsumerStatefulWidget {
  const InventoryCountScreenPro({super.key});

  @override
  ConsumerState<InventoryCountScreenPro> createState() =>
      _InventoryCountScreenProState();
}

class _InventoryCountScreenProState
    extends ConsumerState<InventoryCountScreenPro> {
  final _searchController = TextEditingController();
  final Map<String, int> _countedQuantities = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsHeader(),
            _buildSearchBar(),
            Expanded(
              child: productsAsync.when(
                loading: () => ProLoadingState.list(),
                error: (error, _) => ProEmptyState.error(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(activeProductsStreamProvider),
                ),
                data: (products) {
                  final filteredProducts = _searchQuery.isEmpty
                      ? products
                      : products
                          .where((p) =>
                              p.name
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              (p.barcode?.contains(_searchQuery) ?? false) ||
                              (p.sku?.contains(_searchQuery) ?? false))
                          .toList();

                  return filteredProducts.isEmpty
                      ? ProEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'لا توجد منتجات',
                          message: 'أضف منتجات للبدء في الجرد',
                        )
                      : _buildProductsList(filteredProducts);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ProHeader(
      title: 'جرد المخزون',
      subtitle: 'تحديث الكميات الفعلية',
      actions: [
        // Barcode Scanner Button
        IconButton(
          onPressed: _scanBarcode,
          icon: Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.secondary.soft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.secondary, size: 20.sp),
          ),
        ),
        // Save Button
        if (_countedQuantities.isNotEmpty)
          TextButton.icon(
            onPressed: _saveCount,
            icon:
                Icon(Icons.save_rounded, color: AppColors.success, size: 20.sp),
            label: Text(
              'حفظ (${_countedQuantities.length})',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final productsAsync = ref.watch(activeProductsStreamProvider);

    return productsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) => Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.inventory_2_rounded,
                label: 'إجمالي',
                value: '${products.length}',
                color: AppColors.primary,
              ),
            ),
            Container(width: 1, height: 40.h, color: AppColors.border),
            Expanded(
              child: _buildStatItem(
                icon: Icons.check_circle_rounded,
                label: 'تم جرده',
                value: '${_countedQuantities.length}',
                color: AppColors.success,
              ),
            ),
            Container(width: 1, height: 40.h, color: AppColors.border),
            Expanded(
              child: _buildStatItem(
                icon: Icons.pending_rounded,
                label: 'متبقي',
                value: '${products.length - _countedQuantities.length}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ProSearchBar(
      controller: _searchController,
      hintText: 'بحث بالاسم أو الباركود...',
      margin: EdgeInsets.all(AppSpacing.md),
      onChanged: (value) => setState(() => _searchQuery = value),
      onClear: () => setState(() => _searchQuery = ''),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCountCard(
          product: product,
          countedQuantity: _countedQuantities[product.id],
          onQuantityChanged: (qty) {
            setState(() {
              if (qty != null) {
                _countedQuantities[product.id] = qty;
              } else {
                _countedQuantities.remove(product.id);
              }
            });
          },
        );
      },
    );
  }

  void _scanBarcode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeScannerSheet(
        onBarcodeScanned: (barcode) {
          Navigator.pop(context);
          _searchController.text = barcode;
          setState(() => _searchQuery = barcode);
        },
      ),
    );
  }

  Future<void> _saveCount() async {
    if (_countedQuantities.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('تأكيد الحفظ', style: AppTypography.titleLarge),
        content: Text(
          'سيتم تحديث كميات ${_countedQuantities.length} منتج.\nهل أنت متأكد؟',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppTypography.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حفظ',
                style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      final productsAsync = ref.read(activeProductsStreamProvider);

      final products = productsAsync.value ?? [];

      for (final entry in _countedQuantities.entries) {
        final product = products.firstWhere((p) => p.id == entry.key,
            orElse: () => products.first);
        final difference = entry.value - product.quantity;
        if (difference != 0) {
          await inventoryRepo.adjustStock(
            productId: entry.key,
            actualQuantity: entry.value,
            reason: 'جرد المخزون',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ الجرد بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product Count Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _ProductCountCard extends StatelessWidget {
  final Product product;
  final int? countedQuantity;
  final ValueChanged<int?> onQuantityChanged;

  const _ProductCountCard({
    required this.product,
    required this.countedQuantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final difference =
        countedQuantity != null ? countedQuantity! - product.quantity : null;

    Color? bgColor;
    Color borderColor = AppColors.border;

    if (countedQuantity != null) {
      if (difference! > 0) {
        bgColor = AppColors.success.subtle;
        borderColor = AppColors.success.border;
      } else if (difference < 0) {
        bgColor = AppColors.error.subtle;
        borderColor = AppColors.error.border;
      } else {
        bgColor = AppColors.primary.subtle;
        borderColor = AppColors.primary.border;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.xs,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.barcode != null)
                        Text(
                          product.barcode!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (countedQuantity != null)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 14.sp),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // Quantity Row
            Row(
              children: [
                // System Quantity
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بالنظام',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${product.quantity}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),

                // Actual Quantity Input
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'الكمية الفعلية',
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        hintText: '${product.quantity}',
                        hintStyle: AppTypography.titleMedium.copyWith(
                          color: AppColors.textSecondary.o54,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value);
                        onQuantityChanged(qty);
                      },
                    ),
                  ),
                ),

                // Difference
                if (difference != null) ...[
                  SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: (difference > 0
                              ? AppColors.success
                              : difference < 0
                                  ? AppColors.error
                                  : AppColors.primary)
                          .soft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      difference > 0
                          ? '+$difference'
                          : difference < 0
                              ? '$difference'
                              : '0',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: difference > 0
                            ? AppColors.success
                            : difference < 0
                                ? AppColors.error
                                : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barcode Scanner Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _BarcodeScannerSheet extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const _BarcodeScannerSheet({required this.onBarcodeScanned});

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary),
                ),
                SizedBox(width: AppSpacing.sm),
                Text('مسح الباركود', style: AppTypography.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            child: Container(
              margin: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (_isProcessing) return;
                    final barcode = capture.barcodes.firstOrNull?.rawValue;
                    if (barcode != null) {
                      setState(() => _isProcessing = true);
                      widget.onBarcodeScanned(barcode);
                    }
                  },
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 16.sp),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'وجّه الكاميرا نحو الباركود',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
