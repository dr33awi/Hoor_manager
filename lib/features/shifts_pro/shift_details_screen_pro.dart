// ═══════════════════════════════════════════════════════════════════════════
// Shift Details Screen Pro - Professional Design System
// Modern Shift Details View with Complete Summary
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class ShiftDetailsScreenPro extends ConsumerStatefulWidget {
  final String shiftId;

  const ShiftDetailsScreenPro({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftDetailsScreenPro> createState() =>
      _ShiftDetailsScreenProState();
}

class _ShiftDetailsScreenProState extends ConsumerState<ShiftDetailsScreenPro> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final shiftRepo = ref.read(shiftRepositoryProvider);
      final summary = await shiftRepo.getShiftSummary(widget.shiftId);
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
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_summary == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildSimpleHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64.sp, color: AppColors.textSecondary),
                      SizedBox(height: AppSpacing.md),
                      Text('الوردية غير موجودة',
                          style: AppTypography.titleMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shift = _summary!['shift'] as Shift;
    final movements = _summary!['movements'] as List<CashMovement>;
    final isOpen = shift.status == 'open';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(shift, isOpen),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  _buildStatsGrid(),
                  SizedBox(height: AppSpacing.md),

                  // Financial Summary
                  _buildFinancialSummary(shift),
                  SizedBox(height: AppSpacing.md),

                  // Closing Info (if closed)
                  if (!isOpen) ...[
                    _buildClosingInfo(shift),
                    SizedBox(height: AppSpacing.md),
                  ],

                  // Cash Movements
                  _buildMovementsSection(movements),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
          ),
          Text('تفاصيل الوردية', style: AppTypography.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildAppBar(Shift shift, bool isOpen) {
    final statusColor = isOpen ? AppColors.success : AppColors.textSecondary;

    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
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
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        isOpen ? 'مفتوحة' : 'مغلقة',
                        style: AppTypography.labelMedium
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),

                // Shift Number
                Text(
                  shift.shiftNumber,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),

                // Date
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'ar').format(shift.openedAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),

                // Time Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeChip(
                      icon: Icons.login_rounded,
                      label: 'فتح',
                      time: DateFormat('HH:mm').format(shift.openedAt),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    if (shift.closedAt != null)
                      _buildTimeChip(
                        icon: Icons.logout_rounded,
                        label: 'إغلاق',
                        time: DateFormat('HH:mm').format(shift.closedAt!),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
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
        horizontal: AppSpacing.sm,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            '$label: $time',
            style: AppTypography.labelSmall.copyWith(color: Colors.white),
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
            value: '${_summary!['salesCount'] ?? 0}',
            color: AppColors.success,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_return_rounded,
            label: 'المرتجعات',
            value: '${_summary!['returnsCount'] ?? 0}',
            color: AppColors.error,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            icon: Icons.swap_horiz_rounded,
            label: 'الحركات',
            value: '${(_summary!['movements'] as List).length}',
            color: AppColors.info,
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
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Shift shift) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.primary, size: 20.sp),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'الملخص المالي',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildFinancialRow(
            label: 'الرصيد الافتتاحي',
            value: shift.openingBalance,
            icon: Icons.account_balance_rounded,
            color: AppColors.primary,
          ),
          Divider(color: AppColors.border, height: AppSpacing.md),
          _buildFinancialRow(
            label: 'إجمالي المبيعات',
            value: shift.totalSales,
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            showPlus: true,
          ),
          _buildFinancialRow(
            label: 'إجمالي المرتجعات',
            value: shift.totalReturns,
            icon: Icons.trending_down_rounded,
            color: AppColors.error,
            showMinus: true,
          ),
          _buildFinancialRow(
            label: 'الإيرادات الأخرى',
            value: shift.totalIncome,
            icon: Icons.add_circle_rounded,
            color: AppColors.success,
            showPlus: true,
          ),
          _buildFinancialRow(
            label: 'المصروفات',
            value: shift.totalExpenses,
            icon: Icons.remove_circle_rounded,
            color: AppColors.error,
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Text(
            '$prefix${_formatPrice(value)}',
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingInfo(Shift shift) {
    final difference = shift.difference ?? 0;
    final isPositive = difference >= 0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20.sp),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'معلومات الإغلاق',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildClosingItem(
                  label: 'المتوقع',
                  value: shift.expectedBalance ?? 0,
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildClosingItem(
                  label: 'الفعلي',
                  value: shift.closingBalance ?? 0,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 20.sp,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'الفرق: ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  '${isPositive && difference > 0 ? '+' : ''}${_formatPrice(difference)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
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
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatPrice(value),
            style: AppTypography.titleMedium.copyWith(
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.swap_vert_rounded,
                      color: AppColors.secondary, size: 20.sp),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'حركات الصندوق',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${movements.length} حركة',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (movements.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48.sp, color: AppColors.textSecondary),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'لا توجد حركات',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Divider(color: AppColors.border, height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.take(20).length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppColors.border, height: 1),
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
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 18.sp,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('HH:mm').format(movement.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatPrice(movement.amount)}',
            style: AppTypography.titleSmall.copyWith(
              color: isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
