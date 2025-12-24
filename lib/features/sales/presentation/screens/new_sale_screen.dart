import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/entities/entities.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/sales_providers.dart';
import '../widgets/widgets.dart';

/// شاشة نقطة البيع
class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newSale),
        actions: [
          // عدد العناصر في السلة
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: Center(
                child: Badge(
                  label: Text('${cart.itemCount}'),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _showCartSheet(context),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // قائمة المنتجات
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _filterProducts(products);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppSizes.sm,
                    mainAxisSpacing: AppSizes.sm,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ProductSaleCard(
                      product: filtered[index],
                      onTap: () => _showVariantSelector(filtered[index]),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),

          // شريط السلة السفلي
          if (cart.isNotEmpty) _buildCartBar(cart),
        ],
      ),
    );
  }

  List<ProductEntity> _filterProducts(List<ProductEntity> products) {
    if (_searchQuery.isEmpty) {
      return products.where((p) => p.isActive && p.totalStock > 0).toList();
    }

    final query = _searchQuery.toLowerCase();
    return products.where((p) {
      if (!p.isActive || p.totalStock <= 0) return false;
      return p.name.toLowerCase().contains(query) ||
          (p.barcode?.contains(_searchQuery) ?? false);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSizes.md),
          Text(
            'لا توجد منتجات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBar(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // معلومات السلة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.itemCount} منتج',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    cart.total.toCurrency(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            // زر الدفع
            ElevatedButton.icon(
              onPressed: () => _showCheckoutSheet(context),
              icon: const Icon(Icons.payment),
              label: const Text('الدفع'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scanBarcode() {
    // سيتم تنفيذها لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تفعيل الماسح قريباً')),
    );
  }

  void _showVariantSelector(ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VariantSelectorSheet(
        product: product,
        onSelect: (variant, quantity) {
          ref
              .read(cartProvider.notifier)
              .addItem(product: product, variant: variant, quantity: quantity);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت إضافة ${product.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CartSheet(),
    );
  }

  void _showCheckoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CheckoutSheet(
        onComplete: (invoice) {
          Navigator.pop(context);
          context.pop();
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إنشاء الفاتورة #${invoice.invoiceNumber}'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'عرض',
                textColor: Colors.white,
                onPressed: () => context.push('/sales/${invoice.id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
