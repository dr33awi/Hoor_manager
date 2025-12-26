import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/repositories/account_repository.dart';

/// بطاقة إحصائيات الحسابات
class AccountStatsCard extends StatelessWidget {
  final AccountStats stats;

  const AccountStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'ملخص الحسابات',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // صف الأرقام الرئيسية
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.account_tree,
                    label: 'عدد الحسابات',
                    value: '${stats.totalAccounts}',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.receipt_long,
                    label: 'القيود المرحلة',
                    value: '${stats.postedEntries}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // تفاصيل الأرصدة
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  _BalanceRow(
                    label: 'إجمالي الأصول',
                    value: stats.totalAssets,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8.h),
                  _BalanceRow(
                    label: 'إجمالي الخصوم',
                    value: stats.totalLiabilities,
                    color: Colors.red,
                  ),
                  SizedBox(height: 8.h),
                  _BalanceRow(
                    label: 'حقوق الملكية',
                    value: stats.totalEquity,
                    color: Colors.purple,
                  ),
                  Divider(height: 16.h),
                  _BalanceRow(
                    label: 'إجمالي الإيرادات',
                    value: stats.totalRevenue,
                    color: Colors.green,
                  ),
                  SizedBox(height: 8.h),
                  _BalanceRow(
                    label: 'إجمالي المصروفات',
                    value: stats.totalExpenses,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // صافي الربح / الخسارة
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (stats.totalRevenue - stats.totalExpenses) >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: (stats.totalRevenue - stats.totalExpenses) >= 0
                      ? Colors.green
                      : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        (stats.totalRevenue - stats.totalExpenses) >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: (stats.totalRevenue - stats.totalExpenses) >= 0
                            ? Colors.green
                            : Colors.red,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        (stats.totalRevenue - stats.totalExpenses) >= 0
                            ? 'صافي الربح'
                            : 'صافي الخسارة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: (stats.totalRevenue - stats.totalExpenses) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(stats.totalRevenue - stats.totalExpenses).abs().toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: (stats.totalRevenue - stats.totalExpenses) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(left: 4.w, right: 4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          '${value.toStringAsFixed(2)} ر.س',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
