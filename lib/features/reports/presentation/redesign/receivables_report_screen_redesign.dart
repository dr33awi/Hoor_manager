/// ═══════════════════════════════════════════════════════════════════════════
/// Receivables Report Screen - Redesigned
/// Modern Customer Receivables Report Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';

/// Customer with USD Balance model
class CustomerWithUsdBalance {
  final Customer customer;
  final double usdBalance;

  CustomerWithUsdBalance({required this.customer, required this.usdBalance});
}

class ReceivablesReportScreenRedesign extends ConsumerStatefulWidget {
  const ReceivablesReportScreenRedesign({super.key});

  @override
  ConsumerState<ReceivablesReportScreenRedesign> createState() =>
      _ReceivablesReportScreenRedesignState();
}

class _ReceivablesReportScreenRedesignState
    extends ConsumerState<ReceivablesReportScreenRedesign> {
  final _db = getIt<AppDatabase>();

  String _sortBy = 'balance';
  bool _sortDescending = true;
  bool _showOnlyWithBalance = true;
  bool _isLoading = true;
  List<CustomerWithUsdBalance> _customersWithUsd = [];
  double _totalUsd = 0;

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final customers = await _db.getAllCustomers();
    final List<CustomerWithUsdBalance> result = [];
    double totalUsd = 0;

    for (final customer in customers) {
      if (_showOnlyWithBalance && customer.balance <= 0) continue;

      final usdBalance = await _db.getCustomerBalanceInUsd(customer.id);
      result.add(CustomerWithUsdBalance(
        customer: customer,
        usdBalance: usdBalance,
      ));
      if (customer.balance > 0) {
        totalUsd += usdBalance;
      }
    }

    result.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'name':
          compare = a.customer.name.compareTo(b.customer.name);
          break;
        case 'balance':
        default:
          compare = a.customer.balance.compareTo(b.customer.balance);
      }
      return _sortDescending ? -compare : compare;
    });

    setState(() {
      _customersWithUsd = result;
      _totalUsd = totalUsd;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('الذمم المدينة', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: (_showOnlyWithBalance
                        ? HoorColors.primary
                        : HoorColors.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(
                _showOnlyWithBalance
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_off_rounded,
                color: _showOnlyWithBalance
                    ? HoorColors.primary
                    : HoorColors.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() => _showOnlyWithBalance = !_showOnlyWithBalance);
              _loadData();
            },
            tooltip:
                _showOnlyWithBalance ? 'إظهار الكل' : 'إظهار من عليهم رصيد فقط',
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child:
                  Icon(Icons.sort_rounded, color: HoorColors.primary, size: 20),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortBy = value;
                  _sortDescending = true;
                }
              });
              _loadData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'balance',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'balance'
                          ? (_sortDescending
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded)
                          : Icons.sort_rounded,
                      size: 18,
                      color: _sortBy == 'balance'
                          ? HoorColors.primary
                          : HoorColors.textSecondary,
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Text('الرصيد', style: HoorTypography.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name'
                          ? (_sortDescending
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded)
                          : Icons.sort_rounded,
                      size: 18,
                      color: _sortBy == 'name'
                          ? HoorColors.primary
                          : HoorColors.textSecondary,
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Text('الاسم', style: HoorTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HoorColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final totalReceivables = _customersWithUsd.fold<double>(
        0, (sum, c) => sum + (c.customer.balance > 0 ? c.customer.balance : 0));
    final customersWithDebt =
        _customersWithUsd.where((c) => c.customer.balance > 0).length;

    return CustomScrollView(
      slivers: [
        // Summary Card
        SliverToBoxAdapter(
          child: _buildSummaryCard(
            total: totalReceivables,
            totalUsd: _totalUsd,
            count: customersWithDebt,
          ),
        ),

        // Customers List
        if (_customersWithUsd.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _customersWithUsd[index];
                  return _buildCustomerCard(item);
                },
                childCount: _customersWithUsd.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required double total,
    required double totalUsd,
    required int count,
  }) {
    return Container(
      margin: EdgeInsets.all(HoorSpacing.md.w),
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoorColors.error,
            HoorColors.error.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        boxShadow: [
          BoxShadow(
            color: HoorColors.error.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي الذمم المدينة',
                    style: HoorTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  Text(
                    _formatPrice(total),
                    style: HoorTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${totalUsd.toStringAsFixed(2)}',
                    style: HoorTypography.titleSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(HoorRadius.full),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 32),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: HoorSpacing.sm.w,
              vertical: HoorSpacing.xs.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, color: Colors.white, size: 16),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  '$count عميل عليه رصيد',
                  style: HoorTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerWithUsdBalance item) {
    final customer = item.customer;
    final hasDebt = customer.balance > 0;

    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(
          color: hasDebt
              ? HoorColors.error.withValues(alpha: 0.3)
              : HoorColors.border,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm.w),
                decoration: BoxDecoration(
                  color: (hasDebt ? HoorColors.error : HoorColors.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: hasDebt ? HoorColors.error : HoorColors.success,
                  size: 24,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customer.phone != null)
                      Text(
                        customer.phone!,
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(customer.balance),
                    style: HoorTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasDebt ? HoorColors.error : HoorColors.success,
                    ),
                  ),
                  Text(
                    '\$${item.usdBalance.toStringAsFixed(2)}',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 64, color: HoorColors.success),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Text(
            'لا توجد ذمم مدينة',
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'جميع العملاء قاموا بتسديد مستحقاتهم',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
