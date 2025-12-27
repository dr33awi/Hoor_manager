import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../shared/services/print_service.dart';
import '../../data/models/cart_item.dart';

/// صفحة فاتورة المشتريات
class PurchaseInvoicePage extends ConsumerStatefulWidget {
  final String? invoiceId;

  const PurchaseInvoicePage({super.key, this.invoiceId});

  @override
  ConsumerState<PurchaseInvoicePage> createState() =>
      _PurchaseInvoicePageState();
}

class _PurchaseInvoicePageState extends ConsumerState<PurchaseInvoicePage> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  final _currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');

  List<CartItem> _cartItems = [];
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  double _discountPercent = 0;
  double _discountAmount = 0;
  double _taxPercent = 15;
  String _paymentMethod = 'CASH';
  double _paidAmount = 0;
  bool _isSaving = false;

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.lineTotal);
  double get _totalDiscount =>
      _discountAmount + (_subtotal * _discountPercent / 100);
  double get _taxableAmount => _subtotal - _totalDiscount;
  double get _taxAmount => _taxableAmount * _taxPercent / 100;
  double get _total => _taxableAmount + _taxAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة مشتريات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping),
            onPressed: _selectSupplier,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cartItems.isEmpty ? null : _clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          // المورد المحدد
          if (_selectedSupplierName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              color: AppColors.warning.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, size: 20),
                  const SizedBox(width: 8),
                  Text(_selectedSupplierName!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _selectedSupplierId = null;
                      _selectedSupplierName = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // حقل الباركود والبحث
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSM),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    decoration: InputDecoration(
                      hintText: 'امسح الباركود أو ابحث...',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _showProductSearch,
                      ),
                    ),
                    onSubmitted: _onBarcodeScanned,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () =>
                      showSnackBar(context, 'سيتم فتح الكاميرا للمسح'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // قائمة المنتجات
          Expanded(
            child: _cartItems.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'السلة فارغة',
                    subtitle: 'امسح الباركود أو ابحث عن منتج لإضافته',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingSM),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onQuantityChanged: (qty) => _updateQuantity(index, qty),
                        onPriceChanged: (price) => _updatePrice(index, price),
                        onRemove: () => _removeItem(index),
                      );
                    },
                  ),
          ),

          // ملخص الفاتورة
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                children: [
                  _SummaryRow(label: 'المجموع الفرعي', value: _subtotal),
                  if (_totalDiscount > 0)
                    _SummaryRow(
                        label: 'الخصم',
                        value: -_totalDiscount,
                        valueColor: AppColors.error),
                  _SummaryRow(
                      label: 'الضريبة (${_taxPercent.toStringAsFixed(0)}%)',
                      value: _taxAmount),
                  const Divider(),
                  _SummaryRow(label: 'الإجمالي', value: _total, isTotal: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingMD, 0,
                  AppSizes.paddingMD, AppSizes.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _cartItems.isEmpty ? null : _showDiscountDialog,
                      icon: const Icon(Icons.discount),
                      label: const Text('خصم'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed:
                          _cartItems.isEmpty || _isSaving ? null : _checkout,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isSaving
                          ? 'جاري الحفظ...'
                          : 'حفظ (${_currencyFormat.format(_total)})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeScanned(String barcode) async {
    if (barcode.isEmpty) return;

    final product = await ref.read(productByBarcodeProvider(barcode).future);
    if (product != null) {
      _addProductToCart(
        productId: product.id,
        name: product.name,
        barcode: product.barcode,
        price: product.costPrice, // سعر التكلفة للمشتريات
        costPrice: product.costPrice,
        availableQty: 999999, // المشتريات لا حد لها
      );
    } else {
      if (mounted) {
        showSnackBar(context, 'المنتج غير موجود', isError: true);
      }
    }
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  void _showProductSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: CustomSearchField(
                  controller: _searchController,
                  hintText: 'ابحث عن منتج...',
                  autofocus: true,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final query = _searchController.text;
                    final productsAsync = query.isEmpty
                        ? ref.watch(allProductsProvider)
                        : ref.watch(productSearchProvider(query));

                    return productsAsync.when(
                      data: (products) => ListView.builder(
                        controller: scrollController,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined),
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                                'سعر التكلفة: ${_currencyFormat.format(product.costPrice)}'),
                            onTap: () {
                              _addProductToCart(
                                productId: product.id,
                                name: product.name,
                                barcode: product.barcode,
                                price: product.costPrice,
                                costPrice: product.costPrice,
                                availableQty: 999999,
                              );
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('خطأ: $e')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProductToCart({
    required int productId,
    required String name,
    String? barcode,
    required double price,
    required double costPrice,
    required double availableQty,
  }) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.productId == productId);

    if (existingIndex != -1) {
      final item = _cartItems[existingIndex];
      setState(() {
        _cartItems[existingIndex] = item.copyWith(quantity: item.quantity + 1);
      });
    } else {
      setState(() {
        _cartItems.add(CartItem(
          productId: productId,
          name: name,
          barcode: barcode,
          unitPrice: price,
          costPrice: costPrice,
          quantity: 1,
          availableQty: availableQty,
        ));
      });
    }
  }

  void _updateQuantity(int index, double qty) {
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      _cartItems[index] = _cartItems[index].copyWith(quantity: qty);
    });
  }

  void _updatePrice(int index, double price) {
    setState(() {
      _cartItems[index] = _cartItems[index].copyWith(unitPrice: price);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  Future<void> _clearCart() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'مسح السلة',
      message: 'هل تريد مسح جميع المنتجات؟',
      confirmText: 'مسح',
      confirmColor: AppColors.error,
    );
    if (confirm == true) {
      setState(() => _cartItems.clear());
    }
  }

  void _selectSupplier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              const Text('اختر المورد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final suppliersAsync = ref.watch(allSuppliersProvider);
                    return suppliersAsync.when(
                      data: (suppliers) {
                        if (suppliers.isEmpty) {
                          return const Center(
                            child: Text('لا يوجد موردين',
                                style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: suppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = suppliers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.warning.withValues(alpha: 0.1),
                                child: Text(
                                  supplier.name.isNotEmpty
                                      ? supplier.name[0]
                                      : '?',
                                  style:
                                      const TextStyle(color: AppColors.warning),
                                ),
                              ),
                              title: Text(supplier.name),
                              subtitle: supplier.phone != null
                                  ? Text(supplier.phone!)
                                  : null,
                              trailing: supplier.balance != 0
                                  ? Text(
                                      _currencyFormat.format(supplier.balance),
                                      style: TextStyle(
                                        color: supplier.balance > 0
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedSupplierId = supplier.id;
                                  _selectedSupplierName = supplier.name;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('خطأ: $e')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscountDialog() {
    final controller = TextEditingController(
        text: _discountPercent > 0 ? _discountPercent.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة خصم'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'نسبة الخصم %'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _discountPercent = double.tryParse(controller.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _checkout() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);

      final items = _cartItems
          .map((item) => InvoiceItemData(
                productId: item.productId,
                qty: item.quantity,
                unitPrice: item.unitPrice,
                costPrice: item.costPrice,
                lineTotal: item.lineTotal,
              ))
          .toList();

      final paidAmount = _paymentMethod == 'CASH' ? _total : _paidAmount;

      await invoiceRepo.createInvoice(
        type: 'PURCHASE',
        partyId: _selectedSupplierId,
        items: items,
        discountAmount: _discountAmount,
        discountPercent: _discountPercent,
        taxPercent: _taxPercent,
        paidAmount: paidAmount,
        paymentMethod: _paymentMethod,
        cashAccountId: 1,
      );

      ref.invalidate(purchaseInvoicesProvider);
      ref.invalidate(allProductsProvider);

      if (mounted) {
        final printChoice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم حفظ الفاتورة بنجاح'),
            content: const Text('هل تريد طباعة الفاتورة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'none'),
                child: const Text('لا'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'print'),
                child: const Text('طباعة'),
              ),
            ],
          ),
        );

        if (printChoice == 'print' && mounted) {
          final printableItems = _cartItems
              .map((item) => PrintableInvoiceItem(
                    name: item.name,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    lineTotal: item.lineTotal,
                  ))
              .toList();

          final invoiceNumber =
              DateTime.now().millisecondsSinceEpoch.toString().substring(5);

          await PrintService.previewInvoice(
            context: context,
            invoiceNumber: invoiceNumber,
            invoiceType: 'PURCHASE',
            date: DateTime.now(),
            partyName: _selectedSupplierName,
            items: printableItems,
            subtotal: _subtotal,
            discountAmount: _totalDiscount,
            taxAmount: _taxAmount,
            total: _total,
            paidAmount: _paymentMethod == 'CASH' ? _total : _paidAmount,
            paymentMethod: _paymentMethod,
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في حفظ الفاتورة: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (item.barcode != null)
                        Text(item.barcode!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // تعديل الكمية
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () => onQuantityChanged(item.quantity - 1),
                      ),
                      Text('${item.quantity.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => onQuantityChanged(item.quantity + 1),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // تعديل السعر
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    controller: TextEditingController(
                        text: item.unitPrice.toStringAsFixed(2)),
                    onSubmitted: (value) {
                      final price = double.tryParse(value);
                      if (price != null) onPriceChanged(price);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('${item.lineTotal.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isTotal = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              )),
          Text('${value.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? (isTotal ? AppColors.primary : null),
              )),
        ],
      ),
    );
  }
}
