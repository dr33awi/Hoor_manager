// ═══════════════════════════════════════════════════════════════════════════
// Shifts Screen Pro - Professional Design System
// Shift Management Interface with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';

class ShiftsScreenPro extends ConsumerWidget {
  const ShiftsScreenPro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsStreamProvider);
    final openShiftAsync = ref.watch(openShiftStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: shiftsAsync.when(
          loading: () => ProLoadingState.list(),
          error: (error, stack) => ProEmptyState.error(error: error.toString()),
          data: (shifts) {
            final openShift = openShiftAsync.asData?.value;
            return Column(
              children: [
                _buildHeader(context, shifts.length),
                if (openShift != null)
                  _buildOpenShiftBanner(context, ref, openShift),
                _buildStatsSummary(shifts),
                Expanded(child: _buildShiftsList(shifts)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: openShiftAsync.asData?.value == null
          ? FloatingActionButton.extended(
              onPressed: () => _openNewShift(context, ref),
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'فتح وردية',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, int totalShifts) {
    return ProHeader(
      title: 'الورديات',
      subtitle: '$totalShifts وردية',
      onBack: () => context.go('/'),
    );
  }

  Widget _buildOpenShiftBanner(
      BuildContext context, WidgetRef ref, Shift shift) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.soft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.border),
      ),
      child: Row(
        children: [
          ProIconBox(icon: Icons.access_time_rounded, color: AppColors.success),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وردية مفتوحة #${shift.shiftNumber}',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'منذ ${dateFormat.format(shift.openedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _closeShift(context, ref, shift),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<Shift> shifts) {
    final totalSales = shifts.fold<double>(0.0, (sum, s) => sum + s.totalSales);
    final totalExpenses =
        shifts.fold<double>(0.0, (sum, s) => sum + s.totalExpenses);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'إجمالي المبيعات',
              amount: totalSales,
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'إجمالي المصاريف',
              amount: totalExpenses,
              icon: Icons.trending_down_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsList(List<Shift> shifts) {
    if (shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 80.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد ورديات',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date descending
    final sortedShifts = List<Shift>.from(shifts)
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: sortedShifts.length,
      itemBuilder: (context, index) {
        final shift = sortedShifts[index];
        return _ShiftCard(shift: shift);
      },
    );
  }

  void _openNewShift(BuildContext context, WidgetRef ref) async {
    final confirm = await showProConfirmDialog(
      context: context,
      title: 'فتح وردية جديدة',
      message: 'هل تريد فتح وردية جديدة؟',
      icon: Icons.play_arrow_rounded,
      iconColor: AppColors.success,
      confirmText: 'فتح',
    );

    if (confirm == true && context.mounted) {
      try {
        final shiftRepo = ref.read(shiftRepositoryProvider);
        await shiftRepo.openShift(openingBalance: 0);
        if (context.mounted) {
          ProSnackbar.success(context, 'تم فتح الوردية بنجاح');
        }
      } catch (e) {
        if (context.mounted) {
          ProSnackbar.error(context, 'خطأ: $e');
        }
      }
    }
  }

  void _closeShift(BuildContext context, WidgetRef ref, Shift shift) async {
    final confirm = await showProConfirmDialog(
      context: context,
      title: 'إغلاق الوردية',
      message: 'رصيد الافتتاح: ${shift.openingBalance.toStringAsFixed(0)} ر.س\n'
          'المبيعات: ${shift.totalSales.toStringAsFixed(0)} ر.س\n'
          'المصاريف: ${shift.totalExpenses.toStringAsFixed(0)} ر.س\n\n'
          'هل تريد إغلاق الوردية؟',
      icon: Icons.stop_rounded,
      isDanger: true,
      confirmText: 'إغلاق',
    );

    if (confirm == true && context.mounted) {
      try {
        final shiftRepo = ref.read(shiftRepositoryProvider);
        final closingBalance =
            shift.openingBalance + shift.totalSales - shift.totalExpenses;
        await shiftRepo.closeShift(
          shiftId: shift.id,
          closingBalance: closingBalance,
        );
        if (context.mounted) {
          ProSnackbar.success(context, 'تم إغلاق الوردية بنجاح');
        }
      } catch (e) {
        if (context.mounted) {
          ProSnackbar.error(context, 'خطأ: $e');
        }
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppIconSize.md),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: color),
                ),
                Text(
                  '${amount.toStringAsFixed(0)} ر.س',
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrains Mono',
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

class _ShiftCard extends StatelessWidget {
  final Shift shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    final isOpen = shift.status == 'open';
    final statusColor = isOpen ? AppColors.success : AppColors.textSecondary;

    return ProCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isOpen
                      ? Icons.access_time_rounded
                      : Icons.check_circle_rounded,
                  color: statusColor,
                  size: AppIconSize.sm,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${shift.shiftNumber}',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        ProStatusBadge.fromShiftStatus(shift.status,
                            small: true),
                      ],
                    ),
                    Text(
                      dateFormat.format(shift.openedAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'الافتتاح',
                  value: '${shift.openingBalance.toStringAsFixed(0)} ر.س',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'المبيعات',
                  value: '${shift.totalSales.toStringAsFixed(0)} ر.س',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'المصاريف',
                  value: '${shift.totalExpenses.toStringAsFixed(0)} ر.س',
                  color: AppColors.error,
                ),
              ),
              if (!isOpen && shift.closingBalance != null)
                Expanded(
                  child: _InfoItem(
                    label: 'الإغلاق',
                    value: '${shift.closingBalance!.toStringAsFixed(0)} ر.س',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: color ?? AppColors.textPrimary,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
