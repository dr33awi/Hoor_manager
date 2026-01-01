// ═══════════════════════════════════════════════════════════════════════════
// Professional Point of Sale Screen
// Fast, Intuitive Sales Interface with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/animations/pro_animations.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class SalesScreenPro extends ConsumerStatefulWidget {
  const SalesScreenPro({super.key});

  @override
  ConsumerState<SalesScreenPro> createState() => _SalesScreenProState();
}

class _SalesScreenProState extends ConsumerState<SalesScreenPro> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  String? _selectedCategoryId;
  final List<CartItem> _cartItems = [];
  double _discount = 0;
  // ignore: unused_field
  String _paymentMethod = 'cash';

  List<Product> _filterProducts(
      List<Product> products, List<Category> categories) {
    var filtered = products.where((p) => p.isActive).toList();

    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.barcode?.contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * 0.15;
  double get _total => _subtotal + _tax - _discount;

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    HapticFeedback.lightImpact();
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _cartItems[index].quantity += change;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _cartItems.removeAt(index));
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل تريد مسح جميع المنتجات من السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _cartItems.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('مسح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentSheet(
        total: _total,
        onPaymentComplete: (method) {
          Navigator.pop(context);
          _showReceiptDialog();
        },
      ),
    );
  }

  void _showReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 40.sp,
          ),
        ),
        title: const Text('تمت العملية بنجاح'),
        content: Text(
          'الإجمالي: ${_total.toStringAsFixed(2)} ر.س',
          style: AppTypography.titleMedium.copyWith(
            fontFamily: 'JetBrains Mono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cartItems.clear();
                _discount = 0;
              });
            },
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Print receipt logic
              setState(() {
                _cartItems.clear();
                _discount = 0;
              });
            },
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('خطأ: $e')),
          data: (products) => categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('خطأ: $e')),
            data: (categories) {
              final filteredProducts = _filterProducts(products, categories);
              return Row(
                children: [
                  // Products Section
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildProductsHeader(),
                        _buildCategoryChips(categories),
                        Expanded(child: _buildProductsGrid(filteredProducts)),
                      ],
                    ),
                  ),

                  // Cart Section
                  Container(
                    width: 360.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildCartHeader(),
                        Expanded(child: _buildCartItems()),
                        _buildCartTotals(),
                        _buildPaymentActions(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
          ),
          SizedBox(width: AppSpacing.sm),

          // Title
          Text(
            'نقطة البيع',
            style: AppTypography.titleLarge,
          ),

          const Spacer(),

          // Barcode Input
          Container(
            width: 200.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocus,
              decoration: InputDecoration(
                hintText: 'مسح الباركود...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.textSecondary,
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              onSubmitted: (barcode) async {
                final productsValue = ref.read(activeProductsStreamProvider);
                final products = productsValue.asData?.value ?? [];
                final product =
                    products.where((p) => p.barcode == barcode).firstOrNull;
                if (product != null) {
                  _addToCart(product);
                }
                _barcodeController.clear();
                _barcodeFocus.requestFocus();
              },
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // Search Input
          Container(
            width: 250.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن منتج...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" category
            final isSelected = _selectedCategoryId == null;
            return Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: FilterChip(
                label: const Text('الكل'),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategoryId = null),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: AppTypography.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = category.id == _selectedCategoryId;
          return Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) =>
                  setState(() => _selectedCategoryId = category.id),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> filteredProducts) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64.sp, color: AppColors.textTertiary),
            SizedBox(height: AppSpacing.md),
            Text('لا توجد منتجات',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return StaggeredListAnimation(
          index: index,
          child: _ProductTile(
            product: product,
            onTap: () => _addToCart(product),
          ),
        );
      },
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: Colors.white,
            size: 24.sp,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'السلة',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (_cartItems.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${_cartItems.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_cartItems.isNotEmpty) ...[
            SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: _clearCart,
              icon: Icon(
                Icons.delete_outline,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'السلة فارغة',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'اضغط على المنتجات لإضافتها',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.sm),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return _CartItemTile(
          item: item,
          onIncrease: () => _updateQuantity(index, 1),
          onDecrease: () => _updateQuantity(index, -1),
          onRemove: () => _removeFromCart(index),
        );
      },
    );
  }

  Widget _buildCartTotals() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع الفرعي', _subtotal),
          SizedBox(height: AppSpacing.xs),
          _buildTotalRow('الضريبة (15%)', _tax),
          if (_discount > 0) ...[
            SizedBox(height: AppSpacing.xs),
            _buildTotalRow('الخصم', -_discount, color: AppColors.success),
          ],
          Divider(height: AppSpacing.lg),
          _buildTotalRow(
            'الإجمالي',
            _total,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)
              : AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '${value.toStringAsFixed(2)} ر.س',
          style: isTotal
              ? AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  color: AppColors.primary,
                )
              : AppTypography.bodyMedium.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: color,
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentActions() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Discount Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDiscountDialog(),
              icon: const Icon(Icons.discount_outlined),
              label: const Text('خصم'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Pay Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _processPayment,
              icon: const Icon(Icons.payments),
              label: const Text('دفع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final controller = TextEditingController(text: _discount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة خصم'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'قيمة الخصم',
            suffixText: 'ر.س',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _discount = double.tryParse(controller.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product Tile
// ═══════════════════════════════════════════════════════════════════════════

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                product.name,
                style: AppTypography.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '${product.salePrice.toStringAsFixed(2)} ر.س',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cart Item Tile
// ═══════════════════════════════════════════════════════════════════════════

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTypography.labelMedium,
                ),
                Text(
                  '${item.product.salePrice.toStringAsFixed(2)} ر.س',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove),
                iconSize: 18.sp,
                constraints: BoxConstraints(
                  minWidth: 32.w,
                  minHeight: 32.h,
                ),
              ),
              Container(
                width: 32.w,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: AppTypography.titleSmall.copyWith(
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add),
                iconSize: 18.sp,
                constraints: BoxConstraints(
                  minWidth: 32.w,
                  minHeight: 32.h,
                ),
              ),
            ],
          ),

          // Total
          SizedBox(
            width: 70.w,
            child: Text(
              '${item.total.toStringAsFixed(2)}',
              style: AppTypography.titleSmall.copyWith(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),

          // Delete
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              size: 18.sp,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Payment Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentSheet extends StatefulWidget {
  final double total;
  final Function(String method) onPaymentComplete;

  const _PaymentSheet({
    required this.total,
    required this.onPaymentComplete,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _selectedMethod = 'cash';
  final TextEditingController _amountController = TextEditingController();

  double get _change {
    final paid = double.tryParse(_amountController.text) ?? 0;
    return paid - widget.total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              Text(
                'إتمام الدفع',
                style: AppTypography.headlineSmall,
              ),

              SizedBox(height: AppSpacing.lg),

              // Total
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المبلغ المطلوب',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.total.toStringAsFixed(2)} ر.س',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Payment Methods
              Text(
                'طريقة الدفع',
                style: AppTypography.titleSmall,
              ),
              SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  _PaymentMethodButton(
                    icon: Icons.money,
                    label: 'نقدي',
                    isSelected: _selectedMethod == 'cash',
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                  ),
                  SizedBox(width: AppSpacing.md),
                  _PaymentMethodButton(
                    icon: Icons.credit_card,
                    label: 'بطاقة',
                    isSelected: _selectedMethod == 'card',
                    onTap: () => setState(() => _selectedMethod = 'card'),
                  ),
                  SizedBox(width: AppSpacing.md),
                  _PaymentMethodButton(
                    icon: Icons.account_balance,
                    label: 'تحويل',
                    isSelected: _selectedMethod == 'transfer',
                    onTap: () => setState(() => _selectedMethod = 'transfer'),
                  ),
                ],
              ),

              if (_selectedMethod == 'cash') ...[
                SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    suffixText: 'ر.س',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_change >= 0 && _amountController.text.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الباقي',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '${_change.toStringAsFixed(2)} ر.س',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.success,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              SizedBox(height: AppSpacing.xl),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onPaymentComplete(_selectedMethod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'تأكيد الدفع',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28.sp,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Data Models - Cart Item (uses real Product)
// ═══════════════════════════════════════════════════════════════════════════

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.salePrice * quantity;
}
