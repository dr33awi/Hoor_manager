import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

class ProductsReportScreen extends ConsumerStatefulWidget {
  final DateTimeRange? dateRange;

  const ProductsReportScreen({super.key, this.dateRange});

  @override
  ConsumerState<ProductsReportScreen> createState() =>
      _ProductsReportScreenState();
}

class _ProductsReportScreenState extends ConsumerState<ProductsReportScreen> {
  final _db = getIt<AppDatabase>();

  late DateTimeRange _dateRange;
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
    _loadData();
  }

  Future<void> _loadData() async {
    final topProducts = await _db.getTopSellingProducts(
      _dateRange.start,
      _dateRange.end,
      20,
    );

    setState(() {
      _topProducts = topProducts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المنتجات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Range
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Summary
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'المنتجات المباعة',
                          value: '${_topProducts.length}',
                          icon: Icons.inventory_2,
                          color: AppColors.products,
                        ),
                      ),
                      Gap(8.w),
                      Expanded(
                        child: _SummaryCard(
                          title: 'إجمالي الكميات',
                          value:
                              '${_topProducts.fold(0, (sum, p) => sum + ((p['quantity'] as num?)?.toInt() ?? 0))}',
                          icon: Icons.numbers,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(16.h),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Text(
                        'المنتجات الأكثر مبيعاً',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(8.h),

                // Products List
                Expanded(
                  child: _topProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 64.sp,
                                color: Colors.grey,
                              ),
                              Gap(16.h),
                              Text(
                                'لا توجد مبيعات في هذه الفترة',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: _topProducts.length,
                          itemBuilder: (context, index) {
                            final product = _topProducts[index];
                            return _ProductCard(
                              rank: index + 1,
                              name: product['name'] ?? 'غير معروف',
                              quantity:
                                  (product['quantity'] as num?)?.toInt() ?? 0,
                              total:
                                  (product['total'] as num?)?.toDouble() ?? 0,
                              maxQuantity:
                                  (_topProducts.first['quantity'] as num?)
                                          ?.toInt() ??
                                      1,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _isLoading = true;
      });
      _loadData();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            Gap(8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int rank;
  final String name;
  final int quantity;
  final double total;
  final int maxQuantity;

  const _ProductCard({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.total,
    required this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxQuantity > 0 ? quantity / maxQuantity : 0.0;

    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade300;
    } else {
      rankColor = AppColors.textSecondary;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(4.h),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    color: AppColors.primary,
                  ),
                  Gap(4.h),
                  Text(
                    'الكمية المباعة: $quantity',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Gap(12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'ر.س',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
