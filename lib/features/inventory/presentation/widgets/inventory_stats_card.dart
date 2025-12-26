import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/inventory_providers.dart';

/// بطاقة إحصائيات المخزون
class InventoryStatsCard extends ConsumerWidget {
  const InventoryStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inventoryStatsProvider);

    return statsAsync.when(
      loading: () => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text('خطأ في تحميل الإحصائيات'),
        ),
      ),
      data: (stats) => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'إحصائيات المخزون',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'المستودعات',
                      '${stats.activeWarehouses}/${stats.totalWarehouses}',
                      Icons.warehouse,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'المنتجات',
                      stats.totalProducts.toString(),
                      Icons.inventory_2,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'منخفض المخزون',
                      stats.lowStockProducts.toString(),
                      Icons.warning_amber,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'نفذ من المخزون',
                      stats.outOfStockProducts.toString(),
                      Icons.error_outline,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'إجمالي الحركات',
                      stats.totalMovements.toString(),
                      Icons.swap_horiz,
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'حركات معلقة',
                      stats.pendingMovements.toString(),
                      Icons.pending_actions,
                      Colors.amber,
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
