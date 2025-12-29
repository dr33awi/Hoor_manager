import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/invoice_widgets.dart';
import '../../../core/services/export_service.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/invoice_repository.dart';

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
  final _exportService = getIt<ExportService>();

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

  Future<void> _handleExport(String exportType) async {
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
        case 'excel':
          final filePath = await _exportService.exportInvoicesToExcel(
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
                  onPressed: () => _exportService.shareExcelFile(filePath),
                ),
              ),
            );
          }
          break;

        case 'pdf':
          final pdfBytes = await _exportService.generateInvoicesPdf(
            invoices: invoices,
            type: currentType,
          );
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'invoices_list.pdf',
          );
          break;

        case 'share':
          final filePath = await _exportService.exportInvoicesToExcel(
            invoices: invoices,
            type: currentType,
          );
          await _exportService.shareExcelFile(filePath);
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleExport,
            itemBuilder: (context) => [
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
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('مشاركة'),
                  ],
                ),
              ),
            ],
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
              onTap: () => context.push('/invoices/${invoice.id}'),
            );
          },
        );
      },
    );
  }
}
