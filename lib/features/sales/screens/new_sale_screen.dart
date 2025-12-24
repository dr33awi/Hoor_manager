// lib/features/sales/screens/new_sale_screen.dart
// شاشة إنشاء فاتورة جديدة - مع دعم الباركود

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product_model.dart';
import '../../products/widgets/barcode_scanner_widget.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';
import '../widgets/invoice_print_dialog.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _barcodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');

    return Consumer2<SaleProvider, ProductProvider>(
      builder: (context, saleProvider, productProvider, _) {
        return Column(
          children: [
            _buildBarcodeSearchBar(productProvider, saleProvider),
            Expanded(
              child: saleProvider.isCartEmpty
                  ? _buildEmpty()
                  : _buildCart(saleProvider, formatter),
            ),
            _buildBottom(saleProvider, productProvider, formatter),
          ],
        );
      },
    );
  }

  Widget _buildBarcodeSearchBar(ProductProvider productProvider, SaleProvider saleProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _barcodeController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'امسح أو أدخل الباركود...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.qr_code, color: Colors.grey.shade400),
                  suffixIcon: _barcodeController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                          onPressed: () {
                            _barcodeController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: (value) => _searchByBarcode(value, productProvider, saleProvider),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openBarcodeScanner(productProvider, saleProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProductsList(productProvider, saleProvider),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.qr_code_scanner, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'امسح الباركود لإضافة منتج',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'أو استخدم البحث اليدوي',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickAction(
                icon: Icons.qr_code_scanner,
                label: 'مسح',
                color: AppColors.info,
                onTap: () => _openBarcodeScanner(
                  context.read<ProductProvider>(),
                  context.read<SaleProvider>(),
                ),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(
                icon: Icons.search,
                label: 'بحث',
                color: AppColors.primary,
                onTap: () => _showProductsList(
                  context.read<ProductProvider>(),
                  context.read<SaleProvider>(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(SaleProvider saleProvider, NumberFormat formatter) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: saleProvider.cartItems.length,
      itemBuilder: (_, i) {
        final item = saleProvider.cartItems[i];
        return Dismissible(
          key: Key('${item.productId}-${item.color}-${item.size}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => saleProvider.removeFromCart(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.color, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('مقاس ${item.size}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatter.format(item.unitPrice)} ر.س',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatter.format(item.totalPrice)} ر.س',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(Icons.remove, () {
                            if (item.quantity > 1) {
                              saleProvider.updateCartItemQuantity(i, item.quantity - 1);
                            } else {
                              saleProvider.removeFromCart(i);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          _qtyBtn(Icons.add, () => saleProvider.updateCartItemQuantity(i, item.quantity + 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _buildBottom(SaleProvider saleProvider, ProductProvider productProvider, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!saleProvider.isCartEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('عدد المنتجات', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        Text('${saleProvider.cartItemsCount} قطعة', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('المجموع', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        Text('${formatter.format(saleProvider.subtotal)} ر.س'),
                      ],
                    ),
                    if (saleProvider.discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الخصم', style: TextStyle(color: AppColors.error, fontSize: 13)),
                          Text('- ${formatter.format(saleProvider.discount)} ر.س', style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ],
                    Divider(height: 20, color: Colors.grey.shade300),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                          '${formatter.format(saleProvider.total)} ر.س',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'خصم %',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: Icon(Icons.discount_outlined, size: 20, color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (v) {
                          final discount = double.tryParse(v) ?? 0;
                          saleProvider.setDiscountPercent(discount);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => saleProvider.clearCart(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: saleProvider.isCartEmpty ? null : () => _completeSale(saleProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      saleProvider.isCartEmpty
                          ? 'السلة فارغة'
                          : 'إتمام البيع - ${formatter.format(saleProvider.total)} ر.س',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchByBarcode(String barcode, ProductProvider productProvider, SaleProvider saleProvider) {
    if (barcode.isEmpty) return;

    for (final product in productProvider.allProducts) {
      if (product.barcode == barcode) {
        _showVariantSelector(product, saleProvider);
        _barcodeController.clear();
        return;
      }

      final variant = product.findVariantByBarcode(barcode);
      if (variant != null) {
        _addToCart(product, variant.color, variant.size, saleProvider);
        _barcodeController.clear();
        return;
      }
    }

    _showSnackBar('لم يتم العثور على منتج بهذا الباركود', isError: true);
    _barcodeController.clear();
  }

  void _openBarcodeScanner(ProductProvider productProvider, SaleProvider saleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerWidget(
        onBarcodeScanned: (barcode) {
          Navigator.pop(context);
          _searchByBarcode(barcode, productProvider, saleProvider);
        },
      ),
    );
  }

  void _showProductsList(ProductProvider productProvider, SaleProvider saleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => _ProductSelector(
          productProvider: productProvider,
          saleProvider: saleProvider,
          scrollController: ctrl,
        ),
      ),
    );
  }

  void _showVariantSelector(ProductModel product, SaleProvider saleProvider) {
    String? selectedColor;
    int? selectedSize;
    int qty = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final availableQty = selectedColor != null && selectedSize != null
              ? product.getQuantity(selectedColor!, selectedSize!)
              : 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${product.price.toStringAsFixed(0)} ر.س', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اللون:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: selectedColor == c,
                      onSelected: (s) => setState(() { selectedColor = s ? c : null; qty = 1; }),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('المقاس:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((s) {
                      final q = selectedColor != null ? product.getQuantity(selectedColor!, s) : 0;
                      return ChoiceChip(
                        label: Text('$s${q == 0 ? ' (نفذ)' : ''}'),
                        selected: selectedSize == s,
                        onSelected: q > 0 ? (sel) => setState(() { selectedSize = sel ? s : null; qty = 1; }) : null,
                      );
                    }).toList(),
                  ),
                  if (selectedColor != null && selectedSize != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الكمية:'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: qty > 1 ? () => setState(() => qty--) : null,
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: qty < availableQty ? () => setState(() => qty++) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('متوفر: $availableQty قطعة', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: selectedColor != null && selectedSize != null && qty > 0
                    ? () { _addToCart(product, selectedColor!, selectedSize!, saleProvider, qty: qty); Navigator.pop(ctx); }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart(ProductModel product, String color, int size, SaleProvider saleProvider, {int qty = 1}) {
    final result = saleProvider.addToCart(
      SaleItem(
        productId: product.id,
        productName: product.name,
        color: color,
        size: size,
        quantity: qty,
        unitPrice: product.price,
        costPrice: product.costPrice,
        barcode: product.getVariantBarcode(color, size),
      ),
      availableQuantity: product.getQuantity(color, size),
    );

    if (result.success) {
      _showSnackBar('تمت إضافة ${product.name}');
      _focusNode.requestFocus();
    } else {
      _showSnackBar(result.error ?? 'خطأ', isError: true);
    }
  }

  Future<void> _completeSale(SaleProvider saleProvider) async {
    if (_notesController.text.isNotEmpty) {
      saleProvider.setNotes(_notesController.text);
    }

    final sale = await saleProvider.createSale();

    if (sale != null) {
      _discountController.clear();
      _notesController.clear();
      _showSuccessDialog(sale);
    } else {
      _showSnackBar(saleProvider.error ?? 'حدث خطأ', isError: true);
    }
  }

  void _showSuccessDialog(SaleModel sale) {
    final formatter = NumberFormat('#,##0.00', 'ar');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('تم البيع بنجاح!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رقم الفاتورة:', style: TextStyle(color: Colors.grey.shade600)),
                        Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('عدد المنتجات:', style: TextStyle(color: Colors.grey.shade600)),
                        Text('${sale.itemsCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Divider(height: 20, color: Colors.grey.shade300),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي:', style: TextStyle(fontSize: 16)),
                        Text(
                          '${formatter.format(sale.total)} ر.س',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); _showPrintDialog(sale); },
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text('طباعة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('بيع جديد'),
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

  void _showPrintDialog(SaleModel sale) {
    showDialog(context: context, builder: (_) => InvoicePrintDialog(sale: sale));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ProductSelector extends StatefulWidget {
  final ProductProvider productProvider;
  final SaleProvider saleProvider;
  final ScrollController scrollController;

  const _ProductSelector({
    required this.productProvider,
    required this.saleProvider,
    required this.scrollController,
  });

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final products = widget.productProvider.allProducts
        .where((p) => p.isActive && p.totalQuantity > 0)
        .where((p) => _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase()) || p.barcode.contains(_search))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('اختر المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الباركود...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('لا توجد منتجات', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.totalQuantity} متوفر', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            Text(p.barcode, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'monospace')),
                          ],
                        ),
                        trailing: Text('${p.price.toStringAsFixed(0)} ر.س', style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () { Navigator.pop(context); _showVariantDialog(p); },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showVariantDialog(ProductModel product) {
    String? selectedColor;
    int? selectedSize;
    int qty = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final availableQty = selectedColor != null && selectedSize != null
              ? product.getQuantity(selectedColor!, selectedSize!)
              : 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اللون:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: selectedColor == c,
                      onSelected: (s) => setState(() { selectedColor = s ? c : null; qty = 1; }),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('المقاس:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((s) {
                      final q = selectedColor != null ? product.getQuantity(selectedColor!, s) : 0;
                      return ChoiceChip(
                        label: Text('$s${q == 0 ? ' (نفذ)' : ''}'),
                        selected: selectedSize == s,
                        onSelected: q > 0 ? (sel) => setState(() { selectedSize = sel ? s : null; qty = 1; }) : null,
                      );
                    }).toList(),
                  ),
                  if (selectedColor != null && selectedSize != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('الكمية:'),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: qty > 1 ? () => setState(() => qty--) : null),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: qty < availableQty ? () => setState(() => qty++) : null),
                      ],
                    ),
                    Text('متوفر: $availableQty', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: selectedColor != null && selectedSize != null && qty > 0
                    ? () {
                        widget.saleProvider.addToCart(SaleItem(
                          productId: product.id,
                          productName: product.name,
                          color: selectedColor!,
                          size: selectedSize!,
                          quantity: qty,
                          unitPrice: product.price,
                          costPrice: product.costPrice,
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تمت الإضافة'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }
}
