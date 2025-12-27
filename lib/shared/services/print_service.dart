import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/database.dart';

/// خدمة طباعة الفواتير والمستندات
class PrintService {
  static final _currencyFormat =
      intl.NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');
  static final _dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm', 'ar');

  /// طباعة فاتورة
  static Future<void> printInvoice({
    required BuildContext context,
    required String invoiceNumber,
    required String invoiceType,
    required DateTime date,
    String? partyName,
    required List<PrintableInvoiceItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    double? paidAmount,
    String? paymentMethod,
    String? notes,
  }) async {
    final pdf = await _buildInvoicePdf(
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      date: date,
      partyName: partyName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      total: total,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'فاتورة_$invoiceNumber',
    );
  }

  /// معاينة فاتورة قبل الطباعة
  static Future<void> previewInvoice({
    required BuildContext context,
    required String invoiceNumber,
    required String invoiceType,
    required DateTime date,
    String? partyName,
    required List<PrintableInvoiceItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    double? paidAmount,
    String? paymentMethod,
    String? notes,
  }) async {
    final pdf = await _buildInvoicePdf(
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      date: date,
      partyName: partyName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      total: total,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('معاينة الفاتورة #$invoiceNumber'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => Printing.layoutPdf(
                    onLayout: (format) async => pdf.save(),
                    name: 'فاتورة_$invoiceNumber',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async => Printing.sharePdf(
                    bytes: await pdf.save(),
                    filename: 'فاتورة_$invoiceNumber.pdf',
                  ),
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => pdf.save(),
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: 'فاتورة_$invoiceNumber.pdf',
            ),
          ),
        ),
      );
    }
  }

  /// بناء ملف PDF للفاتورة
  static Future<pw.Document> _buildInvoicePdf({
    required String invoiceNumber,
    required String invoiceType,
    required DateTime date,
    String? partyName,
    required List<PrintableInvoiceItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    double? paidAmount,
    String? paymentMethod,
    String? notes,
  }) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    final invoiceTypeText = _getInvoiceTypeText(invoiceType);
    final invoiceColor = _getInvoiceColor(invoiceType);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // الترويسة
              _buildHeader(arabicFontBold, invoiceTypeText, invoiceColor),
              pw.SizedBox(height: 20),

              // معلومات الفاتورة
              _buildInvoiceInfo(
                  arabicFont, arabicFontBold, invoiceNumber, date, partyName),
              pw.SizedBox(height: 20),

              // جدول المنتجات
              _buildItemsTable(arabicFont, arabicFontBold, items),
              pw.SizedBox(height: 20),

              // الملخص
              _buildSummary(arabicFont, arabicFontBold, subtotal,
                  discountAmount, taxAmount, total, paidAmount, paymentMethod),

              // الملاحظات
              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotes(arabicFont, notes),
              ],

              pw.Spacer(),

              // التذييل
              _buildFooter(arabicFont),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
      pw.Font fontBold, String invoiceType, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'حور للأحذية النسائية',
            style: pw.TextStyle(
                font: fontBold, fontSize: 24, color: PdfColors.white),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            invoiceType,
            style: pw.TextStyle(
                font: fontBold, fontSize: 18, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceInfo(pw.Font font, pw.Font fontBold,
      String number, DateTime date, String? partyName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('رقم الفاتورة: $number',
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text('التاريخ: ${_dateFormat.format(date)}',
                  style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
          if (partyName != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('العميل/المورد:',
                    style: pw.TextStyle(
                        font: font, fontSize: 11, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text(partyName,
                    style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
      pw.Font font, pw.Font fontBold, List<PrintableInvoiceItem> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle:
          pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1976D2)),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headerAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['المنتج', 'الكمية', 'السعر', 'الإجمالي'],
      data: items
          .map((item) => [
                item.name,
                item.quantity.toStringAsFixed(0),
                _currencyFormat.format(item.unitPrice),
                _currencyFormat.format(item.lineTotal),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildSummary(
    pw.Font font,
    pw.Font fontBold,
    double subtotal,
    double discountAmount,
    double taxAmount,
    double total,
    double? paidAmount,
    String? paymentMethod,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _summaryRow(font, 'المجموع الفرعي', subtotal),
            if (discountAmount > 0)
              _summaryRow(font, 'الخصم', -discountAmount, color: PdfColors.red),
            _summaryRow(font, 'الضريبة (15%)', taxAmount),
            pw.Divider(color: PdfColors.grey400),
            _summaryRow(fontBold, 'الإجمالي', total, fontSize: 14),
            if (paidAmount != null) ...[
              pw.SizedBox(height: 8),
              _summaryRow(font, 'المدفوع', paidAmount,
                  color: PdfColors.green700),
              _summaryRow(font, 'المتبقي', total - paidAmount,
                  color: (total - paidAmount) > 0
                      ? PdfColors.red
                      : PdfColors.green700),
            ],
            if (paymentMethod != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'طريقة الدفع: ${_getPaymentMethodText(paymentMethod)}',
                style: pw.TextStyle(
                    font: font, fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(pw.Font font, String label, double value,
      {PdfColor? color, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
          pw.Text(
            _currencyFormat.format(value),
            style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(pw.Font font, String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ملاحظات:',
              style: pw.TextStyle(
                  font: font, fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          'شكراً لتعاملكم معنا',
          style:
              pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'تم إنشاء هذه الفاتورة بواسطة نظام حور لإدارة المتاجر',
          style:
              pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey400),
        ),
      ],
    );
  }

  static String _getInvoiceTypeText(String type) {
    switch (type) {
      case 'SALE':
        return 'فاتورة مبيعات';
      case 'PURCHASE':
        return 'فاتورة مشتريات';
      case 'RETURN_SALE':
        return 'مرتجع مبيعات';
      case 'RETURN_PURCHASE':
        return 'مرتجع مشتريات';
      default:
        return 'فاتورة';
    }
  }

  static PdfColor _getInvoiceColor(String type) {
    switch (type) {
      case 'SALE':
        return const PdfColor.fromInt(0xFF4CAF50); // أخضر
      case 'PURCHASE':
        return const PdfColor.fromInt(0xFF2196F3); // أزرق
      case 'RETURN_SALE':
        return const PdfColor.fromInt(0xFFF44336); // أحمر
      case 'RETURN_PURCHASE':
        return const PdfColor.fromInt(0xFFFF9800); // برتقالي
      default:
        return const PdfColor.fromInt(0xFF9E9E9E); // رمادي
    }
  }

  static String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'نقداً';
      case 'CARD':
        return 'بطاقة';
      case 'TRANSFER':
        return 'تحويل';
      case 'CREDIT':
        return 'آجل';
      default:
        return method;
    }
  }

  /// طباعة إيصال حراري (80mm)
  static Future<void> printThermalReceipt({
    required BuildContext context,
    required String invoiceNumber,
    required String invoiceType,
    required DateTime date,
    String? partyName,
    required List<PrintableInvoiceItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    double? paidAmount,
  }) async {
    final pdf = pw.Document();

    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // حجم الإيصال الحراري 80mm
    final receiptFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // اسم المتجر
              pw.Text('حور للأحذية',
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 16)),
              pw.Text(_getInvoiceTypeText(invoiceType),
                  style: pw.TextStyle(font: arabicFont, fontSize: 12)),
              pw.SizedBox(height: 8),

              // خط فاصل
              pw.Container(
                width: double.infinity,
                child: pw.Text('─' * 30,
                    style: pw.TextStyle(font: arabicFont, fontSize: 8)),
              ),

              // معلومات الفاتورة
              pw.Text('رقم: $invoiceNumber',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10)),
              pw.Text(_dateFormat.format(date),
                  style: pw.TextStyle(font: arabicFont, fontSize: 9)),
              if (partyName != null)
                pw.Text(partyName,
                    style: pw.TextStyle(font: arabicFont, fontSize: 10)),

              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                child: pw.Text('─' * 30,
                    style: pw.TextStyle(font: arabicFont, fontSize: 8)),
              ),

              // المنتجات
              ...items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(item.name,
                            style:
                                pw.TextStyle(font: arabicFont, fontSize: 10)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                '${item.quantity.toStringAsFixed(0)} × ${item.unitPrice}',
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 9)),
                            pw.Text('${item.lineTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  )),

              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                child: pw.Text('─' * 30,
                    style: pw.TextStyle(font: arabicFont, fontSize: 8)),
              ),

              // الإجمالي
              _thermalSummaryRow(arabicFont, 'المجموع', subtotal),
              if (discountAmount > 0)
                _thermalSummaryRow(arabicFont, 'الخصم', -discountAmount),
              _thermalSummaryRow(arabicFont, 'الضريبة', taxAmount),
              pw.SizedBox(height: 4),
              _thermalSummaryRow(arabicFontBold, 'الإجمالي', total),

              if (paidAmount != null) ...[
                _thermalSummaryRow(arabicFont, 'المدفوع', paidAmount),
                _thermalSummaryRow(arabicFont, 'المتبقي', total - paidAmount),
              ],

              pw.SizedBox(height: 12),
              pw.Text('شكراً لزيارتكم',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'إيصال_$invoiceNumber',
    );
  }

  static pw.Widget _thermalSummaryRow(
      pw.Font font, String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('${value.toStringAsFixed(2)} ر.س',
              style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  /// طباعة تقرير المخزون
  static Future<void> printInventoryReport({
    required BuildContext context,
    required String title,
    required List<Product> products,
  }) async {
    final pdf = pw.Document();

    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        header: (context) => pw.Column(
          children: [
            pw.Text(title,
                style: pw.TextStyle(font: arabicFontBold, fontSize: 20)),
            pw.Text('تاريخ التقرير: ${_dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(font: arabicFont, fontSize: 11)),
            pw.SizedBox(height: 15),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                font: arabicFontBold, fontSize: 10, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1976D2)),
            cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
            cellHeight: 25,
            headers: [
              'المنتج',
              'الباركود',
              'الكمية',
              'سعر التكلفة',
              'سعر البيع',
              'القيمة'
            ],
            data: products
                .map((p) => [
                      p.name,
                      p.barcode ?? '-',
                      p.qty.toStringAsFixed(0),
                      _currencyFormat.format(p.costPrice),
                      _currencyFormat.format(p.salePrice),
                      _currencyFormat.format(p.qty * p.costPrice),
                    ])
                .toList(),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(
                font: arabicFont, fontSize: 9, color: PdfColors.grey),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }

  /// مشاركة الفاتورة كـ PDF
  static Future<void> shareInvoice({
    required String invoiceNumber,
    required String invoiceType,
    required DateTime date,
    String? partyName,
    required List<PrintableInvoiceItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    double? paidAmount,
    String? paymentMethod,
  }) async {
    final pdf = await _buildInvoicePdf(
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      date: date,
      partyName: partyName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      total: total,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'فاتورة_$invoiceNumber.pdf',
    );
  }
}

/// نموذج بند فاتورة قابل للطباعة
class PrintableInvoiceItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  PrintableInvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}
