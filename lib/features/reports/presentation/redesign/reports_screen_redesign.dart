import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Reports Screen - Modern Redesign
/// Professional Reports & Analytics Interface
/// ═══════════════════════════════════════════════════════════════════════════

class ReportsScreenRedesign extends ConsumerStatefulWidget {
  const ReportsScreenRedesign({super.key});

  @override
  ConsumerState<ReportsScreenRedesign> createState() =>
      _ReportsScreenRedesignState();
}

class _ReportsScreenRedesignState extends ConsumerState<ReportsScreenRedesign> {
  final _db = getIt<AppDatabase>();
  final _currencyService = getIt<CurrencyService>();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Date Range Selector
            _buildDateRangeSelector(),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                children: [
                  // Quick Summary Cards
                  _QuickSummarySection(
                    dateRange: _dateRange,
                    db: _db,
                    currencyService: _currencyService,
                  ),
                  SizedBox(height: HoorSpacing.xl.h),

                  // Sales & Profit Reports
                  _ReportSection(
                    title: 'المبيعات والأرباح',
                    icon: Icons.trending_up_rounded,
                    reports: [
                      _ReportItem(
                        title: 'تقرير المبيعات',
                        subtitle: 'تفاصيل المبيعات والإيرادات',
                        icon: Icons.point_of_sale_rounded,
                        color: HoorColors.sales,
                        onTap: () =>
                            context.push('/reports/sales', extra: _dateRange),
                      ),
                      _ReportItem(
                        title: 'تقرير الأرباح والخسائر',
                        subtitle: 'تحليل الربحية والمصاريف',
                        icon: Icons.analytics_rounded,
                        color: HoorColors.success,
                        onTap: () => context.push('/reports/profit-loss',
                            extra: _dateRange),
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.lg.h),

                  // Inventory Reports
                  _ReportSection(
                    title: 'المخزون',
                    icon: Icons.inventory_rounded,
                    reports: [
                      _ReportItem(
                        title: 'تقرير المخزون',
                        subtitle: 'حالة المخزون والكميات',
                        icon: Icons.inventory_2_rounded,
                        color: HoorColors.inventory,
                        onTap: () => context.push('/reports/inventory'),
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.lg.h),

                  // Financial Reports
                  _ReportSection(
                    title: 'المالية والحسابات',
                    icon: Icons.account_balance_rounded,
                    reports: [
                      _ReportItem(
                        title: 'تقرير المستحقات',
                        subtitle: 'ديون العملاء والمبالغ المستحقة',
                        icon: Icons.account_balance_wallet_rounded,
                        color: HoorColors.warning,
                        onTap: () => context.push('/reports/receivables'),
                      ),
                      _ReportItem(
                        title: 'تقرير المطلوبات',
                        subtitle: 'ديون الموردين والالتزامات',
                        icon: Icons.payments_rounded,
                        color: HoorColors.expense,
                        onTap: () => context.push('/reports/payables'),
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.xxl.h),
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
          // Back Button
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التقارير',
                  style: HoorTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'تحليلات وإحصائيات الأعمال',
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoorColors.primary,
            HoorColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        boxShadow: [
          BoxShadow(
            color: HoorColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Row(
          children: [
            // Calendar Icon
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: HoorIconSize.md,
              ),
            ),
            SizedBox(width: HoorSpacing.md.w),

            // Date Range Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفترة المحددة',
                    style: HoorTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                    style: HoorTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                ],
              ),
            ),

            // Change Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.md.w,
                vertical: HoorSpacing.xs.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(HoorRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تغيير',
                    style: HoorTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: HoorSpacing.xxs.w),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: HoorIconSize.sm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HoorColors.primary,
              onPrimary: Colors.white,
              surface: HoorColors.surface,
              onSurface: HoorColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _dateRange = result);
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

/// ═══════════════════════════════════════════════════════════════════════════
/// Quick Summary Section
/// ═══════════════════════════════════════════════════════════════════════════

class _QuickSummarySection extends StatelessWidget {
  final DateTimeRange dateRange;
  final AppDatabase db;
  final CurrencyService currencyService;

  const _QuickSummarySection({
    required this.dateRange,
    required this.db,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: HoorSpacing.lg.h),
        HoorSectionHeader(
          title: 'ملخص سريع',
          icon: Icons.dashboard_rounded,
        ),
        SizedBox(height: HoorSpacing.md.h),

        // Summary Cards
        StreamBuilder<List<Invoice>>(
          stream: db.select(db.invoices).watch(),
          builder: (context, snapshot) {
            final invoices = snapshot.data ?? [];

            // Filter by date range
            final filteredInvoices = invoices
                .where((i) =>
                    i.invoiceDate.isAfter(
                        dateRange.start.subtract(const Duration(days: 1))) &&
                    i.invoiceDate
                        .isBefore(dateRange.end.add(const Duration(days: 1))))
                .toList();

            // Calculate totals
            final sales = filteredInvoices
                .where((i) => i.type == 'sale')
                .fold<double>(0, (sum, i) => sum + i.total);
            final purchases = filteredInvoices
                .where((i) => i.type == 'purchase')
                .fold<double>(0, (sum, i) => sum + i.total);
            final profit = sales - purchases;

            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'المبيعات',
                    value: sales,
                    icon: Icons.trending_up_rounded,
                    color: HoorColors.income,
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),
                Expanded(
                  child: _SummaryCard(
                    label: 'المشتريات',
                    value: purchases,
                    icon: Icons.trending_down_rounded,
                    color: HoorColors.expense,
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),
                Expanded(
                  child: _SummaryCard(
                    label: 'الربح',
                    value: profit,
                    icon: Icons.account_balance_rounded,
                    color: profit >= 0 ? HoorColors.success : HoorColors.error,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: HoorIconSize.sm, color: color),
              if (value != 0)
                Icon(
                  value > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: HoorIconSize.xs,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Text(
            _formatCurrency(value.abs()),
            style: HoorTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'IBM Plex Sans Arabic',
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Report Section
/// ═══════════════════════════════════════════════════════════════════════════

class _ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ReportItem> reports;

  const _ReportSection({
    required this.title,
    required this.icon,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HoorDecoratedHeader(
          title: title,
          icon: icon,
        ),
        SizedBox(height: HoorSpacing.md.h),
        ...reports.map((report) => Padding(
              padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
              child: report,
            )),
      ],
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              // Icon Container
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(icon, color: color, size: HoorIconSize.lg),
              ),
              SizedBox(width: HoorSpacing.md.w),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs.w),
                decoration: BoxDecoration(
                  color: HoorColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: HoorColors.primary,
                  size: HoorIconSize.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
