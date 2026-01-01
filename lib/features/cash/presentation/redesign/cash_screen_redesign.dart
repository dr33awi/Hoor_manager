import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/shift_repository.dart';
import '../../../../data/repositories/cash_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Cash Screen - Modern Redesign
/// Professional Cash Drawer Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class CashScreenRedesign extends ConsumerStatefulWidget {
  const CashScreenRedesign({super.key});

  @override
  ConsumerState<CashScreenRedesign> createState() => _CashScreenRedesignState();
}

class _CashScreenRedesignState extends ConsumerState<CashScreenRedesign> {
  final _shiftRepo = getIt<ShiftRepository>();
  final _cashRepo = getIt<CashRepository>();
  final _currencyService = getIt<CurrencyService>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'deposit';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: StreamBuilder<Shift?>(
          stream: _shiftRepo.watchOpenShift(),
          builder: (context, shiftSnapshot) {
            final openShift = shiftSnapshot.data;

            if (openShift == null) {
              return _NoOpenShiftView(
                onOpenShift: () => context.go('/shifts'),
              );
            }

            return _CashScreenBody(
              shift: openShift,
              cashRepo: _cashRepo,
              currencyService: _currencyService,
              onAddMovement: _showAddMovementSheet,
            );
          },
        ),
      ),
    );
  }

  void _showAddMovementSheet(Shift shift) {
    _amountController.clear();
    _noteController.clear();
    _selectedType = 'deposit';

    HoorBottomSheet.show(
      context,
      title: 'حركة صندوق جديدة',
      showCloseButton: true,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movement Type Selection
                Text(
                  'نوع الحركة',
                  style: HoorTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Row(
                  children: [
                    Expanded(
                      child: _TypeToggleButton(
                        label: 'إيداع',
                        icon: Icons.add_circle_rounded,
                        isSelected: _selectedType == 'deposit',
                        color: HoorColors.income,
                        onTap: () =>
                            setSheetState(() => _selectedType = 'deposit'),
                      ),
                    ),
                    SizedBox(width: HoorSpacing.md.w),
                    Expanded(
                      child: _TypeToggleButton(
                        label: 'سحب',
                        icon: Icons.remove_circle_rounded,
                        isSelected: _selectedType == 'withdrawal',
                        color: HoorColors.expense,
                        onTap: () =>
                            setSheetState(() => _selectedType = 'withdrawal'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HoorSpacing.lg.h),

                // Amount Field
                HoorTextField(
                  controller: _amountController,
                  label: 'المبلغ',
                  hint: 'أدخل المبلغ',
                  prefixIcon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: HoorSpacing.md.h),

                // Note Field
                HoorTextField(
                  controller: _noteController,
                  label: 'ملاحظة (اختياري)',
                  hint: 'أدخل ملاحظة',
                  prefixIcon: Icons.note_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: HoorSpacing.xl.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveCashMovement(shift),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'deposit'
                          ? HoorColors.income
                          : HoorColors.expense,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                    child: Text(
                      _selectedType == 'deposit' ? 'إيداع' : 'سحب',
                      style: HoorTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveCashMovement(Shift shift) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال مبلغ صحيح'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (_selectedType == 'deposit') {
        await _cashRepo.addIncome(
          shiftId: shift.id,
          amount: amount,
          description:
              _noteController.text.isNotEmpty ? _noteController.text : 'إيداع',
        );
      } else {
        await _cashRepo.addExpense(
          shiftId: shift.id,
          amount: amount,
          description:
              _noteController.text.isNotEmpty ? _noteController.text : 'سحب',
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedType == 'deposit'
                  ? 'تم الإيداع بنجاح'
                  : 'تم السحب بنجاح',
            ),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Cash Screen Body Widget
/// ═══════════════════════════════════════════════════════════════════════════

class _CashScreenBody extends StatelessWidget {
  final Shift shift;
  final CashRepository cashRepo;
  final CurrencyService currencyService;
  final void Function(Shift) onAddMovement;

  const _CashScreenBody({
    required this.shift,
    required this.cashRepo,
    required this.currencyService,
    required this.onAddMovement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
            children: [
              // Balance Hero Card
              _buildBalanceCard(),
              SizedBox(height: HoorSpacing.xl.h),

              // Quick Actions
              _buildQuickActions(),
              SizedBox(height: HoorSpacing.xl.h),

              // Movements History
              HoorDecoratedHeader(
                title: 'حركات الصندوق',
                icon: Icons.receipt_long_rounded,
              ),
              SizedBox(height: HoorSpacing.md.h),
              _buildMovementsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Text(
              'الصندوق',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          HoorBadge(
            label: 'وردية مفتوحة',
            color: HoorColors.income,
            size: HoorBadgeSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<Map<String, double>>(
      stream: cashRepo.watchShiftCashSummary(shift.id),
      builder: (context, snapshot) {
        final summary = snapshot.data ?? {};
        final balance = shift.openingBalance + (summary['netCash'] ?? 0);

        return Container(
          padding: EdgeInsets.all(HoorSpacing.xl.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HoorColors.primary,
                HoorColors.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(HoorRadius.xl),
            boxShadow: [
              BoxShadow(
                color: HoorColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: HoorIconSize.xxl,
              ),
              SizedBox(height: HoorSpacing.md.h),
              Text(
                'الرصيد الحالي',
                style: HoorTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: HoorSpacing.xs.h),
              Text(
                currencyService.formatSyp(balance),
                style: HoorTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBM Plex Sans Arabic',
                ),
              ),
              SizedBox(height: HoorSpacing.lg.h),
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BalanceStat(
                      label: 'الافتتاحي',
                      value: currencyService.formatSyp(shift.openingBalance),
                      icon: Icons.play_arrow_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40.h,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _BalanceStat(
                      label: 'المبيعات',
                      value: currencyService.formatSyp(shift.totalSales),
                      icon: Icons.trending_up_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40.h,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _BalanceStat(
                      label: 'المصاريف',
                      value: currencyService.formatSyp(shift.totalExpenses),
                      icon: Icons.trending_down_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'إيداع',
            icon: Icons.add_circle_rounded,
            color: HoorColors.income,
            onTap: () => onAddMovement(shift),
          ),
        ),
        SizedBox(width: HoorSpacing.md.w),
        Expanded(
          child: _ActionButton(
            label: 'سحب',
            icon: Icons.remove_circle_rounded,
            color: HoorColors.expense,
            onTap: () => onAddMovement(shift),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsList() {
    return StreamBuilder<List<CashMovement>>(
      stream: cashRepo.watchMovementsByShift(shift.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return Container(
            padding: EdgeInsets.all(HoorSpacing.xl.w),
            decoration: BoxDecoration(
              color: HoorColors.surface,
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              border:
                  Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  color: HoorColors.textTertiary,
                  size: HoorIconSize.xxl,
                ),
                SizedBox(height: HoorSpacing.md.h),
                Text(
                  'لا توجد حركات',
                  style: HoorTypography.titleMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
                SizedBox(height: HoorSpacing.xs.h),
                Text(
                  'ستظهر هنا حركات الإيداع والسحب',
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: movements.length,
          separatorBuilder: (_, __) => SizedBox(height: HoorSpacing.sm.h),
          itemBuilder: (context, index) {
            return _MovementCard(
              movement: movements[index],
              currencyService: currencyService,
            );
          },
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _NoOpenShiftView extends StatelessWidget {
  final VoidCallback onOpenShift;

  const _NoOpenShiftView({required this.onOpenShift});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(HoorSpacing.xl.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xl.w),
            decoration: BoxDecoration(
              color: HoorColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: HoorColors.warning,
              size: 64.sp,
            ),
          ),
          SizedBox(height: HoorSpacing.xl.h),
          Text(
            'لا توجد وردية مفتوحة',
            style: HoorTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Text(
            'يجب فتح وردية أولاً للوصول إلى الصندوق',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: HoorSpacing.xl.h),
          ElevatedButton.icon(
            onPressed: onOpenShift,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('فتح وردية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.xl.w,
                vertical: HoorSpacing.md.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            color: Colors.white.withValues(alpha: 0.7), size: HoorIconSize.sm),
        SizedBox(height: HoorSpacing.xxs.h),
        Text(
          label,
          style: HoorTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: HoorSpacing.xxs.h),
        Text(
          value,
          style: HoorTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBM Plex Sans Arabic',
          ),
        ),
      ],
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(
              color: isSelected ? color : HoorColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : HoorColors.textSecondary,
                size: HoorIconSize.md,
              ),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                label,
                style: HoorTypography.labelLarge.copyWith(
                  color: isSelected ? color : HoorColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.lg.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: HoorIconSize.lg),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                label,
                style: HoorTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final CashMovement movement;
  final CurrencyService currencyService;

  const _MovementCard({
    required this.movement,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = movement.type == 'deposit';

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              color: isDeposit
                  ? HoorColors.income.withValues(alpha: 0.1)
                  : HoorColors.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(
              isDeposit
                  ? Icons.add_circle_rounded
                  : Icons.remove_circle_rounded,
              color: isDeposit ? HoorColors.income : HoorColors.expense,
              size: HoorIconSize.lg,
            ),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'إيداع' : 'سحب',
                  style: HoorTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (movement.description.isNotEmpty) ...[
                  SizedBox(height: HoorSpacing.xxs.h),
                  Text(
                    movement.description,
                    style: HoorTypography.bodySmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: HoorSpacing.xxs.h),
                Text(
                  DateFormat('HH:mm - dd/MM').format(movement.createdAt),
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}${currencyService.formatSyp(movement.amount)}',
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDeposit ? HoorColors.income : HoorColors.expense,
              fontFamily: 'IBM Plex Sans Arabic',
            ),
          ),
        ],
      ),
    );
  }
}
