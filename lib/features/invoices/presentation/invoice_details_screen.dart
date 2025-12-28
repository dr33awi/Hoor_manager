import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/invoice_repository.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  final _invoiceRepo = getIt<InvoiceRepository>();

  Invoice? _invoice;
  List<InvoiceItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final invoice = await _invoiceRepo.getInvoiceById(widget.invoiceId);
    final items = await _invoiceRepo.getInvoiceItems(widget.invoiceId);

    setState(() {
      _invoice = invoice;
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
        body: const Center(child: Text('الفاتورة غير موجودة')),
      );
    }

    final invoice = _invoice!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفاتورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(invoice),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(invoice),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Invoice Header
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _TypeBadge(type: invoice.type),
                    ],
                  ),
                  Gap(8.h),
                  _InfoRow(
                    label: 'التاريخ',
                    value: dateFormat.format(invoice.invoiceDate),
                  ),
                  _InfoRow(
                    label: 'طريقة الدفع',
                    value: _getPaymentMethodLabel(invoice.paymentMethod),
                  ),
                  if (invoice.notes != null && invoice.notes!.isNotEmpty)
                    _InfoRow(label: 'ملاحظات', value: invoice.notes!),
                ],
              ),
            ),
          ),
          Gap(16.h),

          // Items
          Text(
            'المنتجات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Card(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('المنتج',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('الكمية',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('السعر',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('الإجمالي',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // Items
                ..._items.map((item) => Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item.productName)),
                          Expanded(
                              child: Text('${item.quantity}',
                                  textAlign: TextAlign.center)),
                          Expanded(
                              child: Text(
                                  '${item.unitPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center)),
                          Expanded(
                              child: Text('${item.total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          Gap(16.h),

          // Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _SummaryRow(label: 'المجموع الفرعي', value: invoice.subtotal),
                  if (invoice.discountAmount > 0)
                    _SummaryRow(
                      label: 'الخصم',
                      value: invoice.discountAmount,
                      isNegative: true,
                    ),
                  if (invoice.taxAmount > 0)
                    _SummaryRow(label: 'الضريبة', value: invoice.taxAmount),
                  Divider(),
                  _SummaryRow(
                    label: 'الإجمالي',
                    value: invoice.total,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'card':
        return 'بطاقة';
      case 'transfer':
        return 'تحويل';
      case 'credit':
        return 'آجل';
      default:
        return method;
    }
  }

  Future<void> _printInvoice(Invoice invoice) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Hoor Manager',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('فاتورة رقم: ${invoice.invoiceNumber}'),
              pw.Text(
                  'التاريخ: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.invoiceDate)}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['المنتج', 'الكمية', 'السعر', 'الإجمالي'],
                data: _items
                    .map((item) => [
                          item.productName,
                          item.quantity.toString(),
                          item.unitPrice.toStringAsFixed(2),
                          item.total.toStringAsFixed(2),
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${invoice.total.toStringAsFixed(2)} ر.س',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    // TODO: Implement share functionality
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final info = _getTypeInfo(type);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: info['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        info['label'],
        style: TextStyle(
          color: info['color'],
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'sale':
        return {'color': AppColors.sales, 'label': 'مبيعات'};
      case 'purchase':
        return {'color': AppColors.purchases, 'label': 'مشتريات'};
      case 'sale_return':
        return {'color': AppColors.returns, 'label': 'مرتجع مبيعات'};
      case 'purchase_return':
        return {'color': AppColors.returns, 'label': 'مرتجع مشتريات'};
      case 'opening_balance':
        return {'color': AppColors.inventory, 'label': 'أول المدة'};
      default:
        return {'color': AppColors.primary, 'label': 'فاتورة'};
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${value.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? AppColors.error
                  : (isTotal ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}
