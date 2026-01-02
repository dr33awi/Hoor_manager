// ═══════════════════════════════════════════════════════════════════════════
// Unified Transactions Screen Pro
// Sales & Purchase Invoices - Single Source of Truth
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
import '../dashboard_pro/widgets/pro_navigation_drawer.dart';

/// نوع المعاملة
enum TransactionType {
  sales,
  purchase;

  String get label => this == TransactionType.sales ? 'المبيعات' : 'المشتريات';
  String get invoiceType => this == TransactionType.sales ? 'sale' : 'purchase';
  String get singularLabel =>
      this == TransactionType.sales ? 'فاتورة بيع' : 'فاتورة شراء';
  String get partyLabel => this == TransactionType.sales ? 'العميل' : 'المورد';
  String get route => this == TransactionType.sales ? '/sales' : '/purchases';
  String get newRoute =>
      this == TransactionType.sales ? '/sales' : '/invoices/add/purchase';
  Color get color =>
      this == TransactionType.sales ? AppColors.income : AppColors.purchases;
  IconData get icon => this == TransactionType.sales
      ? Icons.point_of_sale_rounded
      : Icons.shopping_cart_rounded;
}

class TransactionsScreenPro extends ConsumerStatefulWidget {
  final TransactionType type;

  const TransactionsScreenPro({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<TransactionsScreenPro> createState() =>
      _TransactionsScreenProState();
}

class _TransactionsScreenProState extends ConsumerState<TransactionsScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  DateTimeRange? _dateRange;

  bool get isSales => widget.type == TransactionType.sales;

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

  // ═══════════════════════════════════════════════════════════════════════════
  // Filter Logic
  // ═══════════════════════════════════════════════════════════════════════════

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    List<Invoice> filtered =
        invoices.where((i) => i.type == widget.type.invoiceType).toList();

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((i) {
        return i.invoiceNumber.toLowerCase().contains(query) ||
            (isSales
                ? i.customerId?.toLowerCase().contains(query) ?? false
                : i.supplierId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by status
    if (_filterStatus != 'all') {
      filtered = filtered.where((i) {
        if (_filterStatus == 'completed') {
          return i.status == 'completed' || i.status == 'paid';
        }
        if (_filterStatus == 'pending') {
          return i.status == 'pending' || i.status == 'partial';
        }
        return i.status == _filterStatus;
      }).toList();
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

    // Sort by date descending
    filtered.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    return filtered;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ProNavigationDrawer(currentRoute: widget.type.route),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            invoicesAsync.when(
              loading: () => _buildStatsLoading(),
              error: (_, __) => const SizedBox.shrink(),
              data: (invoices) => _buildStatsRow(
                invoices
                    .where((i) => i.type == widget.type.invoiceType)
                    .toList(),
              ),
            ),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: invoicesAsync.when(
                loading: () => const ProLoadingState(),
                error: (error, _) => ProEmptyState(
                  icon: Icons.error_outline,
                  title: 'حدث خطأ',
                  message: error.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => ref.invalidate(invoicesStreamProvider),
                ),
                data: (invoices) => _buildInvoicesList(invoices),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(widget.type.newRoute),
        backgroundColor: widget.type.color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          widget.type.singularLabel,
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: widget.type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              widget.type.icon,
              color: widget.type.color,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.type.label,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'إدارة ${widget.type.singularLabel}ات',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: Badge(
              isLabelVisible: _dateRange != null,
              child: const Icon(Icons.filter_list_rounded),
            ),
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
      margin: EdgeInsets.all(AppSpacing.md),
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }

  Widget _buildStatsRow(List<Invoice> invoices) {
    final total = invoices.fold(0.0, (sum, inv) => sum + inv.total);
    final paid = invoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);
    final pending = total - paid;
    final thisMonth = invoices.where((inv) {
      final now = DateTime.now();
      return inv.invoiceDate.month == now.month &&
          inv.invoiceDate.year == now.year;
    }).fold(0.0, (sum, inv) => sum + inv.total);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'الإجمالي',
              value: total,
              icon: Icons.account_balance_wallet_rounded,
              color: widget.type.color,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              title: 'هذا الشهر',
              value: thisMonth,
              icon: Icons.calendar_month_rounded,
              color: AppColors.info,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              title: isSales ? 'المستحق' : 'المتبقي',
              value: pending,
              icon: Icons.pending_actions_rounded,
              color: pending > 0 ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ProSearchBar(
      controller: _searchController,
      hintText: 'بحث برقم الفاتورة أو ${widget.type.partyLabel}...',
      onChanged: (value) => setState(() {}),
      onClear: () => setState(() {}),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
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
          color: widget.type.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle:
            AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'مكتملة'),
          Tab(text: 'معلقة'),
          Tab(text: 'ملغية'),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(List<Invoice> invoices) {
    final filtered = _filterInvoices(invoices);

    if (filtered.isEmpty) {
      return ProEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد فواتير',
        message: 'أنشئ ${widget.type.singularLabel} جديدة للبدء',
        actionLabel: widget.type.singularLabel,
        onAction: () => context.push(widget.type.newRoute),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(invoicesStreamProvider),
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final invoice = filtered[index];
          return _InvoiceCard(
            invoice: invoice,
            type: widget.type,
            partyNameFuture: _getPartyName(invoice),
            onTap: () => context.push('/invoices/${invoice.id}'),
          );
        },
      ),
    );
  }

  Future<String> _getPartyName(Invoice invoice) async {
    try {
      if (isSales) {
        if (invoice.customerId == null) return 'عميل نقدي';
        final customerRepo = ref.read(customerRepositoryProvider);
        final customer =
            await customerRepo.getCustomerById(invoice.customerId!);
        return customer?.name ?? 'غير محدد';
      } else {
        if (invoice.supplierId == null) return 'غير محدد';
        final supplierRepo = ref.read(supplierRepositoryProvider);
        final supplier =
            await supplierRepo.getSupplierById(invoice.supplierId!);
        return supplier?.name ?? 'غير محدد';
      }
    } catch (_) {
      return 'غير محدد';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تصفية النتائج', style: AppTypography.titleLarge),
            SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.date_range_rounded),
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
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filterStatus = 'all';
                    _dateRange = null;
                    _searchController.clear();
                    _tabController.animateTo(0);
                  });
                  Navigator.pop(context);
                },
                child: const Text('مسح الفلاتر'),
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stat Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10.sp,
            ),
          ),
          Text(
            value.toStringAsFixed(0),
            style: AppTypography.titleSmall.copyWith(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Invoice Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final TransactionType type;
  final Future<String> partyNameFuture;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.type,
    required this.partyNameFuture,
    required this.onTap,
  });

  Color get _statusColor {
    switch (invoice.status) {
      case 'completed':
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'partial':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    final isPaid = invoice.paidAmount >= invoice.total;
    final isPartial =
        invoice.paidAmount > 0 && invoice.paidAmount < invoice.total;

    if (invoice.status == 'cancelled') return 'ملغية';
    if (isPaid) return 'مكتملة';
    if (isPartial) return 'جزئي';
    return 'معلقة';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ProCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              // Type Icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  type.icon,
                  color: type.color,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Invoice Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: AppTypography.titleSmall.copyWith(
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    FutureBuilder<String>(
                      future: partyNameFuture,
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? '...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Status Badge
              ProStatusBadge.fromInvoiceStatus(invoice.status, small: true),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14.sp,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                dateFormat.format(invoice.invoiceDate),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Icon(
                invoice.paymentMethod == 'cash'
                    ? Icons.payments_rounded
                    : Icons.credit_card_rounded,
                size: 14.sp,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                invoice.paymentMethod == 'cash' ? 'نقدي' : 'آجل',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${invoice.total.toStringAsFixed(2)} ر.س',
                style: AppTypography.titleMedium.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                  color: type.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
