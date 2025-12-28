import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/shift_repository.dart';

class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> {
  final _shiftRepo = getIt<ShiftRepository>();
  final _openingBalanceController = TextEditingController();

  Shift? _openShift;

  @override
  void initState() {
    super.initState();
    _loadOpenShift();
  }

  Future<void> _loadOpenShift() async {
    final shift = await _shiftRepo.getOpenShift();
    setState(() => _openShift = shift);
  }

  @override
  void dispose() {
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الورديات'),
      ),
      body: Column(
        children: [
          // Current Shift Status
          if (_openShift != null)
            _OpenShiftCard(
              shift: _openShift!,
              onClose: () => _showCloseShiftDialog(_openShift!),
            )
          else
            _NoShiftCard(onOpen: _showOpenShiftDialog),

          Gap(16.h),

          // Shifts History
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'سجل الورديات',
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
            child: StreamBuilder<List<Shift>>(
              stream: _shiftRepo.watchAllShifts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final shifts = snapshot.data ?? [];

                if (shifts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          'لا توجد ورديات سابقة',
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
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shift = shifts[index];
                    return _ShiftCard(
                      shift: shift,
                      onTap: () => context.push('/shifts/${shift.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenShiftDialog() {
    _openingBalanceController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فتح وردية جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _openingBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرصيد الافتتاحي',
                prefixIcon: Icon(Icons.account_balance_wallet),
                suffixText: 'ر.س',
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
              final balance =
                  double.tryParse(_openingBalanceController.text) ?? 0;
              Navigator.pop(context);

              try {
                await _shiftRepo.openShift(openingBalance: balance);
                await _loadOpenShift();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم فتح الوردية بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('فتح الوردية'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(Shift shift) {
    final closingBalanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق الوردية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'الرصيد الافتتاحي: ${shift.openingBalance.toStringAsFixed(2)} ر.س'),
            Gap(16.h),
            TextField(
              controller: closingBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرصيد الختامي',
                prefixIcon: Icon(Icons.account_balance_wallet),
                suffixText: 'ر.س',
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
              final balance =
                  double.tryParse(closingBalanceController.text) ?? 0;
              Navigator.pop(context);

              try {
                await _shiftRepo.closeShift(
                  shiftId: shift.id,
                  closingBalance: balance,
                );
                await _loadOpenShift();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إغلاق الوردية بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('إغلاق الوردية'),
          ),
        ],
      ),
    );
  }
}

class _OpenShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onClose;

  const _OpenShiftCard({required this.shift, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24.sp),
              Gap(8.w),
              Text(
                'الوردية الحالية مفتوحة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('إغلاق'),
              ),
            ],
          ),
          Gap(12.h),
          Text('رقم الوردية: ${shift.shiftNumber}'),
          Text('وقت الفتح: ${dateFormat.format(shift.openedAt)}'),
          Text(
              'الرصيد الافتتاحي: ${shift.openingBalance.toStringAsFixed(2)} ر.س'),
        ],
      ),
    );
  }
}

class _NoShiftCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _NoShiftCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppColors.warning, size: 32.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا توجد وردية مفتوحة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'افتح وردية جديدة للبدء في العمليات المالية',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onOpen,
            child: const Text('فتح وردية'),
          ),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onTap;

  const _ShiftCard({required this.shift, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isOpen = shift.status == 'open';

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (isOpen ? AppColors.success : AppColors.textSecondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  isOpen ? Icons.lock_open : Icons.lock,
                  color: isOpen ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          shift.shiftNumber,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: (isOpen
                                    ? AppColors.success
                                    : AppColors.textSecondary)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isOpen ? 'مفتوحة' : 'مغلقة',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isOpen
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      dateFormat.format(shift.openedAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!isOpen && shift.difference != null) ...[
                      Gap(4.h),
                      Text(
                        'الفرق: ${shift.difference!.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: shift.difference! >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${shift.openingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
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
              Gap(8.w),
              Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
