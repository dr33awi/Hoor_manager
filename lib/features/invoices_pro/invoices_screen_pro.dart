// ═══════════════════════════════════════════════════════════════════════════
// Invoices Screen Pro - Professional Design System
// Sales & Purchase Invoices List with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pro/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';
import 'widgets/invoice_card_pro.dart';
import 'widgets/invoices_stats_header.dart';

class InvoicesScreenPro extends ConsumerStatefulWidget {
  final String? type; // 'sale' or 'purchase' or null for all

  const InvoicesScreenPro({
    super.key,
    this.type,
  });

  @override
  ConsumerState<InvoicesScreenPro> createState() => _InvoicesScreenProState();
}

class _InvoicesScreenProState extends ConsumerState<InvoicesScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  DateTimeRange? _dateRange;

  bool get isSales => widget.type == null || widget.type == 'sale';

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

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    List<Invoice> filtered = List.from(invoices);

    // Filter by type
    if (widget.type != null) {
      filtered = filtered.where((i) => i.type == widget.type).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((i) {
        return i.invoiceNumber.toLowerCase().contains(query) ||
            (i.customerId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by status
    if (_filterStatus != 'all') {
      filtered = filtered.where((i) => i.status == _filterStatus).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((i) {
        return i.invoiceDate
                .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            i.invoiceDate
                .isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // Header
            // ═══════════════════════════════════════════════════════════════
            _buildHeader(),

            // ═══════════════════════════════════════════════════════════════
            // Stats Header
            // ═══════════════════════════════════════════════════════════════
            invoicesAsync.when(
              loading: () => _buildStatsLoading(),
              error: (_, __) => const SizedBox.shrink(),
              data: (invoices) {
                final filtered = widget.type != null
                    ? invoices.where((i) => i.type == widget.type).toList()
                    : invoices;
                final totalAmount =
                    filtered.fold(0.0, (sum, i) => sum + i.total);
                final paidAmount =
                    filtered.fold(0.0, (sum, i) => sum + i.paidAmount);
                final pendingAmount = totalAmount - paidAmount;

                return InvoicesStatsHeader(
                  totalAmount: totalAmount,
                  paidAmount: paidAmount,
                  pendingAmount: pendingAmount,
                  overdueAmount: 0, // TODO: Calculate overdue
                  isSales: isSales,
                );
              },
            ),

            // ═══════════════════════════════════════════════════════════════
            // Search & Filters
            // ═══════════════════════════════════════════════════════════════
            _buildSearchAndFilters(),

            // ═══════════════════════════════════════════════════════════════
            // Tabs
            // ═══════════════════════════════════════════════════════════════
            _buildTabs(),

            // ═══════════════════════════════════════════════════════════════
            // Invoices List
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child: invoicesAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
                data: (invoices) {
                  final filtered = _filterInvoices(invoices);

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(invoicesStreamProvider);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: AppSpacing.md.h),
                      itemBuilder: (context, index) {
                        final invoice = filtered[index];
                        return InvoiceCardPro(
                          invoice: _invoiceToMap(invoice),
                          onTap: () => context.push('/invoices/${invoice.id}'),
                          isSales: invoice.type == 'sale',
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(isSales ? '/sales' : '/purchases/add'),
        backgroundColor: isSales ? AppColors.income : AppColors.purchases,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isSales ? 'فاتورة بيع' : 'فاتورة شراء',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_ios_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSales ? 'فواتير المبيعات' : 'فواتير المشتريات',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'إدارة الفواتير والمدفوعات',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
      height: 100.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث برقم الفاتورة...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.md.h,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: AppSpacing.md.h),

          // Date Range Chip
          if (_dateRange != null)
            Wrap(
              spacing: AppSpacing.sm.w,
              children: [
                Chip(
                  label: Text(
                    '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _dateRange = null),
                  backgroundColor: AppColors.secondaryMuted,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            switch (index) {
              case 0:
                _filterStatus = 'all';
                break;
              case 1:
                _filterStatus = 'completed';
                break;
              case 2:
                _filterStatus = 'pending';
                break;
              case 3:
                _filterStatus = 'cancelled';
                break;
            }
          });
        },
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'مكتملة'),
          Tab(text: 'معلقة'),
          Tab(text: 'ملغية'),
        ],
      ),
    );
  }

  Map<String, dynamic> _invoiceToMap(Invoice invoice) {
    String statusText = 'مكتملة';
    if (invoice.status == 'pending') statusText = 'معلقة';
    if (invoice.status == 'cancelled') statusText = 'ملغية';
    if (invoice.paidAmount < invoice.total && invoice.status != 'cancelled') {
      statusText = 'جزئي';
    }

    return {
      'id': invoice.invoiceNumber,
      'customer': invoice.customerId ?? 'عميل نقدي',
      'supplier': invoice.supplierId ?? 'مورد',
      'date': DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
      'total': invoice.total,
      'paid': invoice.paidAmount,
      'status': statusText,
      'items': 0, // Will be loaded separately
      'paymentMethod': invoice.paymentMethod,
    };
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.screenPadding.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية النتائج',
              style: AppTypography.titleLarge,
            ),
            SizedBox(height: AppSpacing.lg.h),

            // Date Range Picker
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('فترة زمنية'),
              subtitle: _dateRange != null
                  ? Text(
                      '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}')
                  : const Text('اختر فترة'),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('ar'),
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),

            SizedBox(height: AppSpacing.lg.h),

            // Clear Filters
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filterStatus = 'all';
                    _dateRange = null;
                    _searchController.clear();
                  });
                  Navigator.pop(context);
                },
                child: const Text('مسح الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
      itemBuilder: (context, index) {
        return Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80.sp,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text(
            'لا توجد فواتير',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            'أنشئ فاتورة جديدة للبدء',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
          ElevatedButton.icon(
            onPressed: () =>
                context.push(isSales ? '/sales' : '/purchases/add'),
            icon: const Icon(Icons.add),
            label: Text(isSales ? 'فاتورة بيع جديدة' : 'فاتورة شراء جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSales ? AppColors.income : AppColors.purchases,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: AppColors.expense,
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text(
            'حدث خطأ',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.expense,
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(invoicesStreamProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
