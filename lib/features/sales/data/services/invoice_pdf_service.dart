import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;

import '../../domain/entities/entities.dart';

/// خدمة توليد PDF للفواتير
class InvoicePdfService {
  // كاش للخطوط المحملة
  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;

  /// تحميل الخطوط العربية (مع دعم الأوفلاين)
  static Future<(pw.Font, pw.Font)> _loadArabicFonts() async {
    if (_arabicFont != null && _arabicFontBold != null) {
      return (_arabicFont!, _arabicFontBold!);
    }

    try {
      // محاولة تحميل من Google Fonts أولاً (أونلاين)
      _arabicFont = await PdfGoogleFonts.cairoRegular();
      _arabicFontBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      // في حالة عدم الاتصال، استخدام خط Amiri المدمج
      try {
        _arabicFont = await PdfGoogleFonts.amiriRegular();
        _arabicFontBold = await PdfGoogleFonts.amiriBold();
      } catch (e2) {
        // استخدام خط افتراضي كملاذ أخير
        _arabicFont = pw.Font.helvetica();
        _arabicFontBold = pw.Font.helveticaBold();
      }
    }

    return (_arabicFont!, _arabicFontBold!);
  }

  /// توليد PDF للفاتورة
  static Future<Uint8List> generateInvoicePdf(InvoiceEntity invoice) async {
    final pdf = pw.Document();

    // تحميل خط عربي مع دعم الأوفلاين
    final (arabicFont, arabicFontBold) = await _loadArabicFonts();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // رأس الفاتورة
                _buildHeader(arabicFontBold, invoice),
                pw.SizedBox(height: 20),

                // معلومات الفاتورة
                _buildInvoiceInfo(arabicFont, arabicFontBold, invoice),
                pw.SizedBox(height: 20),

                // جدول المنتجات
                _buildItemsTable(arabicFont, arabicFontBold, invoice),
                pw.SizedBox(height: 20),

                // الإجماليات
                _buildTotals(arabicFont, arabicFontBold, invoice),
                pw.SizedBox(height: 30),

                // التذييل
                _buildFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// رأس الفاتورة
  static pw.Widget _buildHeader(pw.Font font, InvoiceEntity invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#12334e'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'متجر حور',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  color: PdfColor.fromHex('#e9dac1'),
                ),
              ),
              pw.Text(
                'للأحذية النسائية والولادية',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'فاتورة بيع',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                '#${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  color: PdfColor.fromHex('#e9dac1'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// معلومات الفاتورة
  static pw.Widget _buildInvoiceInfo(
    pw.Font font,
    pw.Font fontBold,
    InvoiceEntity invoice,
  ) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

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
              _buildInfoRow(font, fontBold, 'التاريخ:',
                  dateFormat.format(invoice.saleDate)),
              pw.SizedBox(height: 4),
              _buildInfoRow(
                  font, fontBold, 'البائع:', invoice.soldByName ?? '-'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                  font, fontBold, 'الحالة:', invoice.status.arabicName),
              pw.SizedBox(height: 4),
              _buildInfoRow(font, fontBold, 'طريقة الدفع:',
                  invoice.paymentMethod.arabicName),
            ],
          ),
        ],
      ),
    );
  }

  /// صف معلومات
  static pw.Widget _buildInfoRow(
      pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 10)),
        pw.SizedBox(width: 4),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// جدول المنتجات
  static pw.Widget _buildItemsTable(
    pw.Font font,
    pw.Font fontBold,
    InvoiceEntity invoice,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#12334e'),
          ),
          children: [
            _buildTableHeader(fontBold, 'المنتج'),
            _buildTableHeader(fontBold, 'اللون/المقاس'),
            _buildTableHeader(fontBold, 'الكمية'),
            _buildTableHeader(fontBold, 'السعر'),
            _buildTableHeader(fontBold, 'الإجمالي'),
          ],
        ),
        // صفوف المنتجات
        ...invoice.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(font, item.productName),
                _buildTableCell(font, '${item.color} / ${item.size}'),
                _buildTableCell(font, '${item.quantity}'),
                _buildTableCell(
                    font, '${item.unitPrice.toStringAsFixed(0)} ل.س'),
                _buildTableCell(
                    font, '${item.totalPrice.toStringAsFixed(0)} ل.س'),
              ],
            )),
      ],
    );
  }

  /// رأس خلية الجدول
  static pw.Widget _buildTableHeader(pw.Font font, String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// خلية الجدول
  static pw.Widget _buildTableCell(pw.Font font, String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// الإجماليات
  static pw.Widget _buildTotals(
    pw.Font font,
    pw.Font fontBold,
    InvoiceEntity invoice,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _buildTotalRow(font, 'المجموع الفرعي:',
                '${invoice.subtotal.toStringAsFixed(0)} ل.س'),
            if (invoice.hasDiscount) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow(
                font,
                'الخصم (${invoice.discount.description}):',
                '- ${invoice.discountAmount.toStringAsFixed(0)} ل.س',
                color: PdfColors.red,
              ),
            ],
            pw.Divider(color: PdfColors.grey400),
            _buildTotalRow(
              fontBold,
              'الإجمالي:',
              '${invoice.total.toStringAsFixed(0)} ل.س',
              fontSize: 14,
            ),
            pw.SizedBox(height: 8),
            _buildTotalRow(font, 'المبلغ المدفوع:',
                '${invoice.amountPaid.toStringAsFixed(0)} ل.س'),
            if (invoice.change > 0)
              _buildTotalRow(
                  font, 'الباقي:', '${invoice.change.toStringAsFixed(0)} ل.س'),
          ],
        ),
      ),
    );
  }

  /// صف الإجمالي
  static pw.Widget _buildTotalRow(
    pw.Font font,
    String label,
    String value, {
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  /// التذييل
  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'شكراً لتسوقكم معنا',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'متجر حور - للأحذية النسائية والولادية',
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// طباعة الفاتورة
  static Future<void> printInvoice(InvoiceEntity invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  /// مشاركة الفاتورة
  static Future<void> shareInvoice(InvoiceEntity invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
