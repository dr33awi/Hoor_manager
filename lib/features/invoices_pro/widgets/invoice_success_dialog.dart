// ═══════════════════════════════════════════════════════════════════════════
// Invoice Success Dialog - حوار نجاح الفاتورة الموحد
// تصميم بسيط ونظيف
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/di/injection.dart';
import 'package:hoor_manager/core/services/printing/print_settings_service.dart';
import 'package:hoor_manager/core/services/printing/invoice_pdf_generator.dart';
import 'package:hoor_manager/core/theme/design_tokens.dart';
import 'package:printing/printing.dart';

import '../../../data/database/app_database.dart';

/// نتيجة حوار الفاتورة
enum InvoiceDialogResult {
  newInvoice,
  viewDetails,
  close,
}

/// بيانات الفاتورة للحوار
class InvoiceDialogData {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final Customer? customer;
  final Supplier? supplier;

  const InvoiceDialogData({
    required this.invoice,
    required this.items,
    this.customer,
    this.supplier,
  });

  String get partyName => customer?.name ?? supplier?.name ?? 'عميل نقدي';

  String get typeLabel {
    switch (invoice.type) {
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

  Color get typeColor {
    switch (invoice.type) {
      case 'sale':
        return AppColors.success;
      case 'purchase':
        return AppColors.purchases;
      case 'sale_return':
        return AppColors.warning;
      case 'purchase_return':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get typeIcon {
    switch (invoice.type) {
      case 'sale':
        return Icons.trending_up_rounded;
      case 'purchase':
        return Icons.shopping_cart_rounded;
      case 'sale_return':
        return Icons.undo_rounded;
      case 'purchase_return':
        return Icons.redo_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  bool get isFullyPaid => (invoice.paidAmount ?? 0) >= invoice.total;
  bool get isPartiallyPaid =>
      (invoice.paidAmount ?? 0) > 0 &&
      (invoice.paidAmount ?? 0) < invoice.total;
  double get remaining => invoice.total - (invoice.paidAmount ?? 0);
}

/// حوار نجاح الفاتورة الموحد
class InvoiceSuccessDialog extends StatefulWidget {
  final InvoiceDialogData data;
  final bool showNewInvoiceButton;
  final bool showViewDetailsButton;
  final VoidCallback? onNewInvoice;

  const InvoiceSuccessDialog({
    super.key,
    required this.data,
    this.showNewInvoiceButton = true,
    this.showViewDetailsButton = true,
    this.onNewInvoice,
  });

  static Future<InvoiceDialogResult?> show({
    required BuildContext context,
    required InvoiceDialogData data,
    bool showNewInvoiceButton = true,
    bool showViewDetailsButton = true,
    VoidCallback? onNewInvoice,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog<InvoiceDialogResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => InvoiceSuccessDialog(
        data: data,
        showNewInvoiceButton: showNewInvoiceButton,
        showViewDetailsButton: showViewDetailsButton,
        onNewInvoice: onNewInvoice,
      ),
    );
  }

  @override
  State<InvoiceSuccessDialog> createState() => _InvoiceSuccessDialogState();
}

class _InvoiceSuccessDialogState extends State<InvoiceSuccessDialog> {
  bool _isLoading = false;
  String? _loadingAction;

  Future<void> _handleAction(
      String action, Future<void> Function() task) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadingAction = action;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingAction = null;
        });
      }
    }
  }

  Future<void> _print() => _handleAction('print', () async {
        final options = await getIt<PrintSettingsService>().getPrintOptions();
        await InvoicePdfGenerator.printInvoiceDirectly(
          invoice: widget.data.invoice,
          items: widget.data.items,
          customer: widget.data.customer,
          supplier: widget.data.supplier,
          options: options,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.print_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('جاري الطباعة...'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

  Future<void> _share() => _handleAction('share', () async {
        final options = await getIt<PrintSettingsService>().getPrintOptions();
        await InvoicePdfGenerator.shareInvoiceAsPdf(
          invoice: widget.data.invoice,
          items: widget.data.items,
          customer: widget.data.customer,
          supplier: widget.data.supplier,
          options: options,
        );
      });

  Future<void> _preview() => _handleAction('preview', () async {
        final options = await getIt<PrintSettingsService>().getPrintOptions();
        final pdfBytes = await InvoicePdfGenerator.generateInvoicePdfBytes(
          invoice: widget.data.invoice,
          items: widget.data.items,
          customer: widget.data.customer,
          supplier: widget.data.supplier,
          options: options,
        );
        if (mounted) _showPreviewDialog(pdfBytes);
      });

  void _showPreviewDialog(dynamic pdfBytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text(
              'معاينة الفاتورة',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) async => pdfBytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'فاتورة_${widget.data.invoice.invoiceNumber}.pdf',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 340.w),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContent(),
                _buildActions(),
              ],
            ),
            // زر الإغلاق في الأعلى
            Positioned(
              top: 8.w,
              left: 8.w,
              child: IconButton(
                onPressed: () =>
                    Navigator.pop(context, InvoiceDialogResult.close),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textTertiary,
                  size: 20.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  padding: EdgeInsets.all(6.w),
                  minimumSize: Size(32.w, 32.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final invoice = widget.data.invoice;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.w, 16.w, 4.w),
      child: Column(
        children: [
          // أيقونة النجاح
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: widget.data.typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: widget.data.typeColor,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 12.h),

          // عنوان
          Text(
            'تم حفظ الفاتورة',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.data.typeLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 20.h),

          // معلومات الفاتورة
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _SimpleInfoRow(
                  label: 'رقم الفاتورة',
                  value: invoice.invoiceNumber,
                ),
                Divider(height: 16.h, color: AppColors.border),
                _SimpleInfoRow(
                  label:
                      invoice.type.contains('purchase') ? 'المورد' : 'العميل',
                  value: widget.data.partyName,
                ),
                Divider(height: 16.h, color: AppColors.border),
                _SimpleInfoRow(
                  label: 'التاريخ',
                  value: _formatDate(invoice.invoiceDate),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // المبلغ الإجمالي
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: widget.data.typeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.data.typeColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          invoice.total.toStringAsFixed(2),
                          style: AppTypography.headlineSmall.copyWith(
                            color: widget.data.typeColor,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'ر.س',
                          style: AppTypography.bodySmall.copyWith(
                            color: widget.data.typeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // تفاصيل الدفع الجزئي
                if (widget.data.isPartiallyPaid) ...[
                  SizedBox(height: 12.h),
                  Divider(
                      height: 1, color: widget.data.typeColor.withOpacity(0.2)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المدفوع',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${(invoice.paidAmount ?? 0).toStringAsFixed(2)} ر.س',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المتبقي',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.data.remaining.toStringAsFixed(2)} ر.س',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ],

                // حالة الدفع
                if (!widget.data.isPartiallyPaid) ...[
                  SizedBox(height: 8.h),
                  _PaymentStatusBadge(data: widget.data),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // أزرار الإجراءات السريعة
          Row(
            children: [
              _SimpleActionButton(
                icon: Icons.print_rounded,
                label: 'طباعة',
                isLoading: _loadingAction == 'print',
                onTap: _isLoading ? null : _print,
              ),
              SizedBox(width: 12.w),
              _SimpleActionButton(
                icon: Icons.visibility_rounded,
                label: 'معاينة',
                isLoading: _loadingAction == 'preview',
                onTap: _isLoading ? null : _preview,
              ),
              SizedBox(width: 12.w),
              _SimpleActionButton(
                icon: Icons.share_rounded,
                label: 'مشاركة',
                isLoading: _loadingAction == 'share',
                onTap: _isLoading ? null : _share,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 16.w),
      child: Column(
        children: [
          // عرض التفاصيل
          if (widget.showViewDetailsButton) ...[
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, InvoiceDialogResult.viewDetails);
                  context.push('/invoices/${widget.data.invoice.id}');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  'عرض التفاصيل',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets المساعدة
// ═══════════════════════════════════════════════════════════════════════════

/// صف معلومات بسيط
class _SimpleInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// شارة حالة الدفع
class _PaymentStatusBadge extends StatelessWidget {
  final InvoiceDialogData data;

  const _PaymentStatusBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (data.isFullyPaid) {
      text = 'مدفوعة بالكامل';
      color = AppColors.success;
    } else {
      text = 'آجل';
      color = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// زر إجراء بسيط
class _SimpleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SimpleActionButton({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
