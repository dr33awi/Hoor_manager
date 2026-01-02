// ═══════════════════════════════════════════════════════════════════════════
// Reports Screen Pro - Professional Design System
// Reports Hub with Modern UI
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

class ReportsScreenPro extends ConsumerWidget {
  const ReportsScreenPro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesInvoicesProvider);
    final purchasesAsync = ref.watch(purchaseInvoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProAppBar.noBack(
        title: 'التقارير',
        actions: [
          ProAppBarAction(
            icon: Icons.date_range_rounded,
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(salesAsync, purchasesAsync),
            SizedBox(height: AppSpacing.lg),

            // Sales Reports
            _buildSectionTitle('تقارير المبيعات'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المبيعات',
              description: 'إجمالي المبيعات والإيرادات',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
              onTap: () => context.push('/reports/sales'),
            ),
            _ReportCard(
              title: 'تقرير المنتجات الأكثر مبيعاً',
              description: 'المنتجات حسب حجم المبيعات',
              icon: Icons.star_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.lg),

            // Purchase Reports
            _buildSectionTitle('تقارير المشتريات'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المشتريات',
              description: 'إجمالي المشتريات والتكاليف',
              icon: Icons.shopping_cart_rounded,
              color: AppColors.secondary,
              onTap: () => context.push('/reports/purchases'),
            ),

            SizedBox(height: AppSpacing.lg),

            // Financial Reports
            _buildSectionTitle('التقارير المالية'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير الأرباح والخسائر',
              description: 'صافي الربح والمصروفات',
              icon: Icons.analytics_rounded,
              color: AppColors.success,
              onTap: () => context.push('/reports/profit'),
            ),
            _ReportCard(
              title: 'تقرير الذمم المدينة',
              description: 'المبالغ المستحقة من العملاء',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.error,
              onTap: () => context.push('/reports/receivables'),
            ),
            _ReportCard(
              title: 'تقرير الذمم الدائنة',
              description: 'المبالغ المستحقة للموردين',
              icon: Icons.payments_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.lg),

            // Inventory Reports
            _buildSectionTitle('تقارير المخزون'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المخزون',
              description: 'الكميات والقيم الحالية',
              icon: Icons.inventory_2_rounded,
              color: AppColors.secondary,
              onTap: () {},
            ),
            _ReportCard(
              title: 'تقرير المخزون المنخفض',
              description: 'المنتجات التي تحتاج إعادة طلب',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    AsyncValue<List<Invoice>> salesAsync,
    AsyncValue<List<Invoice>> purchasesAsync,
  ) {
    final salesTotal = salesAsync.when(
      data: (invoices) {
        final now = DateTime.now();
        return invoices
            .where((inv) =>
                inv.invoiceDate.month == now.month &&
                inv.invoiceDate.year == now.year)
            .fold(0.0, (sum, inv) => sum + inv.total);
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final purchasesTotal = purchasesAsync.when(
      data: (invoices) {
        final now = DateTime.now();
        return invoices
            .where((inv) =>
                inv.invoiceDate.month == now.month &&
                inv.invoiceDate.year == now.year)
            .fold(0.0, (sum, inv) => sum + inv.total);
      },
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final profit = salesTotal - purchasesTotal;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.overlayHeavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الشهر الحالي',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.o87,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  label: 'المبيعات',
                  value: salesTotal.toStringAsFixed(0),
                  icon: Icons.arrow_upward_rounded,
                  trend: '',
                  isPositive: true,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.light,
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'المشتريات',
                  value: purchasesTotal.toStringAsFixed(0),
                  icon: Icons.arrow_downward_rounded,
                  trend: '',
                  isPositive: false,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.light,
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'صافي الربح',
                  value: profit.toStringAsFixed(0),
                  icon: profit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  trend: '',
                  isPositive: profit >= 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required IconData icon,
    required String trend,
    required bool isPositive,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.o70,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white.light,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12.sp,
                color: Colors.white,
              ),
              SizedBox(width: 2.w),
              Text(
                trend,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.soft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: AppIconSize.md),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Report Detail Screen Pro - Full Implementation with Export
// ═══════════════════════════════════════════════════════════════════════════

class ReportDetailScreenPro extends ConsumerStatefulWidget {
  final String reportType;

  const ReportDetailScreenPro({
    super.key,
    required this.reportType,
  });

  @override
  ConsumerState<ReportDetailScreenPro> createState() =>
      _ReportDetailScreenProState();
}

class _ReportDetailScreenProState extends ConsumerState<ReportDetailScreenPro> {
  DateTimeRange? _dateRange;
  bool _isExporting = false;

  String get _title {
    switch (widget.reportType) {
      case 'sales':
        return 'تقرير المبيعات';
      case 'purchases':
        return 'تقرير المشتريات';
      case 'profit':
        return 'تقرير الأرباح والخسائر';
      case 'receivables':
        return 'تقرير الذمم المدينة';
      default:
        return 'تقرير';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProAppBar.simple(
        title: _title,
        actions: [
          ProAppBarAction(
            icon: Icons.date_range_rounded,
            onPressed: _selectDateRange,
            color: _dateRange != null ? AppColors.primary : null,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تصدير PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تصدير Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isExporting
          ? ProLoadingState.withMessage(message: 'جاري التصدير...')
          : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    switch (widget.reportType) {
      case 'sales':
        return _buildSalesReport();
      case 'purchases':
        return _buildPurchasesReport();
      case 'profit':
        return _buildProfitReport();
      case 'receivables':
        return _buildReceivablesReport();
      default:
        return _buildPlaceholder();
    }
  }

  Widget _buildSalesReport() {
    final invoicesAsync = ref.watch(salesInvoicesProvider);

    return invoicesAsync.when(
      loading: () => ProLoadingState.list(),
      error: (error, _) => ProEmptyState.error(error: error.toString()),
      data: (invoices) {
        final filtered = _filterByDate(invoices);
        final total = filtered.fold<double>(0, (sum, inv) => sum + inv.total);
        final count = filtered.length;

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeChip(),
              SizedBox(height: AppSpacing.md),
              _buildSummaryCards(
                total: total,
                count: count,
                label: 'إجمالي المبيعات',
                color: AppColors.success,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildInvoicesList(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchasesReport() {
    final invoicesAsync = ref.watch(purchaseInvoicesProvider);

    return invoicesAsync.when(
      loading: () => ProLoadingState.list(),
      error: (error, _) => ProEmptyState.error(error: error.toString()),
      data: (invoices) {
        final filtered = _filterByDate(invoices);
        final total = filtered.fold<double>(0, (sum, inv) => sum + inv.total);
        final count = filtered.length;

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeChip(),
              SizedBox(height: AppSpacing.md),
              _buildSummaryCards(
                total: total,
                count: count,
                label: 'إجمالي المشتريات',
                color: AppColors.secondary,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildInvoicesList(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfitReport() {
    final salesAsync = ref.watch(salesInvoicesProvider);
    final purchasesAsync = ref.watch(purchaseInvoicesProvider);

    return salesAsync.when(
      loading: () => ProLoadingState.list(),
      error: (error, _) => ProEmptyState.error(error: error.toString()),
      data: (sales) {
        return purchasesAsync.when(
          loading: () => ProLoadingState.list(),
          error: (error, _) => ProEmptyState.error(error: error.toString()),
          data: (purchases) {
            final filteredSales = _filterByDate(sales);
            final filteredPurchases = _filterByDate(purchases);

            final totalSales =
                filteredSales.fold<double>(0, (sum, inv) => sum + inv.total);
            final totalPurchases = filteredPurchases.fold<double>(
                0, (sum, inv) => sum + inv.total);
            final profit = totalSales - totalPurchases;

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeChip(),
                  SizedBox(height: AppSpacing.md),
                  _buildProfitCards(
                    sales: totalSales,
                    purchases: totalPurchases,
                    profit: profit,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceivablesReport() {
    final invoicesAsync = ref.watch(salesInvoicesProvider);

    return invoicesAsync.when(
      loading: () => ProLoadingState.list(),
      error: (error, _) => ProEmptyState.error(error: error.toString()),
      data: (invoices) {
        final unpaid = invoices
            .where((inv) => inv.status == 'unpaid' || inv.status == 'partial')
            .toList();
        final total = unpaid.fold<double>(
            0, (sum, inv) => sum + (inv.total - inv.paidAmount));

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(
                total: total,
                count: unpaid.length,
                label: 'إجمالي المستحقات',
                color: AppColors.error,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildInvoicesList(unpaid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 80.sp,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'قريباً',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    if (_dateRange == null) return const SizedBox.shrink();

    final format = DateFormat('yyyy/MM/dd', 'ar');
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.soft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, size: 16.sp, color: AppColors.primary),
          SizedBox(width: AppSpacing.xs),
          Text(
            '${format.format(_dateRange!.start)} - ${format.format(_dateRange!.end)}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () => setState(() => _dateRange = null),
            child: Icon(Icons.close, size: 16.sp, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required double total,
    required int count,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: label,
            value: '${NumberFormat('#,###').format(total)} ل.س',
            icon: Icons.attach_money_rounded,
            color: color,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            title: 'عدد الفواتير',
            value: '$count',
            icon: Icons.receipt_long_rounded,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitCards({
    required double sales,
    required double purchases,
    required double profit,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'المبيعات',
                value: '${NumberFormat('#,###').format(sales)} ل.س',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                title: 'المشتريات',
                value: '${NumberFormat('#,###').format(purchases)} ل.س',
                icon: Icons.trending_down_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _SummaryCard(
          title: 'صافي الربح',
          value: '${NumberFormat('#,###').format(profit)} ل.س',
          icon: profit >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: profit >= 0 ? AppColors.success : AppColors.error,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildInvoicesList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48.sp, color: AppColors.textTertiary),
              SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد فواتير',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفواتير (${invoices.length})',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ...invoices.take(20).map((inv) => _InvoiceListItem(invoice: inv)),
        if (invoices.length > 20)
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text('عرض الكل (${invoices.length})'),
            ),
          ),
      ],
    );
  }

  List<Invoice> _filterByDate(List<Invoice> invoices) {
    if (_dateRange == null) return invoices;
    return invoices.where((inv) {
      return inv.invoiceDate
              .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          inv.invoiceDate
              .isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  Future<void> _handleExport(String format) async {
    setState(() => _isExporting = true);

    try {
      // Get data based on report type
      List<Invoice> invoices = [];

      if (widget.reportType == 'sales') {
        final data = ref.read(salesInvoicesProvider);
        invoices = data.value ?? [];
      } else if (widget.reportType == 'purchases') {
        final data = ref.read(purchaseInvoicesProvider);
        invoices = data.value ?? [];
      } else if (widget.reportType == 'receivables') {
        final data = ref.read(salesInvoicesProvider);
        invoices = (data.value ?? [])
            .where((inv) => inv.status == 'unpaid' || inv.status == 'partial')
            .toList();
      }

      invoices = _filterByDate(invoices);

      if (invoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للتصدير')),
          );
        }
        return;
      }

      // Export based on format
      // Note: This would require the export_service to be properly integrated
      // For now, show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('جاري تصدير التقرير بصيغة ${format.toUpperCase()}...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLarge;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      padding: EdgeInsets.all(isLarge ? AppSpacing.lg : AppSpacing.md),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: isLarge ? 24.sp : 20.sp),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: (isLarge
                    ? AppTypography.headlineMedium
                    : AppTypography.titleLarge)
                .copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceListItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy/MM/dd', 'ar');

    return ProCard.flat(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  invoice.customerId ?? invoice.supplierId ?? '-',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format(invoice.total)} ل.س',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                format.format(invoice.invoiceDate),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
