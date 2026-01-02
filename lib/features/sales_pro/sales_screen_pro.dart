// ═══════════════════════════════════════════════════════════════════════════
// Sales Screen Pro - Professional Point of Sale Interface
// Modern, Fast & Intuitive Sales Experience
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../invoices_pro/widgets/invoice_success_dialog.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
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
  String? _selectedCustomerId;
  String? _selectedCustomerName;

  List<Product> _filterProducts(List<Product> products) {
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
  double get _total => _subtotal - _discount;

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
    if (_cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            const Text('تأكيد'),
          ],
        ),
        content: const Text('هل تريد مسح جميع المنتجات من السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _cartItems.clear();
                _discount = 0;
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: productsAsync.when(
          loading: () =>
              ProLoadingState.withMessage(message: 'جاري التحميل...'),
          error: (e, s) => ProEmptyState.error(
            error: e.toString(),
            onRetry: () {
              ref.invalidate(activeProductsStreamProvider);
              ref.invalidate(categoriesStreamProvider);
            },
          ),
          data: (products) => categoriesAsync.when(
            loading: () =>
                ProLoadingState.withMessage(message: 'جاري التحميل...'),
            error: (e, s) => ProEmptyState.error(
              error: e.toString(),
              onRetry: () {
                ref.invalidate(activeProductsStreamProvider);
                ref.invalidate(categoriesStreamProvider);
              },
            ),
            data: (categories) {
              final filteredProducts = _filterProducts(products);

              // تخطيط مختلف للشاشات الكبيرة والصغيرة
              if (isLandscape || MediaQuery.of(context).size.width > 800) {
                return _buildLandscapeLayout(filteredProducts, categories);
              }
              return _buildPortraitLayout(filteredProducts, categories);
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Landscape Layout (Tablet / Desktop)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscapeLayout(
      List<Product> products, List<Category> categories) {
    return Row(
      children: [
        // Products Section
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryChips(categories),
              Expanded(child: _buildProductsGrid(products, crossAxisCount: 4)),
            ],
          ),
        ),

        // Cart Section
        Container(
          width: 380.w,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.subtle,
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCartHeader(),
              Expanded(child: _buildCartItems()),
              _buildCartSummary(),
              _buildPaymentActions(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Portrait Layout (Mobile)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPortraitLayout(
      List<Product> products, List<Category> categories) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildCategoryChips(categories),
        Expanded(child: _buildProductsGrid(products, crossAxisCount: 2)),
        _buildMobileCartBar(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: IconButton(
              onPressed: () => context.go('/'),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary,
                size: AppIconSize.sm,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نقطة البيع',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'إنشاء فاتورة بيع سريعة',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Customer Selection
          _buildCustomerButton(),
        ],
      ),
    );
  }

  Widget _buildCustomerButton() {
    return InkWell(
      onTap: _selectCustomer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _selectedCustomerName != null
              ? AppColors.success.soft
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: _selectedCustomerName != null
                ? AppColors.success
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: AppIconSize.sm,
              color: _selectedCustomerName != null
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              _selectedCustomerName ?? 'عميل نقدي',
              style: AppTypography.labelMedium.copyWith(
                color: _selectedCustomerName != null
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
            if (_selectedCustomerName != null) ...[
              SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedCustomerId = null;
                  _selectedCustomerName = null;
                }),
                child: Icon(
                  Icons.close,
                  size: 16.sp,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Barcode Scanner
          Expanded(
            flex: 2,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _barcodeController,
                focusNode: _barcodeFocus,
                style: AppTypography.bodyMedium.copyWith(
                  fontFamily: 'JetBrains Mono',
                ),
                decoration: InputDecoration(
                  hintText: 'مسح الباركود...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.secondary,
                    size: AppIconSize.sm,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (barcode) async {
                  if (barcode.isEmpty) return;
                  final productsValue = ref.read(activeProductsStreamProvider);
                  final products = productsValue.asData?.value ?? [];
                  final product =
                      products.where((p) => p.barcode == barcode).firstOrNull;
                  if (product != null) {
                    _addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة ${product.name}'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('المنتج غير موجود'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  _barcodeController.clear();
                  _barcodeFocus.requestFocus();
                },
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Search Input
          Expanded(
            flex: 3,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث عن منتج...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: AppIconSize.sm,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: AppIconSize.sm,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Category Chips
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips(List<Category> categories) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: _buildCategoryChip(
                label: 'الكل',
                isSelected: isSelected,
                onTap: () => setState(() => _selectedCategoryId = null),
                icon: Icons.apps_rounded,
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = category.id == _selectedCategoryId;
          return Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: _buildCategoryChip(
              label: category.name,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedCategoryId = category.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16.sp,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Products Grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProductsGrid(List<Product> products, {int crossAxisCount = 3}) {
    if (products.isEmpty) {
      return _buildEmptyProducts();
    }

    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final inCart = _cartItems.any((item) => item.product.id == product.id);
        return _ProductCard(
          product: product,
          inCart: inCart,
          onTap: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64.sp,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'لا توجد منتجات',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'جرب تغيير التصنيف أو البحث',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cart Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCartHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.overlayHeavy],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_rounded,
            color: Colors.white,
            size: AppIconSize.md,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'السلة',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_cartItems.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4.h,
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
            SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: _clearCart,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.white.overlayHeavy,
                size: AppIconSize.sm,
              ),
              tooltip: 'مسح السلة',
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cart Items
  // ═══════════════════════════════════════════════════════════════════════════

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
              style: AppTypography.titleSmall.copyWith(
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

    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.sm),
      itemCount: _cartItems.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return _CartItemCard(
          item: item,
          onIncrease: () => _updateQuantity(index, 1),
          onDecrease: () => _updateQuantity(index, -1),
          onRemove: () => _removeFromCart(index),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cart Summary
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCartSummary() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_subtotal.toStringAsFixed(2)} ر.س',
                style: AppTypography.bodyMedium.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Discount
          if (_discount > 0) ...[
            SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'الخصم',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => setState(() => _discount = 0),
                      child: Icon(
                        Icons.close,
                        size: 14.sp,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${_discount.toStringAsFixed(2)} ر.س',
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],

          Divider(height: AppSpacing.lg, color: AppColors.border),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_total.toStringAsFixed(2)} ر.س',
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Payment Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentActions() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Discount Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showDiscountDialog,
                icon: Icon(Icons.discount_outlined, size: AppIconSize.sm),
                label: const Text('خصم'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),

            // Pay Button
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _cartItems.isEmpty ? null : _processPayment,
                icon: Icon(Icons.payments_rounded, size: AppIconSize.sm),
                label: Text(
                  'دفع',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Mobile Cart Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileCartBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: AppShadows.md,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cart Info
            Expanded(
              child: GestureDetector(
                onTap: _showCartSheet,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.shopping_cart_rounded,
                            color: AppColors.primary,
                            size: AppIconSize.md,
                          ),
                          if (_cartItems.isNotEmpty)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_cartItems.length}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_cartItems.length} صنف',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${_total.toStringAsFixed(2)} ر.س',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),

            // Pay Button
            FilledButton.icon(
              onPressed: _cartItems.isEmpty ? null : _processPayment,
              icon: Icon(Icons.payments_rounded, size: AppIconSize.sm),
              label: const Text('دفع'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dialogs & Sheets
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              _buildCartHeader(),
              Expanded(
                child: _buildCartItems(),
              ),
              _buildCartSummary(),
              _buildPaymentActions(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscountDialog() {
    final controller = TextEditingController(
      text: _discount > 0 ? _discount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.discount_outlined, color: AppColors.success),
            SizedBox(width: AppSpacing.sm),
            const Text('إضافة خصم'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTypography.titleMedium.copyWith(
            fontFamily: 'JetBrains Mono',
          ),
          decoration: InputDecoration(
            labelText: 'قيمة الخصم',
            suffixText: 'ر.س',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
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

  void _selectCustomer() {
    final customersAsync = ref.read(customersStreamProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return customersAsync.when(
          loading: () => SizedBox(
            height: 200.h,
            child: ProLoadingState.list(itemCount: 3),
          ),
          error: (e, _) => SizedBox(
            height: 200.h,
            child: ProEmptyState.error(error: e.toString()),
          ),
          data: (customers) => Container(
            constraints: BoxConstraints(maxHeight: 400.h),
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.secondary),
                    SizedBox(width: AppSpacing.sm),
                    Text('اختر العميل', style: AppTypography.titleMedium),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Expanded(
                  child: customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48.sp,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              const Text('لا يوجد عملاء'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.secondary.soft,
                                child: Text(
                                  customer.name[0],
                                  style: TextStyle(color: AppColors.secondary),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Text(
                                'الرصيد: ${customer.balance.toStringAsFixed(0)} ر.س',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCustomerId = customer.id;
                                  _selectedCustomerName = customer.name;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processPayment() {
    if (_cartItems.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentSheet(
        total: _total,
        onPaymentComplete: (method, paidAmount) async {
          Navigator.pop(context);
          await _saveInvoice(method, paidAmount);
        },
      ),
    );
  }

  Future<void> _saveInvoice(String paymentMethod, double paidAmount) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final customerRepo = ref.read(customerRepositoryProvider);
      final openShift = ref.read(openShiftStreamProvider).asData?.value;

      final invoiceItems = _cartItems
          .map((item) => {
                'productId': item.product.id,
                'productName': item.product.name,
                'quantity': item.quantity,
                'unitPrice': item.product.salePrice,
                'purchasePrice': item.product.purchasePrice,
                'discount': 0.0,
              })
          .toList();

      final invoiceId = await invoiceRepo.createInvoice(
        type: 'sale',
        customerId: _selectedCustomerId,
        items: invoiceItems,
        discountAmount: _discount,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        shiftId: openShift?.id,
        invoiceDate: DateTime.now(),
      );

      // تحميل بيانات الفاتورة للحوار
      final invoice = await invoiceRepo.getInvoiceById(invoiceId);
      final items = await invoiceRepo.getInvoiceItems(invoiceId);
      Customer? customer;
      if (_selectedCustomerId != null) {
        customer = await customerRepo.getCustomerById(_selectedCustomerId!);
      }

      if (mounted && invoice != null) {
        // عرض حوار النجاح الموحد
        final result = await InvoiceSuccessDialog.show(
          context: context,
          data: InvoiceDialogData(
            invoice: invoice,
            items: items,
            customer: customer,
          ),
          showNewInvoiceButton: true,
          showViewDetailsButton: true,
          onNewInvoice: _resetCart,
        );

        // إذا اختار المستخدم فاتورة جديدة أو إغلاق
        if (result == InvoiceDialogResult.newInvoice ||
            result == InvoiceDialogResult.close) {
          _resetCart();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetCart() {
    setState(() {
      _cartItems.clear();
      _discount = 0;
      _selectedCustomerId = null;
      _selectedCustomerName = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Loading & Error States (handled by ProLoadingState and ProEmptyState)
  // ═══════════════════════════════════════════════════════════════════════════
}

// ═══════════════════════════════════════════════════════════════════════════
// Product Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool inCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= product.minQuantity;
    final isOutOfStock = product.quantity <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: inCart
                ? AppColors.success.subtle
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: inCart
                  ? AppColors.success
                  : isOutOfStock
                      ? AppColors.error.border
                      : AppColors.border,
              width: inCart ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Product Icon
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.soft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: isOutOfStock
                              ? AppColors.textTertiary
                              : AppColors.primary,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),

                  // Product Name
                  Text(
                    product.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isOutOfStock
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),

                  // Price
                  Text(
                    '${product.salePrice.toStringAsFixed(0)} ر.س',
                    style: AppTypography.titleSmall.copyWith(
                      color: isOutOfStock
                          ? AppColors.textTertiary
                          : AppColors.success,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Stock
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    isOutOfStock
                        ? 'نفذ المخزون'
                        : 'المخزون: ${product.quantity}',
                    style: AppTypography.labelSmall.copyWith(
                      color: isOutOfStock
                          ? AppColors.error
                          : isLowStock
                              ? AppColors.warning
                              : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),

              // In Cart Badge
              if (inCart)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12.sp,
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

// ═══════════════════════════════════════════════════════════════════════════
// Cart Item Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
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
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.product.salePrice.toStringAsFixed(0)} ر.س',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: onDecrease,
                ),
                Container(
                  width: 36.w,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: AppTypography.titleSmall.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: onIncrease,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Total
          SizedBox(
            width: 70.w,
            child: Text(
              item.total.toStringAsFixed(0),
              style: AppTypography.titleSmall.copyWith(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),

          // Delete
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18.sp,
              color: AppColors.error,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xs),
        child: Icon(
          icon,
          size: 18.sp,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Payment Sheet Widget
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentSheet extends StatefulWidget {
  final double total;
  final Function(String method, double paidAmount) onPaymentComplete;

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
  bool _hasEnteredAmount = false;

  double get _paidAmount => double.tryParse(_amountController.text) ?? 0;
  double get _change => _paidAmount - widget.total;
  double get _remainingAmount => widget.total - _paidAmount;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_selectedMethod == 'partial') {
      return _amountController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              // Handle
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

              // Title
              Text(
                'إتمام الدفع',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Total Card
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.overlayHeavy
                    ],
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Payment Methods
              Text(
                'طريقة الدفع',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  _PaymentMethodButton(
                    icon: Icons.payments_rounded,
                    label: 'نقدي',
                    isSelected: _selectedMethod == 'cash',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'cash';
                        _amountController.text =
                            widget.total.toStringAsFixed(0);
                      });
                    },
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _PaymentMethodButton(
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'جزئي',
                    isSelected: _selectedMethod == 'partial',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'partial';
                        _amountController.clear();
                      });
                    },
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _PaymentMethodButton(
                    icon: Icons.schedule_rounded,
                    label: 'آجل',
                    isSelected: _selectedMethod == 'credit',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'credit';
                        _amountController.text = '0';
                      });
                    },
                  ),
                ],
              ),

              // Cash Input - للدفع النقدي
              if (_selectedMethod == 'cash') ...[
                SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'JetBrains Mono',
                  ),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    suffixText: 'ر.س',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),

                // Change - الباقي
                if (_change >= 0 && _amountController.text.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.soft,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Partial Payment - الدفع الجزئي
              if (_selectedMethod == 'partial') ...[
                SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color: AppColors.success,
                  ),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع *',
                    hintText: 'أدخل المبلغ المدفوع',
                    suffixText: 'ر.س',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.success),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          BorderSide(color: AppColors.success, width: 2),
                    ),
                    errorText: _amountController.text.trim().isEmpty &&
                            _hasEnteredAmount
                        ? 'الرجاء إدخال المبلغ المدفوع'
                        : null,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() => _hasEnteredAmount = true),
                ),

                // المبلغ المتبقي
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _remainingAmount > 0
                        ? AppColors.warning.soft
                        : AppColors.success.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المبلغ المتبقي',
                        style: AppTypography.titleSmall.copyWith(
                          color: _remainingAmount > 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                      Text(
                        '${_remainingAmount.toStringAsFixed(2)} ر.س',
                        style: AppTypography.titleMedium.copyWith(
                          color: _remainingAmount > 0
                              ? AppColors.warning
                              : AppColors.success,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // أزرار سريعة
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _QuickAmountChip(
                      label: '25%',
                      amount: (widget.total * 0.25).round(),
                      onTap: () => setState(() {
                        _amountController.text =
                            (widget.total * 0.25).round().toString();
                        _hasEnteredAmount = true;
                      }),
                    ),
                    _QuickAmountChip(
                      label: '50%',
                      amount: (widget.total * 0.5).round(),
                      onTap: () => setState(() {
                        _amountController.text =
                            (widget.total * 0.5).round().toString();
                        _hasEnteredAmount = true;
                      }),
                    ),
                    _QuickAmountChip(
                      label: '75%',
                      amount: (widget.total * 0.75).round(),
                      onTap: () => setState(() {
                        _amountController.text =
                            (widget.total * 0.75).round().toString();
                        _hasEnteredAmount = true;
                      }),
                    ),
                  ],
                ),
              ],

              // Credit - آجل
              if (_selectedMethod == 'credit') ...[
                SizedBox(height: AppSpacing.lg),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: AppColors.warning.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: AppIconSize.sm,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'سيتم تسجيل المبلغ كامل كدين على العميل',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.xl),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canConfirm
                      ? () {
                          double paid;
                          if (_selectedMethod == 'cash') {
                            paid =
                                _paidAmount > 0 ? widget.total : widget.total;
                          } else if (_selectedMethod == 'credit') {
                            paid = 0;
                          } else {
                            // partial
                            paid = _paidAmount;
                          }
                          widget.onPaymentComplete(_selectedMethod, paid);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    _selectedMethod == 'credit'
                        ? 'تأكيد (آجل)'
                        : _selectedMethod == 'partial'
                            ? 'تأكيد الدفع الجزئي'
                            : 'تأكيد الدفع',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final int amount;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$label ($amount)'),
      onPressed: onTap,
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.border),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.soft
                : AppColors.background,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
// Data Models
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
