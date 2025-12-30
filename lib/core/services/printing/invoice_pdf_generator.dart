import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../export/export_templates.dart';
import '../../theme/pdf_theme.dart';

/// أحجام الطباعة المدعومة للفواتير
enum InvoicePrintSize {
  a4, // فاتورة A4 كاملة
  thermal80mm, // طابعة حرارية 80mm
  thermal58mm, // طابعة حرارية 58mm
}

/// خيارات طباعة الفاتورة
class InvoicePrintOptions {
  final InvoicePrintSize size;
  final bool showBarcode;
  final bool showLogo;
  final bool showCustomerInfo;
  final bool showNotes;
  final bool showPaymentMethod;
  final bool showTaxDetails;
  final Uint8List? logoBytes;
  final String? companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyTaxNumber;

  const InvoicePrintOptions({
    this.size = InvoicePrintSize.a4,
    this.showBarcode = true,
    this.showLogo = true,
    this.showCustomerInfo = true,
    this.showNotes = true,
    this.showPaymentMethod = true,
    this.showTaxDetails = true,
    this.logoBytes,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyTaxNumber,
  });

  InvoicePrintOptions copyWith({
    InvoicePrintSize? size,
    bool? showBarcode,
    bool? showLogo,
    bool? showCustomerInfo,
    bool? showNotes,
    bool? showPaymentMethod,
    bool? showTaxDetails,
    Uint8List? logoBytes,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyTaxNumber,
  }) {
    return InvoicePrintOptions(
      size: size ?? this.size,
      showBarcode: showBarcode ?? this.showBarcode,
      showLogo: showLogo ?? this.showLogo,
      showCustomerInfo: showCustomerInfo ?? this.showCustomerInfo,
      showNotes: showNotes ?? this.showNotes,
      showPaymentMethod: showPaymentMethod ?? this.showPaymentMethod,
      showTaxDetails: showTaxDetails ?? this.showTaxDetails,
      logoBytes: logoBytes ?? this.logoBytes,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyTaxNumber: companyTaxNumber ?? this.companyTaxNumber,
    );
  }
}

/// بيانات عنصر الفاتورة
class InvoiceItemData {
  final String name;
  final String? barcode;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discount;
  final double total;

  const InvoiceItemData({
    required this.name,
    this.barcode,
    required this.quantity,
    this.unit = 'قطعة',
    required this.unitPrice,
    this.discount = 0,
    required this.total,
  });
}

/// بيانات الفاتورة للطباعة
class InvoiceData {
  final String invoiceNumber;
  final String invoiceType; // sale, purchase, saleReturn, purchaseReturn
  final DateTime date;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<InvoiceItemData> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double? paidAmount;
  final double? remainingAmount;
  final String? paymentMethod; // cash, credit, deferred
  final String? notes;
  final String? createdBy;

  const InvoiceData({
    required this.invoiceNumber,
    required this.invoiceType,
    required this.date,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.paidAmount,
    this.remainingAmount,
    this.paymentMethod,
    this.notes,
    this.createdBy,
  });
}

/// مولد PDF للفواتير
class InvoicePdfGenerator {
  late pw.Font _arabicFont;
  late pw.Font _arabicFontBold;
  bool _fontsLoaded = false;

  // ==================== Static Helper Methods ====================

  /// طباعة فاتورة مباشرة (static method للاستخدام المباشر)
  static Future<void> printInvoiceDirectly({
    required dynamic invoice,
    required List<dynamic> items,
    dynamic customer,
    dynamic supplier,
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final generator = InvoicePdfGenerator();
    final invoiceData = _createInvoiceData(invoice, items, customer, supplier);
    await generator.printInvoice(invoiceData, options: options);
  }

  /// مشاركة فاتورة كـ PDF (static method للاستخدام المباشر)
  static Future<void> shareInvoiceAsPdf({
    required dynamic invoice,
    required List<dynamic> items,
    dynamic customer,
    dynamic supplier,
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final generator = InvoicePdfGenerator();
    final invoiceData = _createInvoiceData(invoice, items, customer, supplier);
    await generator.shareInvoice(invoiceData, options: options);
  }

  /// حفظ فاتورة كـ PDF (static method للاستخدام المباشر)
  static Future<String> saveInvoiceAsPdf({
    required dynamic invoice,
    required List<dynamic> items,
    dynamic customer,
    dynamic supplier,
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final generator = InvoicePdfGenerator();
    final invoiceData = _createInvoiceData(invoice, items, customer, supplier);
    return await generator.saveInvoicePdf(invoiceData, options: options);
  }

  /// الحصول على bytes الـ PDF للمعاينة (static method للاستخدام المباشر)
  static Future<Uint8List> generateInvoicePdfBytes({
    required dynamic invoice,
    required List<dynamic> items,
    dynamic customer,
    dynamic supplier,
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final generator = InvoicePdfGenerator();
    final invoiceData = _createInvoiceData(invoice, items, customer, supplier);
    return await generator.generateInvoicePdf(invoiceData, options: options);
  }

  /// تحويل بيانات الفاتورة من الـ Database models إلى InvoiceData
  static InvoiceData _createInvoiceData(
    dynamic invoice,
    List<dynamic> items,
    dynamic customer,
    dynamic supplier,
  ) {
    return InvoiceData(
      invoiceNumber: invoice.invoiceNumber,
      date: invoice.invoiceDate,
      invoiceType: invoice.type,
      customerName: customer?.name ?? supplier?.name,
      customerPhone: customer?.phone ?? supplier?.phone,
      customerAddress: customer?.address ?? supplier?.address,
      items: items
          .map((item) => InvoiceItemData(
                name: item.productName,
                barcode: null,
                quantity: item.quantity.toDouble(),
                unit: 'قطعة',
                unitPrice: item.unitPrice,
                discount: item.discountAmount ?? 0.0,
                total: item.total,
              ))
          .toList(),
      subtotal: invoice.subtotal,
      discount: invoice.discountAmount,
      total: invoice.total,
      paymentMethod: invoice.paymentMethod,
      notes: invoice.notes,
    );
  }

  // ==================== Instance Methods ====================

  /// تحميل الخطوط العربية
  Future<void> _loadFonts() async {
    if (_fontsLoaded) return;

    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _arabicFont = pw.Font.ttf(fontData);
      _arabicFontBold = pw.Font.ttf(fontBoldData);
      _fontsLoaded = true;
    } catch (e) {
      // استخدام الخطوط المُهيأة مسبقاً
      _arabicFont = PdfFonts.regular;
      _arabicFontBold = PdfFonts.bold;
      _fontsLoaded = true;
    }
  }

  /// طباعة الفاتورة مباشرة
  Future<void> printInvoice(
    InvoiceData invoice, {
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final pdfBytes = await generateInvoicePdf(invoice, options: options);
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'فاتورة_${invoice.invoiceNumber}',
    );
  }

  /// إنشاء PDF للفاتورة
  Future<Uint8List> generateInvoicePdf(
    InvoiceData invoice, {
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    switch (options.size) {
      case InvoicePrintSize.a4:
        pdf.addPage(_buildA4Invoice(invoice, options));
        break;
      case InvoicePrintSize.thermal80mm:
        pdf.addPage(_buildThermalInvoice(invoice, options, 80));
        break;
      case InvoicePrintSize.thermal58mm:
        pdf.addPage(_buildThermalInvoice(invoice, options, 58));
        break;
    }

    return pdf.save();
  }

  /// حفظ PDF للفاتورة
  Future<String> saveInvoicePdf(
    InvoiceData invoice, {
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final pdfBytes = await generateInvoicePdf(invoice, options: options);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'فاتورة_${invoice.invoiceNumber}_$timestamp.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// مشاركة الفاتورة
  Future<void> shareInvoice(
    InvoiceData invoice, {
    InvoicePrintOptions options = const InvoicePrintOptions(),
  }) async {
    final filePath = await saveInvoicePdf(invoice, options: options);
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'فاتورة رقم ${invoice.invoiceNumber}',
    );
  }

  // ==================== فاتورة A4 (باستخدام القالب الموحد) ====================

  pw.Page _buildA4Invoice(InvoiceData invoice, InvoicePrintOptions options) {
    final invoiceColor = _getInvoiceColor(invoice.invoiceType);

    // استخدام القالب الموحد
    final template = PdfReportTemplate(
      title: _getInvoiceTypeLabel(invoice.invoiceType),
      subtitle: 'رقم الفاتورة: ${invoice.invoiceNumber}',
      reportDate: invoice.date,
      headerColor: invoiceColor,
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(40),
      theme: PdfTheme.create(),
      build: (context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // الرأس الموحد
              template.buildHeader(),
              pw.SizedBox(height: 16),

              // صندوق الإحصائيات الموحد
              template.buildStatsBox([
                StatItem(
                  label: 'عدد الأصناف',
                  value: '${invoice.items.length}',
                ),
                StatItem(
                  label: 'المجموع الفرعي',
                  value: ExportFormatters.formatPrice(invoice.subtotal),
                ),
                if (invoice.discount > 0)
                  StatItem(
                    label: 'الخصم',
                    value: ExportFormatters.formatPrice(invoice.discount),
                    color: ExportColors.error,
                  ),
                StatItem(
                  label: 'الإجمالي',
                  value: ExportFormatters.formatPrice(invoice.total),
                  color: ExportColors.success,
                ),
              ]),
              pw.SizedBox(height: 16),

              // معلومات العميل/المورد
              if (options.showCustomerInfo && invoice.customerName != null) ...[
                _buildUnifiedCustomerInfoBox(invoice),
                pw.SizedBox(height: 16),
              ],

              // جدول المنتجات الموحد
              template.buildTable(
                headers: [
                  'الإجمالي',
                  'الخصم',
                  'السعر',
                  'الكمية',
                  'الصنف',
                  '#',
                ],
                data: List.generate(invoice.items.length, (index) {
                  final item = invoice.items[index];
                  return [
                    ExportFormatters.formatPrice(item.total,
                        showCurrency: false),
                    ExportFormatters.formatPrice(item.discount,
                        showCurrency: false),
                    ExportFormatters.formatPrice(item.unitPrice,
                        showCurrency: false),
                    ExportFormatters.formatQuantity(item.quantity),
                    item.name,
                    '${index + 1}',
                  ];
                }),
                headerBgColor: invoiceColor,
              ),
              pw.SizedBox(height: 16),

              // طريقة الدفع والملاحظات
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (options.showPaymentMethod &&
                      invoice.paymentMethod != null)
                    pw.Expanded(
                      child: _buildInfoBox(
                        'طريقة الدفع',
                        ExportFormatters.getPaymentMethodLabel(
                            invoice.paymentMethod!),
                      ),
                    ),
                  if (options.showPaymentMethod &&
                      invoice.paymentMethod != null &&
                      options.showNotes &&
                      invoice.notes != null)
                    pw.SizedBox(width: 16),
                  if (options.showNotes && invoice.notes != null)
                    pw.Expanded(
                      child: _buildInfoBox('ملاحظات', invoice.notes!),
                    ),
                ],
              ),

              pw.Spacer(),

              // التذييل الموحد
              template.buildFooter(),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _buildUnifiedCustomerInfoBox(InvoiceData invoice) {
    final isSupplier = invoice.invoiceType == 'purchase' ||
        invoice.invoiceType == 'purchase_return';
    final label = isSupplier ? 'المورد' : 'العميل';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: ExportColors.tableBorder),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$label: ${invoice.customerName}',
                  style: pw.TextStyle(font: PdfFonts.bold, fontSize: 12),
                ),
                if (invoice.customerPhone != null)
                  pw.Text(
                    'الهاتف: ${invoice.customerPhone}',
                    style: pw.TextStyle(font: PdfFonts.regular, fontSize: 10),
                  ),
                if (invoice.customerAddress != null)
                  pw.Text(
                    'العنوان: ${invoice.customerAddress}',
                    style: pw.TextStyle(font: PdfFonts.regular, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoBox(String title, String content) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: ExportColors.tableBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: PdfFonts.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            content,
            style: pw.TextStyle(font: PdfFonts.regular, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== الدوال القديمة (للحفاظ على التوافق) ====================

  pw.Widget _buildA4Header(
    InvoiceData invoice,
    InvoicePrintOptions options,
    PdfColor invoiceColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(invoiceColor.toInt()).shade(0.9),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: invoiceColor, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // معلومات الفاتورة
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _getInvoiceTypeLabel(invoice.invoiceType),
                style: pw.TextStyle(
                  font: _arabicFontBold,
                  fontSize: 24,
                  color: invoiceColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'رقم: ${invoice.invoiceNumber}',
                style: pw.TextStyle(font: _arabicFont, fontSize: 12),
              ),
              pw.Text(
                'التاريخ: ${ExportFormatters.formatDateTime(invoice.date)}',
                style: pw.TextStyle(font: _arabicFont, fontSize: 12),
              ),
            ],
          ),
          // الشعار أو اسم الشركة
          if (options.companyName != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  options.companyName!,
                  style: pw.TextStyle(font: _arabicFontBold, fontSize: 18),
                ),
                if (options.companyPhone != null)
                  pw.Text(
                    options.companyPhone!,
                    style: pw.TextStyle(font: _arabicFont, fontSize: 10),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfoBox(InvoiceData invoice, PdfColor invoiceColor) {
    final isSupplier = invoice.invoiceType == 'purchase' ||
        invoice.invoiceType == 'purchaseReturn';
    final label = isSupplier ? 'المورد' : 'العميل';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$label: ${invoice.customerName}',
                  style: pw.TextStyle(font: _arabicFontBold, fontSize: 12),
                ),
                if (invoice.customerPhone != null)
                  pw.Text(
                    'الهاتف: ${invoice.customerPhone}',
                    style: pw.TextStyle(font: _arabicFont, fontSize: 10),
                  ),
                if (invoice.customerAddress != null)
                  pw.Text(
                    'العنوان: ${invoice.customerAddress}',
                    style: pw.TextStyle(font: _arabicFont, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildA4ItemsTable(InvoiceData invoice, PdfColor invoiceColor) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6), // #
        1: const pw.FlexColumnWidth(3), // الصنف
        2: const pw.FlexColumnWidth(1), // الكمية
        3: const pw.FlexColumnWidth(1), // الوحدة
        4: const pw.FlexColumnWidth(1.2), // السعر
        5: const pw.FlexColumnWidth(1), // الخصم
        6: const pw.FlexColumnWidth(1.2), // الإجمالي
      },
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: pw.BoxDecoration(color: invoiceColor),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('الصنف'),
            _tableHeaderCell('الكمية'),
            _tableHeaderCell('الوحدة'),
            _tableHeaderCell('السعر'),
            _tableHeaderCell('الخصم'),
            _tableHeaderCell('الإجمالي'),
          ],
        ),
        // بيانات العناصر
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _tableDataCell('${index + 1}'),
              _tableDataCell(item.name, align: pw.TextAlign.right),
              _tableDataCell(ExportFormatters.formatQuantity(item.quantity)),
              _tableDataCell(item.unit),
              _tableDataCell(ExportFormatters.formatPrice(item.unitPrice,
                  showCurrency: false)),
              _tableDataCell(ExportFormatters.formatPrice(item.discount,
                  showCurrency: false)),
              _tableDataCell(
                  ExportFormatters.formatPrice(item.total, showCurrency: false),
                  bold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _arabicFontBold,
          fontSize: 10,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? _arabicFontBold : _arabicFont,
          fontSize: 9,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildA4Summary(
    InvoiceData invoice,
    InvoicePrintOptions options,
    PdfColor invoiceColor,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // طريقة الدفع
        if (options.showPaymentMethod && invoice.paymentMethod != null)
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'طريقة الدفع',
                    style: pw.TextStyle(font: _arabicFontBold, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ExportFormatters.getPaymentMethodLabel(
                        invoice.paymentMethod!),
                    style: pw.TextStyle(font: _arabicFont, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        if (options.showPaymentMethod && invoice.paymentMethod != null)
          pw.SizedBox(width: 16),

        // ملخص المبالغ
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: invoiceColor, width: 2),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              _summaryRow('المجموع الفرعي', invoice.subtotal),
              if (invoice.discount > 0)
                _summaryRow('الخصم', invoice.discount, isNegative: true),
              if (options.showTaxDetails && invoice.tax > 0)
                _summaryRow('الضريبة', invoice.tax),
              pw.Divider(color: invoiceColor),
              _summaryRow('الإجمالي', invoice.total,
                  isTotal: true, color: invoiceColor),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryRow(
    String label,
    double value, {
    bool isNegative = false,
    bool isTotal = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isTotal ? _arabicFontBold : _arabicFont,
              fontSize: isTotal ? 12 : 10,
            ),
          ),
          pw.Text(
            '${isNegative ? "-" : ""}${ExportFormatters.formatPrice(value)}',
            style: pw.TextStyle(
              font: isTotal ? _arabicFontBold : _arabicFont,
              fontSize: isTotal ? 14 : 10,
              color: color ?? (isNegative ? PdfColors.red : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotesBox(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.amber200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملاحظات: ',
            style: pw.TextStyle(font: _arabicFontBold, fontSize: 10),
          ),
          pw.Expanded(
            child: pw.Text(
              notes,
              style: pw.TextStyle(font: _arabicFont, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildA4Footer(InvoiceData invoice, InvoicePrintOptions options) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (invoice.createdBy != null)
            pw.Text(
              'أنشأها: ${invoice.createdBy}',
              style: pw.TextStyle(
                  font: _arabicFont, fontSize: 9, color: PdfColors.grey600),
            ),
          pw.Text(
            'نظام حور للمبيعات',
            style: pw.TextStyle(
                font: _arabicFont, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ==================== فاتورة حرارية ====================

  pw.Page _buildThermalInvoice(
    InvoiceData invoice,
    InvoicePrintOptions options,
    int widthMm,
  ) {
    final pageWidth = widthMm * PdfPageFormat.mm;
    final invoiceColor = _getInvoiceColor(invoice.invoiceType);

    return pw.Page(
      pageFormat: PdfPageFormat(pageWidth, double.infinity),
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      theme: PdfTheme.create(),
      build: (context) {
        return pw.Column(
          children: [
            // الرأس
            _buildThermalHeader(invoice, options, invoiceColor),
            _thermalDivider(),

            // معلومات العميل
            if (options.showCustomerInfo && invoice.customerName != null) ...[
              _buildThermalCustomerInfo(invoice),
              _thermalDivider(),
            ],

            // المنتجات
            _buildThermalItems(invoice, widthMm),
            _thermalDivider(),

            // الإجماليات
            _buildThermalTotals(invoice, options),

            // طريقة الدفع
            if (options.showPaymentMethod && invoice.paymentMethod != null) ...[
              _thermalDivider(),
              _buildThermalPayment(invoice),
            ],

            _thermalDivider(),

            // التذييل
            _buildThermalFooter(options),
          ],
        );
      },
    );
  }

  pw.Widget _buildThermalHeader(
    InvoiceData invoice,
    InvoicePrintOptions options,
    PdfColor invoiceColor,
  ) {
    return pw.Column(
      children: [
        // اسم الشركة
        if (options.companyName != null)
          pw.Text(
            options.companyName!,
            style: pw.TextStyle(font: _arabicFontBold, fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),

        if (options.companyPhone != null)
          pw.Text(
            options.companyPhone!,
            style: pw.TextStyle(font: _arabicFont, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),

        pw.SizedBox(height: 8),

        // نوع الفاتورة
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: invoiceColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _getInvoiceTypeLabel(invoice.invoiceType),
            style: pw.TextStyle(
              font: _arabicFontBold,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 6),

        // رقم الفاتورة والتاريخ
        pw.Text(
          'رقم: ${invoice.invoiceNumber}',
          style: pw.TextStyle(font: _arabicFont, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          ExportFormatters.formatDateTime(invoice.date),
          style: pw.TextStyle(font: _arabicFont, fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildThermalCustomerInfo(InvoiceData invoice) {
    final isSupplier = invoice.invoiceType == 'purchase' ||
        invoice.invoiceType == 'purchaseReturn';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${isSupplier ? "المورد" : "العميل"}: ${invoice.customerName}',
          style: pw.TextStyle(font: _arabicFont, fontSize: 9),
        ),
        if (invoice.customerPhone != null)
          pw.Text(
            'الهاتف: ${invoice.customerPhone}',
            style: pw.TextStyle(font: _arabicFont, fontSize: 8),
          ),
      ],
    );
  }

  pw.Widget _buildThermalItems(InvoiceData invoice, int widthMm) {
    final fontSize = widthMm == 58 ? 7.0 : 8.0;

    return pw.Column(
      children: invoice.items.map((item) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.name,
                style: pw.TextStyle(font: _arabicFontBold, fontSize: fontSize),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${ExportFormatters.formatQuantity(item.quantity)} × ${ExportFormatters.formatPrice(item.unitPrice, showCurrency: false)}',
                    style:
                        pw.TextStyle(font: _arabicFont, fontSize: fontSize - 1),
                  ),
                  pw.Text(
                    ExportFormatters.formatPrice(item.total,
                        showCurrency: false),
                    style:
                        pw.TextStyle(font: _arabicFontBold, fontSize: fontSize),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildThermalTotals(
      InvoiceData invoice, InvoicePrintOptions options) {
    return pw.Column(
      children: [
        _thermalTotalRow('المجموع', invoice.subtotal),
        if (invoice.discount > 0)
          _thermalTotalRow('الخصم', invoice.discount, isNegative: true),
        if (options.showTaxDetails && invoice.tax > 0)
          _thermalTotalRow('الضريبة', invoice.tax),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الإجمالي',
                style: pw.TextStyle(font: _arabicFontBold, fontSize: 12),
              ),
              pw.Text(
                ExportFormatters.formatPrice(invoice.total),
                style: pw.TextStyle(font: _arabicFontBold, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _thermalTotalRow(String label, double value,
      {bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: _arabicFont, fontSize: 9),
          ),
          pw.Text(
            '${isNegative ? "-" : ""}${ExportFormatters.formatPrice(value, showCurrency: false)}',
            style: pw.TextStyle(
              font: _arabicFont,
              fontSize: 9,
              color: isNegative ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildThermalPayment(InvoiceData invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'طريقة الدفع: ${ExportFormatters.getPaymentMethodLabel(invoice.paymentMethod!)}',
          style: pw.TextStyle(font: _arabicFont, fontSize: 9),
        ),
        if (invoice.paidAmount != null)
          pw.Text(
            'المدفوع: ${ExportFormatters.formatPrice(invoice.paidAmount!)}',
            style: pw.TextStyle(font: _arabicFont, fontSize: 9),
          ),
        if (invoice.remainingAmount != null && invoice.remainingAmount! > 0)
          pw.Text(
            'المتبقي: ${ExportFormatters.formatPrice(invoice.remainingAmount!)}',
            style: pw.TextStyle(
              font: _arabicFontBold,
              fontSize: 9,
              color: PdfColors.red,
            ),
          ),
      ],
    );
  }

  pw.Widget _buildThermalFooter(InvoicePrintOptions options) {
    return pw.Column(
      children: [
        pw.Text(
          'شكراً لتعاملكم معنا',
          style: pw.TextStyle(font: _arabicFont, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'نظام حور للمبيعات',
          style: pw.TextStyle(
              font: _arabicFont, fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _thermalDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: List.generate(
          40,
          (index) => pw.Expanded(
            child: pw.Container(
              height: 1,
              color: index.isEven ? PdfColors.grey400 : PdfColors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== دوال مساعدة ====================

  PdfColor _getInvoiceColor(String invoiceType) {
    switch (invoiceType) {
      case 'sale':
        return PdfColor.fromHex('#22C55E');
      case 'purchase':
        return PdfColor.fromHex('#3B82F6');
      case 'saleReturn':
      case 'sale_return':
        return PdfColor.fromHex('#F97316');
      case 'purchaseReturn':
      case 'purchase_return':
        return PdfColor.fromHex('#EF4444');
      default:
        return PdfColor.fromHex('#6B7280');
    }
  }

  String _getInvoiceTypeLabel(String invoiceType) {
    switch (invoiceType) {
      case 'sale':
        return 'فاتورة مبيعات';
      case 'purchase':
        return 'فاتورة مشتريات';
      case 'saleReturn':
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchaseReturn':
      case 'purchase_return':
        return 'مرتجع مشتريات';
      default:
        return 'فاتورة';
    }
  }
}
