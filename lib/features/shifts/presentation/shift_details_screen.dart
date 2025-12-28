import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/shift_repository.dart';

class ShiftDetailsScreen extends ConsumerStatefulWidget {
  final String shiftId;

  const ShiftDetailsScreen({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftDetailsScreen> createState() => _ShiftDetailsScreenState();
}

class _ShiftDetailsScreenState extends ConsumerState<ShiftDetailsScreen> {
  final _shiftRepo = getIt<ShiftRepository>();

  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await _shiftRepo.getShiftSummary(widget.shiftId);
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الوردية')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الوردية')),
        body: const Center(child: Text('الوردية غير موجودة')),
      );
    }

    final shift = _summary!['shift'] as Shift;
    final movements = _summary!['movements'] as List<CashMovement>;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الوردية'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Shift Info Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shift.shiftNumber,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: (shift.status == 'open'
                                  ? AppColors.success
                                  : AppColors.textSecondary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          shift.status == 'open' ? 'مفتوحة' : 'مغلقة',
                          style: TextStyle(
                            color: shift.status == 'open'
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(12.h),
                  _InfoRow(
                      label: 'وقت الفتح',
                      value: dateFormat.format(shift.openedAt)),
                  if (shift.closedAt != null)
                    _InfoRow(
                        label: 'وقت الإغلاق',
                        value: dateFormat.format(shift.closedAt!)),
                ],
              ),
            ),
          ),
          Gap(16.h),

          // Financial Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الملخص المالي',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(12.h),
                  _SummaryRow(
                    label: 'الرصيد الافتتاحي',
                    value: shift.openingBalance,
                    color: AppColors.primary,
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: 'إجمالي المبيعات',
                    value: shift.totalSales,
                    color: AppColors.success,
                    icon: Icons.trending_up,
                  ),
                  _SummaryRow(
                    label: 'إجمالي المرتجعات',
                    value: shift.totalReturns,
                    color: AppColors.error,
                    icon: Icons.trending_down,
                  ),
                  _SummaryRow(
                    label: 'الإيرادات الأخرى',
                    value: shift.totalIncome,
                    color: AppColors.success,
                    icon: Icons.add_circle,
                  ),
                  _SummaryRow(
                    label: 'المصروفات',
                    value: shift.totalExpenses,
                    color: AppColors.error,
                    icon: Icons.remove_circle,
                  ),
                  const Divider(),
                  if (shift.status == 'closed') ...[
                    _SummaryRow(
                      label: 'الرصيد المتوقع',
                      value: shift.expectedBalance ?? 0,
                      color: AppColors.primary,
                    ),
                    _SummaryRow(
                      label: 'الرصيد الختامي',
                      value: shift.closingBalance ?? 0,
                      color: AppColors.primary,
                    ),
                    _SummaryRow(
                      label: 'الفرق',
                      value: shift.difference ?? 0,
                      color: (shift.difference ?? 0) >= 0
                          ? AppColors.success
                          : AppColors.error,
                      isBold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Gap(16.h),

          // Statistics
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt,
                  label: 'عدد المبيعات',
                  value: '${_summary!['salesCount']}',
                  color: AppColors.sales,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.assignment_return,
                  label: 'عدد المرتجعات',
                  value: '${_summary!['returnsCount']}',
                  color: AppColors.returns,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.swap_horiz,
                  label: 'حركات الصندوق',
                  value: '${movements.length}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          Gap(16.h),

          // Cash Movements
          Text(
            'حركات الصندوق',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          if (movements.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Center(
                  child: Text(
                    'لا توجد حركات',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ...movements.take(20).map((m) => _MovementCard(movement: m)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20.sp, color: color),
            Gap(8.w),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16.sp : 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            Gap(8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
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

class _MovementCard extends StatelessWidget {
  final CashMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIncome = movement.type == 'income' || movement.type == 'sale';
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? AppColors.success : AppColors.error,
        ),
        title: Text(movement.description),
        subtitle: Text(timeFormat.format(movement.createdAt)),
        trailing: Text(
          '${isIncome ? '+' : '-'}${movement.amount.toStringAsFixed(2)} ر.س',
          style: TextStyle(
            color: isIncome ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
