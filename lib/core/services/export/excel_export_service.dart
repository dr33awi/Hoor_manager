import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';
import 'export_templates.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Excel Export Service - خدمة تصدير Excel الموحدة
/// ═══════════════════════════════════════════════════════════════════════════
class ExcelExportService {
  ExcelExportService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // الأنماط المشتركة
  // ═══════════════════════════════════════════════════════════════════════════

  static CellStyle _headerStyle({String? bgColor}) => CellStyle(
        bold: true,
        backgroundColorHex:
            ExcelColor.fromHexString(bgColor ?? ExcelStyles.headerBgColor),
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle _titleStyle() => CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle _summaryLabelStyle() => CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );

  static CellStyle _summaryValueStyle({String? fontColor}) {
    if (fontColor != null) {
      return CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(fontColor),
      );
    }
    return CellStyle(bold: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير قائمة الفواتير
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> exportInvoices({
    required List<Invoice> invoices,
    String? type,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final typeName = type != null
        ? ExportFormatters.getInvoiceTypeLabel(type)
        : 'جميع الفواتير';
    final sheet = excel[typeName];
    excel.delete('Sheet1');

    // حساب الإحصائيات
    double totalAmount = 0;
    double totalDiscount = 0;
    for (final inv in invoices) {
      totalAmount += inv.total;
      totalDiscount += inv.discountAmount;
    }

    int row = 0;

    // ═══════════════════════════════════════════════════════════════════════
    // الترويسة
    // ═══════════════════════════════════════════════════════════════════════
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(typeName)
      ..cellStyle = _titleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'تاريخ التصدير: ${ExportFormatters.formatDateTime(DateTime.now())}');
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // ملخص الإحصائيات
    // ═══════════════════════════════════════════════════════════════════════
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('عدد الفواتير:')
      ..cellStyle = _summaryLabelStyle();
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = IntCellValue(invoices.length)
      ..cellStyle = _summaryValueStyle();
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('إجمالي المبلغ:')
      ..cellStyle = _summaryLabelStyle();
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(ExportFormatters.formatPrice(totalAmount))
      ..cellStyle = _summaryValueStyle(fontColor: ExcelStyles.successColor);
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('إجمالي الخصومات:')
      ..cellStyle = _summaryLabelStyle();
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(ExportFormatters.formatPrice(totalDiscount))
      ..cellStyle = _summaryValueStyle(fontColor: ExcelStyles.errorColor);
    row += 2;

    // ═══════════════════════════════════════════════════════════════════════
    // رأس الجدول
    // ═══════════════════════════════════════════════════════════════════════
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

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = _headerStyle();
    }
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // البيانات
    // ═══════════════════════════════════════════════════════════════════════
    for (var i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      final rowData = [
        '${i + 1}',
        inv.invoiceNumber,
        ExportFormatters.formatDateTime(inv.invoiceDate),
        ExportFormatters.getInvoiceTypeLabel(inv.type),
        ExportFormatters.getPaymentMethodLabel(inv.paymentMethod),
        ExportFormatters.formatPrice(inv.subtotal, showCurrency: false),
        ExportFormatters.formatPrice(inv.discountAmount, showCurrency: false),
        ExportFormatters.formatPrice(inv.total, showCurrency: false),
        ExportFormatters.getInvoiceStatusLabel(inv.status),
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = TextCellValue(rowData[j]);
      }
      row++;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ضبط عرض الأعمدة
    // ═══════════════════════════════════════════════════════════════════════
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 18);
    sheet.setColumnWidth(8, 15);

    return await _saveExcelFile(excel, fileName ?? 'invoices_list');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير تقرير المبيعات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> exportSalesReport({
    required List<Invoice> invoices,
    required DateTime startDate,
    required DateTime endDate,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المبيعات'];
    excel.delete('Sheet1');

    // حساب الإحصائيات
    double totalSales = 0;
    double totalReturns = 0;
    double totalDiscount = 0;

    for (final inv in invoices) {
      if (inv.type == 'sale') {
        totalSales += inv.total;
      } else if (inv.type == 'sale_return') {
        totalReturns += inv.total;
      }
      totalDiscount += inv.discountAmount;
    }

    int row = 0;

    // ═══════════════════════════════════════════════════════════════════════
    // الترويسة
    // ═══════════════════════════════════════════════════════════════════════
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('تقرير المبيعات')
      ..cellStyle = _titleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'الفترة: ${ExportFormatters.formatDateRange(startDate, endDate)}');
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'تاريخ التصدير: ${ExportFormatters.formatDateTime(DateTime.now())}');
    row += 2;

    // ═══════════════════════════════════════════════════════════════════════
    // ملخص الإحصائيات
    // ═══════════════════════════════════════════════════════════════════════
    _addSummaryRow(
        sheet, row++, 'إجمالي المبيعات:', totalSales, ExcelStyles.successColor);
    _addSummaryRow(sheet, row++, 'إجمالي المرتجعات:', totalReturns,
        ExcelStyles.errorColor);
    _addSummaryRow(sheet, row++, 'إجمالي الخصومات:', totalDiscount,
        ExcelStyles.warningColor);
    _addSummaryRow(sheet, row++, 'صافي المبيعات:', totalSales - totalReturns,
        ExcelStyles.successColor);
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // رأس الجدول
    // ═══════════════════════════════════════════════════════════════════════
    final headers = [
      'رقم الفاتورة',
      'التاريخ',
      'النوع',
      'طريقة الدفع',
      'المجموع الفرعي',
      'الخصم',
      'الإجمالي',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = _headerStyle(bgColor: ExcelStyles.successColor);
    }
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // البيانات
    // ═══════════════════════════════════════════════════════════════════════
    for (final inv in invoices) {
      final rowData = [
        inv.invoiceNumber,
        ExportFormatters.formatDateTime(inv.invoiceDate),
        ExportFormatters.getInvoiceTypeLabel(inv.type),
        ExportFormatters.getPaymentMethodLabel(inv.paymentMethod),
        ExportFormatters.formatPrice(inv.subtotal, showCurrency: false),
        ExportFormatters.formatPrice(inv.discountAmount, showCurrency: false),
        ExportFormatters.formatPrice(inv.total, showCurrency: false),
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = TextCellValue(rowData[j]);
      }
      row++;
    }

    // ضبط عرض الأعمدة
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }

    return await _saveExcelFile(excel, fileName ?? 'sales_report');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير تقرير المخزون
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> exportInventoryReport({
    required List<Product> products,
    Map<String, int>? soldQuantities,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المخزون'];
    excel.delete('Sheet1');

    // حساب الإحصائيات
    double totalCostValue = 0;
    double totalSaleValue = 0;
    int totalQuantity = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (final p in products) {
      totalCostValue += p.purchasePrice * p.quantity;
      totalSaleValue += p.salePrice * p.quantity;
      totalQuantity += p.quantity;
      if (p.quantity <= 0) {
        outOfStockCount++;
      } else if (p.quantity <= p.minQuantity) {
        lowStockCount++;
      }
    }

    int row = 0;

    // ═══════════════════════════════════════════════════════════════════════
    // الترويسة
    // ═══════════════════════════════════════════════════════════════════════
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('تقرير المخزون')
      ..cellStyle = _titleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'تاريخ التقرير: ${ExportFormatters.formatDateTime(DateTime.now())}');
    row += 2;

    // ═══════════════════════════════════════════════════════════════════════
    // ملخص الإحصائيات
    // ═══════════════════════════════════════════════════════════════════════
    _addSummaryRow(
        sheet, row++, 'عدد المنتجات:', products.length.toDouble(), null);
    _addSummaryRow(
        sheet, row++, 'إجمالي الكميات:', totalQuantity.toDouble(), null);
    _addSummaryRow(sheet, row++, 'قيمة التكلفة:', totalCostValue,
        ExcelStyles.headerBgColor);
    _addSummaryRow(
        sheet, row++, 'قيمة البيع:', totalSaleValue, ExcelStyles.successColor);
    _addSummaryRow(sheet, row++, 'الربح المتوقع:',
        totalSaleValue - totalCostValue, ExcelStyles.successColor);
    _addSummaryRow(sheet, row++, 'نقص مخزون:', lowStockCount.toDouble(),
        ExcelStyles.warningColor);
    _addSummaryRow(sheet, row++, 'نفذ المخزون:', outOfStockCount.toDouble(),
        ExcelStyles.errorColor);
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // رأس الجدول
    // ═══════════════════════════════════════════════════════════════════════
    final headers = [
      'اسم المنتج',
      'الباركود',
      'الكمية',
      'المباع',
      'الحد الأدنى',
      'سعر الشراء',
      'سعر البيع',
      'قيمة المخزون',
      'الحالة',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = _headerStyle(bgColor: ExcelStyles.warningColor);
    }
    row++;

    // ═══════════════════════════════════════════════════════════════════════
    // البيانات
    // ═══════════════════════════════════════════════════════════════════════
    for (final p in products) {
      String status;
      if (p.quantity <= 0) {
        status = 'نفذ المخزون';
      } else if (p.quantity <= p.minQuantity) {
        status = 'نقص مخزون';
      } else {
        status = 'متوفر';
      }

      final soldQty = soldQuantities?[p.id] ?? 0;
      final inventoryValue = p.purchasePrice * p.quantity;
      final rowData = [
        p.name,
        p.barcode ?? '-',
        '${p.quantity}',
        '$soldQty',
        '${p.minQuantity}',
        ExportFormatters.formatPrice(p.purchasePrice, showCurrency: false),
        ExportFormatters.formatPrice(p.salePrice, showCurrency: false),
        ExportFormatters.formatPrice(inventoryValue, showCurrency: false),
        status,
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = TextCellValue(rowData[j]);
      }
      row++;
    }

    // ضبط عرض الأعمدة
    sheet.setColumnWidth(0, 30);
    for (var i = 1; i < headers.length; i++) {
      sheet.setColumnWidth(i, 16);
    }

    return await _saveExcelFile(excel, fileName ?? 'inventory_report');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير قائمة المنتجات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> exportProducts({
    required List<Product> products,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['قائمة المنتجات'];
    excel.delete('Sheet1');

    int row = 0;

    // الترويسة
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('قائمة المنتجات')
      ..cellStyle = _titleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'تاريخ التصدير: ${ExportFormatters.formatDateTime(DateTime.now())}');
    row++;

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('إجمالي المنتجات: ${products.length}');
    row += 2;

    // رأس الجدول
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

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = _headerStyle();
    }
    row++;

    // البيانات
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

      final rowData = [
        '${i + 1}',
        p.name,
        p.barcode ?? '-',
        ExportFormatters.formatPrice(p.purchasePrice, showCurrency: false),
        ExportFormatters.formatPrice(p.salePrice, showCurrency: false),
        '${p.quantity}',
        '${p.minQuantity}',
        status,
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = TextCellValue(rowData[j]);
      }
      row++;
    }

    // ضبط عرض الأعمدة
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 30);
    for (var i = 2; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }

    return await _saveExcelFile(excel, fileName ?? 'products_list');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تصدير السندات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> exportVouchers({
    required List<Voucher> vouchers,
    String? type,
    String? fileName,
  }) async {
    final excel = Excel.createExcel();
    final typeName = type != null ? _getVoucherTypeLabel(type) : 'جميع السندات';
    final sheet = excel[typeName];
    excel.delete('Sheet1');

    // حساب الإحصائيات
    double totalAmount = 0;
    for (final v in vouchers) {
      totalAmount += v.amount;
    }

    int row = 0;

    // الترويسة
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(typeName)
      ..cellStyle = _titleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    row++;

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            'تاريخ التصدير: ${ExportFormatters.formatDateTime(DateTime.now())}');
    row++;

    // ملخص
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('عدد السندات:')
      ..cellStyle = _summaryLabelStyle();
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = IntCellValue(vouchers.length);
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('المجموع:')
      ..cellStyle = _summaryLabelStyle();
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(ExportFormatters.formatPrice(totalAmount));
    row += 2;

    // رأس الجدول
    final headers = [
      '#',
      'رقم السند',
      'النوع',
      'التاريخ',
      'المبلغ',
      'الوصف',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = _headerStyle();
    }
    row++;

    // البيانات
    for (var i = 0; i < vouchers.length; i++) {
      final v = vouchers[i];
      final rowData = [
        '${i + 1}',
        v.voucherNumber,
        _getVoucherTypeLabel(v.type),
        ExportFormatters.formatDate(v.voucherDate),
        ExportFormatters.formatPrice(v.amount, showCurrency: false),
        v.description ?? '',
      ];

      for (var j = 0; j < rowData.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
            .value = TextCellValue(rowData[j]);
      }
      row++;
    }

    // ضبط عرض الأعمدة
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 30);

    return await _saveExcelFile(excel, fileName ?? 'vouchers_list');
  }

  static String _getVoucherTypeLabel(String type) {
    switch (type) {
      case 'receipt':
        return 'سند قبض';
      case 'payment':
        return 'سند دفع';
      case 'expense':
        return 'سند مصاريف';
      default:
        return type;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════════════════

  static void _addSummaryRow(
      Sheet sheet, int row, String label, double value, String? color,
      {String? prefix}) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(label)
      ..cellStyle = _summaryLabelStyle();
    final valueText = prefix != null
        ? '$prefix${value.toStringAsFixed(2)}'
        : ExportFormatters.formatPrice(value);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue(valueText)
      ..cellStyle = _summaryValueStyle(fontColor: color);
  }

  static Future<String> _saveExcelFile(Excel excel, String fileName) async {
    final timestamp =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}';

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

  /// مشاركة ملف Excel
  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? 'تقرير Excel',
    );
  }
}
