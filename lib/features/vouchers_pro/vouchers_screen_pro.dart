// ═══════════════════════════════════════════════════════════════════════════
// Vouchers Screen Pro - Professional Design System
// Voucher Management Interface with Real Data
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

class VouchersScreenPro extends ConsumerStatefulWidget {
  const VouchersScreenPro({super.key});

  @override
  ConsumerState<VouchersScreenPro> createState() => _VouchersScreenProState();
}

class _VouchersScreenProState extends ConsumerState<VouchersScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Voucher> _filterVouchers(List<Voucher> vouchers, String? type) {
    var filtered = vouchers;

    if (type != null) {
      filtered = filtered.where((v) => v.type == type).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((v) =>
              v.voucherNumber.toLowerCase().contains(query) ||
              (v.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.voucherDate.compareTo(a.voucherDate));

    return filtered;
  }

  double _totalReceipts(List<Voucher> vouchers) => vouchers
      .where((v) => v.type == 'receipt')
      .fold(0.0, (sum, v) => sum + v.amount);

  double _totalPayments(List<Voucher> vouchers) => vouchers
      .where((v) => v.type == 'payment')
      .fold(0.0, (sum, v) => sum + v.amount);

  double _totalExpenses(List<Voucher> vouchers) => vouchers
      .where((v) => v.type == 'expense')
      .fold(0.0, (sum, v) => sum + v.amount);

  @override
  Widget build(BuildContext context) {
    final vouchersAsync = ref.watch(vouchersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: vouchersAsync.when(
          loading: () => ProLoadingState.list(),
          error: (error, stack) => ProEmptyState.error(error: error.toString()),
          data: (vouchers) {
            return Column(
              children: [
                _buildHeader(vouchers.length),
                _buildStatsSummary(vouchers),
                _buildSearchBar(),
                _buildTabs(vouchers),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVoucherList(_filterVouchers(vouchers, null)),
                      _buildVoucherList(_filterVouchers(vouchers, 'receipt')),
                      _buildVoucherList(_filterVouchers(vouchers, 'payment')),
                      _buildVoucherList(_filterVouchers(vouchers, 'expense')),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'receipt',
            onPressed: () => context.push('/vouchers/receipt/new'),
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.arrow_downward_rounded),
          ),
          SizedBox(height: AppSpacing.sm),
          FloatingActionButton(
            heroTag: 'payment',
            onPressed: () => context.push('/vouchers/payment/new'),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalVouchers) {
    return ProHeader(
      title: 'السندات',
      subtitle: '$totalVouchers سند',
      onBack: () => context.go('/'),
    );
  }

  Widget _buildStatsSummary(List<Voucher> vouchers) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'قبض',
              amount: _totalReceipts(vouchers),
              icon: Icons.arrow_downward_rounded,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StatCard(
              label: 'صرف',
              amount: _totalPayments(vouchers),
              icon: Icons.arrow_upward_rounded,
              color: AppColors.error,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StatCard(
              label: 'مصاريف',
              amount: _totalExpenses(vouchers),
              icon: Icons.receipt_outlined,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ProSearchBar(
      controller: _searchController,
      hintText: 'ابحث برقم السند أو الوصف...',
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildTabs(List<Voucher> vouchers) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary.soft,
          borderRadius: BorderRadius.circular(AppRadius.md - 1),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          _buildTab('الكل', vouchers.length),
          _buildTab('قبض', vouchers.where((v) => v.type == 'receipt').length),
          _buildTab('صرف', vouchers.where((v) => v.type == 'payment').length),
          _buildTab(
              'مصاريف', vouchers.where((v) => v.type == 'expense').length),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          SizedBox(width: AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.light,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(List<Voucher> vouchers) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد سندات',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return _VoucherCard(voucher: voucher);
      },
    );
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
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.soft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppIconSize.sm),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
          Text(
            amount.toStringAsFixed(0),
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;

  const _VoucherCard({required this.voucher});

  Color get _typeColor {
    switch (voucher.type) {
      case 'receipt':
        return AppColors.success;
      case 'payment':
        return AppColors.error;
      case 'expense':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _typeLabel {
    switch (voucher.type) {
      case 'receipt':
        return 'قبض';
      case 'payment':
        return 'صرف';
      case 'expense':
        return 'مصاريف';
      default:
        return voucher.type;
    }
  }

  IconData get _typeIcon {
    switch (voucher.type) {
      case 'receipt':
        return Icons.arrow_downward_rounded;
      case 'payment':
        return Icons.arrow_upward_rounded;
      case 'expense':
        return Icons.receipt_outlined;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return ProCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ProIconBox(icon: _typeIcon, color: _typeColor),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${voucher.voucherNumber}',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ProStatusBadge.fromVoucherType(voucher.type, small: true),
                  ],
                ),
                if (voucher.description != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    voucher.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  dateFormat.format(voucher.voucherDate),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${voucher.amount.toStringAsFixed(0)} ر.س',
            style: AppTypography.titleMedium.copyWith(
              color: _typeColor,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Voucher Form Screen Pro - Placeholder
// ═══════════════════════════════════════════════════════════════════════════

class VoucherFormScreenPro extends StatelessWidget {
  final String type; // 'receipt' or 'payment'

  const VoucherFormScreenPro({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProAppBar.close(
        title: type == 'receipt' ? 'سند قبض' : 'سند صرف',
      ),
      body: Center(
        child: Text(
          'قريباً',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
