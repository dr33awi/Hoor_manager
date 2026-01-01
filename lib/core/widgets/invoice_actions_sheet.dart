import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../di/injection.dart';
import '../services/printing/printing_services.dart';
import '../services/print_settings_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../theme/redesign/design_tokens.dart';
import '../theme/redesign/typography.dart';
import 'invoice_widgets.dart';
import 'print_dialog.dart';

/// Bottom Sheet موحد لعرض خيارات الفاتورة (معاينة، طباعة، مشاركة)
class InvoiceActionsSheet extends StatelessWidget {
  final Invoice invoice;
  final bool showDetails;

  const InvoiceActionsSheet({
    super.key,
    required this.invoice,
    this.showDetails = true,
  });

  static final _invoiceRepo = getIt<InvoiceRepository>();
  static final _customerRepo = getIt<CustomerRepository>();
  static final _supplierRepo = getIt<SupplierRepository>();
  static final _printSettingsService = getIt<PrintSettingsService>();

  /// عرض Bottom Sheet للفاتورة
  static void show(BuildContext context, Invoice invoice,
      {bool showDetails = true}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HoorColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: HoorRadius.sheetRadius,
      ),
      builder: (context) => InvoiceActionsSheet(
        invoice: invoice,
        showDetails: showDetails,
      ),
    );
  }

  /// عرض Dialog الطباعة مباشرة (طباعة + معاينة)
  static Future<void> showPrintDialog(
      BuildContext context, Invoice invoice) async {
    final dialogResult = await PrintDialog.show(
      context: context,
      title: 'طباعة الفاتورة',
      color: HoorColors.primary,
    );

    if (dialogResult == null || !context.mounted) return;

    try {
      final items = await _invoiceRepo.getInvoiceItems(invoice.id);
      final customer = invoice.customerId != null
          ? await _customerRepo.getCustomerById(invoice.customerId!)
          : null;
      final supplier = invoice.supplierId != null
          ? await _supplierRepo.getSupplierById(invoice.supplierId!)
          : null;

      final options = await _printSettingsService.getPrintOptions();

      if (dialogResult.result == PrintDialogResult.print) {
        await InvoicePdfGenerator.printInvoiceDirectly(
          invoice: invoice,
          items: items,
          customer: customer,
          supplier: supplier,
          options: options,
        );
      } else if (dialogResult.result == PrintDialogResult.preview) {
        final pdfBytes = await InvoicePdfGenerator.generateInvoicePdfBytes(
          invoice: invoice,
          items: items,
          customer: customer,
          supplier: supplier,
          options: options,
        );
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'فاتورة_${invoice.invoiceNumber}.pdf',
        );
      } else if (dialogResult.result == PrintDialogResult.share) {
        await InvoicePdfGenerator.shareInvoiceAsPdf(
          invoice: invoice,
          items: items,
          customer: customer,
          supplier: supplier,
          options: options,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = InvoiceTypeInfo.fromType(invoice.type);

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: HoorColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Row(
            children: [
              InvoiceTypeIcon(type: invoice.type),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فاتورة ${invoice.invoiceNumber}',
                      style: HoorTypography.titleMedium,
                    ),
                    Text(
                      typeInfo.label,
                      style: HoorTypography.bodySmall.copyWith(
                        color: typeInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatAmount(invoice.total),
                style: HoorTypography.titleLarge.copyWith(
                  color: typeInfo.color,
                ),
              ),
            ],
          ),
          Gap(20.h),
          const Divider(height: 1, color: HoorColors.divider),
          Gap(12.h),

          // Actions
          _ActionTile(
            icon: Icons.print,
            color: HoorColors.primary,
            title: 'طباعة',
            subtitle: 'طباعة الفاتورة مباشرة',
            onTap: () => _printInvoice(context),
          ),
          _ActionTile(
            icon: Icons.preview,
            color: HoorColors.suppliers,
            title: 'معاينة الطباعة',
            subtitle: 'معاينة الفاتورة قبل الطباعة',
            onTap: () => _previewInvoice(context),
          ),
          _ActionTile(
            icon: Icons.share,
            color: HoorColors.income,
            title: 'مشاركة PDF',
            subtitle: 'مشاركة الفاتورة كملف PDF',
            onTap: () => _shareInvoice(context),
          ),
          if (showDetails) ...[
            Gap(8.h),
            const Divider(height: 1, color: HoorColors.divider),
            Gap(8.h),
            _ActionTile(
              icon: Icons.visibility,
              color: HoorColors.sales,
              title: 'تفاصيل الفاتورة',
              subtitle: 'عرض جميع تفاصيل الفاتورة',
              onTap: () {
                Navigator.pop(context);
                context.push('/invoices/details/${invoice.id}');
              },
            ),
          ],
          Gap(8.h),
        ],
      ),
    );
  }

  Future<void> _previewInvoice(BuildContext context) async {
    Navigator.pop(context);

    try {
      final items = await _invoiceRepo.getInvoiceItems(invoice.id);
      final customer = invoice.customerId != null
          ? await _customerRepo.getCustomerById(invoice.customerId!)
          : null;
      final supplier = invoice.supplierId != null
          ? await _supplierRepo.getSupplierById(invoice.supplierId!)
          : null;

      // استخدام إعدادات الطباعة الموحدة
      final printOptions = await _printSettingsService.getPrintOptions();

      final pdfBytes = await InvoicePdfGenerator.generateInvoicePdfBytes(
        invoice: invoice,
        items: items,
        customer: customer,
        supplier: supplier,
        options: printOptions,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'فاتورة_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المعاينة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    Navigator.pop(context);

    // استخدام PrintDialog الموحد بدلاً من النسخة المكررة
    await InvoiceActionsSheet.showPrintDialog(context, invoice);
  }

  Future<void> _shareInvoice(BuildContext context) async {
    Navigator.pop(context);

    // استخدام PrintDialog الموحد للمشاركة أيضاً
    // لكن هنا نريد المشاركة مباشرة، لذا يمكننا استخدام showPrintDialog
    // ولكن إذا أردنا المشاركة مباشرة دون المرور بالديالوغ، يمكننا استخدام الكود القديم
    // ولكن لتوحيد التجربة، سنستخدم showPrintDialog
    await InvoiceActionsSheet.showPrintDialog(context, invoice);
  }
}

/// Tile للإجراءات
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(HoorRadius.md.r),
        ),
        child: Icon(icon, color: color, size: 24.sp),
      ),
      title: Text(title, style: HoorTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_left,
        color: HoorColors.textTertiary,
        size: 20.sp,
      ),
      onTap: onTap,
    );
  }
}

/// زر طباعة سريع للإضافة في أي مكان
class InvoicePrintButton extends StatelessWidget {
  final Invoice invoice;
  final bool mini;

  const InvoicePrintButton({
    super.key,
    required this.invoice,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return IconButton(
        icon: const Icon(Icons.print),
        tooltip: 'طباعة الفاتورة',
        onPressed: () => InvoiceActionsSheet.show(context, invoice),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => InvoiceActionsSheet.show(context, invoice),
      icon: const Icon(Icons.print, size: 18),
      label: const Text('طباعة'),
    );
  }
}

/// زر خيارات الفاتورة (More options)
class InvoiceOptionsButton extends StatelessWidget {
  final Invoice invoice;
  final bool showDetails;

  const InvoiceOptionsButton({
    super.key,
    required this.invoice,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      tooltip: 'خيارات الفاتورة',
      onPressed: () => InvoiceActionsSheet.show(
        context,
        invoice,
        showDetails: showDetails,
      ),
    );
  }
}
