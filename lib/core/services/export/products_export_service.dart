import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../export/export_templates.dart';
import '../../theme/pdf_theme.dart';
import '../../../data/database/app_database.dart';

/// خدمة تصدير المنتجات
/// تدعم تصدير قائمة المنتجات إلى Excel و PDF
class ProductsExportService {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;

  /// تحميل الخطوط العربية
  static Future<void> _loadFonts() async {
    if (_arabicFont != null && _arabicFontBold != null) return;

    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _arabicFont = pw.Font.ttf(fontData);
      _arabicFontBold = pw.Font.ttf(fontBoldData);
    } catch (e) {
      // استخدام الخطوط المُهيأة مسبقاً من PdfFonts
      _arabicFont = PdfFonts.regular;
      _arabicFontBold = PdfFonts.bold;
    }
  }

  static pw.Font get _font => _arabicFont ?? PdfFonts.regular;
  static pw.Font get _fontBold => _arabicFontBold ?? PdfFonts.bold;
  // ══════════════════════════════════════════════════════════════════════════
  // تصدير Excel
  // ══════════════════════════════════════════════════════════════════════════

  /// تصدير المنتجات إلى ملف Excel
  static Future<String> exportToExcel({
    required List<Product> products,
    List<Category>? categories,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['المنتجات'];

    // حذف الورقة الافتراضية
    excel.delete('Sheet1');

    // تنسيق رأس الجدول
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
      fontColorHex: ExcelColor.white,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // العناوين
    final headers = [
      '#',
      'اسم المنتج',
      'الباركود',
      'SKU',
      'التصنيف',
      'سعر التكلفة',
      'سعر البيع',
      'هامش الربح',
      'الكمية',
      'الحد الأدنى',
      'الوحدة',
      'قيمة المخزون',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // بناء خريطة التصنيفات
    final categoryMap = <String, String>{};
    if (categories != null) {
      for (final cat in categories) {
        categoryMap[cat.id] = cat.name;
      }
    }

    // تنسيق الصفوف
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );

    final lowStockStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
    );

    // البيانات
    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final row = i + 1;
      final isEven = i.isEven;
      final isLowStock = product.quantity <= product.minQuantity;

      final profit = product.salePrice - product.purchasePrice;
      final margin =
          product.salePrice > 0 ? (profit / product.salePrice * 100) : 0;
      final stockValue = product.quantity * product.purchasePrice;

      final categoryName = product.categoryId != null
          ? categoryMap[product.categoryId] ?? ''
          : '';

      // رقم الصف
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(i + 1);

      // اسم المنتج
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(product.name);

      // الباركود
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(product.barcode ?? '');

      // SKU
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(product.sku ?? '');

      // التصنيف
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(categoryName);

      // سعر التكلفة
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = DoubleCellValue(product.purchasePrice);

      // سعر البيع
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = DoubleCellValue(product.salePrice);

      // هامش الربح
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = TextCellValue('${margin.toStringAsFixed(1)}%');

      // الكمية
      final qtyCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
      qtyCell.value = IntCellValue(product.quantity);
      if (isLowStock) {
        qtyCell.cellStyle = lowStockStyle;
      }

      // الحد الأدنى
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
          .value = IntCellValue(product.minQuantity);

      // الوحدة
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
          .value = TextCellValue('قطعة');

      // قيمة المخزون
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
          .value = DoubleCellValue(stockValue);

      // تطبيق تنسيق الصف الزوجي
      if (isEven && !isLowStock) {
        for (var col = 0; col < headers.length; col++) {
          if (col != 8) {
            // تجنب الكتابة فوق تنسيق المخزون المنخفض
            sheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
                .cellStyle = evenRowStyle;
          }
        }
      }
    }

    // صف الإجماليات
    final summaryRow = products.length + 2;
    final summaryStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      bold: true,
    );

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .value = TextCellValue('الإجمالي');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    // إجمالي عدد المنتجات
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = TextCellValue('${products.length} منتج');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    // إجمالي الكمية
    final totalQty = products.fold(0, (sum, p) => sum + p.quantity);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRow))
        .value = IntCellValue(totalQty);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    // إجمالي قيمة المخزون
    final totalValue =
        products.fold(0.0, (sum, p) => sum + (p.quantity * p.purchasePrice));
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: summaryRow))
        .value = DoubleCellValue(totalValue);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    // ضبط عرض الأعمدة
    sheet.setColumnWidth(0, 5); // #
    sheet.setColumnWidth(1, 25); // اسم المنتج
    sheet.setColumnWidth(2, 15); // الباركود
    sheet.setColumnWidth(3, 12); // SKU
    sheet.setColumnWidth(4, 15); // التصنيف
    sheet.setColumnWidth(5, 12); // سعر التكلفة
    sheet.setColumnWidth(6, 12); // سعر البيع
    sheet.setColumnWidth(7, 10); // هامش الربح
    sheet.setColumnWidth(8, 10); // الكمية
    sheet.setColumnWidth(9, 10); // الحد الأدنى
    sheet.setColumnWidth(10, 10); // الوحدة
    sheet.setColumnWidth(11, 15); // قيمة المخزون

    // حفظ الملف
    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل في إنشاء ملف Excel');

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${directory.path}/${fileName ?? 'products'}_$timestamp.xlsx');
    await file.writeAsBytes(bytes);

    return file.path;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // تصدير PDF
  // ══════════════════════════════════════════════════════════════════════════

  /// تصدير المنتجات إلى ملف PDF
  static Future<Uint8List> generatePdf({
    required List<Product> products,
    List<Category>? categories,
    String? title,
    String? companyName,
  }) async {
    // تحميل الخطوط العربية
    await _loadFonts();

    final pdf = pw.Document();

    // بناء خريطة التصنيفات
    final categoryMap = <String, String>{};
    if (categories != null) {
      for (final cat in categories) {
        categoryMap[cat.id] = cat.name;
      }
    }

    // حساب الإحصائيات
    final totalQty = products.fold(0, (sum, p) => sum + p.quantity);
    final totalCostValue =
        products.fold(0.0, (sum, p) => sum + (p.quantity * p.purchasePrice));
    final totalSaleValue =
        products.fold(0.0, (sum, p) => sum + (p.quantity * p.salePrice));
    final lowStockCount =
        products.where((p) => p.quantity <= p.minQuantity).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        theme: PdfTheme.create(),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: _buildHeader(
            title: title ?? 'قائمة المنتجات',
            companyName: companyName,
            productCount: products.length,
          ),
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // إحصائيات سريعة
                _buildStatsRow(
                  totalProducts: products.length,
                  totalQty: totalQty,
                  totalCostValue: totalCostValue,
                  totalSaleValue: totalSaleValue,
                  lowStockCount: lowStockCount,
                ),
                pw.SizedBox(height: 16),

                // جدول المنتجات
                _buildProductsTable(products, categoryMap),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String title,
    String? companyName,
    required int productCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // العنوان (يمين في RTL)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: _fontBold,
                  fontSize: 18,
                  color: ExportColors.primary,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '$productCount منتج',
                style: pw.TextStyle(
                  font: _font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          // معلومات الشركة والتاريخ (يسار في RTL)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (companyName != null)
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 12,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              pw.Text(
                ExportFormatters.formatDateTime(DateTime.now()),
                style: pw.TextStyle(
                  font: _font,
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount}',
        style: pw.TextStyle(
          font: _font,
          fontSize: 9,
          color: PdfColors.grey500,
        ),
      ),
    );
  }

  static pw.Widget _buildStatsRow({
    required int totalProducts,
    required int totalQty,
    required double totalCostValue,
    required double totalSaleValue,
    required int lowStockCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'عدد المنتجات', '$totalProducts', ExportColors.primary),
          _buildStatItem('إجمالي الكمية', '$totalQty', ExportColors.info),
          _buildStatItem(
            'قيمة المخزون (تكلفة)',
            ExportFormatters.formatPrice(totalCostValue),
            ExportColors.success,
          ),
          _buildStatItem(
            'قيمة المخزون (بيع)',
            ExportFormatters.formatPrice(totalSaleValue),
            ExportColors.primary,
          ),
          if (lowStockCount > 0)
            _buildStatItem(
              'مخزون منخفض',
              '$lowStockCount',
              ExportColors.error,
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: _font,
            fontSize: 8,
            color: PdfColors.grey600,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: 12,
            color: color,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static pw.Widget _buildProductsTable(
    List<Product> products,
    Map<String, String> categoryMap,
  ) {
    // ترتيب الأعمدة من اليمين لليسار (RTL)
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // قيمة المخزون
        1: const pw.FlexColumnWidth(1), // الكمية
        2: const pw.FlexColumnWidth(1.2), // البيع
        3: const pw.FlexColumnWidth(1.2), // التكلفة
        4: const pw.FlexColumnWidth(1.5), // الباركود
        5: const pw.FlexColumnWidth(3), // المنتج
        6: const pw.FlexColumnWidth(0.5), // #
      },
      children: [
        // رأس الجدول (RTL)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ExportColors.primary),
          children: [
            _headerCell('القيمة'),
            _headerCell('الكمية'),
            _headerCell('البيع'),
            _headerCell('التكلفة'),
            _headerCell('الباركود'),
            _headerCell('المنتج'),
            _headerCell('#'),
          ],
        ),
        // البيانات (RTL)
        ...products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isEven = i.isEven;
          final isLowStock = p.quantity <= p.minQuantity;
          final stockValue = p.quantity * p.purchasePrice;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isLowStock
                  ? PdfColors.red50
                  : isEven
                      ? PdfColors.grey50
                      : PdfColors.white,
            ),
            children: [
              _dataCell(ExportFormatters.formatPrice(stockValue,
                  showCurrency: false)),
              _dataCell(
                '${p.quantity}',
                color: isLowStock ? ExportColors.error : null,
                bold: isLowStock,
              ),
              _dataCell(ExportFormatters.formatPrice(p.salePrice,
                  showCurrency: false)),
              _dataCell(ExportFormatters.formatPrice(p.purchasePrice,
                  showCurrency: false)),
              _dataCell(p.barcode ?? '-'),
              _dataCell(p.name, align: pw.Alignment.centerRight),
              _dataCell('${i + 1}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: 9,
          color: PdfColors.white,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _dataCell(
    String text, {
    pw.Alignment align = pw.Alignment.center,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? _fontBold : _font,
          fontSize: 8,
          color: color ?? PdfColors.grey800,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: align == pw.Alignment.centerRight
            ? pw.TextAlign.right
            : pw.TextAlign.center,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // حفظ ومشاركة
  // ══════════════════════════════════════════════════════════════════════════

  /// حفظ PDF إلى ملف
  static Future<String> savePdf(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${fileName}_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// مشاركة ملف
  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? 'قائمة المنتجات',
    );
  }

  /// مشاركة PDF مباشرة من bytes
  static Future<void> sharePdfBytes(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  }) async {
    final filePath = await savePdf(bytes, fileName);
    await shareFile(filePath, subject: subject);
  }
}
