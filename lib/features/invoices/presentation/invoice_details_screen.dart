import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                ...(_items.map((item) => Container(
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
                    ))),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFESSIONAL INVOICE PDF GENERATION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _printInvoice(Invoice invoice) async {
    final doc = pw.Document();

    // Load Arabic fonts
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();
    final arabicFontLight = await PdfGoogleFonts.cairoLight();

    // Try to load logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/Hoor-icons.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo not available
    }

    final typeLabel = _getTypeLabel(invoice.type);
    final typeColor = _getTypeColor(invoice.type);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════════════════════════════
              // HEADER - Company Info & Logo
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColors.blue900, PdfColors.blue700],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Company Info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Hoor Manager',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 28,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'نظام إدارة المبيعات والمخزون',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 12,
                            color: PdfColors.blue100,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'هاتف: 0999-999-999 | البريد: info@hoor.com',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 9,
                            color: PdfColors.blue200,
                          ),
                        ),
                      ],
                    ),
                    // Logo
                    if (logoImage != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'H',
                            style: pw.TextStyle(
                              font: arabicFontBold,
                              fontSize: 36,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // INVOICE TYPE & NUMBER ROW
              // ═══════════════════════════════════════════════════════════
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Invoice Type Badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: typeColor,
                      borderRadius: pw.BorderRadius.circular(25),
                    ),
                    child: pw.Text(
                      typeLabel,
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  // Invoice Number Box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'رقم الفاتورة',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 16,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // INVOICE DETAILS GRID
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(arabicFontBold, arabicFontLight, 'التاريخ',
                        DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                        icon: '\u{1F4C5}'),
                    _buildVerticalDivider(),
                    _buildInfoColumn(arabicFontBold, arabicFontLight, 'الوقت',
                        DateFormat('HH:mm').format(invoice.invoiceDate),
                        icon: '\u{1F552}'),
                    _buildVerticalDivider(),
                    _buildInfoColumn(
                        arabicFontBold,
                        arabicFontLight,
                        'طريقة الدفع',
                        _getPaymentMethodLabel(invoice.paymentMethod),
                        icon: '\u{1F4B3}'),
                    _buildVerticalDivider(),
                    _buildInfoColumn(arabicFontBold, arabicFontLight, 'الحالة',
                        invoice.status == 'completed' ? 'مكتملة ' : 'معلقة',
                        icon: ''),
                  ],
                ),
              ),
              pw.SizedBox(height: 28),

              // ═══════════════════════════════════════════════════════════
              // ITEMS TABLE
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    // Table Title
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(9),
                          topRight: pw.Radius.circular(9),
                        ),
                      ),
                      child: pw.Text(
                        'تفاصيل المنتجات',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 12,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '#',
                              style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              'اسم المنتج',
                              style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'الكمية',
                              style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'السعر',
                              style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'الإجمالي',
                              style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Rows
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isEven = index % 2 == 0;
                      final isLast = index == _items.length - 1;

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColors.grey50,
                          borderRadius: isLast
                              ? const pw.BorderRadius.only(
                                  bottomLeft: pw.Radius.circular(9),
                                  bottomRight: pw.Radius.circular(9),
                                )
                              : null,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.blue100,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  '${index + 1}',
                                  style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 9,
                                    color: PdfColors.blue900,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(
                                item.productName,
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                '${item.quantity}',
                                style: pw.TextStyle(
                                  font: arabicFontBold,
                                  fontSize: 10,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                '${item.unitPrice.toStringAsFixed(0)}',
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize: 10,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                '${item.total.toStringAsFixed(0)}',
                                style: pw.TextStyle(
                                  font: arabicFontBold,
                                  fontSize: 10,
                                  color: PdfColors.blue900,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // SUMMARY & NOTES ROW
              // ═══════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Notes Section
                  pw.Expanded(
                    flex: 3,
                    child: invoice.notes != null && invoice.notes!.isNotEmpty
                        ? pw.Container(
                            padding: const pw.EdgeInsets.all(14),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.amber50,
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: PdfColors.amber200),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      '📝 ',
                                      style: const pw.TextStyle(fontSize: 12),
                                    ),
                                    pw.Text(
                                      'ملاحظات:',
                                      style: pw.TextStyle(
                                        font: arabicFontBold,
                                        fontSize: 11,
                                        color: PdfColors.amber900,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  invoice.notes!,
                                  style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 10,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : pw.SizedBox(),
                  ),
                  pw.SizedBox(width: 20),
                  // Totals Box
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        children: [
                          _buildSummaryRow(
                            arabicFont,
                            'المجموع الفرعي',
                            '${invoice.subtotal.toStringAsFixed(0)} ل.س',
                          ),
                          pw.SizedBox(height: 8),
                          if (invoice.discountAmount > 0) ...[
                            _buildSummaryRow(
                              arabicFont,
                              'الخصم',
                              '- ${invoice.discountAmount.toStringAsFixed(0)} ل.س',
                              valueColor: PdfColors.red700,
                            ),
                            pw.SizedBox(height: 8),
                          ],
                          pw.Container(
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                          pw.SizedBox(height: 12),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'الإجمالي',
                                style: pw.TextStyle(
                                  font: arabicFontBold,
                                  fontSize: 14,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.blue900,
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Text(
                                  '${invoice.total.toStringAsFixed(0)} ل.س',
                                  style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 14,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ═══════════════════════════════════════════════════════════
              // FOOTER
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300, width: 2),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        ' شكراً لتعاملكم معنا ',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'تم الإنشاء بواسطة ',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.Text(
                          'Hoor Manager',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 8,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.Text(
                          ' | ',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 8,
                            color: PdfColors.grey400,
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS FOR PDF
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildInfoColumn(
    pw.Font boldFont,
    pw.Font lightFont,
    String label,
    String value, {
    String icon = '',
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: lightFont,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildVerticalDivider() {
    return pw.Container(
      width: 1,
      height: 35,
      color: PdfColors.grey300,
    );
  }

  pw.Widget _buildSummaryRow(
    pw.Font font,
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: valueColor ?? PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'فاتورة مبيعات';
      case 'purchase':
        return 'فاتورة مشتريات';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      case 'opening_balance':
        return 'فاتورة أول المدة';
      default:
        return 'فاتورة';
    }
  }

  PdfColor _getTypeColor(String type) {
    switch (type) {
      case 'sale':
        return PdfColors.blue800;
      case 'purchase':
        return PdfColors.blueGrey700;
      case 'sale_return':
        return PdfColors.purple700;
      case 'purchase_return':
        return PdfColors.purple700;
      case 'opening_balance':
        return PdfColors.teal700;
      default:
        return PdfColors.blue800;
    }
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    // TODO: Implement share functionality
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UI WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

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
            '${isNegative ? '-' : ''}${value.toStringAsFixed(2)} ل.س',
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
