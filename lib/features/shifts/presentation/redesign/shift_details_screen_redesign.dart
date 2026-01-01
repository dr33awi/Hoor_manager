/// ═══════════════════════════════════════════════════════════════════════════
/// Shift Details Screen - Redesigned
/// Modern Shift Details View
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/shift_repository.dart';

class ShiftDetailsScreenRedesign extends ConsumerStatefulWidget {
  final String shiftId;

  const ShiftDetailsScreenRedesign({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftDetailsScreenRedesign> createState() =>
      _ShiftDetailsScreenRedesignState();
}

class _ShiftDetailsScreenRedesignState
    extends ConsumerState<ShiftDetailsScreenRedesign> {
  final _shiftRepo = getIt<ShiftRepository>();
  final _currencyService = getIt<CurrencyService>();

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

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل الوردية', style: HoorTypography.headlineSmall),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: HoorColors.primary)),
      );
    }

    if (_summary == null) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل الوردية', style: HoorTypography.headlineSmall),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: HoorColors.textSecondary),
              SizedBox(height: HoorSpacing.md.h),
              Text('الوردية غير موجودة', style: HoorTypography.titleMedium),
            ],
          ),
        ),
      );
    }

    final shift = _summary!['shift'] as Shift;
    final movements = _summary!['movements'] as List<CashMovement>;
    final isOpen = shift.status == 'open';

    return Scaffold(
      backgroundColor: HoorColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(shift, isOpen),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  _buildStatsGrid(),
                  SizedBox(height: HoorSpacing.md.h),

                  // Financial Summary
                  _buildFinancialSummary(shift),
                  SizedBox(height: HoorSpacing.md.h),

                  // Closing Info (if closed)
                  if (!isOpen) ...[
                    _buildClosingInfo(shift),
                    SizedBox(height: HoorSpacing.md.h),
                  ],

                  // Cash Movements
                  _buildMovementsSection(movements),
                  SizedBox(height: HoorSpacing.xl.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Shift shift, bool isOpen) {
    final statusColor = isOpen ? HoorColors.success : HoorColors.textSecondary;

    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: HoorColors.primary,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HoorColors.primary,
                HoorColors.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: HoorSpacing.md.w,
                    vertical: HoorSpacing.xs.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(HoorRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: HoorSpacing.xs.w),
                      Text(
                        isOpen ? 'مفتوحة' : 'مغلقة',
                        style: HoorTypography.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Text(
                  shift.shiftNumber,
                  style: HoorTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: HoorSpacing.xxs.h),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'ar').format(shift.openedAt),
                  style: HoorTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: HoorSpacing.xs.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeChip(
                      icon: Icons.login_rounded,
                      label: 'فتح',
                      time: DateFormat('HH:mm').format(shift.openedAt),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    if (shift.closedAt != null)
                      _buildTimeChip(
                        icon: Icons.logout_rounded,
                        label: 'إغلاق',
                        time: DateFormat('HH:mm').format(shift.closedAt!),
                      ),
                  ],
                ),
                SizedBox(height: HoorSpacing.md.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.sm.w,
        vertical: HoorSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(HoorRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(width: HoorSpacing.xxs.w),
          Text(
            '$label: $time',
            style: HoorTypography.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'المبيعات',
            value: '${_summary!['salesCount']}',
            color: HoorColors.success,
          ),
        ),
        SizedBox(width: HoorSpacing.sm.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_return_rounded,
            label: 'المرتجعات',
            value: '${_summary!['returnsCount']}',
            color: HoorColors.error,
          ),
        ),
        SizedBox(width: HoorSpacing.sm.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.swap_horiz_rounded,
            label: 'الحركات',
            value: '${(_summary!['movements'] as List).length}',
            color: HoorColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            value,
            style: HoorTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Shift shift) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'الملخص المالي',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          _buildFinancialRow(
            label: 'الرصيد الافتتاحي',
            value: shift.openingBalance,
            icon: Icons.account_balance_rounded,
            color: HoorColors.primary,
          ),
          Divider(color: HoorColors.border, height: HoorSpacing.md.h),
          _buildFinancialRow(
            label: 'إجمالي المبيعات',
            value: shift.totalSales,
            icon: Icons.trending_up_rounded,
            color: HoorColors.success,
            showPlus: true,
          ),
          _buildFinancialRow(
            label: 'إجمالي المرتجعات',
            value: shift.totalReturns,
            icon: Icons.trending_down_rounded,
            color: HoorColors.error,
            showMinus: true,
          ),
          _buildFinancialRow(
            label: 'الإيرادات الأخرى',
            value: shift.totalIncome,
            icon: Icons.add_circle_rounded,
            color: HoorColors.success,
            showPlus: true,
          ),
          _buildFinancialRow(
            label: 'المصروفات',
            value: shift.totalExpenses,
            icon: Icons.remove_circle_rounded,
            color: HoorColors.error,
            showMinus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool showPlus = false,
    bool showMinus = false,
  }) {
    String prefix = '';
    if (showPlus && value > 0) prefix = '+';
    if (showMinus && value > 0) prefix = '-';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: HoorSpacing.xs.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: HoorSpacing.sm.w),
          Expanded(
            child: Text(
              label,
              style: HoorTypography.bodyMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${_formatPrice(value)}',
                style: HoorTypography.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${_currencyService.sypToUsd(value).toStringAsFixed(2)}',
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClosingInfo(Shift shift) {
    final difference = shift.difference ?? 0;
    final isPositive = difference >= 0;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: HoorColors.success, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'معلومات الإغلاق',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Row(
            children: [
              Expanded(
                child: _buildClosingItem(
                  label: 'المتوقع',
                  value: shift.expectedBalance ?? 0,
                  color: HoorColors.info,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _buildClosingItem(
                  label: 'الفعلي',
                  value: shift.closingBalance ?? 0,
                  color: HoorColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: (isPositive ? HoorColors.success : HoorColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: isPositive ? HoorColors.success : HoorColors.error,
                  size: 20,
                ),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  'الفرق: ',
                  style: HoorTypography.bodyMedium.copyWith(
                    color: isPositive ? HoorColors.success : HoorColors.error,
                  ),
                ),
                Text(
                  '${isPositive && difference > 0 ? '+' : ''}${_formatPrice(difference)}',
                  style: HoorTypography.titleMedium.copyWith(
                    color: isPositive ? HoorColors.success : HoorColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingItem({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.xxs.h),
          Text(
            _formatPrice(value),
            style: HoorTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsSection(List<CashMovement> movements) {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Icon(Icons.swap_vert_rounded,
                    color: HoorColors.primary, size: HoorIconSize.sm),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  'حركات الصندوق',
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: HoorSpacing.sm.w,
                    vertical: HoorSpacing.xxs.h,
                  ),
                  decoration: BoxDecoration(
                    color: HoorColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.sm),
                  ),
                  child: Text(
                    '${movements.length} حركة',
                    style: HoorTypography.labelMedium.copyWith(
                      color: HoorColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (movements.isEmpty)
            Padding(
              padding: EdgeInsets.all(HoorSpacing.xl.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48, color: HoorColors.textSecondary),
                    SizedBox(height: HoorSpacing.sm.h),
                    Text(
                      'لا توجد حركات',
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Divider(color: HoorColors.border, height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.take(20).length,
              separatorBuilder: (_, __) =>
                  Divider(color: HoorColors.border, height: 1),
              itemBuilder: (context, index) {
                final movement = movements[index];
                return _buildMovementItem(movement);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementItem(CashMovement movement) {
    final isIncome = movement.type == 'income' || movement.type == 'sale';

    return Padding(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: (isIncome ? HoorColors.success : HoorColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome ? HoorColors.success : HoorColors.error,
              size: 18,
            ),
          ),
          SizedBox(width: HoorSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: HoorTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('HH:mm').format(movement.createdAt),
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatPrice(movement.amount)}',
            style: HoorTypography.titleSmall.copyWith(
              color: isIncome ? HoorColors.success : HoorColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
