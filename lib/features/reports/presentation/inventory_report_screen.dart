import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:printing/printing.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/export/export_services.dart';
import '../../../core/widgets/invoice_widgets.dart';
import '../../../data/database/app_database.dart';

class InventoryReportScreen extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const InventoryReportScreen({super.key, this.dateRange});

  @override
  ConsumerState<InventoryReportScreen> createState() =>
      _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  final _db = getIt<AppDatabase>();
  bool _isExporting = false;

  Future<void> _handleExport(ExportType type) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final products = await _db.getAllProducts();
      final soldQuantities = await _db.getProductSoldQuantities();

      String? filePath;

      switch (type) {
        case ExportType.excel:
          filePath = await ExcelExportService.exportInventoryReport(
            products: products,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تصدير التقرير بنجاح'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'مشاركة',
                  textColor: Colors.white,
                  onPressed: () => ExcelExportService.shareFile(filePath!),
                ),
              ),
            );
          }
          break;

        case ExportType.pdf:
          final pdfBytes = await PdfExportService.generateInventoryReport(
            products: products,
            soldQuantities: soldQuantities,
          );
          await Printing.layoutPdf(
            onLayout: (format) async => pdfBytes,
            name: 'inventory_report.pdf',
          );
          break;

        case ExportType.sharePdf:
          final pdfBytes = await PdfExportService.generateInventoryReport(
            products: products,
            soldQuantities: soldQuantities,
          );
          await Printing.sharePdf(
              bytes: pdfBytes, filename: 'inventory_report.pdf');
          break;

        case ExportType.shareExcel:
          filePath = await ExcelExportService.exportInventoryReport(
            products: products,
          );
          await ExcelExportService.shareFile(filePath);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المخزون'),
        actions: [
          ExportMenuButton(
            onExport: _handleExport,
            isLoading: _isExporting,
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _db.watchAllProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data!;
          final lowStockProducts = allProducts
              .where((p) => p.quantity > 0 && p.quantity <= p.minQuantity)
              .toList();
          final outOfStockProducts =
              allProducts.where((p) => p.quantity <= 0).toList();

          // Calculate inventory value
          double totalCost = 0;
          double totalSale = 0;
          for (final product in allProducts) {
            totalCost += product.purchasePrice * product.quantity;
            totalSale += product.salePrice * product.quantity;
          }

          final inventoryValue = {
            'totalCost': totalCost,
            'totalSale': totalSale,
            'potentialProfit': totalSale - totalCost,
          };

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Inventory Value Summary
              Text(
                'قيمة المخزون',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: _ValueCard(
                      title: 'قيمة التكلفة',
                      value: inventoryValue['totalCost'] ?? 0,
                      color: AppColors.primary,
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: _ValueCard(
                      title: 'قيمة البيع',
                      value: inventoryValue['totalSale'] ?? 0,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              Card(
                color: AppColors.success.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الربح المتوقع',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatPrice((inventoryValue['potentialProfit'] ?? 0)
                            .toDouble()),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap(24.h),

              // Stock Status
              Text(
                'حالة المخزون',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      title: 'إجمالي المنتجات',
                      count: allProducts.length,
                      icon: Icons.inventory_2,
                      color: AppColors.primary,
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: _StatusCard(
                      title: 'نقص مخزون',
                      count: lowStockProducts.length,
                      icon: Icons.warning,
                      color: AppColors.warning,
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: _StatusCard(
                      title: 'نفذ المخزون',
                      count: outOfStockProducts.length,
                      icon: Icons.error,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              Gap(24.h),

              // Out of Stock Products
              if (outOfStockProducts.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'منتجات نفذت',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      '${outOfStockProducts.length} منتج',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Gap(8.h),
                ...outOfStockProducts.take(5).map((p) => _ProductItem(
                      product: p,
                      color: AppColors.error,
                    )),
                Gap(16.h),
              ],

              // Low Stock Products
              if (lowStockProducts.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'منتجات تحتاج إعادة طلب',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      '${lowStockProducts.length} منتج',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Gap(8.h),
                ...lowStockProducts.take(10).map((p) => _ProductItem(
                      product: p,
                      color: AppColors.warning,
                    )),
              ],

              // All Products Table
              Gap(24.h),
              Text(
                'جميع المنتجات',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(12.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('المنتج')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('الحد الأدنى')),
                    DataColumn(label: Text('التكلفة')),
                    DataColumn(label: Text('سعر البيع')),
                    DataColumn(label: Text('قيمة المخزون')),
                  ],
                  rows: allProducts
                      .take(50)
                      .map((p) => DataRow(
                            cells: [
                              DataCell(Text(p.name)),
                              DataCell(Text(
                                '${p.quantity}',
                                style: TextStyle(
                                  color: p.quantity <= 0
                                      ? AppColors.error
                                      : p.quantity <= p.minQuantity
                                          ? AppColors.warning
                                          : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                              DataCell(Text('${p.minQuantity}')),
                              DataCell(Text(formatPrice(p.purchasePrice,
                                  showCurrency: false))),
                              DataCell(Text(formatPrice(p.salePrice,
                                  showCurrency: false))),
                              DataCell(Text(formatPrice(
                                  p.salePrice * p.quantity,
                                  showCurrency: false))),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _ValueCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Gap(8.h),
            Text(
              formatPrice(value),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            Gap(8.h),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final Product product;
  final Color color;

  const _ProductItem({required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 4.h),
      child: ListTile(
        leading: Icon(Icons.inventory_2, color: color),
        title: Text(product.name),
        subtitle: Text(
            'الكمية: ${product.quantity} | الحد الأدنى: ${product.minQuantity}'),
        trailing: Text(
          formatPrice(product.salePrice),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
