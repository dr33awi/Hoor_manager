// lib/features/sales/screens/new_sale_screen.dart
// شاشة إنشاء فاتورة جديدة - تصميم حديث

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product_model.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'السلة فارغة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط + لإضافة منتجات',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCart(SaleProvider saleProvider, NumberFormat formatter) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: saleProvider.cartItems.length,
      itemBuilder: (_, i) {
        final item = saleProvider.cartItems[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.color} - مقاس ${item.size}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(item.unitPrice)} ر.س',
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    if (item.quantity > 1)
                      saleProvider.updateCartItemQuantity(i, item.quantity - 1);
                    else
                      saleProvider.removeFromCart(i);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _qtyBtn(
                    Icons.add,
                    () => saleProvider.updateCartItemQuantity(
                      i,
                      item.quantity + 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatter.format(item.totalPrice)} ر.س',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () => saleProvider.removeFromCart(i),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildBottom(
    SaleProvider saleProvider,
    ProductProvider productProvider,
    NumberFormat formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!saleProvider.isCartEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text('${formatter.format(saleProvider.subtotal)} ر.س'),
                ],
              ),
              if (saleProvider.discount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الخصم',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                    Text(
                      '- ${formatter.format(saleProvider.discount)} ر.س',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ],
              Divider(height: 20, color: Colors.grey.shade100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${formatter.format(saleProvider.total)} ر.س',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddProduct(productProvider, saleProvider),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('إضافة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: saleProvider.isCartEmpty
                        ? null
                        : () => _showCheckout(saleProvider),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                    label: const Text('إتمام البيع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProduct(
    ProductProvider productProvider,
    SaleProvider saleProvider,
  ) {
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

  void _showCheckout(SaleProvider saleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CheckoutSheet(
          saleProvider: saleProvider,
          buyerNameCtrl: _buyerNameController,
          buyerPhoneCtrl: _buyerPhoneController,
          notesCtrl: _notesController,
          discountCtrl: _discountController,
        ),
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
        .where(
          (p) =>
              _search.isEmpty ||
              p.name.toLowerCase().contains(_search.toLowerCase()),
        )
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
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'اختر المنتج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
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
                    child: Text(
                      'لا توجد منتجات',
                      style: TextStyle(color: Colors.grey.shade500),
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
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${p.totalQuantity} متوفر',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Text(
                          '${p.price.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showProductOptions(p);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showProductOptions(ProductModel product) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اللون:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.colors
                        .map(
                          (c) => ChoiceChip(
                            label: Text(c),
                            selected: selectedColor == c,
                            onSelected: (s) => setState(() {
                              selectedColor = s ? c : null;
                              qty = 1;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'المقاس:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.sizes.map((s) {
                      final q = selectedColor != null
                          ? product.getQuantity(selectedColor!, s)
                          : 0;
                      return ChoiceChip(
                        label: Text('$s${q == 0 ? ' (نفذ)' : ''}'),
                        selected: selectedSize == s,
                        onSelected: q > 0
                            ? (sel) => setState(() {
                                selectedSize = sel ? s : null;
                                qty = 1;
                              })
                            : null,
                      );
                    }).toList(),
                  ),
                  if (selectedColor != null && selectedSize != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('الكمية:'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: qty > 1
                              ? () => setState(() => qty--)
                              : null,
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: qty < availableQty
                              ? () => setState(() => qty++)
                              : null,
                        ),
                      ],
                    ),
                    Text(
                      'متوفر: $availableQty',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed:
                    selectedColor != null && selectedSize != null && qty > 0
                    ? () {
                        widget.saleProvider.addToCart(
                          SaleItem(
                            productId: product.id,
                            productName: product.name,
                            color: selectedColor!,
                            size: selectedSize!,
                            quantity: qty,
                            unitPrice: product.price,
                            costPrice: product.costPrice,
                          ),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تمت الإضافة'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                ),
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  final SaleProvider saleProvider;
  final TextEditingController buyerNameCtrl,
      buyerPhoneCtrl,
      notesCtrl,
      discountCtrl;

  const _CheckoutSheet({
    required this.saleProvider,
    required this.buyerNameCtrl,
    required this.buyerPhoneCtrl,
    required this.notesCtrl,
    required this.discountCtrl,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  bool _isPercent = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final sp = widget.saleProvider;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'إتمام البيع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _field(
                    widget.buyerNameCtrl,
                    'الاسم',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    widget.buyerPhoneCtrl,
                    'الهاتف',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(
                    widget.discountCtrl,
                    _isPercent ? 'الخصم %' : 'الخصم',
                    Icons.discount_outlined,
                    suffix: _isPercent ? '%' : 'ر.س',
                    keyboard: TextInputType.number,
                    onChanged: (v) {
                      final a = double.tryParse(v) ?? 0;
                      if (_isPercent)
                        sp.setDiscountPercent(a);
                      else
                        sp.setDiscountAmount(a);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [_isPercent, !_isPercent],
                  onPressed: (i) {
                    setState(() {
                      _isPercent = i == 0;
                      widget.discountCtrl.clear();
                      sp.setDiscountPercent(0);
                      sp.setDiscountAmount(0);
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('%'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ر.س'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'طريقة الدفع',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('نقدي'),
                  selected: sp.paymentMethod == AppConstants.paymentCash,
                  onSelected: (_) =>
                      sp.setPaymentMethod(AppConstants.paymentCash),
                ),
                ChoiceChip(
                  label: const Text('بطاقة'),
                  selected: sp.paymentMethod == AppConstants.paymentCard,
                  onSelected: (_) =>
                      sp.setPaymentMethod(AppConstants.paymentCard),
                ),
                ChoiceChip(
                  label: const Text('آجل'),
                  selected: sp.paymentMethod == AppConstants.paymentCredit,
                  onSelected: (_) =>
                      sp.setPaymentMethod(AppConstants.paymentCredit),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(
              widget.notesCtrl,
              'ملاحظات',
              Icons.note_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<SaleProvider>(
                builder: (_, p, __) => Column(
                  children: [
                    _row('المجموع', '${formatter.format(p.subtotal)} ر.س'),
                    if (p.discount > 0)
                      _row(
                        'الخصم',
                        '- ${formatter.format(p.discount)} ر.س',
                        color: const Color(0xFFEF4444),
                      ),
                    Divider(height: 16, color: Colors.grey.shade300),
                    _row(
                      'الإجمالي',
                      '${formatter.format(p.total)} ر.س',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _complete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'تأكيد',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboard,
    String? suffix,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(fontWeight: isBold ? FontWeight.w600 : null),
          ),
          Text(
            v,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete() async {
    setState(() => _isLoading = true);
    final sp = widget.saleProvider;
    sp.setBuyerInfo(
      name: widget.buyerNameCtrl.text.trim().isNotEmpty
          ? widget.buyerNameCtrl.text.trim()
          : null,
      phone: widget.buyerPhoneCtrl.text.trim().isNotEmpty
          ? widget.buyerPhoneCtrl.text.trim()
          : null,
    );
    sp.setNotes(
      widget.notesCtrl.text.trim().isNotEmpty
          ? widget.notesCtrl.text.trim()
          : null,
    );

    final sale = await sp.createSale();
    setState(() => _isLoading = false);

    if (sale != null) {
      Navigator.pop(context);
      _showSuccess(sale);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sp.error ?? 'خطأ'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showSuccess(SaleModel sale) {
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم البيع بنجاح',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'رقم الفاتورة: ${sale.invoiceNumber}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                '${NumberFormat('#,##0.00', 'ar').format(sale.total)} ر.س',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
