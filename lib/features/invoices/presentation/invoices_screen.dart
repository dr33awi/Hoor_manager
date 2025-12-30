import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/invoice_widgets.dart';
import '../../../core/services/export/export_services.dart';
import '../../../core/services/printing/printing_services.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/supplier_repository.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  final String? type;

  const InvoicesScreen({super.key, this.type});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _invoiceRepo = getIt<InvoiceRepository>();

  final _tabs = [
    {'type': null, 'label': 'الكل'},
    {'type': 'sale', 'label': 'المبيعات'},
    {'type': 'purchase', 'label': 'المشتريات'},
    {'type': 'sale_return', 'label': 'مرتجع مبيعات'},
    {'type': 'purchase_return', 'label': 'مرتجع مشتريات'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.type != null) {
      initialIndex = _tabs.indexWhere((t) => t['type'] == widget.type);
      if (initialIndex < 0) initialIndex = 0;
    }
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(ExportType exportType) async {
    // Get current tab type
    final currentTabIndex = _tabController.index;
    final currentType = _tabs[currentTabIndex]['type'];

    // Get invoices
    var invoices = await _invoiceRepo.getAllInvoices();
    if (currentType != null) {
      invoices = invoices.where((i) => i.type == currentType).toList();
    }

    if (invoices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد فواتير للتصدير')),
        );
      }
      return;
    }

    try {
      switch (exportType) {
        case ExportType.excel:
          final filePath = await ExcelExportService.exportInvoices(
            invoices: invoices,
            type: currentType,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تصدير الفواتير بنجاح'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'مشاركة',
                  textColor: Colors.white,
                  onPressed: () => ExcelExportService.shareFile(filePath),
                ),
              ),
            );
          }
          break;

        case ExportType.pdf:
          final pdfBytes = await PdfExportService.generateInvoicesList(
            invoices: invoices,
            type: currentType,
          );
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'invoices_list.pdf',
          );
          break;

        case ExportType.sharePdf:
          final pdfBytes = await PdfExportService.generateInvoicesList(
            invoices: invoices,
            type: currentType,
          );
          await Printing.sharePdf(
              bytes: pdfBytes, filename: 'invoices_list.pdf');
          break;

        case ExportType.shareExcel:
          final filePath = await ExcelExportService.exportInvoices(
            invoices: invoices,
            type: currentType,
          );
          await ExcelExportService.shareFile(filePath);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
        actions: [
          ExportMenuButton(
            onExport: _handleExport,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) => context.push('/invoices/new/$value'),
            itemBuilder: (context) => invoiceTypes.entries
                .where((e) => e.key != 'default')
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          Icon(e.value.icon, color: e.value.color),
                          const SizedBox(width: 8),
                          Text(e.value.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _InvoicesList(type: tab['type'])).toList(),
      ),
    );
  }
}

class _InvoicesList extends StatelessWidget {
  final String? type;
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _customerRepo = getIt<CustomerRepository>();
  final _supplierRepo = getIt<SupplierRepository>();

  _InvoicesList({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invoice>>(
      stream: _invoiceRepo.watchAllInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var invoices = snapshot.data ?? [];

        if (type != null) {
          invoices = invoices.where((i) => i.type == type).toList();
        }

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                Gap(16.h),
                Text(
                  'لا توجد فواتير',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return InvoiceCard(
              invoice: invoice,
              onTap: () => _showInvoiceActions(context, invoice),
            );
          },
        );
      },
    );
  }

  /// عرض خيارات الفاتورة (معاينة، طباعة، مشاركة)
  void _showInvoiceActions(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _InvoiceActionsSheet(
        invoice: invoice,
        invoiceRepo: _invoiceRepo,
        customerRepo: _customerRepo,
        supplierRepo: _supplierRepo,
      ),
    );
  }
}

/// Bottom Sheet لعرض خيارات الفاتورة
class _InvoiceActionsSheet extends StatelessWidget {
  final Invoice invoice;
  final InvoiceRepository invoiceRepo;
  final CustomerRepository customerRepo;
  final SupplierRepository supplierRepo;

  const _InvoiceActionsSheet({
    required this.invoice,
    required this.invoiceRepo,
    required this.customerRepo,
    required this.supplierRepo,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = InvoiceTypeInfo.fromType(invoice.type);

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      typeInfo.label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: typeInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatAmount(invoice.total),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: typeInfo.color,
                ),
              ),
            ],
          ),
          Gap(20.h),
          Divider(height: 1),
          Gap(12.h),

          // Actions
          _ActionTile(
            icon: Icons.visibility,
            color: Colors.blue,
            title: 'معاينة الفاتورة',
            subtitle: 'عرض تفاصيل الفاتورة',
            onTap: () => _previewInvoice(context),
          ),
          _ActionTile(
            icon: Icons.print,
            color: Colors.purple,
            title: 'طباعة',
            subtitle: 'طباعة الفاتورة مباشرة',
            onTap: () => _printInvoice(context),
          ),
          _ActionTile(
            icon: Icons.share,
            color: Colors.green,
            title: 'مشاركة PDF',
            subtitle: 'مشاركة الفاتورة كملف PDF',
            onTap: () => _shareInvoice(context),
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  Future<void> _previewInvoice(BuildContext context) async {
    Navigator.pop(context);

    try {
      final items = await invoiceRepo.getInvoiceItems(invoice.id);
      final customer = invoice.customerId != null
          ? await customerRepo.getCustomerById(invoice.customerId!)
          : null;
      final supplier = invoice.supplierId != null
          ? await supplierRepo.getSupplierById(invoice.supplierId!)
          : null;

      final pdfBytes = await InvoicePdfGenerator.generateInvoicePdfBytes(
        invoice: invoice,
        items: items,
        customer: customer,
        supplier: supplier,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'invoice_${invoice.invoiceNumber}.pdf',
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

    try {
      final items = await invoiceRepo.getInvoiceItems(invoice.id);
      final customer = invoice.customerId != null
          ? await customerRepo.getCustomerById(invoice.customerId!)
          : null;
      final supplier = invoice.supplierId != null
          ? await supplierRepo.getSupplierById(invoice.supplierId!)
          : null;

      await InvoicePdfGenerator.printInvoiceDirectly(
        invoice: invoice,
        items: items,
        customer: customer,
        supplier: supplier,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    Navigator.pop(context);

    try {
      final items = await invoiceRepo.getInvoiceItems(invoice.id);
      final customer = invoice.customerId != null
          ? await customerRepo.getCustomerById(invoice.customerId!)
          : null;
      final supplier = invoice.supplierId != null
          ? await supplierRepo.getSupplierById(invoice.supplierId!)
          : null;

      await InvoicePdfGenerator.shareInvoiceAsPdf(
        invoice: invoice,
        items: items,
        customer: customer,
        supplier: supplier,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: color, size: 24.sp),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
      ),
      trailing: Icon(Icons.chevron_left, color: Colors.grey),
      onTap: onTap,
    );
  }
}
