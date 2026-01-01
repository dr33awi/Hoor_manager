import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/voucher_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Vouchers Screen - Modern Redesign
/// Professional Voucher Management with Tabs
/// ═══════════════════════════════════════════════════════════════════════════

extension VoucherTypeUIExt on VoucherType {
  String get label {
    switch (this) {
      case VoucherType.receipt:
        return 'سندات قبض';
      case VoucherType.payment:
        return 'سندات صرف';
      case VoucherType.expense:
        return 'مصاريف';
    }
  }

  IconData get icon {
    switch (this) {
      case VoucherType.receipt:
        return Icons.call_received_rounded;
      case VoucherType.payment:
        return Icons.call_made_rounded;
      case VoucherType.expense:
        return Icons.receipt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case VoucherType.receipt:
        return HoorColors.income;
      case VoucherType.payment:
        return HoorColors.expense;
      case VoucherType.expense:
        return HoorColors.warning;
    }
  }
}

class VouchersScreenRedesign extends ConsumerStatefulWidget {
  const VouchersScreenRedesign({super.key});

  @override
  ConsumerState<VouchersScreenRedesign> createState() =>
      _VouchersScreenRedesignState();
}

class _VouchersScreenRedesignState extends ConsumerState<VouchersScreenRedesign>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _voucherRepo = getIt<VoucherRepository>();
  final _currencyService = getIt<CurrencyService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVoucherList(VoucherType.receipt),
                  _buildVoucherList(VoucherType.payment),
                  _buildVoucherList(VoucherType.expense),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVoucherSheet,
        backgroundColor: HoorColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند جديد'),
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
              'السندات',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _IconButton(
            icon: Icons.date_range_rounded,
            onTap: _showDateFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث في السندات...',
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: HoorSpacing.lg.w,
        vertical: HoorSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          color: HoorColors.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: HoorColors.textSecondary,
        labelStyle: HoorTypography.labelLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: HoorTypography.labelLarge,
        tabs: VoucherType.values.map((type) {
          return Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: HoorIconSize.sm),
                  SizedBox(width: HoorSpacing.xs.w),
                  Text(type.label),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoucherList(VoucherType type) {
    return StreamBuilder<List<Voucher>>(
      stream: _voucherRepo.watchVouchersByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        var vouchers = snapshot.data ?? [];

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          vouchers = vouchers
              .where((v) =>
                  v.description
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ==
                      true ||
                  v.id.toString().contains(_searchQuery))
              .toList();
        }

        if (_startDate != null) {
          vouchers =
              vouchers.where((v) => v.createdAt.isAfter(_startDate!)).toList();
        }

        if (_endDate != null) {
          vouchers = vouchers
              .where((v) =>
                  v.createdAt.isBefore(_endDate!.add(const Duration(days: 1))))
              .toList();
        }

        if (vouchers.isEmpty) {
          return _buildEmptyState(type);
        }

        // Group vouchers by date
        final groupedVouchers = _groupVouchersByDate(vouchers);

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          itemCount: groupedVouchers.length,
          itemBuilder: (context, index) {
            final entry = groupedVouchers.entries.elementAt(index);
            return _buildDateGroup(entry.key, entry.value, type);
          },
        );
      },
    );
  }

  Map<String, List<Voucher>> _groupVouchersByDate(List<Voucher> vouchers) {
    final grouped = <String, List<Voucher>>{};
    for (final voucher in vouchers) {
      final dateKey = DateFormat('yyyy-MM-dd').format(voucher.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(voucher);
    }
    return grouped;
  }

  Widget _buildDateGroup(
      String dateKey, List<Voucher> vouchers, VoucherType type) {
    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
    final displayDate =
        isToday ? 'اليوم' : DateFormat('EEEE, d MMMM', 'ar').format(date);

    final total = vouchers.fold<double>(0, (sum, v) => sum + v.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: HoorSpacing.md.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayDate,
              style: HoorTypography.labelLarge.copyWith(
                color: HoorColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.sm.w,
                vertical: HoorSpacing.xxs.h,
              ),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.full),
              ),
              child: Text(
                _currencyService.formatSyp(total),
                style: HoorTypography.labelSmall.copyWith(
                  color: type.color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBM Plex Sans Arabic',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        ...vouchers.map((voucher) => _VoucherCard(
              voucher: voucher,
              type: type,
              currencyService: _currencyService,
              onTap: () => _showVoucherDetails(voucher, type),
            )),
      ],
    );
  }

  Widget _buildEmptyState(VoucherType type) {
    return HoorEmptyState(
      icon: type.icon,
      title: 'لا توجد ${type.label}',
      message: 'سيظهر هنا ${type.label} المسجلة',
    );
  }

  void _showDateFilterSheet() {
    HoorBottomSheet.show(
      context,
      title: 'تصفية حسب التاريخ',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateFilterButton(
              label: 'من تاريخ',
              date: _startDate,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                  Navigator.pop(context);
                }
              },
            ),
            SizedBox(height: HoorSpacing.md.h),
            _DateFilterButton(
              label: 'إلى تاريخ',
              date: _endDate,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                  Navigator.pop(context);
                }
              },
            ),
            SizedBox(height: HoorSpacing.lg.h),
            if (_startDate != null || _endDate != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                  child: const Text('إزالة الفلتر'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddVoucherSheet() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    VoucherType selectedType = VoucherType.values[_tabController.index];

    HoorBottomSheet.show(
      context,
      title: 'سند جديد',
      showCloseButton: true,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Selection
                Text(
                  'نوع السند',
                  style: HoorTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: HoorSpacing.sm.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: VoucherType.values.map((type) {
                      final isSelected = selectedType == type;
                      return Padding(
                        padding: EdgeInsets.only(left: HoorSpacing.sm.w),
                        child: ChoiceChip(
                          label: Text(type.label),
                          avatar: Icon(
                            type.icon,
                            size: HoorIconSize.sm,
                            color: isSelected ? Colors.white : type.color,
                          ),
                          selected: isSelected,
                          selectedColor: type.color,
                          backgroundColor: type.color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : type.color,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedType = type);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: HoorSpacing.lg.h),

                // Amount Field
                HoorTextField(
                  controller: amountController,
                  label: 'المبلغ',
                  hint: 'أدخل المبلغ',
                  prefixIcon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: HoorSpacing.md.h),

                // Note Field
                HoorTextField(
                  controller: noteController,
                  label: 'الوصف',
                  hint: 'أدخل وصف السند',
                  prefixIcon: Icons.description_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: HoorSpacing.xl.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveVoucher(
                      context,
                      selectedType,
                      amountController.text,
                      noteController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType.color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                    child: const Text('حفظ السند'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveVoucher(
    BuildContext context,
    VoucherType type,
    String amountText,
    String note,
  ) async {
    final amount = double.tryParse(amountText);
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
      await _voucherRepo.createVoucher(
        type: type,
        amount: amount,
        description: note.isNotEmpty ? note : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ السند بنجاح'),
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

  void _showVoucherDetails(Voucher voucher, VoucherType type) {
    HoorBottomSheet.show(
      context,
      title: 'تفاصيل السند',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: type.color,
                size: HoorIconSize.xl,
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            Text(
              _currencyService.formatSyp(voucher.amount),
              style: HoorTypography.displaySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: type.color,
                fontFamily: 'IBM Plex Sans Arabic',
              ),
            ),
            SizedBox(height: HoorSpacing.xs.h),
            HoorBadge(
              label: type.label,
              color: type.color,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            _DetailRow(
              icon: Icons.numbers_rounded,
              label: 'رقم السند',
              value: '#${voucher.id}',
            ),
            SizedBox(height: HoorSpacing.md.h),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'التاريخ',
              value: DateFormat('dd/MM/yyyy - HH:mm').format(voucher.createdAt),
            ),
            if (voucher.description?.isNotEmpty == true) ...[
              SizedBox(height: HoorSpacing.md.h),
              _DetailRow(
                icon: Icons.description_rounded,
                label: 'الوصف',
                value: voucher.description!,
              ),
            ],
            SizedBox(height: HoorSpacing.xl.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement edit
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('تعديل'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: HoorSpacing.md.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteVoucher(voucher),
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HoorColors.error,
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
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    try {
      await _voucherRepo.deleteVoucher(voucher.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف السند'),
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

class _DateFilterButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: HoorColors.textSecondary,
                size: HoorIconSize.md,
              ),
              SizedBox(width: HoorSpacing.md.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textTertiary,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date!)
                        : 'اختر التاريخ',
                    style: HoorTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_left_rounded,
                color: HoorColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoucherType type;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _VoucherCard({
    required this.voucher,
    required this.type,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Material(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              border:
                  Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(
                    type.icon,
                    color: type.color,
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
                          Text(
                            '#${voucher.id}',
                            style: HoorTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (voucher.description?.isNotEmpty == true) ...[
                        SizedBox(height: HoorSpacing.xxs.h),
                        Text(
                          voucher.description!,
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: HoorSpacing.xxs.h),
                      Text(
                        DateFormat('HH:mm').format(voucher.createdAt),
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyService.formatSyp(voucher.amount),
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: type.color,
                    fontFamily: 'IBM Plex Sans Arabic',
                  ),
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
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: HoorColors.textTertiary, size: HoorIconSize.md),
          SizedBox(width: HoorSpacing.md.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: HoorTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
