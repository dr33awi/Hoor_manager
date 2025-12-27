import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../shared/services/print_service.dart';
import '../../data/models/cart_item.dart';

/// صفحة المرتجعات
class ReturnsPage extends ConsumerStatefulWidget {
  final String type; // 'sale' or 'purchase'

  const ReturnsPage({super.key, this.type = 'sale'});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  final _currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');

  List<CartItem> _cartItems = [];
  int? _selectedPartyId;
  String? _selectedPartyName;
  int? _originalInvoiceId;
  String? _originalInvoiceNumber;
  double _discountPercent = 0;
  double _taxPercent = 15;
  bool _isSaving = false;

  bool get _isSaleReturn => widget.type == 'sale';

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.lineTotal);
  double get _totalDiscount => _subtotal * _discountPercent / 100;
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
        title: Text(_isSaleReturn ? 'مرتجع مبيعات' : 'مرتجع مشتريات'),
        actions: [
          IconButton(
            icon: Icon(_isSaleReturn ? Icons.person : Icons.local_shipping),
            onPressed: _selectParty,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _selectOriginalInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cartItems.isEmpty ? null : _clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          // الفاتورة الأصلية
          if (_originalInvoiceNumber != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              color: AppColors.info.withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 20, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text('مرتجع من فاتورة: $_originalInvoiceNumber',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _originalInvoiceId = null;
                      _originalInvoiceNumber = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // الطرف المحدد (عميل/مورد)
          if (_selectedPartyName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              color: (_isSaleReturn ? AppColors.error : AppColors.warning)
                  .withValues(alpha: 0.2),
              child: Row(
                children: [
                  Icon(_isSaleReturn ? Icons.person : Icons.local_shipping,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(_selectedPartyName!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _selectedPartyId = null;
                      _selectedPartyName = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // حقل الباركود
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
              ],
            ),
          ),

          const Divider(height: 1),

          // قائمة المنتجات المرتجعة
          Expanded(
            child: _cartItems.isEmpty
                ? EmptyState(
                    icon: Icons.undo,
                    title: 'لا توجد منتجات مرتجعة',
                    subtitle: _isSaleReturn
                        ? 'امسح باركود المنتج المراد إرجاعه من العميل'
                        : 'امسح باركود المنتج المراد إرجاعه للمورد',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingSM),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _ReturnItemCard(
                        item: item,
                        onQuantityChanged: (qty) => _updateQuantity(index, qty),
                        onRemove: () => _removeItem(index),
                      );
                    },
                  ),
          ),

          // ملخص المرتجع
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
                  _SummaryRow(label: 'الضريبة', value: _taxAmount),
                  const Divider(),
                  _SummaryRow(
                      label: 'إجمالي المرتجع', value: _total, isTotal: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingMD, 0,
                  AppSizes.paddingMD, AppSizes.paddingMD),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _cartItems.isEmpty || _isSaving ? null : _saveReturn,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving
                      ? 'جاري الحفظ...'
                      : 'حفظ المرتجع (${_currencyFormat.format(_total)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSaleReturn ? AppColors.error : AppColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
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
      _addProductToReturn(
        productId: product.id,
        name: product.name,
        barcode: product.barcode,
        price: _isSaleReturn ? product.salePrice : product.costPrice,
        costPrice: product.costPrice,
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
                            subtitle: Text(_currencyFormat.format(_isSaleReturn
                                ? product.salePrice
                                : product.costPrice)),
                            onTap: () {
                              _addProductToReturn(
                                productId: product.id,
                                name: product.name,
                                barcode: product.barcode,
                                price: _isSaleReturn
                                    ? product.salePrice
                                    : product.costPrice,
                                costPrice: product.costPrice,
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

  void _addProductToReturn({
    required int productId,
    required String name,
    String? barcode,
    required double price,
    required double costPrice,
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
          availableQty: 999999,
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

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  Future<void> _clearCart() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'مسح القائمة',
      message: 'هل تريد مسح جميع المنتجات؟',
      confirmText: 'مسح',
      confirmColor: AppColors.error,
    );
    if (confirm == true) {
      setState(() => _cartItems.clear());
    }
  }

  void _selectParty() {
    final partyAsync = _isSaleReturn
        ? ref.watch(allCustomersProvider)
        : ref.watch(allSuppliersProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              Text(
                _isSaleReturn ? 'اختر العميل' : 'اختر المورد',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: partyAsync.when(
                  data: (parties) {
                    if (parties.isEmpty) {
                      return Center(
                        child: Text(
                          _isSaleReturn ? 'لا يوجد عملاء' : 'لا يوجد موردين',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: parties.length,
                      itemBuilder: (context, index) {
                        final party = parties[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (_isSaleReturn
                                    ? AppColors.primary
                                    : AppColors.warning)
                                .withValues(alpha: 0.1),
                            child: Text(
                              party.name.isNotEmpty ? party.name[0] : '?',
                              style: TextStyle(
                                  color: _isSaleReturn
                                      ? AppColors.primary
                                      : AppColors.warning),
                            ),
                          ),
                          title: Text(party.name),
                          subtitle:
                              party.phone != null ? Text(party.phone!) : null,
                          onTap: () {
                            setState(() {
                              _selectedPartyId = party.id;
                              _selectedPartyName = party.name;
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectOriginalInvoice() {
    final invoicesAsync = _isSaleReturn
        ? ref.watch(salesInvoicesProvider)
        : ref.watch(purchaseInvoicesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              const Text('اختر الفاتورة الأصلية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: invoicesAsync.when(
                  data: (invoices) {
                    if (invoices.isEmpty) {
                      return const Center(
                          child: Text('لا توجد فواتير',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.info.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt,
                                color: AppColors.info),
                          ),
                          title: Text('فاتورة #${invoice.number}'),
                          subtitle: Text(_currencyFormat.format(invoice.total)),
                          onTap: () {
                            setState(() {
                              _originalInvoiceId = invoice.id;
                              _originalInvoiceNumber = invoice.number;
                              _selectedPartyId = invoice.partyId;
                            });
                            Navigator.pop(context);
                            // TODO: جلب بنود الفاتورة الأصلية
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('خطأ: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveReturn() async {
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

      await invoiceRepo.createInvoice(
        type: _isSaleReturn ? 'RETURN_SALE' : 'RETURN_PURCHASE',
        partyId: _selectedPartyId,
        items: items,
        discountPercent: _discountPercent,
        taxPercent: _taxPercent,
        paidAmount: _total,
        paymentMethod: 'CASH',
        cashAccountId: 1,
      );

      if (_isSaleReturn) {
        ref.invalidate(salesReturnsProvider);
      } else {
        ref.invalidate(purchaseReturnsProvider);
      }
      ref.invalidate(allProductsProvider);

      if (mounted) {
        final printChoice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم حفظ المرتجع بنجاح'),
            content: const Text('هل تريد طباعة المرتجع؟'),
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
            invoiceType: _isSaleReturn ? 'RETURN_SALE' : 'RETURN_PURCHASE',
            date: DateTime.now(),
            partyName: _selectedPartyName,
            items: printableItems,
            subtotal: _subtotal,
            discountAmount: _totalDiscount,
            taxAmount: _taxAmount,
            total: _total,
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في حفظ المرتجع: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ReturnItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const _ReturnItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.error.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.undo, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '${item.unitPrice} × ${item.quantity.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text('${item.lineTotal.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error)),
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
                color: valueColor ?? (isTotal ? AppColors.error : null),
              )),
        ],
      ),
    );
  }
}
