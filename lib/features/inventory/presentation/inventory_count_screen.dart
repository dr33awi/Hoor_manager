import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/inventory_repository.dart';

class InventoryCountScreen extends ConsumerStatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  ConsumerState<InventoryCountScreen> createState() =>
      _InventoryCountScreenState();
}

class _InventoryCountScreenState extends ConsumerState<InventoryCountScreen> {
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
      appBar: AppBar(
        title: const Text('جرد المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
          if (_countedQuantities.isNotEmpty)
            TextButton.icon(
              onPressed: _saveCount,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                'حفظ (${_countedQuantities.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Banner
                Container(
                  padding: EdgeInsets.all(12.w),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.primary, size: 20.sp),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          'أدخل الكمية الفعلية للمنتجات التي تم جردها',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الباركود...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),

                // Stats Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'إجمالي',
                        value: '${_products.length}',
                        color: AppColors.primary,
                      ),
                      Gap(8.w),
                      _StatChip(
                        label: 'تم جرده',
                        value: '${_countedQuantities.length}',
                        color: AppColors.success,
                      ),
                      Gap(8.w),
                      _StatChip(
                        label: 'متبقي',
                        value:
                            '${_products.length - _countedQuantities.length}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
                Gap(8.h),

                // Products List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final counted = _countedQuantities[product.id];
                      final difference =
                          counted != null ? counted - product.quantity : null;

                      return Card(
                        margin: EdgeInsets.only(bottom: 8.h),
                        color: counted != null
                            ? (difference! > 0
                                ? AppColors.success.withOpacity(0.05)
                                : difference < 0
                                    ? AppColors.error.withOpacity(0.05)
                                    : AppColors.primary.withOpacity(0.05))
                            : null,
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (product.barcode != null)
                                          Text(
                                            product.barcode!,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (counted != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 16.sp),
                                    ),
                                ],
                              ),
                              Gap(12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'الكمية بالنظام',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${product.quantity}',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Gap(12.w),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'الكمية الفعلية',
                                        hintText: '${product.quantity}',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 8.h,
                                        ),
                                      ),
                                      controller: TextEditingController(
                                        text: counted?.toString() ?? '',
                                      ),
                                      onChanged: (value) {
                                        final qty = int.tryParse(value);
                                        setState(() {
                                          if (qty != null) {
                                            _countedQuantities[product.id] =
                                                qty;
                                          } else {
                                            _countedQuantities
                                                .remove(product.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (difference != null && difference != 0) ...[
                                Gap(8.h),
                                Text(
                                  'الفرق: ${difference > 0 ? '+' : ''}$difference',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: difference > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _countedQuantities.isNotEmpty
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _saveCount,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text('حفظ الجرد (${_countedQuantities.length} منتج)'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => _BarcodeScannerDialog(),
    );

    if (barcode != null && barcode.isNotEmpty) {
      setState(() => _searchQuery = barcode);
      _searchController.text = barcode;

      // Find product by barcode
      final product = _products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => _products.first,
      );

      // Show quantity input dialog
      _showQuantityDialog(product);
    }
  }

  void _showQuantityDialog(Product product) {
    final controller = TextEditingController(
      text: _countedQuantities[product.id]?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الكمية بالنظام: ${product.quantity}'),
            Gap(16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'الكمية الفعلية',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null) {
                setState(() => _countedQuantities[product.id] = qty);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ الجرد'),
        content: Text(
          'سيتم تعديل كمية ${_countedQuantities.length} منتج.\n\nهل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final entry in _countedQuantities.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);

        if (entry.value != product.quantity) {
          await _inventoryRepo.adjustStock(
            productId: entry.key,
            actualQuantity: entry.value,
            reason:
                'جرد ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الجرد بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Gap(4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeScannerDialog extends StatefulWidget {
  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مسح الباركود'),
      content: SizedBox(
        width: 300.w,
        height: 300.h,
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_scanned) return;
            final barcode = capture.barcodes.firstOrNull?.rawValue;
            if (barcode != null) {
              _scanned = true;
              Navigator.pop(context, barcode);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
