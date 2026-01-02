// ═══════════════════════════════════════════════════════════════════════════
// Returns Screen Pro - Unified Returns Management
// Handles both Sales Returns and Purchase Returns
// Replaces: sales_returns_screen_pro.dart & purchase_returns_screen_pro.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

/// نوع المرتجع
enum ReturnType {
  sales,
  purchase,
}

extension ReturnTypeExtension on ReturnType {
  String get title =>
      this == ReturnType.sales ? 'مرتجعات المبيعات' : 'مرتجعات المشتريات';
  String get subtitle => this == ReturnType.sales
      ? 'إدارة مرتجعات العملاء'
      : 'إدارة مرتجعات الموردين';
  String get invoiceType =>
      this == ReturnType.sales ? 'sale_return' : 'purchase_return';
  String get originalInvoiceType =>
      this == ReturnType.sales ? 'sale' : 'purchase';
  String get newReturnTitle =>
      this == ReturnType.sales ? 'مرتجع مبيعات جديد' : 'مرتجع مشتريات جديد';
  String get selectInvoiceLabel => this == ReturnType.sales
      ? 'اختر فاتورة المبيعات'
      : 'اختر فاتورة المشتريات';
  String get partyField =>
      this == ReturnType.sales ? 'customerId' : 'supplierId';
  String get searchHint => this == ReturnType.sales
      ? 'بحث برقم الفاتورة أو العميل...'
      : 'بحث برقم الفاتورة أو المورد...';
  Color get accentColor =>
      this == ReturnType.sales ? AppColors.error : AppColors.warning;
}

class ReturnsScreenPro extends ConsumerStatefulWidget {
  final ReturnType type;

  const ReturnsScreenPro({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<ReturnsScreenPro> createState() => _ReturnsScreenProState();
}

class _ReturnsScreenProState extends ConsumerState<ReturnsScreenPro> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Provider based on type
  // ═══════════════════════════════════════════════════════════════════════════

  StreamProvider<List<Invoice>> get _returnsProvider =>
      widget.type == ReturnType.sales
          ? salesReturnsStreamProvider
          : purchaseReturnsStreamProvider;

  // ═══════════════════════════════════════════════════════════════════════════
  // Filter Logic
  // ═══════════════════════════════════════════════════════════════════════════

  List<Invoice> _filterReturns(List<Invoice> returns) {
    var filtered = returns;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final partyId =
            widget.type == ReturnType.sales ? r.customerId : r.supplierId;
        return r.invoiceNumber.contains(_searchQuery) ||
            (partyId?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    if (_dateRange != null) {
      filtered = filtered.where((r) {
        return r.createdAt.isAfter(_dateRange!.start) &&
            r.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(_returnsProvider);

    return ProSimpleScaffold(
      header: _buildHeader(returnsAsync),
      searchWidget: _buildFilters(),
      body: returnsAsync.when(
        loading: () => const ProLoadingState(),
        error: (error, _) => ProErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(_returnsProvider),
        ),
        data: (returns) {
          final filtered = _filterReturns(returns);
          return filtered.isEmpty
              ? ProEmptyState.returns(isSales: widget.type == ReturnType.sales)
              : _buildReturnsList(filtered);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewReturnSheet(),
        backgroundColor: widget.type.accentColor,
        icon: const Icon(Icons.assignment_return_rounded, color: Colors.white),
        label: Text(
          'مرتجع جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Invoice>> returnsAsync) {
    return ProHeader(
      title: widget.type.title,
      subtitle: widget.type.subtitle,
      onBack: () => context.pop(),
      actions: [
        returnsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (returns) {
            final total = returns.fold<double>(0, (sum, r) => sum + r.total);
            return ProStatsChip(
              count: returns.length,
              total: total,
              color: widget.type.accentColor,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return ProSearchBarWithDateRange(
      controller: _searchController,
      hintText: widget.type.searchHint,
      onChanged: (value) => setState(() => _searchQuery = value),
      dateRange: _dateRange,
      onDateRangeTap: _selectDateRange,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: widget.type.accentColor),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Widget _buildReturnsList(List<Invoice> returns) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_returnsProvider),
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: returns.length,
        itemBuilder: (context, index) => _ReturnCard(
          returnInvoice: returns[index],
          type: widget.type,
          onTap: () => context.push('/invoices/${returns[index].id}'),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // New Return Sheet
  // ═══════════════════════════════════════════════════════════════════════════

  void _showNewReturnSheet() {
    Invoice? selectedInvoice;
    final reasonController = TextEditingController();
    final invoicesAsync = ref.read(invoicesStreamProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: widget.type.accentColor.soft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.assignment_return_rounded,
                        color: widget.type.accentColor,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      widget.type.newReturnTitle,
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),

                // Select Invoice
                Text(widget.type.selectInvoiceLabel,
                    style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                invoicesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل الفواتير'),
                  data: (invoices) {
                    final filteredInvoices = invoices
                        .where((i) =>
                            i.type == widget.type.originalInvoiceType &&
                            i.status != 'returned')
                        .toList();
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Invoice>(
                          isExpanded: true,
                          value: selectedInvoice,
                          hint: const Text('اختر الفاتورة'),
                          items: filteredInvoices
                              .map((i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      '${i.invoiceNumber} - ${NumberFormat('#,###').format(i.total)} ل.س',
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setSheetState(() => selectedInvoice = value),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppSpacing.md),

                // Reason
                Text('سبب الإرجاع', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: widget.type == ReturnType.sales
                        ? 'أدخل سبب إرجاع المنتجات'
                        : 'أدخل سبب إرجاع المنتجات للمورد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: selectedInvoice != null
                            ? () => _createReturn(
                                  invoice: selectedInvoice!,
                                  reason: reasonController.text,
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.type.accentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('إنشاء المرتجع'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createReturn({
    required Invoice invoice,
    required String reason,
  }) async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      // Get original invoice items
      final items = await invoiceRepo.getInvoiceItems(invoice.id);

      final Map<String, dynamic> invoiceData = {
        'type': widget.type.invoiceType,
        'items': items
            .map((item) => {
                  'productId': item.productId,
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'purchasePrice': item.purchasePrice,
                })
            .toList(),
        'paymentMethod': invoice.paymentMethod,
        'notes': reason.isEmpty
            ? 'مرتجع ${widget.type == ReturnType.sales ? "مبيعات" : "مشتريات"} - فاتورة رقم: ${invoice.invoiceNumber}'
            : reason,
      };

      // Add customer or supplier based on type
      if (widget.type == ReturnType.sales) {
        invoiceData['customerId'] = invoice.customerId;
      } else {
        invoiceData['supplierId'] = invoice.supplierId;
      }

      await invoiceRepo.createInvoice(
        type: invoiceData['type'],
        customerId: invoiceData['customerId'],
        supplierId: invoiceData['supplierId'],
        items: invoiceData['items'],
        paymentMethod: invoiceData['paymentMethod'],
        notes: invoiceData['notes'],
      );

      if (mounted) {
        Navigator.pop(context);
        ProSnackbar.success(context, 'تم إنشاء المرتجع بنجاح');
      }
    } catch (e) {
      if (mounted) {
        ProSnackbar.showError(context, e);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Return Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _ReturnCard extends StatelessWidget {
  final Invoice returnInvoice;
  final ReturnType type;
  final VoidCallback onTap;

  const _ReturnCard({
    required this.returnInvoice,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    final partyId = type == ReturnType.sales
        ? returnInvoice.customerId
        : returnInvoice.supplierId;

    return ProCard(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      borderColor: type.accentColor.border,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: type.accentColor.soft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.assignment_return_rounded,
                  color: type.accentColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      returnInvoice.invoiceNumber,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dateFormat.format(returnInvoice.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(returnInvoice.total)} ل.س',
                style: AppTypography.titleMedium.copyWith(
                  color: type.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (partyId != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    type == ReturnType.sales
                        ? Icons.person_outline
                        : Icons.business_outlined,
                    size: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    partyId,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14.sp, color: AppColors.textTertiary),
                  SizedBox(width: 4.w),
                  Text(
                    returnInvoice.status,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}
