import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/database/app_database.dart';
import '../theme/pdf_theme.dart';
import '../widgets/invoice_widgets.dart';
import 'invoice_print_service.dart';

/// خدمة موحدة للتصدير والطباعة
class ExportService {
  ExportService();

  /// تهيئة خطوط PDF - يجب استدعاؤها مرة واحدة عند بدء التطبيق
  static Future<void> initializePdfFonts() async {
    await PdfFonts.init();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير Excel
  // ═══════════════════════════════════════════════════════════════════════════

  /// تصدير تقرير المبيعات إلى Excel
  Future<String> exportSalesReportToExcel({
    required List<Invoice> invoices,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المبيعات'];

    // إزالة الورقة الافتراضية
    excel.delete('Sheet1');

    // تنسيق العناوين
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // إضافة معلومات التقرير
    sheet.appendRow([
      TextCellValue('تقرير المبيعات'),
    ]);
    sheet.appendRow([
      TextCellValue(
          'الفترة: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'),
    ]);
    sheet.appendRow([TextCellValue('')]); // سطر فارغ

    // رأس الجدول
    final headers = [
      'رقم الفاتورة',
      'التاريخ',
      'النوع',
      'طريقة الدفع',
      'المجموع الفرعي',
      'الخصم',
      'الإجمالي',
      'الحالة',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // تطبيق التنسيق على العناوين
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
          .cellStyle = headerStyle;
    }

    // إضافة البيانات
    double totalSales = 0;
    double totalReturns = 0;
    double totalDiscount = 0;

    for (final invoice in invoices) {
      sheet.appendRow([
        TextCellValue(invoice.invoiceNumber),
        TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm').format(invoice.invoiceDate)),
        TextCellValue(getInvoiceTypeLabel(invoice.type)),
        TextCellValue(getPaymentMethodLabel(invoice.paymentMethod)),
        DoubleCellValue(invoice.subtotal),
        DoubleCellValue(invoice.discountAmount),
        DoubleCellValue(invoice.total),
        TextCellValue(invoice.status == 'completed' ? 'مكتملة' : 'معلقة'),
      ]);

      if (invoice.type == 'sale') {
        totalSales += invoice.total;
      } else if (invoice.type == 'sale_return') {
        totalReturns += invoice.total;
      }
      totalDiscount += invoice.discountAmount;
    }

    // إضافة الملخص
    sheet.appendRow([TextCellValue('')]); // سطر فارغ
    sheet.appendRow([
      TextCellValue('الملخص'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي المبيعات:'),
      DoubleCellValue(totalSales),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي المرتجعات:'),
      DoubleCellValue(totalReturns),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي الخصومات:'),
      DoubleCellValue(totalDiscount),
    ]);
    sheet.appendRow([
      TextCellValue('صافي المبيعات:'),
      DoubleCellValue(totalSales - totalReturns),
    ]);

    // ضبط عرض الأعمدة
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 12);

    return await _saveExcelFile(excel, 'sales_report');
  }

  /// تصدير تقرير المخزون إلى Excel
  Future<String> exportInventoryReportToExcel({
    required List<Product> products,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المخزون'];

    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.green700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // معلومات التقرير
    sheet.appendRow([TextCellValue('تقرير المخزون')]);
    sheet.appendRow([
      TextCellValue(
          'تاريخ التقرير: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    // رأس الجدول
    final headers = [
      'اسم المنتج',
      'الباركود',
      'الكمية',
      'الحد الأدنى',
      'سعر الشراء',
      'سعر البيع',
      'قيمة التكلفة',
      'قيمة البيع',
      'الحالة',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
          .cellStyle = headerStyle;
    }

    // إضافة البيانات
    double totalCostValue = 0;
    double totalSaleValue = 0;

    for (final product in products) {
      final costValue = product.purchasePrice * product.quantity;
      final saleValue = product.salePrice * product.quantity;
      totalCostValue += costValue;
      totalSaleValue += saleValue;

      String status;
      if (product.quantity <= 0) {
        status = 'نفذ المخزون';
      } else if (product.quantity <= product.minQuantity) {
        status = 'نقص مخزون';
      } else {
        status = 'متوفر';
      }

      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.barcode ?? ''),
        IntCellValue(product.quantity),
        IntCellValue(product.minQuantity),
        DoubleCellValue(product.purchasePrice),
        DoubleCellValue(product.salePrice),
        DoubleCellValue(costValue),
        DoubleCellValue(saleValue),
        TextCellValue(status),
      ]);
    }

    // الملخص
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('إجمالي المنتجات:'),
      IntCellValue(products.length),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي قيمة التكلفة:'),
      DoubleCellValue(totalCostValue),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي قيمة البيع:'),
      DoubleCellValue(totalSaleValue),
    ]);
    sheet.appendRow([
      TextCellValue('الربح المتوقع:'),
      DoubleCellValue(totalSaleValue - totalCostValue),
    ]);

    // ضبط عرض الأعمدة
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(0, 25); // اسم المنتج

    return await _saveExcelFile(excel, 'inventory_report');
  }

  /// تصدير تقرير المنتجات إلى Excel
  Future<String> exportProductsReportToExcel({
    required List<Map<String, dynamic>> productsData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المنتجات'];

    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.purple700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([TextCellValue('تقرير أداء المنتجات')]);
    sheet.appendRow([
      TextCellValue(
          'الفترة: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    final headers = [
      'اسم المنتج',
      'الكمية المباعة',
      'إجمالي المبيعات',
      'متوسط السعر',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
          .cellStyle = headerStyle;
    }

    for (final data in productsData) {
      sheet.appendRow([
        TextCellValue(data['name'] ?? ''),
        IntCellValue(data['quantity'] ?? 0),
        DoubleCellValue(data['total'] ?? 0.0),
        DoubleCellValue(data['averagePrice'] ?? 0.0),
      ]);
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
    sheet.setColumnWidth(0, 30);

    return await _saveExcelFile(excel, 'products_report');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF وظائف
  // ═══════════════════════════════════════════════════════════════════════════

  /// إنشاء PDF للفاتورة ومشاركتها
  Future<void> shareInvoiceAsPdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String printSize = 'A4',
    Customer? customer,
    Supplier? supplier,
  }) async {
    final pdfBytes = await InvoicePrintService.generateInvoicePdf(
      invoice: invoice,
      items: items,
      printSize: printSize,
      customer: customer,
      supplier: supplier,
    );

    final filePath =
        await _savePdfFile(pdfBytes, 'invoice_${invoice.invoiceNumber}');

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'فاتورة ${invoice.invoiceNumber}',
      text:
          'فاتورة رقم ${invoice.invoiceNumber} بتاريخ ${DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)}',
    );
  }

  /// حفظ PDF للفاتورة محلياً
  Future<String> saveInvoiceAsPdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String printSize = 'A4',
    Customer? customer,
    Supplier? supplier,
  }) async {
    final pdfBytes = await InvoicePrintService.generateInvoicePdf(
      invoice: invoice,
      items: items,
      printSize: printSize,
      customer: customer,
      supplier: supplier,
    );

    return await _savePdfFile(pdfBytes, 'invoice_${invoice.invoiceNumber}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تقرير الفواتير
  // ═══════════════════════════════════════════════════════════════════════════

  /// تصدير قائمة الفواتير إلى Excel
  Future<String> exportInvoicesToExcel({
    required List<Invoice> invoices,
    String? type,
  }) async {
    final excel = Excel.createExcel();
    final typeName = type != null ? getInvoiceTypeLabel(type) : 'جميع الفواتير';
    final sheet = excel[typeName];

    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // حساب الإحصائيات
    double totalAmount = 0;
    for (final inv in invoices) {
      totalAmount += inv.total;
    }

    sheet.appendRow([TextCellValue(typeName)]);
    sheet.appendRow([
      TextCellValue(
          'تاريخ التصدير: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
    ]);
    sheet.appendRow([TextCellValue('عدد الفواتير: ${invoices.length}')]);
    sheet.appendRow(
        [TextCellValue('إجمالي المبلغ: ${formatPrice(totalAmount)}')]);
    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'رقم الفاتورة',
      'التاريخ',
      'النوع',
      'طريقة الدفع',
      'المجموع الفرعي',
      'الخصم',
      'الإجمالي',
      'الحالة',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5))
          .cellStyle = headerStyle;
    }

    for (var i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(inv.invoiceNumber),
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(inv.invoiceDate)),
        TextCellValue(getInvoiceTypeLabel(inv.type)),
        TextCellValue(getPaymentMethodLabel(inv.paymentMethod)),
        DoubleCellValue(inv.subtotal),
        DoubleCellValue(inv.discountAmount),
        DoubleCellValue(inv.total),
        TextCellValue(inv.status == 'completed' ? 'مكتملة' : 'معلقة'),
      ]);
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(1, 20);

    return await _saveExcelFile(excel, 'invoices_list');
  }

  /// إنشاء PDF لقائمة الفواتير
  Future<Uint8List> generateInvoicesPdf({
    required List<Invoice> invoices,
    String? type,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final doc = pw.Document();
    final typeName = type != null ? getInvoiceTypeLabel(type) : 'جميع الفواتير';

    // حساب الإحصائيات
    double totalAmount = 0;
    double totalDiscount = 0;
    for (final inv in invoices) {
      totalAmount += inv.total;
      totalDiscount += inv.discountAmount;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              PdfTheme.header(
                title: typeName,
                date: 'تاريخ التقرير: ${dateFormat.format(now)}',
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('عدد الفواتير: ${invoices.length}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                  pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.summaryBox(
              items: [
                MapEntry('عدد الفواتير', '${invoices.length}'),
                MapEntry('إجمالي المبلغ', formatPrice(totalAmount)),
                MapEntry('إجمالي الخصومات', formatPrice(totalDiscount)),
                MapEntry(
                    'المتوسط',
                    formatPrice(invoices.isNotEmpty
                        ? totalAmount / invoices.length
                        : 0)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // جدول الفواتير
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.table(
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
                  formatPrice(inv.total, showCurrency: false),
                  formatPrice(inv.discountAmount, showCurrency: false),
                  getPaymentMethodLabel(inv.paymentMethod),
                  getInvoiceTypeLabel(inv.type),
                  DateFormat('dd/MM/yyyy HH:mm').format(inv.invoiceDate),
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

  /// إنشاء PDF لتقرير المبيعات
  Future<Uint8List> generateSalesReportPdf({
    required List<Invoice> invoices,
    required Map<String, double> summary,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final doc = pw.Document();

    // حساب الإحصائيات
    final totalSales = summary['totalSales'] ?? 0;
    final invoiceCount = (summary['invoiceCount'] ?? 0).toInt();
    final averageInvoice = summary['averageInvoice'] ?? 0;
    final totalDiscount =
        invoices.fold(0.0, (sum, inv) => sum + inv.discountAmount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              PdfTheme.header(
                title: 'تقرير المبيعات',
                subtitle:
                    'الفترة: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                date: 'تاريخ التقرير: ${dateFormat.format(now)}',
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('عدد الفواتير: $invoiceCount',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                  pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.summaryBox(
              items: [
                MapEntry('عدد الفواتير', '$invoiceCount'),
                MapEntry('إجمالي المبيعات', formatPrice(totalSales)),
                MapEntry('متوسط الفاتورة', formatPrice(averageInvoice)),
                MapEntry('إجمالي الخصومات', formatPrice(totalDiscount)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // جدول الفواتير
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.table(
              headers: [
                'الإجمالي',
                'الخصم',
                'طريقة الدفع',
                'التاريخ',
                'رقم الفاتورة',
                '#',
              ],
              data: List.generate(invoices.length, (index) {
                final invoice = invoices[index];
                return [
                  formatPrice(invoice.total, showCurrency: false),
                  formatPrice(invoice.discountAmount, showCurrency: false),
                  getPaymentMethodLabel(invoice.paymentMethod),
                  DateFormat('dd/MM/yyyy HH:mm').format(invoice.invoiceDate),
                  invoice.invoiceNumber,
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

  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filePath = '${exportDir.path}/${fileName}_$timestamp.xlsx';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      debugPrint('Excel file saved: $filePath');
      return filePath;
    }

    throw Exception('فشل في إنشاء ملف Excel');
  }

  Future<String> _savePdfFile(Uint8List bytes, String fileName) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
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

  /// مشاركة ملف Excel
  Future<void> shareExcelFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'تقرير Excel',
    );
  }

  /// مشاركة ملف PDF
  Future<void> sharePdfFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? 'تقرير PDF',
    );
  }

  /// تصدير قائمة المنتجات إلى Excel
  Future<String> exportProductsToExcel({
    required List<Product> products,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['قائمة المنتجات'];

    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue700,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([TextCellValue('قائمة المنتجات')]);
    sheet.appendRow([
      TextCellValue(
          'تاريخ التصدير: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
    ]);
    sheet.appendRow([TextCellValue('إجمالي المنتجات: ${products.length}')]);
    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'اسم المنتج',
      'الباركود',
      'سعر الشراء',
      'سعر البيع',
      'الكمية',
      'الحد الأدنى',
      'الحالة',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
          .cellStyle = headerStyle;
    }

    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      String status;
      if (p.quantity <= 0) {
        status = 'نفذ المخزون';
      } else if (p.quantity <= p.minQuantity) {
        status = 'نقص مخزون';
      } else {
        status = 'متوفر';
      }

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.name),
        TextCellValue(p.barcode ?? '-'),
        DoubleCellValue(p.purchasePrice),
        DoubleCellValue(p.salePrice),
        IntCellValue(p.quantity),
        IntCellValue(p.minQuantity),
        TextCellValue(status),
      ]);
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(1, 30);

    return await _saveExcelFile(excel, 'products_list');
  }

  /// إنشاء PDF لقائمة المنتجات (نظام موحد مثل جرد المخزون)
  Future<Uint8List> generateProductsPdf({
    required List<Product> products,
    Map<String, int>? soldQuantities,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final doc = pw.Document();

    // حساب الإحصائيات
    double totalCostValue = 0;
    int totalQuantity = 0;
    int totalSold = 0;

    for (final p in products) {
      totalCostValue += p.purchasePrice * p.quantity;
      totalQuantity += p.quantity;
      totalSold += soldQuantities?[p.id] ?? 0;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              PdfTheme.header(
                title: 'قائمة المنتجات',
                date: 'تاريخ التقرير: ${dateFormat.format(now)}',
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('إجمالي المنتجات: ${products.length}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                  pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.summaryBox(
              items: [
                MapEntry('عدد المنتجات', '${products.length}'),
                MapEntry('إجمالي الكميات', '$totalQuantity'),
                MapEntry('إجمالي المباع', '$totalSold'),
                MapEntry('قيمة المخزون', formatPrice(totalCostValue)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // جدول المنتجات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.table(
              headers: [
                'القيمة',
                'سعر البيع',
                'سعر الشراء',
                'المباع',
                'الكمية',
                'الباركود',
                'اسم المنتج',
                '#',
              ],
              data: List.generate(products.length, (index) {
                final product = products[index];
                final value = product.quantity * product.purchasePrice;
                final soldQty = soldQuantities?[product.id] ?? 0;
                return [
                  formatPrice(value, showCurrency: false),
                  formatPrice(product.salePrice, showCurrency: false),
                  formatPrice(product.purchasePrice, showCurrency: false),
                  '$soldQty',
                  '${product.quantity}',
                  product.barcode ?? '-',
                  product.name,
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

  /// إنشاء PDF لتقرير المخزون (نظام موحد مثل جرد المخزون)
  Future<Uint8List> generateInventoryReportPdf({
    required List<Product> products,
    Map<String, int>? soldQuantities,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final doc = pw.Document();

    // حساب الإحصائيات
    double totalCostValue = 0;
    int totalQuantity = 0;
    int totalSold = 0;

    for (final p in products) {
      totalCostValue += p.purchasePrice * p.quantity;
      totalQuantity += p.quantity;
      totalSold += soldQuantities?[p.id] ?? 0;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              PdfTheme.header(
                title: 'تقرير جرد المخزون',
                date: 'تاريخ التقرير: ${dateFormat.format(now)}',
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('إجمالي المنتجات: ${products.length}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                  pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
                      style: PdfStyles.caption(),
                      textDirection: pw.TextDirection.rtl),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // ملخص الإحصائيات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.summaryBox(
              items: [
                MapEntry('عدد المنتجات', '${products.length}'),
                MapEntry('إجمالي الكميات', '$totalQuantity'),
                MapEntry('إجمالي المباع', '$totalSold'),
                MapEntry('قيمة المخزون', formatPrice(totalCostValue)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // جدول المنتجات
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: PdfTheme.table(
              headers: [
                'القيمة',
                'سعر البيع',
                'سعر الشراء',
                'المباع',
                'الكمية',
                'الباركود',
                'اسم المنتج',
                '#',
              ],
              data: List.generate(products.length, (index) {
                final product = products[index];
                final value = product.quantity * product.purchasePrice;
                final soldQty = soldQuantities?[product.id] ?? 0;
                return [
                  formatPrice(value, showCurrency: false),
                  formatPrice(product.salePrice, showCurrency: false),
                  formatPrice(product.purchasePrice, showCurrency: false),
                  '$soldQty',
                  '${product.quantity}',
                  product.barcode ?? '-',
                  product.name,
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
}
