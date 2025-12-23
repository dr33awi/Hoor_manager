// lib/features/sales/screens/new_sale_screen.dart
// شاشة إنشاء فاتورة جديدة

import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product_model.dart';
import '../models/sale_model.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _searchController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');

    return Consumer2<SaleProvider, ProductProvider>(
      builder: (context, saleProvider, productProvider, _) {
        return Column(
          children: [
            // السلة والإجماليات
            Expanded(
              child: saleProvider.isCartEmpty
                  ? _buildEmptyCart()
                  : _buildCartList(saleProvider, formatter),
            ),

            // شريط الأدوات السفلي
            _buildBottomBar(saleProvider, productProvider, formatter),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: TextStyle(fontSize: 18, color: AppTheme.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة منتجات',
            style: TextStyle(color: AppTheme.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(SaleProvider saleProvider, NumberFormat formatter) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: saleProvider.cartItems.length,
      itemBuilder: (context, index) {
        final item = saleProvider.cartItems[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // معلومات المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.color} - مقاس ${item.size}',
                        style: TextStyle(fontSize: 12, color: AppTheme.grey600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatter.format(item.unitPrice)} ر.س',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),

                // التحكم في الكمية
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (item.quantity > 1) {
                          saleProvider.updateCartItemQuantity(
                            index,
                            item.quantity - 1,
                          );
                        } else {
                          saleProvider.removeFromCart(index);
                        }
                      },
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        saleProvider.updateCartItemQuantity(
                          index,
                          item.quantity + 1,
                        );
                      },
                    ),
                  ],
                ),

                // الإجمالي وزر الحذف
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatter.format(item.totalPrice)} ر.س',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorColor,
                      ),
                      onPressed: () => saleProvider.removeFromCart(index),
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

  Widget _buildBottomBar(
    SaleProvider saleProvider,
    ProductProvider productProvider,
    NumberFormat formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey400.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الإجماليات
            if (!saleProvider.isCartEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الفرعي:'),
                  Text('${formatter.format(saleProvider.subtotal)} ر.س'),
                ],
              ),
              if (saleProvider.discount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الخصم:'),
                    Text(
                      '- ${formatter.format(saleProvider.discount)} ر.س',
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ],
              if (saleProvider.tax > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الضريبة (${(AppConstants.defaultTaxRate * 100).toInt()}%):',
                    ),
                    Text('${formatter.format(saleProvider.tax)} ر.س'),
                  ],
                ),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${formatter.format(saleProvider.total)} ر.س',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // الأزرار
            Row(
              children: [
                // زر إضافة منتج
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddProductDialog(productProvider, saleProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج'),
                  ),
                ),
                const SizedBox(width: 12),

                // زر إتمام البيع
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: saleProvider.isCartEmpty
                        ? null
                        : () => _showCheckoutDialog(saleProvider),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('إتمام البيع'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(
    ProductProvider productProvider,
    SaleProvider saleProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ProductSelector(
          productProvider: productProvider,
          saleProvider: saleProvider,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showCheckoutDialog(SaleProvider saleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CheckoutSheet(
          saleProvider: saleProvider,
          buyerNameController: _buyerNameController,
          buyerPhoneController: _buyerPhoneController,
          notesController: _notesController,
          discountController: _discountController,
        ),
      ),
    );
  }
}

/// قائمة اختيار المنتجات
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final products = widget.productProvider.allProducts
        .where((p) => p.isActive && p.totalQuantity > 0)
        .where(
          (p) =>
              _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.brand.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // العنوان والبحث
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اختر المنتج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث عن منتج...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ],
          ),
        ),

        // قائمة المنتجات
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('لا توجد منتجات متاحة'))
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.grey200,
                        child: const Icon(Icons.inventory_2),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.brand} - ${product.totalQuantity} قطعة متوفرة',
                      ),
                      trailing: Text(
                        '${NumberFormat('#,##0', 'ar').format(product.price)} ر.س',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showProductOptionsDialog(product);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showProductOptionsDialog(ProductModel product) {
    String? selectedColor;
    int? selectedSize;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableQty = selectedColor != null && selectedSize != null
              ? product.getQuantity(selectedColor!, selectedSize!)
              : 0;

          return AlertDialog(
            title: Text(product.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيار اللون
                  const Text('اللون:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.colors.map((color) {
                      return ChoiceChip(
                        label: Text(color),
                        selected: selectedColor == color,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedColor = selected ? color : null;
                            quantity = 1;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // اختيار المقاس
                  const Text('المقاس:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.sizes.map((size) {
                      final qty = selectedColor != null
                          ? product.getQuantity(selectedColor!, size)
                          : 0;
                      return ChoiceChip(
                        label: Text('$size${qty == 0 ? ' (نفذ)' : ''}'),
                        selected: selectedSize == size,
                        onSelected: qty > 0
                            ? (selected) {
                                setDialogState(() {
                                  selectedSize = selected ? size : null;
                                  quantity = 1;
                                });
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // الكمية
                  if (selectedColor != null && selectedSize != null) ...[
                    Row(
                      children: [
                        const Text('الكمية:'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: quantity > 1
                              ? () => setDialogState(() => quantity--)
                              : null,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: quantity < availableQty
                              ? () => setDialogState(() => quantity++)
                              : null,
                        ),
                      ],
                    ),
                    Text(
                      'متوفر: $availableQty',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed:
                    selectedColor != null &&
                        selectedSize != null &&
                        quantity > 0
                    ? () {
                        final item = SaleItem(
                          productId: product.id,
                          productName: product.name,
                          color: selectedColor!,
                          size: selectedSize!,
                          quantity: quantity,
                          unitPrice: product.price,
                          costPrice: product.costPrice,
                        );
                        widget.saleProvider.addToCart(item);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت الإضافة للسلة'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    : null,
                child: const Text('إضافة للسلة'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// شاشة إتمام البيع
class _CheckoutSheet extends StatefulWidget {
  final SaleProvider saleProvider;
  final TextEditingController buyerNameController;
  final TextEditingController buyerPhoneController;
  final TextEditingController notesController;
  final TextEditingController discountController;

  const _CheckoutSheet({
    required this.saleProvider,
    required this.buyerNameController,
    required this.buyerPhoneController,
    required this.notesController,
    required this.discountController,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  bool _isDiscountPercent = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final saleProvider = widget.saleProvider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'إتمام البيع',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // بيانات المشتري (اختياري)
          const Text('بيانات المشتري (اختياري)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.buyerNameController,
                  decoration: const InputDecoration(
                    hintText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.buyerPhoneController,
                  decoration: const InputDecoration(
                    hintText: 'الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الخصم
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.discountController,
                  decoration: InputDecoration(
                    hintText: _isDiscountPercent ? 'نسبة الخصم' : 'قيمة الخصم',
                    prefixIcon: const Icon(Icons.discount_outlined),
                    suffixText: _isDiscountPercent ? '%' : 'ر.س',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    if (_isDiscountPercent) {
                      saleProvider.setDiscountPercent(amount);
                    } else {
                      saleProvider.setDiscountAmount(amount);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [_isDiscountPercent, !_isDiscountPercent],
                onPressed: (index) {
                  setState(() {
                    _isDiscountPercent = index == 0;
                    widget.discountController.clear();
                    saleProvider.setDiscountPercent(0);
                    saleProvider.setDiscountAmount(0);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('%')),
                  Padding(padding: EdgeInsets.all(8), child: Text('ر.س')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // طريقة الدفع
          const Text('طريقة الدفع'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('نقدي'),
                selected:
                    saleProvider.paymentMethod == AppConstants.paymentCash,
                onSelected: (_) =>
                    saleProvider.setPaymentMethod(AppConstants.paymentCash),
              ),
              ChoiceChip(
                label: const Text('بطاقة'),
                selected:
                    saleProvider.paymentMethod == AppConstants.paymentCard,
                onSelected: (_) =>
                    saleProvider.setPaymentMethod(AppConstants.paymentCard),
              ),
              ChoiceChip(
                label: const Text('آجل'),
                selected:
                    saleProvider.paymentMethod == AppConstants.paymentCredit,
                onSelected: (_) =>
                    saleProvider.setPaymentMethod(AppConstants.paymentCredit),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ملاحظات
          TextField(
            controller: widget.notesController,
            decoration: const InputDecoration(
              hintText: 'ملاحظات',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // ملخص الفاتورة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<SaleProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      _buildSummaryRow(
                        'المجموع الفرعي',
                        '${formatter.format(provider.subtotal)} ر.س',
                      ),
                      if (provider.discount > 0)
                        _buildSummaryRow(
                          'الخصم',
                          '- ${formatter.format(provider.discount)} ر.س',
                          color: AppTheme.errorColor,
                        ),
                      if (provider.tax > 0)
                        _buildSummaryRow(
                          'الضريبة',
                          '${formatter.format(provider.tax)} ر.س',
                        ),
                      const Divider(),
                      _buildSummaryRow(
                        'الإجمالي',
                        '${formatter.format(provider.total)} ر.س',
                        isBold: true,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // زر التأكيد
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeSale,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textOnPrimary,
                      ),
                    )
                  : const Text('تأكيد البيع', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale() async {
    setState(() => _isLoading = true);

    // تحديث بيانات المشتري
    widget.saleProvider.setBuyerInfo(
      name: widget.buyerNameController.text.trim().isNotEmpty
          ? widget.buyerNameController.text.trim()
          : null,
      phone: widget.buyerPhoneController.text.trim().isNotEmpty
          ? widget.buyerPhoneController.text.trim()
          : null,
    );
    widget.saleProvider.setNotes(
      widget.notesController.text.trim().isNotEmpty
          ? widget.notesController.text.trim()
          : null,
    );

    final sale = await widget.saleProvider.createSale();

    setState(() => _isLoading = false);

    if (sale != null) {
      Navigator.pop(context);
      _showSuccessDialog(sale);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.saleProvider.error ?? 'حدث خطأ'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showSuccessDialog(SaleModel sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 64,
        ),
        title: const Text('تمت عملية البيع بنجاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رقم الفاتورة: ${sale.invoiceNumber}'),
            Text(
              'الإجمالي: ${NumberFormat('#,##0.00', 'ar').format(sale.total)} ر.س',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: طباعة الفاتورة
            },
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
          ),
        ],
      ),
    );
  }
}
