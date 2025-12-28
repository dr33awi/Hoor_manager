import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';

class InventoryReportScreen extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const InventoryReportScreen({super.key, this.dateRange});

  @override
  ConsumerState<InventoryReportScreen> createState() =>
      _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  final _productRepo = getIt<ProductRepository>();

  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  Map<String, double> _inventoryValue = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allProducts = await _productRepo.getAllProducts();
    final lowStock = allProducts
        .where((p) => p.quantity > 0 && p.quantity <= p.minQuantity)
        .toList();
    final outOfStock = allProducts.where((p) => p.quantity <= 0).toList();

    // Calculate inventory value
    double totalCost = 0;
    double totalSale = 0;
    for (final product in allProducts) {
      totalCost += product.purchasePrice * product.quantity;
      totalSale += product.salePrice * product.quantity;
    }

    setState(() {
      _allProducts = allProducts;
      _lowStockProducts = lowStock;
      _outOfStockProducts = outOfStock;
      _inventoryValue = {
        'totalCost': totalCost,
        'totalSale': totalSale,
        'potentialProfit': totalSale - totalCost,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المخزون'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        value: _inventoryValue['totalCost'] ?? 0,
                        color: AppColors.primary,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _ValueCard(
                        title: 'قيمة البيع',
                        value: _inventoryValue['totalSale'] ?? 0,
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
                          '${(_inventoryValue['potentialProfit'] ?? 0).toStringAsFixed(2)} ر.س',
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
                        count: _allProducts.length,
                        icon: Icons.inventory_2,
                        color: AppColors.primary,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatusCard(
                        title: 'نقص مخزون',
                        count: _lowStockProducts.length,
                        icon: Icons.warning,
                        color: AppColors.warning,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatusCard(
                        title: 'نفذ المخزون',
                        count: _outOfStockProducts.length,
                        icon: Icons.error,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Gap(24.h),

                // Out of Stock Products
                if (_outOfStockProducts.isNotEmpty) ...[
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
                        '${_outOfStockProducts.length} منتج',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Gap(8.h),
                  ..._outOfStockProducts.take(5).map((p) => _ProductItem(
                        product: p,
                        color: AppColors.error,
                      )),
                  Gap(16.h),
                ],

                // Low Stock Products
                if (_lowStockProducts.isNotEmpty) ...[
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
                        '${_lowStockProducts.length} منتج',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Gap(8.h),
                  ..._lowStockProducts.take(10).map((p) => _ProductItem(
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
                    rows: _allProducts
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
                                DataCell(Text(
                                    '${p.purchasePrice.toStringAsFixed(2)}')),
                                DataCell(
                                    Text('${p.salePrice.toStringAsFixed(2)}')),
                                DataCell(Text(
                                    '${(p.salePrice * p.quantity).toStringAsFixed(2)}')),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
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
              '${value.toStringAsFixed(2)} ر.س',
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
          '${product.salePrice.toStringAsFixed(2)} ر.س',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
