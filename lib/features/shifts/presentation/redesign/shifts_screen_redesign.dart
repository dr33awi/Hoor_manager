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

/// ═══════════════════════════════════════════════════════════════════════════
/// Shifts Screen - Modern Redesign
/// Professional Shift Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class ShiftsScreenRedesign extends ConsumerStatefulWidget {
  const ShiftsScreenRedesign({super.key});

  @override
  ConsumerState<ShiftsScreenRedesign> createState() =>
      _ShiftsScreenRedesignState();
}

class _ShiftsScreenRedesignState extends ConsumerState<ShiftsScreenRedesign> {
  final _shiftRepo = getIt<ShiftRepository>();
  final _currencyService = getIt<CurrencyService>();
  final _openingBalanceController = TextEditingController();

  @override
  void dispose() {
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                children: [
                  // Current Shift Status
                  _buildCurrentShiftCard(),
                  SizedBox(height: HoorSpacing.xl.h),

                  // Shifts History
                  HoorDecoratedHeader(
                    title: 'سجل الورديات',
                    icon: Icons.history_rounded,
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  _buildShiftsHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
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
              'الورديات',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentShiftCard() {
    return StreamBuilder<Shift?>(
      stream: _shiftRepo.watchOpenShift(),
      builder: (context, snapshot) {
        final openShift = snapshot.data;

        if (openShift != null) {
          return _OpenShiftCard(
            shift: openShift,
            currencyService: _currencyService,
            onClose: () => _showCloseShiftDialog(openShift),
            onViewDetails: () => context.push('/shifts/${openShift.id}'),
          );
        } else {
          return _NoShiftCard(onOpen: _showOpenShiftDialog);
        }
      },
    );
  }

  Widget _buildShiftsHistory() {
    return StreamBuilder<List<Shift>>(
      stream: _shiftRepo.watchAllShifts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        final shifts = snapshot.data ?? [];

        if (shifts.isEmpty) {
          return HoorEmptyState(
            icon: Icons.access_time_outlined,
            title: 'لا توجد ورديات سابقة',
            message: 'سيظهر هنا سجل الورديات بعد فتح أول وردية',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shifts.length,
          separatorBuilder: (_, __) => SizedBox(height: HoorSpacing.sm.h),
          itemBuilder: (context, index) {
            final shift = shifts[index];
            return _ShiftHistoryCard(
              shift: shift,
              currencyService: _currencyService,
              onTap: () => context.push('/shifts/${shift.id}'),
            );
          },
        );
      },
    );
  }

  void _showOpenShiftDialog() {
    _openingBalanceController.clear();

    HoorBottomSheet.show(
      context,
      title: 'فتح وردية جديدة',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.lg.w),
              decoration: BoxDecoration(
                color: HoorColors.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.lg),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.play_circle_rounded,
                    color: HoorColors.income,
                    size: HoorIconSize.xxl,
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  Text(
                    'بدء وردية جديدة',
                    style: HoorTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  Text(
                    'أدخل رصيد الصندوق الافتتاحي',
                    style: HoorTypography.bodyMedium.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: _openingBalanceController,
              label: 'الرصيد الافتتاحي',
              hint: 'أدخل المبلغ بالليرة',
              prefixIcon: Icons.account_balance_wallet_rounded,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openShift,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('فتح الوردية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.income,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openShift() async {
    final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0;

    try {
      await _shiftRepo.openShift(openingBalance: openingBalance);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم فتح الوردية بنجاح'),
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

  void _showCloseShiftDialog(Shift shift) {
    final closingBalanceController = TextEditingController();

    HoorBottomSheet.show(
      context,
      title: 'إغلاق الوردية',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.lg.w),
              decoration: BoxDecoration(
                color: HoorColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.lg),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.stop_circle_rounded,
                    color: HoorColors.warning,
                    size: HoorIconSize.xxl,
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  Text(
                    'هل تريد إغلاق الوردية؟',
                    style: HoorTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  _SummaryRow(
                    label: 'الرصيد الافتتاحي',
                    value: _currencyService.formatSyp(shift.openingBalance),
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  _SummaryRow(
                    label: 'المبيعات',
                    value: _currencyService.formatSyp(shift.totalSales),
                    valueColor: HoorColors.income,
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  _SummaryRow(
                    label: 'المشتريات',
                    value: _currencyService.formatSyp(shift.totalExpenses),
                    valueColor: HoorColors.expense,
                  ),
                ],
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: closingBalanceController,
              label: 'الرصيد الختامي الفعلي',
              hint: 'أدخل الرصيد الموجود في الصندوق',
              prefixIcon: Icons.account_balance_wallet_rounded,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                SizedBox(width: HoorSpacing.md.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _closeShift(shift, closingBalanceController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HoorColors.warning,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeShift(Shift shift, String closingBalanceText) async {
    final closingBalance = double.tryParse(closingBalanceText) ?? 0;

    try {
      await _shiftRepo.closeShift(
          shiftId: shift.id, closingBalance: closingBalance);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إغلاق الوردية بنجاح'),
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

class _OpenShiftCard extends StatelessWidget {
  final Shift shift;
  final CurrencyService currencyService;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _OpenShiftCard({
    required this.shift,
    required this.currencyService,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(shift.openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoorColors.income,
            HoorColors.income.withValues(alpha: 0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.xl),
        boxShadow: [
          BoxShadow(
            color: HoorColors.income.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(HoorRadius.lg),
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: Colors.white,
                  size: HoorIconSize.xl,
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: HoorSpacing.sm.w,
                            vertical: HoorSpacing.xxs.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(HoorRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: HoorSpacing.xxs.w),
                              Text(
                                'وردية مفتوحة',
                                style: HoorTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: HoorSpacing.xs.h),
                    Text(
                      '$hoursس $minutesد',
                      style: HoorTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'منذ ${DateFormat('HH:mm').format(shift.openedAt)}',
                      style: HoorTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                _ShiftStat(
                  label: 'الافتتاحي',
                  value: currencyService.formatSyp(shift.openingBalance),
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _ShiftStat(
                  label: 'المبيعات',
                  value: currencyService.formatSyp(shift.totalSales),
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _ShiftStat(
                  label: 'المصاريف',
                  value: currencyService.formatSyp(shift.totalExpenses),
                ),
              ],
            ),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('التفاصيل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('إغلاق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HoorColors.income,
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftStat extends StatelessWidget {
  final String label;
  final String value;

  const _ShiftStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: HoorTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
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

class _NoShiftCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _NoShiftCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.xl.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.xl),
        border: Border.all(
          color: HoorColors.border,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.textTertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_outlined,
              color: HoorColors.textTertiary,
              size: HoorIconSize.xxl,
            ),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Text(
            'لا توجد وردية مفتوحة',
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'افتح وردية جديدة لبدء العمل',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.xl.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('فتح وردية جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HoorColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(HoorSpacing.md.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftHistoryCard extends StatelessWidget {
  final Shift shift;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _ShiftHistoryCard({
    required this.shift,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = shift.closedAt != null;
    final duration =
        (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: isClosed
                      ? HoorColors.textTertiary.withValues(alpha: 0.1)
                      : HoorColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  isClosed ? Icons.check_circle_rounded : Icons.timer_rounded,
                  color: isClosed ? HoorColors.textTertiary : HoorColors.income,
                  size: HoorIconSize.lg,
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(shift.openedAt),
                            style: HoorTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: HoorSpacing.xs.w),
                        HoorBadge(
                          label: isClosed ? 'مغلقة' : 'مفتوحة',
                          color: isClosed
                              ? HoorColors.textTertiary
                              : HoorColors.income,
                          size: HoorBadgeSize.small,
                        ),
                      ],
                    ),
                    SizedBox(height: HoorSpacing.xxs.h),
                    Text(
                      '${DateFormat('HH:mm').format(shift.openedAt)} - ${isClosed ? DateFormat('HH:mm').format(shift.closedAt!) : 'الآن'}',
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: HoorSpacing.xxs.h),
                    Text(
                      'المدة: $hoursس $minutesد',
                      style: HoorTypography.labelSmall.copyWith(
                        color: HoorColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyService.formatSyp(shift.totalSales),
                    style: HoorTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HoorColors.income,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                  Text(
                    'مبيعات',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: HoorSpacing.xs.w),
              Icon(
                Icons.chevron_left_rounded,
                color: HoorColors.textTertiary,
                size: HoorIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: HoorTypography.bodyMedium.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: HoorTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? HoorColors.textPrimary,
            fontFamily: 'IBM Plex Sans Arabic',
          ),
        ),
      ],
    );
  }
}
