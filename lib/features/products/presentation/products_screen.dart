import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _productRepo = getIt<ProductRepository>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            icon: Icon(_showLowStock ? Icons.warning : Icons.warning_outlined),
            color: _showLowStock ? AppColors.lowStock : null,
            onPressed: () => setState(() => _showLowStock = !_showLowStock),
            tooltip: 'نقص المخزون',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportProducts,
            tooltip: 'تصدير',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productRepo.watchActiveProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                var products = snapshot.data ?? [];

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  products = products
                      .where((p) =>
                          p.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          (p.sku
                                  ?.toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ??
                              false) ||
                          (p.barcode?.contains(_searchQuery) ?? false))
                      .toList();
                }

                // Filter by low stock
                if (_showLowStock) {
                  products = products
                      .where((p) => p.quantity <= p.minQuantity)
                      .toList();
                }

                // Filter by category
                if (_selectedCategory != null) {
                  products = products
                      .where((p) => p.categoryId == _selectedCategory)
                      .toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          _searchQuery.isNotEmpty || _showLowStock
                              ? 'لا توجد نتائج'
                              : 'لا توجد منتجات',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => context.push('/products/${product.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
    );
  }

  void _showPriceUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الأسعار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('تعديل أسعار البيع'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to bulk price edit
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('تعديل أسعار الشراء'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to bulk purchase price edit
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportProducts() async {
    final products = await _productRepo.getAllProducts();

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد منتجات للتصدير')),
      );
      return;
    }

    // تحميل الخط العربي
    final arabicFont = await PdfGoogleFonts.cairoBold();
    final arabicFontRegular = await PdfGoogleFonts.cairoRegular();

    final pdf = pw.Document();

    // تقسيم المنتجات إلى صفحات (25 منتج لكل صفحة)
    const productsPerPage = 25;
    final totalPages = (products.length / productsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * productsPerPage;
      final endIndex = (startIndex + productsPerPage > products.length)
          ? products.length
          : startIndex + productsPerPage;
      final pageProducts = products.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // العنوان
                pw.Center(
                  child: pw.Text(
                    'قائمة المنتجات',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 24,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'إجمالي المنتجات: ${products.length}',
                    style: pw.TextStyle(
                      font: arabicFontRegular,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                // الجدول
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellStyle: pw.TextStyle(
                    font: arabicFontRegular,
                    fontSize: 9,
                  ),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  headers: [
                    'الكمية',
                    'سعر البيع',
                    'سعر الشراء',
                    'الباركود',
                    'اسم المنتج',
                    '#',
                  ],
                  data: pageProducts.asMap().entries.map((entry) {
                    final index = startIndex + entry.key + 1;
                    final p = entry.value;
                    return [
                      '${p.quantity}',
                      '${p.salePrice.toStringAsFixed(0)}',
                      '${p.purchasePrice.toStringAsFixed(0)}',
                      p.barcode ?? '-',
                      p.name,
                      '$index',
                    ];
                  }).toList(),
                ),
                pw.Spacer(),
                // رقم الصفحة
                pw.Center(
                  child: pw.Text(
                    'صفحة ${page + 1} من $totalPages',
                    style: pw.TextStyle(
                      font: arabicFontRegular,
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // طباعة أو مشاركة الملف
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'products_list.pdf',
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.quantity <= product.minQuantity;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Product Image/Icon
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2,
                            color: AppColors.primary,
                            size: 28.sp,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        color: AppColors.primary,
                        size: 28.sp,
                      ),
              ),
              Gap(12.w),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.sku != null) ...[
                      Gap(2.h),
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    Gap(4.h),
                    Row(
                      children: [
                        Text(
                          '${product.salePrice.toStringAsFixed(2)} ل.س',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Gap(16.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? AppColors.lowStock.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'المخزون: ${product.quantity}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isLowStock
                                  ? AppColors.lowStock
                                  : AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
