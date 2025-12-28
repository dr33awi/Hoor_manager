import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/cash_repository.dart';

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  ConsumerState<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  final _shiftRepo = getIt<ShiftRepository>();
  final _cashRepo = getIt<CashRepository>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Shift?>(
      stream: _shiftRepo.watchOpenShift(),
      builder: (context, shiftSnapshot) {
        if (shiftSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('حركة الصندوق')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentShift = shiftSnapshot.data;

        if (currentShift == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('حركة الصندوق')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    size: 64.sp,
                    color: AppColors.warning,
                  ),
                  Gap(16.h),
                  Text(
                    'لا توجد وردية مفتوحة',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    'يجب فتح وردية لإدارة حركة الصندوق',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _CashScreenBody(
          shiftRepo: _shiftRepo,
          cashRepo: _cashRepo,
          currentShift: currentShift,
        );
      },
    );
  }
}

class _CashScreenBody extends StatelessWidget {
  final ShiftRepository shiftRepo;
  final CashRepository cashRepo;
  final Shift currentShift;

  const _CashScreenBody({
    required this.shiftRepo,
    required this.cashRepo,
    required this.currentShift,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الصندوق'),
      ),
      body: Column(
        children: [
          // Current Balance Card
          StreamBuilder<Map<String, double>>(
            stream: cashRepo.watchShiftCashSummary(currentShift.id),
            builder: (context, snapshot) {
              final summary = snapshot.data ?? {};
              return Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'رصيد الصندوق',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      '${(currentShift.openingBalance + (summary['netCash'] ?? 0)).toStringAsFixed(2)} ل.س',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap(16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BalanceItem(
                          label: 'المبيعات',
                          value: summary['totalSales'] ?? 0,
                          icon: Icons.trending_up,
                        ),
                        _BalanceItem(
                          label: 'الإيرادات',
                          value: summary['totalIncome'] ?? 0,
                          icon: Icons.add_circle,
                        ),
                        _BalanceItem(
                          label: 'المصروفات',
                          value: summary['totalExpense'] ?? 0,
                          icon: Icons.remove_circle,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddMovementDialog(
                        context, cashRepo, currentShift,
                        isIncome: true),
                    icon: const Icon(Icons.add),
                    label: const Text('إيراد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddMovementDialog(
                        context, cashRepo, currentShift,
                        isIncome: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('مصروف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap(16.h),

          // Movements List
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'حركات اليوم',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Gap(8.h),

          Expanded(
            child: StreamBuilder<List<CashMovement>>(
              stream: cashRepo.watchMovementsByShift(currentShift.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movements = snapshot.data ?? [];

                if (movements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          'لا توجد حركات',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return _MovementCard(movement: movement);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMovementDialog(
      BuildContext context, CashRepository cashRepo, Shift currentShift,
      {required bool isIncome}) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'إضافة إيراد' : 'إضافة مصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'ل.س',
              ),
            ),
            Gap(16.h),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'الوصف',
                prefixIcon: const Icon(Icons.description),
                hintText: isIncome ? 'مثال: إيراد من...' : 'مثال: مصروف لـ...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              if (descriptionController.text.isEmpty) return;

              Navigator.pop(context);

              if (isIncome) {
                await cashRepo.addIncome(
                  shiftId: currentShift.id,
                  amount: amount,
                  description: descriptionController.text,
                );
              } else {
                await cashRepo.addExpense(
                  shiftId: currentShift.id,
                  amount: amount,
                  description: descriptionController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? AppColors.success : AppColors.error,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        Gap(4.h),
        Text(
          '${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  final CashMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.type == 'income' ||
        movement.type == 'sale' ||
        movement.type == 'opening';
    final timeFormat = DateFormat('HH:mm');

    IconData icon;
    String typeLabel;

    switch (movement.type) {
      case 'income':
        icon = Icons.arrow_downward;
        typeLabel = 'إيراد';
        break;
      case 'expense':
        icon = Icons.arrow_upward;
        typeLabel = 'مصروف';
        break;
      case 'sale':
        icon = Icons.point_of_sale;
        typeLabel = 'مبيعات';
        break;
      case 'purchase':
        icon = Icons.shopping_cart;
        typeLabel = 'مشتريات';
        break;
      case 'opening':
        icon = Icons.lock_open;
        typeLabel = 'افتتاحي';
        break;
      case 'closing':
        icon = Icons.lock;
        typeLabel = 'ختامي';
        break;
      default:
        icon = Icons.swap_horiz;
        typeLabel = movement.type;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.success : AppColors.error)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon,
              color: isPositive ? AppColors.success : AppColors.error),
        ),
        title: Text(movement.description),
        subtitle: Row(
          children: [
            Text(
              typeLabel,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Gap(8.w),
            Text(
              timeFormat.format(movement.createdAt),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isPositive ? '+' : '-'}${movement.amount.toStringAsFixed(2)} ل.س',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
        ),
      ),
    );
  }
}
