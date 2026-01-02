// ═══════════════════════════════════════════════════════════════════════════
// Export Service Pro - Professional Design System
// Excel and PDF Export Functionality
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

import '../../../data/database/app_database.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _priceFormat = NumberFormat('#,###');

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF Export
  // ═══════════════════════════════════════════════════════════════════════════

  Future<File?> exportInvoicesToPdf({
    required List<Invoice> invoices,
    required String title,
    String? subtitle,
  }) async {
    try {
      final pdf = pw.Document();

      // Load Arabic font
      final arabicFont =
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final arabicTtf = pw.Font.ttf(arabicFont);

      final total = invoices.fold<double>(0, (sum, inv) => sum + inv.total);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicTtf),
          header: (context) => _buildPdfHeader(title, subtitle, arabicTtf),
          footer: (context) => _buildPdfFooter(context, arabicTtf),
          build: (context) => [
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'الإجمالي: ${_priceFormat.format(total)} ل.س',
                    style: pw.TextStyle(
                      font: arabicTtf,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    'عدد الفواتير: ${invoices.length}',
                    style: pw.TextStyle(font: arabicTtf, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                font: arabicTtf,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: pw.TextStyle(font: arabicTtf, fontSize: 10),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headers: [
                'المجموع',
                'الحالة',
                'التاريخ',
                'العميل/المورد',
                'رقم الفاتورة'
              ],
              data: invoices
                  .map((inv) => [
                        '${_priceFormat.format(inv.total)} ل.س',
                        _getStatusText(inv.status),
                        _dateFormat.format(inv.invoiceDate),
                        inv.customerId ?? inv.supplierId ?? '-',
                        inv.invoiceNumber,
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePdf(pdf,
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return null;
    }
  }

  Future<File?> exportProductsToPdf({
    required List<Product> products,
    required String title,
  }) async {
    try {
      final pdf = pw.Document();

      final arabicFont =
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final arabicTtf = pw.Font.ttf(arabicFont);

      final totalValue = products.fold<double>(
        0,
        (sum, p) => sum + (p.quantity * p.purchasePrice),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: arabicTtf),
          header: (context) => _buildPdfHeader(title, null, arabicTtf),
          footer: (context) => _buildPdfFooter(context, arabicTtf),
          build: (context) => [
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'قيمة المخزون: ${_priceFormat.format(totalValue)} ل.س',
                    style: pw.TextStyle(
                      font: arabicTtf,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    'عدد المنتجات: ${products.length}',
                    style: pw.TextStyle(font: arabicTtf, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                font: arabicTtf,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: pw.TextStyle(font: arabicTtf, fontSize: 10),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headers: [
                'القيمة',
                'الكمية',
                'سعر البيع',
                'التكلفة',
                'اسم المنتج'
              ],
              data: products
                  .map((p) => [
                        '${_priceFormat.format(p.quantity * p.purchasePrice)} ل.س',
                        '${p.quantity}',
                        '${_priceFormat.format(p.salePrice)} ل.س',
                        '${_priceFormat.format(p.purchasePrice)} ل.س',
                        p.name,
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePdf(pdf,
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return null;
    }
  }

  pw.Widget _buildPdfHeader(String title, String? subtitle, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          pw.Text(
            'تاريخ الطباعة: ${_dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Hoor Manager',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Future<File> _savePdf(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Excel Export
  // ═══════════════════════════════════════════════════════════════════════════

  Future<File?> exportInvoicesToExcel({
    required List<Invoice> invoices,
    required String title,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Header row
      sheet.appendRow([
        TextCellValue('رقم الفاتورة'),
        TextCellValue('التاريخ'),
        TextCellValue('العميل/المورد'),
        TextCellValue('النوع'),
        TextCellValue('الحالة'),
        TextCellValue('المجموع الفرعي'),
        TextCellValue('الضريبة'),
        TextCellValue('الخصم'),
        TextCellValue('المجموع'),
      ]);

      // Style header
      for (var i = 0; i < 9; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue800,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Data rows
      for (final inv in invoices) {
        sheet.appendRow([
          TextCellValue(inv.invoiceNumber),
          TextCellValue(_dateFormat.format(inv.invoiceDate)),
          TextCellValue(inv.customerId ?? inv.supplierId ?? '-'),
          TextCellValue(inv.type == 'sale' ? 'مبيعات' : 'مشتريات'),
          TextCellValue(_getStatusText(inv.status)),
          DoubleCellValue(inv.subtotal),
          DoubleCellValue(inv.taxAmount),
          DoubleCellValue(inv.discountAmount),
          DoubleCellValue(inv.total),
        ]);
      }

      // Summary row
      final total = invoices.fold<double>(0, (sum, inv) => sum + inv.total);
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('الإجمالي'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(total),
      ]);

      // Auto-fit columns
      for (var i = 0; i < 9; i++) {
        sheet.setColumnWidth(i, 15);
      }

      return await _saveExcel(excel,
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      return null;
    }
  }

  Future<File?> exportProductsToExcel({
    required List<Product> products,
    required String title,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Header row
      sheet.appendRow([
        TextCellValue('اسم المنتج'),
        TextCellValue('الباركود'),
        TextCellValue('SKU'),
        TextCellValue('سعر التكلفة'),
        TextCellValue('سعر البيع'),
        TextCellValue('الكمية'),
        TextCellValue('الحد الأدنى'),
        TextCellValue('القيمة'),
      ]);

      // Style header
      for (var i = 0; i < 8; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue800,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Data rows
      for (final p in products) {
        sheet.appendRow([
          TextCellValue(p.name),
          TextCellValue(p.barcode ?? '-'),
          TextCellValue(p.sku ?? '-'),
          DoubleCellValue(p.purchasePrice),
          DoubleCellValue(p.salePrice),
          IntCellValue(p.quantity),
          IntCellValue(p.minQuantity),
          DoubleCellValue(p.quantity * p.purchasePrice),
        ]);
      }

      // Summary row
      final totalValue = products.fold<double>(
        0,
        (sum, p) => sum + (p.quantity * p.purchasePrice),
      );
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('الإجمالي'),
        DoubleCellValue(totalValue),
      ]);

      // Auto-fit columns
      for (var i = 0; i < 8; i++) {
        sheet.setColumnWidth(i, 15);
      }

      return await _saveExcel(excel,
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      return null;
    }
  }

  Future<File> _saveExcel(Excel excel, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Share Functions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'تقرير من تطبيق Hoor Manager',
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوعة';
      case 'unpaid':
        return 'غير مدفوعة';
      case 'partial':
        return 'مدفوعة جزئياً';
      case 'cancelled':
        return 'ملغية';
      case 'returned':
        return 'مرتجعة';
      default:
        return status;
    }
  }
}
