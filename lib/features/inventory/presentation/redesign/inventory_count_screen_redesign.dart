/// ═══════════════════════════════════════════════════════════════════════════
/// Inventory Count Screen - Redesigned
/// Modern Inventory Count Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/inventory_repository.dart';

class InventoryCountScreenRedesign extends ConsumerStatefulWidget {
  const InventoryCountScreenRedesign({super.key});

  @override
  ConsumerState<InventoryCountScreenRedesign> createState() =>
      _InventoryCountScreenRedesignState();
}

class _InventoryCountScreenRedesignState
    extends ConsumerState<InventoryCountScreenRedesign> {
  final _productRepo = getIt<ProductRepository>();
  final _inventoryRepo = getIt<InventoryRepository>();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  final Map<String, int> _countedQuantities = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _searchQuery.isEmpty
        ? _products
        : _products
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.barcode?.contains(_searchQuery) ?? false) ||
                (p.sku?.contains(_searchQuery) ?? false))
            .toList();

    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('جرد المخزون', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.qr_code_scanner_rounded,
                  color: HoorColors.primary, size: 20),
            ),
            onPressed: _scanBarcode,
          ),
          if (_countedQuantities.isNotEmpty)
            TextButton.icon(
              onPressed: _saveCount,
              icon: const Icon(Icons.save_rounded, color: HoorColors.primary),
              label: Text(
                'حفظ (${_countedQuantities.length})',
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HoorColors.primary))
          : Column(
              children: [
                // Stats Header
                _buildStatsHeader(),

                // Search Bar
                Padding(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: HoorColors.surface,
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                      border: Border.all(color: HoorColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: HoorTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم أو الباركود...',
                        hintStyle: HoorTypography.bodyMedium.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: HoorColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    color: HoorColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ),

                // Products List
                Expanded(
                  child: filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: HoorSpacing.md.w),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        border: Border(
          bottom: BorderSide(color: HoorColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.inventory_2_rounded,
              label: 'إجمالي',
              value: '${_products.length}',
              color: HoorColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: HoorColors.border,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_rounded,
              label: 'تم جرده',
              value: '${_countedQuantities.length}',
              color: HoorColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: HoorColors.border,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.pending_rounded,
              label: 'متبقي',
              value: '${_products.length - _countedQuantities.length}',
              color: HoorColors.warning,
            ),
          ),
        ],
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
            Icon(icon, color: color, size: 16),
            SizedBox(width: HoorSpacing.xxs.w),
            Text(
              value,
              style: HoorTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xxs.h),
        Text(
          label,
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final counted = _countedQuantities[product.id];
    final difference = counted != null ? counted - product.quantity : null;

    Color? bgColor;
    if (counted != null) {
      if (difference! > 0) {
        bgColor = HoorColors.success.withValues(alpha: 0.05);
      } else if (difference < 0) {
        bgColor = HoorColors.error.withValues(alpha: 0.05);
      } else {
        bgColor = HoorColors.primary.withValues(alpha: 0.05);
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: bgColor ?? HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(
          color: counted != null
              ? (difference! > 0
                  ? HoorColors.success.withValues(alpha: 0.3)
                  : difference < 0
                      ? HoorColors.error.withValues(alpha: 0.3)
                      : HoorColors.primary.withValues(alpha: 0.3))
              : HoorColors.border,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.sm.w),
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
                        style: HoorTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.barcode != null)
                        Text(
                          product.barcode!,
                          style: HoorTypography.labelSmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (counted != null)
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.xxs.w),
                    decoration: BoxDecoration(
                      color: HoorColors.success,
                      borderRadius: BorderRadius.circular(HoorRadius.full),
                    ),
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
              ],
            ),
            SizedBox(height: HoorSpacing.sm.h),

            // Quantity Row
            Row(
              children: [
                // System Quantity
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(HoorSpacing.xs.w),
                    decoration: BoxDecoration(
                      color: HoorColors.background,
                      borderRadius: BorderRadius.circular(HoorRadius.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بالنظام',
                          style: HoorTypography.labelSmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${product.quantity}',
                          style: HoorTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),

                // Actual Quantity Input
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HoorColors.background,
                      borderRadius: BorderRadius.circular(HoorRadius.sm),
                      border: Border.all(color: HoorColors.border),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: HoorTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'الكمية الفعلية',
                        labelStyle: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                        hintText: '${product.quantity}',
                        hintStyle: HoorTypography.titleMedium.copyWith(
                          color:
                              HoorColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: HoorSpacing.sm.w,
                          vertical: HoorSpacing.xs.h,
                        ),
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value);
                        setState(() {
                          if (qty != null) {
                            _countedQuantities[product.id] = qty;
                          } else if (value.isEmpty) {
                            _countedQuantities.remove(product.id);
                          }
                        });
                      },
                    ),
                  ),
                ),

                // Difference
                if (difference != null) ...[
                  SizedBox(width: HoorSpacing.sm.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HoorSpacing.sm.w,
                      vertical: HoorSpacing.xs.h,
                    ),
                    decoration: BoxDecoration(
                      color: (difference > 0
                              ? HoorColors.success
                              : difference < 0
                                  ? HoorColors.error
                                  : HoorColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(HoorRadius.sm),
                    ),
                    child: Text(
                      difference > 0
                          ? '+$difference'
                          : difference < 0
                              ? '$difference'
                              : '0',
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: difference > 0
                            ? HoorColors.success
                            : difference < 0
                                ? HoorColors.error
                                : HoorColors.primary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: HoorColors.textSecondary),
          SizedBox(height: HoorSpacing.md.h),
          Text(
            'لا توجد منتجات',
            style: HoorTypography.titleMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
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
        backgroundColor: HoorColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: Text('تأكيد الحفظ', style: HoorTypography.titleLarge),
        content: Text(
          'سيتم تحديث كميات ${_countedQuantities.length} منتج.\nهل أنت متأكد؟',
          style: HoorTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: HoorTypography.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حفظ',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      for (final entry in _countedQuantities.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        final difference = entry.value - product.quantity;
        if (difference != 0) {
          await _inventoryRepo.adjustStock(
            productId: entry.key,
            actualQuantity: entry.value,
            reason: 'جرد المخزون',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الجرد بنجاح'),
            backgroundColor: HoorColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: HoorColors.error,
          ),
        );
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Barcode Scanner Sheet
/// ═══════════════════════════════════════════════════════════════════════════
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
        color: HoorColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HoorRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: HoorColors.border,
              borderRadius: BorderRadius.circular(HoorRadius.full),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: HoorColors.primary),
                SizedBox(width: HoorSpacing.sm.w),
                Text('مسح الباركود', style: HoorTypography.titleMedium),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HoorRadius.lg),
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

          // Instructions
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Text(
              'وجّه الكاميرا نحو الباركود',
              style: HoorTypography.bodySmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
