/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Details Screen - Redesigned
/// Modern Invoice Details View
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/invoice_actions_sheet.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../../../data/repositories/supplier_repository.dart';

class InvoiceDetailsScreenRedesign extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreenRedesign({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreenRedesign> createState() =>
      _InvoiceDetailsScreenRedesignState();
}

class _InvoiceDetailsScreenRedesignState
    extends State<InvoiceDetailsScreenRedesign> {
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _customerRepo = getIt<CustomerRepository>();
  final _supplierRepo = getIt<SupplierRepository>();
  final _currencyService = getIt<CurrencyService>();

  Invoice? _invoice;
  List<InvoiceItem> _items = [];
  Customer? _customer;
  Supplier? _supplier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);

    try {
      final invoice = await _invoiceRepo.getInvoiceById(widget.invoiceId);
      if (invoice == null) {
        if (mounted) {
          _showErrorSnackBar('الفاتورة غير موجودة');
          context.pop();
        }
        return;
      }

      final items = await _invoiceRepo.getInvoiceItems(widget.invoiceId);

      Customer? customer;
      Supplier? supplier;

      if (invoice.customerId != null) {
        customer = await _customerRepo.getCustomerById(invoice.customerId!);
      }
      if (invoice.supplierId != null) {
        supplier = await _supplierRepo.getSupplierById(invoice.supplierId!);
      }

      setState(() {
        _invoice = invoice;
        _items = items;
        _customer = customer;
        _supplier = supplier;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackBar('خطأ في تحميل الفاتورة: $e');
    }
  }

  String _toUsd(double sypAmount) {
    final rate = _invoice?.exchangeRate ?? _currencyService.exchangeRate;
    if (rate <= 0) return '\$0.00';
    return '\$${(sypAmount / rate).toStringAsFixed(2)}';
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  Color get _typeColor {
    switch (_invoice?.type) {
      case 'sale':
        return HoorColors.success;
      case 'purchase':
        return HoorColors.warning;
      case 'sale_return':
      case 'purchase_return':
        return HoorColors.error;
      default:
        return HoorColors.primary;
    }
  }

  String get _typeLabel {
    switch (_invoice?.type) {
      case 'sale':
        return 'فاتورة مبيعات';
      case 'purchase':
        return 'فاتورة مشتريات';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      default:
        return 'فاتورة';
    }
  }

  IconData get _typeIcon {
    switch (_invoice?.type) {
      case 'sale':
        return Icons.point_of_sale_rounded;
      case 'purchase':
        return Icons.shopping_cart_rounded;
      case 'sale_return':
      case 'purchase_return':
        return Icons.assignment_return_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل الفاتورة', style: HoorTypography.headlineSmall),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: HoorColors.primary)),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل الفاتورة', style: HoorTypography.headlineSmall),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: HoorColors.textSecondary),
              SizedBox(height: HoorSpacing.md.h),
              Text('الفاتورة غير موجودة', style: HoorTypography.titleMedium),
            ],
          ),
        ),
      );
    }

    final invoice = _invoice!;

    return Scaffold(
      backgroundColor: HoorColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(invoice),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Card
                  _buildTotalCard(invoice),
                  SizedBox(height: HoorSpacing.md.h),

                  // Contact Card
                  if (_customer != null || _supplier != null) ...[
                    _buildContactCard(),
                    SizedBox(height: HoorSpacing.md.h),
                  ],

                  // Items Card
                  _buildItemsCard(),
                  SizedBox(height: HoorSpacing.md.h),

                  // Payment Card
                  _buildPaymentCard(invoice),

                  // Notes
                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                    SizedBox(height: HoorSpacing.md.h),
                    _buildNotesCard(invoice.notes!),
                  ],

                  SizedBox(height: HoorSpacing.xl.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(invoice),
    );
  }

  Widget _buildAppBar(Invoice invoice) {
    return SliverAppBar(
      expandedHeight: 160.h,
      pinned: true,
      backgroundColor: _typeColor,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _editInvoice(invoice);
                break;
              case 'delete':
                await _deleteInvoice(invoice);
                break;
              case 'share':
                // TODO: Share invoice
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, color: HoorColors.textSecondary),
                  SizedBox(width: 12),
                  Text('تعديل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded, color: HoorColors.textSecondary),
                  SizedBox(width: 12),
                  Text('مشاركة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: HoorColors.error),
                  SizedBox(width: 12),
                  Text('حذف', style: TextStyle(color: HoorColors.error)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: HoorSpacing.xs.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _typeColor,
                _typeColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(HoorSpacing.sm.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                      child: Icon(_typeIcon, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel,
                          style: HoorTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          invoice.invoiceNumber,
                          style: HoorTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(invoice.invoiceDate),
                  style: HoorTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: HoorSpacing.md.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(Invoice invoice) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: HoorTypography.titleMedium.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(invoice.total),
                    style: HoorTypography.headlineMedium.copyWith(
                      color: _typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _toUsd(invoice.total),
                    style: HoorTypography.bodySmall.copyWith(
                      color: HoorColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (invoice.discountAmount > 0) ...[
            Divider(color: HoorColors.border, height: HoorSpacing.lg.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.discount_rounded,
                        size: 18, color: HoorColors.error),
                    SizedBox(width: HoorSpacing.xs.w),
                    Text('الخصم',
                        style: HoorTypography.bodyMedium
                            .copyWith(color: HoorColors.error)),
                  ],
                ),
                Text(
                  '-${_formatPrice(invoice.discountAmount)}',
                  style: HoorTypography.titleMedium.copyWith(
                    color: HoorColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final isCustomer = _customer != null;
    final name = isCustomer ? _customer!.name : _supplier!.name;
    final phone = isCustomer ? _customer!.phone : _supplier!.phone;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: (isCustomer ? HoorColors.primary : HoorColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(
              isCustomer ? Icons.person_rounded : Icons.business_rounded,
              color: isCustomer ? HoorColors.primary : HoorColors.warning,
              size: 24,
            ),
          ),
          SizedBox(width: HoorSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCustomer ? 'العميل' : 'المورد',
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (phone != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.sm.w,
                vertical: HoorSpacing.xxs.h,
              ),
              decoration: BoxDecoration(
                color: HoorColors.background,
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_rounded,
                      size: 14, color: HoorColors.textSecondary),
                  SizedBox(width: HoorSpacing.xxs.w),
                  Text(
                    phone,
                    style: HoorTypography.labelMedium.copyWith(
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

  Widget _buildItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Icon(Icons.shopping_basket_rounded,
                    color: _typeColor, size: HoorIconSize.sm),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  'المنتجات',
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: HoorSpacing.sm.w,
                    vertical: HoorSpacing.xxs.h,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.sm),
                  ),
                  child: Text(
                    '${_items.length} منتج',
                    style: HoorTypography.labelMedium.copyWith(
                      color: _typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: HoorColors.border, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) =>
                Divider(color: HoorColors.border, height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: EdgeInsets.all(HoorSpacing.sm.w),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(HoorRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: HoorTypography.labelMedium.copyWith(
                            color: _typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: HoorTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(item.unitPrice * item.quantity),
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Invoice invoice) {
    final isPaid = invoice.paidAmount >= invoice.total;
    final remaining = invoice.total - invoice.paidAmount;

    String paymentLabel;
    switch (invoice.paymentMethod) {
      case 'cash':
        paymentLabel = 'نقدي';
        break;
      case 'card':
        paymentLabel = 'بطاقة';
        break;
      case 'transfer':
        paymentLabel = 'تحويل';
        break;
      case 'credit':
        paymentLabel = 'آجل';
        break;
      case 'partial':
        paymentLabel = 'جزئي';
        break;
      default:
        paymentLabel = invoice.paymentMethod;
    }

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'معلومات الدفع',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Row(
            children: [
              _buildPaymentItem(
                label: 'طريقة الدفع',
                value: paymentLabel,
                icon: Icons.credit_card_rounded,
              ),
              SizedBox(width: HoorSpacing.sm.w),
              _buildPaymentItem(
                label: 'المدفوع',
                value: _formatPrice(invoice.paidAmount),
                icon: Icons.check_circle_rounded,
                color: HoorColors.success,
              ),
            ],
          ),
          if (!isPaid) ...[
            SizedBox(height: HoorSpacing.sm.h),
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: HoorColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.md),
                border: Border.all(
                    color: HoorColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded,
                      color: HoorColors.warning, size: 20),
                  SizedBox(width: HoorSpacing.sm.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المبلغ المتبقي',
                          style: HoorTypography.labelSmall.copyWith(
                            color: HoorColors.warning,
                          ),
                        ),
                        Text(
                          _formatPrice(remaining),
                          style: HoorTypography.titleMedium.copyWith(
                            color: HoorColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.sm.w),
        decoration: BoxDecoration(
          color: HoorColors.background,
          borderRadius: BorderRadius.circular(HoorRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? HoorColors.textSecondary),
            SizedBox(width: HoorSpacing.xs.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: HoorTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded,
                  color: HoorColors.info, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'ملاحظات',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Text(
            notes,
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Invoice invoice) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        border: Border(top: BorderSide(color: HoorColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editInvoice(invoice),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('تعديل'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () =>
                    InvoiceActionsSheet.showPrintDialog(context, invoice),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _editInvoice(Invoice invoice) async {
    final result = await context.push<bool>(
      '/invoices/edit/${invoice.id}/${invoice.type}',
    );

    if (result == true) {
      _loadInvoice();
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: const Text('حذف الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف الفاتورة ${invoice.invoiceNumber}؟'),
            SizedBox(height: HoorSpacing.md.h),
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: HoorColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
                border: Border.all(
                    color: HoorColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: HoorColors.warning, size: 20),
                  SizedBox(width: HoorSpacing.xs.w),
                  Expanded(
                    child: Text(
                      'سيتم إرجاع الكميات للمخزون تلقائياً',
                      style: HoorTypography.labelSmall.copyWith(
                        color: HoorColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _invoiceRepo.deleteInvoiceWithReverse(invoice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف الفاتورة وإرجاع الكميات للمخزون'),
              backgroundColor: HoorColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
            ),
          );
          context.pop();
        }
      } catch (e) {
        _showErrorSnackBar('خطأ في حذف الفاتورة: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HoorColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
      ),
    );
  }
}
