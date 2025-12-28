import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/cash_repository.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String type;

  const InvoiceFormScreen({super.key, required this.type});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _productRepo = getIt<ProductRepository>();
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _shiftRepo = getIt<ShiftRepository>();
  final _cashRepo = getIt<CashRepository>();

  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  final Map<String, int> _productStock = {}; // لتخزين كميات المخزون
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  Shift? _currentShift;

  @override
  void initState() {
    super.initState();
    _loadCurrentShift();
  }

  Future<void> _loadCurrentShift() async {
    final shift = await _shiftRepo.getOpenShift();
    setState(() => _currentShift = shift);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _typeTitle {
    switch (widget.type) {
      case 'sale':
        return 'فاتورة مبيعات جديدة';
      case 'purchase':
        return 'فاتورة مشتريات جديدة';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      case 'opening_balance':
        return 'فاتورة أول المدة';
      default:
        return 'فاتورة جديدة';
    }
  }

  double get _subtotal => _items.fold(
      0,
      (sum, item) =>
          sum + (item['quantity'] as int) * (item['unitPrice'] as double));

  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _total => _subtotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_typeTitle),
        actions: [
          if (_currentShift == null && widget.type != 'opening_balance')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Chip(
                label: const Text('لا توجد وردية'),
                backgroundColor: AppColors.warning.withOpacity(0.2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Add Product
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث عن منتج...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _scanBarcode,
                      ),
                    ),
                    onSubmitted: _searchProduct,
                  ),
                ),
                Gap(8.w),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                  iconSize: 40.sp,
                  onPressed: () => _showProductsDialog(),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          'أضف منتجات إلى الفاتورة',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSale = widget.type == 'sale' ||
                          widget.type == 'purchase_return';
                      return _InvoiceItemCard(
                        item: item,
                        isPurchase: widget.type == 'purchase' ||
                            widget.type == 'opening_balance',
                        isSale: isSale,
                        onQuantityChanged: (qty) {
                          if (isSale) {
                            final availableStock =
                                item['availableStock'] as int? ??
                                    _productStock[item['productId']] ??
                                    999;
                            if (qty > availableStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'الكمية المطلوبة ($qty) أكبر من المتاح ($availableStock)'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }
                          }
                          setState(() => item['quantity'] = qty);
                        },
                        onPriceChanged: (price) {
                          setState(() => item['unitPrice'] = price);
                        },
                        onRemove: () {
                          setState(() => _items.removeAt(index));
                        },
                      );
                    },
                  ),
          ),

          // Summary & Submit
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Discount
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الخصم',
                          prefixIcon: Icon(Icons.discount),
                          suffixText: 'ل.س',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Gap(16.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'طريقة الدفع',
                          prefixIcon: Icon(Icons.payment),
                          isDense: true,
                        ),
                        items: PaymentMethod.values
                            .map((p) => DropdownMenuItem(
                                  value: p.value,
                                  child: Text(p.label),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value!),
                      ),
                    ),
                  ],
                ),
                Gap(12.h),

                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع:', style: TextStyle(fontSize: 14.sp)),
                    Text('${_subtotal.toStringAsFixed(2)} ل.س'),
                  ],
                ),
                if (_discount > 0) ...[
                  Gap(4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الخصم:',
                          style: TextStyle(
                              fontSize: 14.sp, color: AppColors.error)),
                      Text('-${_discount.toStringAsFixed(2)} ل.س',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ],
                Gap(8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي:',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_total.toStringAsFixed(2)} ل.س',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Gap(12.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed:
                        _items.isEmpty || _isLoading ? null : _submitInvoice,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'حفظ الفاتورة',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => _BarcodeScannerDialog(),
    );

    if (barcode != null) {
      final product = await _productRepo.getProductByBarcode(barcode);
      if (product != null) {
        _addProduct(product);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المنتج غير موجود')),
          );
        }
      }
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;

    // Try barcode first
    var product = await _productRepo.getProductByBarcode(query);

    if (product == null) {
      // Show search results
      await _showProductsDialog(searchQuery: query);
    } else {
      _addProduct(product);
    }

    _searchController.clear();
  }

  Future<void> _showProductsDialog({String? searchQuery}) async {
    final products = await _productRepo.getAllProducts();
    var filtered = products.where((p) => p.isActive).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (p.sku?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    if (!mounted) return;

    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر منتج'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${product.salePrice.toStringAsFixed(2)} ل.س'),
                trailing: Text('الكمية: ${product.quantity}'),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _addProduct(selected);
    }
  }

  void _addProduct(Product product) {
    // For sales, check stock availability
    final isSale = widget.type == 'sale' || widget.type == 'purchase_return';

    if (isSale && product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المنتج "${product.name}" غير متوفر في المخزون'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if already in list
    final existingIndex =
        _items.indexWhere((i) => i['productId'] == product.id);

    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex]['quantity'] as int;
      final availableStock = _productStock[product.id] ?? product.quantity;

      if (isSale && currentQty >= availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('لا يمكن إضافة المزيد. الكمية المتاحة: $availableStock'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      setState(() {
        _items[existingIndex]['quantity']++;
      });
    } else {
      // Store the original stock for this product
      _productStock[product.id] = product.quantity;

      final isPurchase =
          widget.type == 'purchase' || widget.type == 'opening_balance';
      setState(() {
        _items.add({
          'productId': product.id,
          'productName': product.name,
          'quantity': 1,
          'unitPrice': isPurchase ? product.purchasePrice : product.salePrice,
          'purchasePrice': product.purchasePrice,
          'availableStock': product.quantity, // تخزين الكمية المتاحة
        });
      });
    }
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty) return;

    // Check for open shift (except for opening balance)
    if (widget.type != 'opening_balance' && _currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب فتح وردية أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoiceId = await _invoiceRepo.createInvoice(
        type: widget.type,
        items: _items,
        discountAmount: _discount,
        paymentMethod: _paymentMethod,
        paidAmount: _total,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        shiftId: _currentShift?.id,
      );

      // Record cash movement if there's an open shift
      if (_currentShift != null) {
        if (widget.type == 'sale') {
          await _cashRepo.recordSale(
            shiftId: _currentShift!.id,
            amount: _total,
            invoiceId: invoiceId,
            paymentMethod: _paymentMethod,
          );
        } else if (widget.type == 'purchase') {
          await _cashRepo.recordPurchase(
            shiftId: _currentShift!.id,
            amount: _total,
            invoiceId: invoiceId,
            paymentMethod: _paymentMethod,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الفاتورة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _InvoiceItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isPurchase;
  final bool isSale;
  final Function(int) onQuantityChanged;
  final Function(double) onPriceChanged;
  final VoidCallback onRemove;

  const _InvoiceItemCard({
    required this.item,
    required this.isPurchase,
    this.isSale = false,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity'] as int;
    final unitPrice = item['unitPrice'] as double;
    final total = quantity * unitPrice;
    final availableStock = item['availableStock'] as int? ?? 999;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['productName'] as String,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSale) ...[
                        Gap(2.h),
                        Text(
                          'المتاح: $availableStock',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: quantity >= availableStock
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: onRemove,
                ),
              ],
            ),
            Gap(8.h),
            Row(
              children: [
                // Quantity
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => onQuantityChanged(quantity + 1),
                    ),
                  ],
                ),
                const Spacer(),
                // Price
                SizedBox(
                  width: 100.w,
                  child: TextField(
                    controller: TextEditingController(
                        text: unitPrice.toStringAsFixed(2)),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      isDense: true,
                      suffixText: 'ل.س',
                    ),
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null) onPriceChanged(price);
                    },
                  ),
                ),
                Gap(16.w),
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} ل.س',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
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
  final MobileScannerController _controller = MobileScannerController();
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
