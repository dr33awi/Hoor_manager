// ═══════════════════════════════════════════════════════════════════════════
// Purchase Returns Screen Pro - Professional Design System
// Modern Purchase Returns Management Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class PurchaseReturnsScreenPro extends ConsumerStatefulWidget {
  const PurchaseReturnsScreenPro({super.key});

  @override
  ConsumerState<PurchaseReturnsScreenPro> createState() =>
      _PurchaseReturnsScreenProState();
}

class _PurchaseReturnsScreenProState
    extends ConsumerState<PurchaseReturnsScreenPro> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(purchaseReturnsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: returnsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error.toString()),
                data: (returns) {
                  var filtered = _filterReturns(returns);
                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildReturnsList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewReturnSheet(),
        backgroundColor: AppColors.warning,
        icon: const Icon(Icons.assignment_return_rounded, color: Colors.white),
        label: Text(
          'مرتجع جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  List<Invoice> _filterReturns(List<Invoice> returns) {
    var filtered = returns;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        return r.invoiceNumber.contains(_searchQuery) ||
            (r.supplierId?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرتجعات المشتريات',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'إدارة مرتجعات الموردين',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          _buildStatsChip(),
        ],
      ),
    );
  }

  Widget _buildStatsChip() {
    final returnsAsync = ref.watch(purchaseReturnsStreamProvider);

    return returnsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (returns) {
        final total = returns.fold<double>(0, (sum, r) => sum + r.total);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(
                '${returns.length}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormat.compact(locale: 'ar').format(total),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث برقم الفاتورة أو المورد...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Date Filter
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: _dateRange != null
                    ? AppColors.secondary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _dateRange != null
                      ? AppColors.secondary
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18.sp,
                    color: _dateRange != null
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                  ),
                  if (_dateRange != null) ...[
                    SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: () => setState(() => _dateRange = null),
                      icon: Icon(Icons.close, size: 16.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: AppSpacing.md),
          Text('حدث خطأ', style: AppTypography.titleMedium),
          SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_return_rounded,
                size: 64.sp,
                color: AppColors.warning,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد مرتجعات',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'سجل مرتجعات المشتريات سيظهر هنا',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnsList(List<Invoice> returns) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: returns.length,
      itemBuilder: (context, index) {
        return _ReturnCard(
          returnInvoice: returns[index],
          onTap: () => context.push('/invoices/${returns[index].id}'),
        );
      },
    );
  }

  void _showNewReturnSheet() {
    final invoicesAsync = ref.read(invoicesStreamProvider);

    Invoice? selectedInvoice;
    final reasonController = TextEditingController();

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
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.assignment_return_rounded,
                          color: AppColors.warning),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      'مرتجع مشتريات جديد',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),

                // Select Invoice
                Text('اختر فاتورة المشتريات', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                invoicesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل الفواتير'),
                  data: (invoices) {
                    final purchaseInvoices = invoices
                        .where((i) =>
                            i.type == 'purchase' && i.status != 'returned')
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
                          items: purchaseInvoices
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
                    hintText: 'أدخل سبب إرجاع المنتجات للمورد',
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
                          backgroundColor: AppColors.warning,
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
      await invoiceRepo.createInvoice(
        type: 'purchase_return',
        supplierId: invoice.supplierId,
        items: items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'price': item.unitPrice,
                })
            .toList(),
        paymentMethod: invoice.paymentMethod,
        notes: reason.isEmpty
            ? 'مرتجع مشتريات - فاتورة رقم: ${invoice.invoiceNumber}'
            : reason,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء المرتجع بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Return Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _ReturnCard extends StatelessWidget {
  final Invoice returnInvoice;
  final VoidCallback onTap;

  const _ReturnCard({
    required this.returnInvoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        boxShadow: AppShadows.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.assignment_return_rounded,
                      color: AppColors.warning,
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
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (returnInvoice.supplierId != null) ...[
                SizedBox(height: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined,
                          size: 16.sp, color: AppColors.textSecondary),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        returnInvoice.supplierId!,
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
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
