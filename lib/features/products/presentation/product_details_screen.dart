import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/inventory_repository.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final _productRepo = getIt<ProductRepository>();
  final _inventoryRepo = getIt<InventoryRepository>();

  Product? _product;
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final product = await _productRepo.getProductById(widget.productId);
    final movements =
        await _inventoryRepo.getProductMovements(widget.productId);

    setState(() {
      _product = product;
      _movements = movements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: const Center(child: Text('المنتج غير موجود')),
      );
    }

    final product = _product!;
    final isLowStock = product.quantity <= product.minQuantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/products/edit/${product.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'print_barcode':
                  await _printBarcode(product);
                  break;
                case 'delete':
                  await _deleteProduct(product);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print_barcode',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('طباعة الباركود'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('حذف', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Product Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            size: 40.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        Gap(16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product.sku != null) ...[
                                Gap(4.h),
                                Text(
                                  'SKU: ${product.sku}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Barcode
                    if (product.barcode != null) ...[
                      Gap(16.h),
                      Center(
                        child: BarcodeWidget(
                          data: product.barcode!,
                          barcode: Barcode.code128(),
                          width: 200.w,
                          height: 60.h,
                        ),
                      ),
                      Gap(4.h),
                      Center(
                        child: Text(
                          product.barcode!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Gap(16.h),

            // Stock Card
            Card(
              color: isLowStock ? AppColors.lowStock.withOpacity(0.1) : null,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(
                      isLowStock ? Icons.warning : Icons.inventory,
                      color:
                          isLowStock ? AppColors.lowStock : AppColors.success,
                      size: 32.sp,
                    ),
                    Gap(16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المخزون الحالي',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${product.quantity}',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? AppColors.lowStock
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showStockAdjustmentDialog(),
                      child: const Text('تعديل'),
                    ),
                  ],
                ),
              ),
            ),
            Gap(16.h),

            // Price Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأسعار',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap(12.h),
                    _InfoRow(
                      label: 'سعر الشراء',
                      value: '${product.purchasePrice.toStringAsFixed(2)} ر.س',
                    ),
                    _InfoRow(
                      label: 'سعر البيع',
                      value: '${product.salePrice.toStringAsFixed(2)} ر.س',
                    ),
                    _InfoRow(
                      label: 'هامش الربح',
                      value:
                          '${(product.salePrice - product.purchasePrice).toStringAsFixed(2)} ر.س',
                    ),
                    if (product.taxRate != null)
                      _InfoRow(
                        label: 'نسبة الضريبة',
                        value:
                            '${(product.taxRate! * 100).toStringAsFixed(0)}%',
                      ),
                  ],
                ),
              ),
            ),
            Gap(16.h),

            // Additional Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات إضافية',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap(12.h),
                    _InfoRow(
                      label: 'الحد الأدنى للمخزون',
                      value: '${product.minQuantity}',
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      _InfoRow(
                        label: 'الوصف',
                        value: product.description!,
                      ),
                  ],
                ),
              ),
            ),
            Gap(16.h),

            // Inventory Movements
            Text(
              'حركة المخزون',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(8.h),
            if (_movements.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Center(
                    child: Text(
                      'لا توجد حركات مخزون',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...(_movements.take(10).map((m) => _MovementCard(movement: m))),
          ],
        ),
      ),
    );
  }

  void _showStockAdjustmentDialog() {
    final quantityController = TextEditingController();
    String adjustmentType = 'add';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل المخزون'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'add', label: Text('إضافة')),
                  ButtonSegment(value: 'withdraw', label: Text('سحب')),
                  ButtonSegment(value: 'adjust', label: Text('جرد')),
                ],
                selected: {adjustmentType},
                onSelectionChanged: (value) {
                  setDialogState(() => adjustmentType = value.first);
                },
              ),
              Gap(16.h),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      adjustmentType == 'adjust' ? 'الكمية الفعلية' : 'الكمية',
                  prefixIcon: const Icon(Icons.numbers),
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
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) return;

                Navigator.pop(context);

                switch (adjustmentType) {
                  case 'add':
                    await _inventoryRepo.addStock(
                      productId: _product!.id,
                      quantity: quantity,
                      reason: 'إضافة يدوية',
                    );
                    break;
                  case 'withdraw':
                    await _inventoryRepo.withdrawStock(
                      productId: _product!.id,
                      quantity: quantity,
                      reason: 'سحب يدوي',
                    );
                    break;
                  case 'adjust':
                    await _inventoryRepo.adjustStock(
                      productId: _product!.id,
                      actualQuantity: quantity,
                      reason: 'جرد يدوي',
                    );
                    break;
                }

                _loadData();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcode(Product product) async {
    if (product.barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد باركود للمنتج')),
      );
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (context) {
          return pw.Column(
            children: [
              pw.Text(product.name, style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.BarcodeWidget(
                data: product.barcode!,
                barcode: pw.Barcode.code128(),
                width: 150,
                height: 50,
              ),
              pw.Text(product.barcode!, style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Text('${product.salePrice.toStringAsFixed(2)} ر.س',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productRepo.deleteProduct(product.id);
      if (mounted) {
        context.pop();
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.newQuantity > movement.previousQuantity;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(
          isPositive ? Icons.add_circle : Icons.remove_circle,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
        title: Text(movement.reason ?? movement.type),
        subtitle: Text(
          '${movement.previousQuantity} → ${movement.newQuantity}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Text(
          '${isPositive ? '+' : '-'}${movement.quantity}',
          style: TextStyle(
            color: isPositive ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
