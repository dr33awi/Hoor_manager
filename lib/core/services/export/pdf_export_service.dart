import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';
import '../printing/pdf_theme.dart';
import 'export_templates.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PDF Export Service - خدمة تصدير PDF الموحدة
/// ═══════════════════════════════════════════════════════════════════════════
class PdfExportService {
  PdfExportService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير قائمة الفواتير
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInvoicesList({
    required List<Invoice> invoices,
    String? type,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final typeName = type != null
        ? ExportFormatters.getInvoiceTypeLabel(type)
        : 'جميع الفواتير';

    // حساب الإحصائيات
    double totalAmount = 0;
    double totalDiscount = 0;
    for (final inv in invoices) {
      totalAmount += inv.total;
      totalDiscount += inv.discountAmount;
    }

    final template = PdfReportTemplate(
      title: typeName,
      reportDate: now,
      headerColor: type != null
          ? ExportColors.getInvoiceTypeColor(type)
          : ExportColors.primary,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              template.buildHeader(),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: template.buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildStatsBox([
              StatItem(label: 'عدد الفواتير', value: '${invoices.length}'),
              StatItem(
                label: 'إجمالي المبلغ',
                value: ExportFormatters.formatPrice(totalAmount),
                color: ExportColors.success,
              ),
              StatItem(
                label: 'إجمالي الخصومات',
                value: ExportFormatters.formatPrice(totalDiscount),
                color: ExportColors.error,
              ),
            ]),
          ),
          pw.SizedBox(height: 16),

          // جدول الفواتير
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildTable(
              headers: [
                'الإجمالي',
                'الخصم',
                'طريقة الدفع',
                'النوع',
                'التاريخ',
                'رقم الفاتورة',
                '#',
              ],
              data: List.generate(invoices.length, (index) {
                final inv = invoices[index];
                return [
                  ExportFormatters.formatPrice(inv.total, showCurrency: false),
                  ExportFormatters.formatPrice(inv.discountAmount,
                      showCurrency: false),
                  ExportFormatters.getPaymentMethodLabel(inv.paymentMethod),
                  ExportFormatters.getInvoiceTypeLabel(inv.type),
                  ExportFormatters.formatDateTime(inv.invoiceDate),
                  inv.invoiceNumber,
                  '${index + 1}',
                ];
              }),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير تقرير المبيعات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateSalesReport({
    required List<Invoice> invoices,
    required Map<String, double> summary,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    // حساب الإحصائيات
    final totalSales = summary['totalSales'] ?? 0;
    final invoiceCount = (summary['invoiceCount'] ?? 0).toInt();
    final totalDiscount =
        invoices.fold(0.0, (sum, inv) => sum + inv.discountAmount);

    final template = PdfReportTemplate(
      title: 'تقرير المبيعات',
      subtitle: ExportFormatters.formatDateRange(startDate, endDate),
      reportDate: now,
      headerColor: ExportColors.success,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              template.buildHeader(),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: template.buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildStatsBox([
              StatItem(label: 'عدد الفواتير', value: '$invoiceCount'),
              StatItem(
                label: 'إجمالي المبيعات',
                value: ExportFormatters.formatPrice(totalSales),
                color: ExportColors.success,
              ),
              StatItem(
                label: 'إجمالي الخصومات',
                value: ExportFormatters.formatPrice(totalDiscount),
                color: ExportColors.error,
              ),
            ]),
          ),
          pw.SizedBox(height: 16),

          template.buildSectionDivider('تفاصيل الفواتير'),

          // جدول الفواتير
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildTable(
              headers: [
                'الإجمالي',
                'الخصم',
                'طريقة الدفع',
                'التاريخ',
                'رقم الفاتورة',
                '#',
              ],
              headerBgColor: ExportColors.success,
              data: List.generate(invoices.length, (index) {
                final inv = invoices[index];
                return [
                  ExportFormatters.formatPrice(inv.total, showCurrency: false),
                  ExportFormatters.formatPrice(inv.discountAmount,
                      showCurrency: false),
                  ExportFormatters.getPaymentMethodLabel(inv.paymentMethod),
                  ExportFormatters.formatDateTime(inv.invoiceDate),
                  inv.invoiceNumber,
                  '${index + 1}',
                ];
              }),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير تقرير المخزون
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInventoryReport({
    required List<Product> products,
    Map<String, int>? soldQuantities,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    // حساب الإحصائيات
    double totalCostValue = 0;
    double totalSaleValue = 0;
    int totalQuantity = 0;

    for (final p in products) {
      totalCostValue += p.purchasePrice * p.quantity;
      totalSaleValue += p.salePrice * p.quantity;
      totalQuantity += p.quantity;
    }

    final template = PdfReportTemplate(
      title: 'تقرير المخزون',
      reportDate: now,
      headerColor: ExportColors.warning,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              template.buildHeader(),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: template.buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildStatsBox([
              StatItem(label: 'عدد المنتجات', value: '${products.length}'),
              StatItem(label: 'إجمالي الكميات', value: '$totalQuantity'),
              StatItem(
                label: 'قيمة المخزون',
                value: ExportFormatters.formatPrice(totalCostValue),
                color: ExportColors.primary,
              ),
            ]),
          ),
          pw.SizedBox(height: 8),

          // صندوق الربح المتوقع
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: ExportColors.success),
            ),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'الربح المتوقع:',
                    style: pw.TextStyle(
                      font: PdfFonts.bold,
                      fontSize: 12,
                      color: ExportColors.success,
                    ),
                  ),
                  pw.Text(
                    ExportFormatters.formatPrice(
                        totalSaleValue - totalCostValue),
                    style: pw.TextStyle(
                      font: PdfFonts.bold,
                      fontSize: 14,
                      color: ExportColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          template.buildSectionDivider('تفاصيل المنتجات'),

          // جدول المنتجات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildTable(
              headers: [
                'القيمة',
                'سعر البيع',
                'سعر الشراء',
                'الكمية',
                'اسم المنتج',
                '#',
              ],
              headerBgColor: ExportColors.warning,
              data: List.generate(products.length, (index) {
                final p = products[index];
                final value = p.quantity * p.purchasePrice;
                return [
                  ExportFormatters.formatPrice(value, showCurrency: false),
                  ExportFormatters.formatPrice(p.salePrice,
                      showCurrency: false),
                  ExportFormatters.formatPrice(p.purchasePrice,
                      showCurrency: false),
                  '${p.quantity}',
                  p.name,
                  '${index + 1}',
                ];
              }),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير قائمة المنتجات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateProductsList({
    required List<Product> products,
    Map<String, int>? soldQuantities,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    // حساب الإحصائيات
    double totalCostValue = 0;
    int totalQuantity = 0;

    for (final p in products) {
      totalCostValue += p.purchasePrice * p.quantity;
      totalQuantity += p.quantity;
    }

    final template = PdfReportTemplate(
      title: 'قائمة المنتجات',
      reportDate: now,
      headerColor: ExportColors.primary,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              template.buildHeader(),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: template.buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildStatsBox([
              StatItem(label: 'عدد المنتجات', value: '${products.length}'),
              StatItem(label: 'إجمالي الكميات', value: '$totalQuantity'),
              StatItem(
                label: 'قيمة المخزون',
                value: ExportFormatters.formatPrice(totalCostValue),
              ),
            ]),
          ),
          pw.SizedBox(height: 16),

          // جدول المنتجات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildTable(
              headers: [
                'سعر البيع',
                'سعر الشراء',
                'الكمية',
                'اسم المنتج',
                '#',
              ],
              data: List.generate(products.length, (index) {
                final p = products[index];
                return [
                  ExportFormatters.formatPrice(p.salePrice,
                      showCurrency: false),
                  ExportFormatters.formatPrice(p.purchasePrice,
                      showCurrency: false),
                  '${p.quantity}',
                  p.name,
                  '${index + 1}',
                ];
              }),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير قائمة السندات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateVouchersList({
    required List<Voucher> vouchers,
    String? type,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final typeName = type != null ? _getVoucherTypeLabel(type) : 'جميع السندات';

    // حساب الإحصائيات
    double totalAmount = 0;
    for (final voucher in vouchers) {
      totalAmount += voucher.amount;
    }

    final template = PdfReportTemplate(
      title: typeName,
      reportDate: now,
      headerColor:
          type != null ? _getVoucherTypeColor(type) : ExportColors.primary,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              template.buildHeader(),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: template.buildFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildStatsBox([
              StatItem(label: 'عدد السندات', value: '${vouchers.length}'),
              StatItem(
                label: 'إجمالي المبلغ',
                value: ExportFormatters.formatPrice(totalAmount),
                color: ExportColors.success,
              ),
              StatItem(
                label: 'المتوسط',
                value: ExportFormatters.formatPrice(
                    vouchers.isNotEmpty ? totalAmount / vouchers.length : 0),
              ),
            ]),
          ),
          pw.SizedBox(height: 16),

          // جدول السندات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: template.buildTable(
              headers: [
                'المبلغ',
                'الوصف',
                'النوع',
                'التاريخ',
                'رقم السند',
                '#',
              ],
              data: List.generate(vouchers.length, (index) {
                final voucher = vouchers[index];
                return [
                  ExportFormatters.formatPrice(voucher.amount,
                      showCurrency: false),
                  voucher.description ?? '-',
                  _getVoucherTypeLabel(voucher.type),
                  ExportFormatters.formatDateTime(voucher.voucherDate),
                  voucher.voucherNumber,
                  '${index + 1}',
                ];
              }),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _getVoucherTypeLabel(String type) {
    switch (type) {
      case 'receipt':
        return 'سند قبض';
      case 'payment':
        return 'سند دفع';
      case 'expense':
        return 'مصاريف';
      default:
        return type;
    }
  }

  static PdfColor _getVoucherTypeColor(String type) {
    switch (type) {
      case 'receipt':
        return ExportColors.success;
      case 'payment':
        return ExportColors.primary;
      case 'expense':
        return ExportColors.warning;
      default:
        return ExportColors.primary;
    }
  }

  /// حفظ PDF كملف
  static Future<String> savePdfFile(Uint8List bytes, String fileName) async {
    final timestamp =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}';

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filePath = '${exportDir.path}/${fileName}_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('PDF file saved: $filePath');
    return filePath;
  }

  /// مشاركة ملف PDF
  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? 'تقرير PDF',
    );
  }

  /// مشاركة PDF مباشرة من bytes
  static Future<void> sharePdfBytes(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  }) async {
    final filePath = await savePdfFile(bytes, fileName);
    await shareFile(filePath, subject: subject);
  }
}
