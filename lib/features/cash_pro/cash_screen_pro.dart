// ═══════════════════════════════════════════════════════════════════════════
// Cash Screen Pro - Professional Design System
// Cash Drawer Management with Modern UI
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

class CashScreenPro extends ConsumerStatefulWidget {
  const CashScreenPro({super.key});

  @override
  ConsumerState<CashScreenPro> createState() => _CashScreenProState();
}

class _CashScreenProState extends ConsumerState<CashScreenPro> {
  @override
  Widget build(BuildContext context) {
    final shiftAsync = ref.watch(openShiftStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProAppBar.simple(
        title: 'الصندوق',
        actions: [
          ProAppBarAction(
            icon: Icons.access_time_rounded,
            onPressed: () => context.push('/shifts'),
            tooltip: 'الورديات',
          ),
        ],
      ),
      body: shiftAsync.when(
        loading: () => ProLoadingState.simple(),
        error: (error, _) => ProEmptyState.error(error: error.toString()),
        data: (shift) {
          if (shift == null) {
            return _buildNoShiftView();
          }
          return _buildCashView(shift);
        },
      ),
    );
  }

  Widget _buildNoShiftView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.warning.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                size: 64.sp,
                color: AppColors.warning,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد وردية مفتوحة',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'افتح وردية جديدة للبدء في إدارة الصندوق',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.push('/shifts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'فتح وردية',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashView(Shift shift) {
    final cashMovementsAsync =
        ref.watch(cashMovementsByShiftProvider(shift.id));

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          _buildBalanceCard(shift),
          SizedBox(height: AppSpacing.lg),

          // Quick Actions
          _buildQuickActions(shift),
          SizedBox(height: AppSpacing.lg),

          // Movements List
          Text(
            'حركات اليوم',
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.md),

          cashMovementsAsync.when(
            loading: () => ProLoadingState.list(itemCount: 3),
            error: (error, _) => ProEmptyState.error(error: error.toString()),
            data: (movements) {
              if (movements.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48.sp,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'لا توجد حركات',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movements.length,
                itemBuilder: (context, index) {
                  return _MovementCard(movement: movements[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Shift shift) {
    final openingBalance = shift.openingBalance;
    final totalIncome = shift.totalIncome;
    final totalExpenses = shift.totalExpenses;
    final currentBalance = openingBalance + totalIncome - totalExpenses;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.overlayHeavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.border,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رصيد الصندوق',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white.overlayHeavy,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.light,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'وردية #${shift.shiftNumber}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '${currentBalance.toStringAsFixed(2)} ر.س',
            style: AppTypography.displaySmall
                .copyWith(
                  color: Colors.white,
                )
                .monoBold,
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  label: 'الرصيد الافتتاحي',
                  value: openingBalance,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.light,
              ),
              Expanded(
                child: _buildBalanceItem(
                  label: 'الإيرادات',
                  value: totalIncome,
                  icon: Icons.arrow_downward_rounded,
                  isPositive: true,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.light,
              ),
              Expanded(
                child: _buildBalanceItem(
                  label: 'المصروفات',
                  value: totalExpenses,
                  icon: Icons.arrow_upward_rounded,
                  isPositive: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required String label,
    required double value,
    required IconData icon,
    bool? isPositive,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.o70,
          size: 20.sp,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.o70,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value.toStringAsFixed(0),
          style: AppTypography.titleSmall
              .copyWith(
                color: Colors.white,
              )
              .monoBold,
        ),
      ],
    );
  }

  Widget _buildQuickActions(Shift shift) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'إيداع',
            icon: Icons.add_circle_outline,
            color: AppColors.success,
            onTap: () => _showMovementSheet(shift, isDeposit: true),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            label: 'سحب',
            icon: Icons.remove_circle_outline,
            color: AppColors.error,
            onTap: () => _showMovementSheet(shift, isDeposit: false),
          ),
        ),
      ],
    );
  }

  void _showMovementSheet(Shift shift, {required bool isDeposit}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: (isDeposit ? AppColors.success : AppColors.error)
                          .soft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isDeposit
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: isDeposit ? AppColors.success : AppColors.error,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    isDeposit ? 'إيداع في الصندوق' : 'سحب من الصندوق',
                    style: AppTypography.titleLarge,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  suffixText: 'ر.س',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ProSnackbar.warning(context, 'أدخل مبلغ صحيح');
                      return;
                    }

                    try {
                      final cashRepo = ref.read(cashRepositoryProvider);
                      if (isDeposit) {
                        await cashRepo.addIncome(
                          shiftId: shift.id,
                          amount: amount,
                          description: noteController.text.isNotEmpty
                              ? noteController.text
                              : 'إيداع',
                        );
                      } else {
                        await cashRepo.addExpense(
                          shiftId: shift.id,
                          amount: amount,
                          description: noteController.text.isNotEmpty
                              ? noteController.text
                              : 'سحب',
                        );
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ProSnackbar.success(
                          context,
                          isDeposit ? 'تم الإيداع بنجاح' : 'تم السحب بنجاح',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ProSnackbar.showError(context, e);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDeposit ? AppColors.success : AppColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    isDeposit ? 'إيداع' : 'سحب',
                    style:
                        AppTypography.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Button
// ═══════════════════════════════════════════════════════════════════════════

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.soft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Movement Card
// ═══════════════════════════════════════════════════════════════════════════

class _MovementCard extends StatelessWidget {
  final CashMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIncome = movement.type == 'income' ||
        movement.type == 'sale' ||
        movement.type == 'deposit' ||
        movement.type == 'opening';
    final dateFormat = DateFormat('hh:mm a', 'ar');

    return ProCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ProIconBox(
            icon: isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIncome ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFormat.format(movement.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${movement.amount.toStringAsFixed(0)}',
            style: AppTypography.titleMedium
                .copyWith(
                  color: isIncome ? AppColors.success : AppColors.error,
                )
                .monoBold,
          ),
        ],
      ),
    );
  }
}
