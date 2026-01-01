import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/export/export_services.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/category_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Products Screen - Modern Redesign
/// Professional Product Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class ProductsScreenRedesign extends ConsumerStatefulWidget {
  const ProductsScreenRedesign({super.key});

  @override
  ConsumerState<ProductsScreenRedesign> createState() =>
      _ProductsScreenRedesignState();
}

class _ProductsScreenRedesignState
    extends ConsumerState<ProductsScreenRedesign> {
  final _productRepo = getIt<ProductRepository>();
  final _categoryRepo = getIt<CategoryRepository>();
  final _currencyService = getIt<CurrencyService>();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStock = false;
  _ViewMode _viewMode = _ViewMode.grid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Stats Section
            _buildStats(),

            // Search & Filters
            _buildSearchAndFilters(),

            // Category Chips
            _buildCategoryChips(),

            // Products Grid/List
            Expanded(child: _buildProductsList()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          // Back Button
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المنتجات',
                  style: HoorTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                StreamBuilder<List<Product>>(
                  stream: _productRepo.watchActiveProducts(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count منتج',
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Low Stock Filter
          _FilterButton(
            icon: Icons.warning_amber_rounded,
            isActive: _showLowStock,
            activeColor: HoorColors.warning,
            tooltip: 'نقص المخزون',
            onTap: () => setState(() => _showLowStock = !_showLowStock),
          ),
          SizedBox(width: HoorSpacing.xs.w),

          // View Mode Toggle
          _FilterButton(
            icon: _viewMode == _ViewMode.grid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            isActive: false,
            tooltip: 'تغيير العرض',
            onTap: () {
              setState(() {
                _viewMode = _viewMode == _ViewMode.grid
                    ? _ViewMode.list
                    : _ViewMode.grid;
              });
            },
          ),
          SizedBox(width: HoorSpacing.xs.w),

          // Export Button
          _IconButton(
            icon: Icons.file_download_outlined,
            onTap: () => _showExportOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<List<Product>>(
      stream: _productRepo.watchActiveProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 100.h,
            child:
                const Center(child: HoorLoading(size: HoorLoadingSize.small)),
          );
        }

        final products = snapshot.data!;
        final totalProducts = products.length;
        final lowStockCount =
            products.where((p) => p.quantity <= p.minQuantity).length;
        final totalValue = products.fold<double>(
          0,
          (sum, p) => sum + (p.salePrice * p.quantity),
        );

        return Container(
          margin: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          child: Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'إجمالي المنتجات',
                  value: totalProducts.toString(),
                  color: HoorColors.primary,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'نقص مخزون',
                  value: lowStockCount.toString(),
                  color: lowStockCount > 0
                      ? HoorColors.warning
                      : HoorColors.success,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'قيمة المخزون',
                  value: _formatCurrency(totalValue),
                  color: HoorColors.income,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث عن منتج بالاسم أو الباركود...',
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: _searchQuery.isNotEmpty
            ? () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }
            : null,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return StreamBuilder<List<Category>>(
      stream: _categoryRepo.watchAllCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        return SizedBox(
          height: 44.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 for "All" chip
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" chip
                final isSelected = _selectedCategory == null;
                return Padding(
                  padding: EdgeInsets.only(left: HoorSpacing.xs.w),
                  child: _CategoryChip(
                    label: 'الكل',
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                );
              }

              final category = categories[index - 1];
              final isSelected = _selectedCategory == category.id;
              return Padding(
                padding: EdgeInsets.only(left: HoorSpacing.xs.w),
                child: _CategoryChip(
                  label: category.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCategory = category.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    return StreamBuilder<List<Product>>(
      stream: _productRepo.watchActiveProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: HoorLoading(
              size: HoorLoadingSize.large,
              message: 'جاري تحميل المنتجات...',
            ),
          );
        }

        var products = snapshot.data ?? [];

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                      false) ||
                  (p.barcode?.contains(_searchQuery) ?? false))
              .toList();
        }

        if (_showLowStock) {
          products =
              products.where((p) => p.quantity <= p.minQuantity).toList();
        }

        if (_selectedCategory != null) {
          products =
              products.where((p) => p.categoryId == _selectedCategory).toList();
        }

        if (products.isEmpty) {
          return HoorEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد منتجات',
            message: _searchQuery.isNotEmpty || _showLowStock
                ? 'لم يتم العثور على منتجات تطابق معايير البحث'
                : 'ابدأ بإضافة منتجاتك',
            actionLabel: _searchQuery.isEmpty ? 'إضافة منتج' : null,
            onAction: _searchQuery.isEmpty
                ? () => context.push('/products/new')
                : null,
          );
        }

        if (_viewMode == _ViewMode.grid) {
          return GridView.builder(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: HoorSpacing.md.h,
              crossAxisSpacing: HoorSpacing.md.w,
              childAspectRatio: 0.85,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductGridCard(
                product: product,
                currencyService: _currencyService,
                onTap: () => context.push('/products/details/${product.id}'),
              );
            },
          );
        } else {
          return ListView.separated(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: HoorSpacing.sm.h),
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductListCard(
                product: product,
                currencyService: _currencyService,
                onTap: () => context.push('/products/details/${product.id}'),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/products/new'),
      backgroundColor: HoorColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'منتج جديد',
        style: HoorTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    HoorActionSheet.show(
      context,
      title: 'تصدير المنتجات',
      message: 'اختر صيغة التصدير',
      actions: [
        HoorActionSheetItem(
          label: 'تصدير كملف Excel',
          icon: Icons.table_chart_rounded,
          onTap: () => _handleExport(ExportType.excel),
        ),
        HoorActionSheetItem(
          label: 'تصدير كملف PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () => _handleExport(ExportType.pdf),
        ),
        HoorActionSheetItem(
          label: 'مشاركة',
          icon: Icons.share_rounded,
          onTap: () => _handleExport(ExportType.shareExcel),
        ),
      ],
    );
  }

  Future<void> _handleExport(ExportType exportType) async {
    var products = await _productRepo.getAllProducts();
    products = products.where((p) => p.isActive).toList();

    if (_searchQuery.isNotEmpty) {
      products = products
          .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_showLowStock) {
      products = products.where((p) => p.quantity <= p.minQuantity).toList();
    }

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لا توجد منتجات للتصدير'),
            backgroundColor: HoorColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
      return;
    }

    try {
      switch (exportType) {
        case ExportType.excel:
          await ExcelExportService.exportProducts(
            products: products,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تصدير المنتجات بنجاح'),
                backgroundColor: HoorColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
              ),
            );
          }
          break;

        case ExportType.pdf:
          final pdfBytes = await PdfExportService.generateProductsList(
            products: products,
          );
          await Printing.layoutPdf(
            onLayout: (format) async => pdfBytes,
            name: 'products_list.pdf',
          );
          break;

        case ExportType.shareExcel:
          final filePath = await ExcelExportService.exportProducts(
            products: products,
          );
          await ExcelExportService.shareFile(filePath);
          break;

        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

enum _ViewMode { grid, list }

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.isActive,
    this.activeColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? HoorColors.primary)
        : HoorColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? color.withValues(alpha: 0.1) : HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              border: Border.all(
                color: isActive ? color : HoorColors.border,
              ),
            ),
            child: Icon(icon, size: HoorIconSize.md, color: color),
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: HoorIconSize.sm, color: color),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            value,
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'IBM Plex Sans Arabic',
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.lg.w,
          vertical: HoorSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? HoorColors.primary : HoorColors.surface,
          borderRadius: BorderRadius.circular(HoorRadius.full),
          border: isSelected ? null : Border.all(color: HoorColors.border),
        ),
        child: Text(
          label,
          style: HoorTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : HoorColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _ProductGridCard({
    required this.product,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= product.minQuantity;

    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(
              color: isLowStock
                  ? HoorColors.warning.withValues(alpha: 0.5)
                  : HoorColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: HoorColors.primarySoft,
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(HoorRadius.md),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              SizedBox(height: HoorSpacing.sm.h),

              // Product Name
              Text(
                product.name,
                style: HoorTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: HoorSpacing.xxs.h),

              // Price
              Text(
                '${product.salePrice.toStringAsFixed(2)} ر.س',
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBM Plex Sans Arabic',
                ),
              ),
              SizedBox(height: HoorSpacing.xs.h),

              // Stock Status
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color:
                          isLowStock ? HoorColors.warning : HoorColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: HoorSpacing.xxs.w),
                  Expanded(
                    child: Text(
                      '${product.quantity} قطعة',
                      style: HoorTypography.labelSmall.copyWith(
                        color: isLowStock
                            ? HoorColors.warning
                            : HoorColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: HoorIconSize.xxl,
        color: HoorColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final Product product;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _ProductListCard({
    required this.product,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= product.minQuantity;

    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(
              color: isLowStock
                  ? HoorColors.warning.withValues(alpha: 0.5)
                  : HoorColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: HoorColors.primarySoft,
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
              ),
              SizedBox(width: HoorSpacing.md.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: HoorSpacing.xxs.h),
                    if (product.sku != null)
                      Text(
                        'SKU: ${product.sku}',
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textTertiary,
                        ),
                      ),
                    SizedBox(height: HoorSpacing.xs.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? HoorColors.warning
                                : HoorColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: HoorSpacing.xxs.w),
                        Text(
                          '${product.quantity} قطعة',
                          style: HoorTypography.labelSmall.copyWith(
                            color: isLowStock
                                ? HoorColors.warning
                                : HoorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.salePrice.toStringAsFixed(2),
                    style: HoorTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HoorColors.primary,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                  Text(
                    'ر.س',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: HoorSpacing.xs.w),

              Icon(
                Icons.chevron_left_rounded,
                color: HoorColors.textTertiary,
                size: HoorIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: HoorIconSize.lg,
        color: HoorColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
