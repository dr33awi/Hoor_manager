import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/services/barcode_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/entities/entities.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/sales_repository.dart';
import '../providers/sales_providers.dart';

/// ترتيب المنتجات
enum ProductSortType {
  name,
  price,
  stock,
  bestSelling,
}

/// شاشة البيع المباشر - بدون سلة
class DirectSaleScreen extends ConsumerStatefulWidget {
  const DirectSaleScreen({super.key});

  @override
  ConsumerState<DirectSaleScreen> createState() => _DirectSaleScreenState();
}

class _DirectSaleScreenState extends ConsumerState<DirectSaleScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  ProductSortType _sortType = ProductSortType.name;
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsStreamProvider);
    final todayStats = ref.watch(todayStatsProvider);
    final todayInvoices = ref.watch(todayInvoicesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('البيع المباشر'),
        centerTitle: true,
        actions: [
          // زر تبديل العرض
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكة',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // زر الترتيب
          PopupMenuButton<ProductSortType>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب',
            onSelected: (type) => setState(() => _sortType = type),
            itemBuilder: (context) => [
              _buildSortMenuItem(
                  ProductSortType.name, 'الاسم', Icons.sort_by_alpha),
              _buildSortMenuItem(
                  ProductSortType.price, 'السعر', Icons.attach_money),
              _buildSortMenuItem(
                  ProductSortType.stock, 'المخزون', Icons.inventory),
              _buildSortMenuItem(ProductSortType.bestSelling, 'الأكثر مبيعاً',
                  Icons.trending_up),
            ],
          ),
          // زر إحصائيات اليوم
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'إحصائيات اليوم',
            onPressed: () => _showTodayStats(context, todayStats),
          ),
          // زر فواتير اليوم
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'فواتير اليوم',
            onPressed: () => _showTodayInvoices(context, todayInvoices),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الإحصائيات السريعة
          todayStats.when(
            data: (stats) => _buildQuickStats(stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // شريط الفئات
          categoriesAsync.when(
            data: (categories) => _buildCategoriesBar(categories),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

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
                      tooltip: 'مسح الباركود',
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // قائمة المنتجات
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _filterAndSortProducts(products);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _isGridView
                    ? _buildGridView(filtered)
                    : _buildListView(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSizes.md),
                    Text('خطأ: $e'),
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allProductsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ProductSortType> _buildSortMenuItem(
      ProductSortType type, String label, IconData icon) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: _sortType == type ? AppColors.primary : null),
          const SizedBox(width: AppSizes.sm),
          Text(label),
          if (_sortType == type) ...[
            const Spacer(),
            const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesBar(List<CategoryEntity> categories) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: FilterChip(
                label: const Text('الكل'),
                selected: _selectedCategoryId == null,
                onSelected: (_) => setState(() => _selectedCategoryId = null),
                selectedColor: AppColors.primary.withOpacity(0.2),
              ),
            );
          }
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: FilterChip(
              label: Text(category.name),
              selected: _selectedCategoryId == category.id,
              onSelected: (_) =>
                  setState(() => _selectedCategoryId = category.id),
              selectedColor: AppColors.primary.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView(List<ProductEntity> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(
          product: products[index],
          onTap: () => _showDirectSaleDialog(products[index]),
        );
      },
    );
  }

  Widget _buildListView(List<ProductEntity> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child:
                          Image.network(product.imageUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image, color: AppColors.textHint),
            ),
            title: Text(product.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.isLowStock
                        ? AppColors.warning
                        : AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product.totalStock}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(product.price.toCurrency(),
                    style: TextStyle(color: AppColors.primary)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              color: AppColors.primary,
              onPressed: () => _showDirectSaleDialog(product),
            ),
            onTap: () => _showDirectSaleDialog(product),
          ),
        );
      },
    );
  }

  /// إحصائيات سريعة في الأعلى
  Widget _buildQuickStats(DailySalesStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.receipt,
            label: 'الفواتير',
            value: '${stats.invoiceCount}',
          ),
          _StatItem(
            icon: Icons.shopping_bag,
            label: 'المنتجات',
            value: '${stats.itemCount}',
          ),
          _StatItem(
            icon: Icons.attach_money,
            label: 'المبيعات',
            value: stats.totalSales.toCompactCurrency(),
          ),
          _StatItem(
            icon: Icons.trending_up,
            label: 'الأرباح',
            value: stats.totalProfit.toCompactCurrency(),
          ),
        ],
      ),
    );
  }

  List<ProductEntity> _filterAndSortProducts(List<ProductEntity> products) {
    var filtered =
        products.where((p) => p.isActive && p.totalStock > 0).toList();

    // فلترة حسب الفئة
    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.barcode?.contains(_searchQuery) ?? false);
      }).toList();
    }

    // الترتيب
    switch (_sortType) {
      case ProductSortType.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortType.price:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortType.stock:
        filtered.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case ProductSortType.bestSelling:
        // يمكن إضافة حقل للمبيعات لاحقاً
        break;
    }

    return filtered;
  }

  List<ProductEntity> _filterProducts(List<ProductEntity> products) {
    return _filterAndSortProducts(products);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSizes.md),
          Text(
            _searchQuery.isEmpty
                ? 'لا توجد منتجات متاحة'
                : 'لا توجد نتائج للبحث',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('مسح البحث'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerService.scan(context);

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final productAsync =
          await ref.read(productByBarcodeProvider(barcode).future);

      if (mounted) {
        if (productAsync != null) {
          _showDirectSaleDialog(productAsync);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لم يتم العثور على منتج بالباركود: $barcode'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// عرض حوار البيع المباشر
  void _showDirectSaleDialog(ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DirectSaleSheet(
        product: product,
        onSaleComplete: (invoice) {
          Navigator.pop(context);
          _showSaleSuccessDialog(invoice);
        },
      ),
    );
  }

  /// عرض حوار نجاح البيع
  void _showSaleSuccessDialog(InvoiceEntity invoice) {
    // تشغيل صوت النجاح
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon:
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        title: const Text('تم البيع بنجاح!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رقم الفاتورة: ${invoice.invoiceNumber}'),
            const SizedBox(height: AppSizes.sm),
            Text(
              'الإجمالي: ${invoice.total.toCurrency()}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (invoice.change > 0) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.money, color: AppColors.success),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'الباقي: ${invoice.change.toCurrency()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.sm),
            ),
            child: const Text('إغلاق'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: AppSizes.md),
      ),
    );

    // عرض خيارات إضافية بعد إغلاق الحوار الأول
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/sales/${invoice.id}');
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('عرض الفاتورة والطباعة'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSizes.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    // تحديث الإحصائيات والفواتير
    ref.invalidate(todayStatsProvider);
    ref.invalidate(todayInvoicesProvider);
  }

  /// عرض إحصائيات اليوم
  void _showTodayStats(
      BuildContext context, AsyncValue<DailySalesStats> statsAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return statsAsync.when(
            data: (stats) => _TodayStatsSheet(
                stats: stats, scrollController: scrollController),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          );
        },
      ),
    );
  }

  /// عرض فواتير اليوم
  void _showTodayInvoices(
      BuildContext context, AsyncValue<List<InvoiceEntity>> invoicesAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return invoicesAsync.when(
            data: (invoices) => _TodayInvoicesSheet(
              invoices: invoices,
              scrollController: scrollController,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          );
        },
      ),
    );
  }
}

/// عنصر إحصائية
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// بطاقة منتج للبيع المباشر
class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة المنتج
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // خلفية الصورة
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: AppColors.textHint.withOpacity(0.5),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppColors.textHint.withOpacity(0.5),
                                ),
                              ),
                      ),
                    ),
                    // شارة المخزون
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: product.isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (product.isLowStock
                                      ? AppColors.warning
                                      : AppColors.success)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${product.totalStock}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // زر بيع سريع
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, 20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(25),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // معلومات المنتج
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.price.toCurrency(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
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

/// شيت البيع المباشر
class DirectSaleSheet extends ConsumerStatefulWidget {
  final ProductEntity product;
  final void Function(InvoiceEntity invoice) onSaleComplete;

  const DirectSaleSheet({
    super.key,
    required this.product,
    required this.onSaleComplete,
  });

  @override
  ConsumerState<DirectSaleSheet> createState() => _DirectSaleSheetState();
}

class _DirectSaleSheetState extends ConsumerState<DirectSaleSheet> {
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  DiscountType _discountType = DiscountType.percentage;
  final _discountController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;

  ProductVariant? get _selectedVariant {
    if (_selectedColor == null || _selectedSize == null) return null;
    return widget.product.getVariant(_selectedColor!, _selectedSize!);
  }

  double get _unitPrice => widget.product.price;
  double get _subtotal => _unitPrice * _quantity;

  double get _discountValue {
    final value = double.tryParse(_discountController.text) ?? 0;
    if (_discountType == DiscountType.percentage) {
      return (_subtotal * value) / 100;
    }
    return value;
  }

  double get _total => (_subtotal - _discountValue).clamp(0, double.infinity);

  double get _amountPaid => double.tryParse(_amountController.text) ?? 0;
  double get _change => (_amountPaid - _total).clamp(0, double.infinity);

  bool get _canSell =>
      _selectedVariant != null && _quantity > 0 && _amountPaid >= _total;

  @override
  void initState() {
    super.initState();
    // تحديث المبلغ المدفوع عند تغير السعر
    _updateAmountPaid();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmountPaid() {
    _amountController.text = _total.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final availableColors = widget.product.availableColors;
    final availableSizes = _selectedColor != null
        ? widget.product.availableSizesForColor(_selectedColor!)
        : <String>[];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppSizes.md,
          right: AppSizes.md,
          top: AppSizes.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المقبض
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // معلومات المنتج
              Row(
                children: [
                  // صورة المنتج
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: widget.product.imageUrl != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                            child: Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, color: AppColors.textHint),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          _unitPrice.toCurrency(),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.lg),
              const Divider(),
              const SizedBox(height: AppSizes.md),

              // اختيار اللون
              Text('اللون', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: availableColors.map((color) {
                  final isSelected = _selectedColor == color;
                  final colorCode = CommonColors.getColorCode(color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _selectedSize = null;
                        _quantity = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _hexToColor(colorCode),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            color,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSizes.lg),

              // اختيار المقاس
              Text('المقاس', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSizes.sm),
              if (_selectedColor == null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Text(
                    'اختر اللون أولاً',
                    style: TextStyle(color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: availableSizes.map((size) {
                    final isSelected = _selectedSize == size;
                    final variant =
                        widget.product.getVariant(_selectedColor!, size);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSize = size;
                          _quantity = 1;
                          _updateAmountPaid();
                        });
                      },
                      child: Container(
                        width: 60,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSizes.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              size,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(${variant?.quantity ?? 0})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? AppColors.textLight.withOpacity(0.7)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: AppSizes.lg),

              // الكمية
              if (_selectedVariant != null) ...[
                Text('الكمية', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: _quantity > 1
                          ? () => setState(() {
                                _quantity--;
                                _updateAmountPaid();
                              })
                          : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _quantity < _selectedVariant!.quantity
                          ? () => setState(() {
                                _quantity++;
                                _updateAmountPaid();
                              })
                          : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'المتوفر: ${_selectedVariant!.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.lg),
                const Divider(),
                const SizedBox(height: AppSizes.md),

                // الخصم
                Text('الخصم (اختياري)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          setState(() {});
                          _updateAmountPaid();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    SegmentedButton<DiscountType>(
                      segments: const [
                        ButtonSegment(
                            value: DiscountType.percentage, label: Text('%')),
                        ButtonSegment(
                            value: DiscountType.fixed, label: Text('ل.س')),
                      ],
                      selected: {_discountType},
                      onSelectionChanged: (set) {
                        setState(() => _discountType = set.first);
                        _updateAmountPaid();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.lg),

                // ملخص الفاتورة
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    children: [
                      _buildRow('المجموع الفرعي', _subtotal.toCurrency()),
                      if (_discountValue > 0)
                        _buildRow('الخصم', '- ${_discountValue.toCurrency()}',
                            color: AppColors.error),
                      const Divider(),
                      _buildRow('الإجمالي', _total.toCurrency(), isBold: true),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.md),

                // المبلغ المدفوع
                Text('المبلغ المدفوع',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    suffixText: 'ل.س',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),

                // الباقي
                if (_change > 0) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الباقي'),
                        Text(
                          _change.toCurrency(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: AppSizes.lg),

              // زر البيع
              ElevatedButton(
                onPressed: _canSell && !_isLoading ? _completeSale : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  backgroundColor: AppColors.success,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _canSell
                            ? 'إتمام البيع (${_total.toCurrency()})'
                            : 'اختر اللون والمقاس',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
              fontSize: isBold ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _completeSale() async {
    if (!_canSell) return;

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);

    // إنشاء عنصر السلة
    final cartItem = CartItem.fromProduct(
      product: widget.product,
      variant: _selectedVariant!,
      quantity: _quantity,
    );

    // إنشاء الخصم
    final discount = _discountValue > 0
        ? Discount(
            type: _discountType,
            value: double.tryParse(_discountController.text) ?? 0)
        : Discount.none;

    // إنشاء الفاتورة مباشرة
    final invoice =
        await ref.read(directSaleProvider.notifier).createDirectSale(
              item: cartItem,
              discount: discount,
              amountPaid: _amountPaid,
              soldBy: user?.id ?? '',
              soldByName: user?.fullName,
            );

    setState(() => _isLoading = false);

    if (invoice != null) {
      widget.onSaleComplete(invoice);
    } else {
      if (mounted) {
        final errorState = ref.read(directSaleProvider);
        final errorMessage = errorState.error?.toString() ?? 'خطأ غير معروف';
        print('❌ فشل البيع: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء الفاتورة: $errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

/// شيت إحصائيات اليوم
class _TodayStatsSheet extends StatelessWidget {
  final DailySalesStats stats;
  final ScrollController scrollController;

  const _TodayStatsSheet({
    required this.stats,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // المقبض
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Text(
            'إحصائيات اليوم',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              _StatsCard(
                icon: Icons.receipt,
                title: 'عدد الفواتير',
                value: '${stats.invoiceCount}',
                color: AppColors.primary,
              ),
              _StatsCard(
                icon: Icons.shopping_bag,
                title: 'عدد المنتجات المباعة',
                value: '${stats.itemCount}',
                color: Colors.blue,
              ),
              _StatsCard(
                icon: Icons.attach_money,
                title: 'إجمالي المبيعات',
                value: stats.totalSales.toCurrency(),
                color: AppColors.success,
              ),
              _StatsCard(
                icon: Icons.trending_up,
                title: 'صافي الأرباح',
                value: stats.totalProfit.toCurrency(),
                color: Colors.green,
              ),
              _StatsCard(
                icon: Icons.money_off,
                title: 'إجمالي الخصومات',
                value: stats.totalDiscount.toCurrency(),
                color: AppColors.warning,
              ),
              _StatsCard(
                icon: Icons.cancel,
                title: 'الفواتير الملغاة',
                value: '${stats.cancelledCount}',
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

/// شيت فواتير اليوم
class _TodayInvoicesSheet extends StatelessWidget {
  final List<InvoiceEntity> invoices;
  final ScrollController scrollController;

  const _TodayInvoicesSheet({
    required this.invoices,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // المقبض
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فواتير اليوم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Chip(
                label: Text('${invoices.length}'),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: AppSizes.md),
                      const Text('لا توجد فواتير اليوم'),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: invoice.isCancelled
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        child: Icon(
                          invoice.isCancelled ? Icons.cancel : Icons.receipt,
                          color: invoice.isCancelled
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                      title: Text(invoice.invoiceNumber),
                      subtitle: Text(
                        '${invoice.itemCount} منتج • ${invoice.saleDate.toTime()}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            invoice.total.toCurrency(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: invoice.isCancelled
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                              decoration: invoice.isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (invoice.isCancelled)
                            const Text(
                              'ملغاة',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/sales/${invoice.id}');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
