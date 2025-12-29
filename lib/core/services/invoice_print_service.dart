import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/database/app_database.dart';
import '../constants/invoice_types.dart';
import '../theme/pdf_theme.dart';
import '../widgets/invoice_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة طباعة الفواتير - تستخدم InvoiceTheme و InvoiceStyles الموحدة
/// ═══════════════════════════════════════════════════════════════════════════
class InvoicePrintService {
  /// طباعة الفاتورة
  static Future<void> printInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required String printSize,
    Customer? customer,
    Supplier? supplier,
    bool showBarcode = true,
    bool showLogo = true,
    bool showCustomerInfo = true,
    bool showNotes = true,
    bool showPaymentMethod = true,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      items: items,
      printSize: printSize,
      customer: customer,
      supplier: supplier,
      showBarcode: showBarcode,
      showLogo: showLogo,
      showCustomerInfo: showCustomerInfo,
      showNotes: showNotes,
      showPaymentMethod: showPaymentMethod,
    );

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  /// إنشاء PDF للفاتورة
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required String printSize,
    Customer? customer,
    Supplier? supplier,
    bool showBarcode = true,
    bool showLogo = true,
    bool showCustomerInfo = true,
    bool showNotes = true,
    bool showPaymentMethod = true,
  }) async {
    final doc = pw.Document();

    // استخدام InvoiceStyles الموحدة
    final styles = InvoiceStyles(printSize);

    // تحميل الشعار
    pw.MemoryImage? logoImage;
    if (showLogo) {
      try {
        final logoData = await rootBundle.load('assets/images/Hoor-icons.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        // الشعار غير متاح
      }
    }

    // تحديد حجم الورق
    final pageFormat = _getPageFormat(printSize);

    // الحصول على إعدادات نوع الفاتورة
    final typeConfig = InvoiceTypeConfig.fromCode(invoice.type);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        margin: pw.EdgeInsets.all(styles.margin),
        theme: PdfTheme.create(),
        build: (context) {
          if (printSize == 'A4') {
            return _buildA4Invoice(
              invoice: invoice,
              items: items,
              styles: styles,
              typeConfig: typeConfig,
              customer: customer,
              supplier: supplier,
              logoImage: logoImage,
              showBarcode: showBarcode,
              showCustomerInfo: showCustomerInfo,
              showNotes: showNotes,
              showPaymentMethod: showPaymentMethod,
            );
          } else {
            return _buildThermalInvoice(
              invoice: invoice,
              items: items,
              styles: styles,
              typeConfig: typeConfig,
              customer: customer,
              supplier: supplier,
              is58mm: printSize == '58mm',
              showBarcode: showBarcode,
              showCustomerInfo: showCustomerInfo,
              showNotes: showNotes,
              showPaymentMethod: showPaymentMethod,
            );
          }
        },
      ),
    );

    return doc.save();
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// تصميم الفاتورة للطابعات الحرارية (58mm و 80mm)
  /// ═══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildThermalInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required InvoiceStyles styles,
    required InvoiceTypeConfig typeConfig,
    Customer? customer,
    Supplier? supplier,
    required bool is58mm,
    bool showBarcode = true,
    bool showCustomerInfo = true,
    bool showNotes = true,
    bool showPaymentMethod = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ═══════════════════════════════════════════════════════════════
        // الترويسة - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.header(
          storeName: 'Hoor Manager',
          invoiceType: typeConfig.label,
          typeColor: typeConfig.pdfColor,
          styles: styles,
        ),

        pw.SizedBox(height: styles.gap),
        InvoiceTheme.dottedDivider(height: styles.divider),

        // ═══════════════════════════════════════════════════════════════
        // معلومات الفاتورة - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.invoiceInfo(
          invoiceNumber: invoice.invoiceNumber,
          date: DateFormat('dd/MM/yyyy HH:mm').format(invoice.invoiceDate),
          styles: styles,
          customerName:
              showCustomerInfo ? (customer?.name ?? supplier?.name) : null,
          paymentMethod: showPaymentMethod
              ? getPaymentMethodLabel(invoice.paymentMethod)
              : null,
        ),

        pw.SizedBox(height: styles.gap),
        InvoiceTheme.dottedDivider(height: styles.divider),
        pw.SizedBox(height: styles.gap / 2),

        // ═══════════════════════════════════════════════════════════════
        // جدول المنتجات - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.thermalItemsTable(
          items: items
              .map((item) => {
                    'name': item.productName,
                    'quantity': '${item.quantity}',
                    'price': _formatPrice(item.unitPrice),
                    'total': _formatPrice(item.total),
                  })
              .toList(),
          styles: styles,
          showQuantity: !is58mm,
        ),

        pw.SizedBox(height: styles.gap),
        InvoiceTheme.dottedDivider(height: styles.divider * 2),

        // ═══════════════════════════════════════════════════════════════
        // الإجماليات - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: styles.gap / 2),
          child: pw.Column(
            children: [
              if (invoice.discountAmount > 0) ...[
                InvoiceTheme.totalRow(
                  label: 'المجموع الفرعي',
                  value: '${_formatPrice(invoice.subtotal)} ل.س',
                  styles: styles,
                ),
                InvoiceTheme.totalRow(
                  label: 'الخصم',
                  value: '- ${_formatPrice(invoice.discountAmount)} ل.س',
                  styles: styles,
                  color: PdfColors.red700,
                ),
                pw.SizedBox(height: styles.gap / 2),
              ],

              // الإجمالي النهائي
              InvoiceTheme.totalBox(
                total: '${_formatPrice(invoice.total)} ل.س',
                styles: styles,
                color: AppPdfColors.primary,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: styles.gap),
        InvoiceTheme.dottedDivider(height: styles.divider),

        // ═══════════════════════════════════════════════════════════════
        // الباركود
        // ═══════════════════════════════════════════════════════════════
        if (showBarcode) ...[
          pw.SizedBox(height: styles.gap),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: invoice.invoiceNumber,
              width: is58mm ? 120 : 160,
              height: is58mm ? 35 : 45,
              drawText: true,
              textStyle: styles.small(),
            ),
          ),
          pw.SizedBox(height: styles.gap),
          InvoiceTheme.dottedDivider(height: styles.divider),
        ],

        // ═══════════════════════════════════════════════════════════════
        // التذييل - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.footer(
          styles: styles,
          note: showNotes && invoice.notes != null && invoice.notes!.isNotEmpty
              ? invoice.notes
              : null,
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// تصميم الفاتورة لـ A4 - باستخدام InvoiceTheme الموحد
  /// ═══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildA4Invoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required InvoiceStyles styles,
    required InvoiceTypeConfig typeConfig,
    pw.MemoryImage? logoImage,
    Customer? customer,
    Supplier? supplier,
    bool showBarcode = true,
    bool showCustomerInfo = true,
    bool showNotes = true,
    bool showPaymentMethod = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ═══════════════════════════════════════════════════════════════
        // الترويسة - باستخدام InvoiceTheme.a4Header
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.a4Header(
          storeName: 'Hoor Manager',
          subtitle: 'نظام إدارة المبيعات والمخزون',
          styles: styles,
          logo: logoImage,
          color: AppPdfColors.primary,
        ),

        pw.SizedBox(height: styles.gap * 2),

        // ═══════════════════════════════════════════════════════════════
        // نوع الفاتورة ورقمها - باستخدام InvoiceTheme.a4InvoiceBadge
        // ═══════════════════════════════════════════════════════════════
        InvoiceTheme.a4InvoiceBadge(
          invoiceType: typeConfig.label,
          invoiceNumber: invoice.invoiceNumber,
          styles: styles,
          typeColor: typeConfig.pdfColor,
        ),

        pw.SizedBox(height: styles.gap * 1.5),

        // ═══════════════════════════════════════════════════════════════
        // معلومات الفاتورة - باستخدام PdfTheme.summaryBox
        // ═══════════════════════════════════════════════════════════════
        PdfTheme.summaryBox(
          items: [
            MapEntry('التاريخ',
                DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)),
            MapEntry('الوقت', DateFormat('HH:mm').format(invoice.invoiceDate)),
            if (showPaymentMethod)
              MapEntry(
                  'طريقة الدفع', getPaymentMethodLabel(invoice.paymentMethod)),
            MapEntry(
                'الحالة', invoice.status == 'completed' ? 'مكتملة' : 'معلقة'),
          ],
          borderColor: AppPdfColors.primary,
        ),

        // ═══════════════════════════════════════════════════════════════
        // معلومات العميل/المورد - باستخدام InvoiceTheme.a4CustomerInfo
        // ═══════════════════════════════════════════════════════════════
        if (showCustomerInfo && (customer != null || supplier != null)) ...[
          pw.SizedBox(height: styles.gap),
          InvoiceTheme.a4CustomerInfo(
            title: customer != null ? 'معلومات العميل' : 'معلومات المورد',
            name: customer?.name ?? supplier?.name ?? '',
            styles: styles,
            phone: customer?.phone ?? supplier?.phone,
            address: customer?.address ?? supplier?.address,
            isCustomer: customer != null,
          ),
        ],

        pw.SizedBox(height: styles.gap * 2),

        // ═══════════════════════════════════════════════════════════════
        // جدول المنتجات - باستخدام PdfTheme
        // ═══════════════════════════════════════════════════════════════
        PdfTheme.sectionDivider('تفاصيل المنتجات'),

        PdfTheme.table(
          headers: ['#', 'اسم المنتج', 'الكمية', 'السعر', 'الإجمالي'],
          data: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return [
              '${index + 1}',
              item.productName,
              '${item.quantity}',
              _formatPrice(item.unitPrice),
              _formatPrice(item.total),
            ];
          }).toList(),
          headerColor: AppPdfColors.primary,
        ),

        pw.SizedBox(height: styles.gap * 2),

        // ═══════════════════════════════════════════════════════════════
        // قسم الإجماليات والباركود - باستخدام InvoiceTheme
        // ═══════════════════════════════════════════════════════════════
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // الباركود على اليسار
            if (showBarcode)
              pw.Expanded(
                flex: 2,
                child: InvoiceTheme.a4BarcodeBox(
                  data: invoice.invoiceNumber,
                  styles: styles,
                  useQrCode: true,
                ),
              ),

            if (showBarcode) pw.SizedBox(width: styles.gap * 2),

            // الإجماليات على اليمين
            pw.Expanded(
              flex: 3,
              child: InvoiceTheme.a4TotalsBox(
                itemCount: items.length,
                subtotal: '${_formatPrice(invoice.subtotal)} ل.س',
                total: '${_formatPrice(invoice.total)} ل.س',
                styles: styles,
                discount: invoice.discountAmount > 0
                    ? '- ${_formatPrice(invoice.discountAmount)} ل.س'
                    : null,
              ),
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════
        // الملاحظات - باستخدام InvoiceTheme.notesBox
        // ═══════════════════════════════════════════════════════════════
        if (showNotes &&
            invoice.notes != null &&
            invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: styles.gap * 2),
          InvoiceTheme.notesBox(
            notes: invoice.notes!,
            styles: styles,
          ),
        ],

        pw.Spacer(),

        // ═══════════════════════════════════════════════════════════════
        // التذييل - باستخدام PdfTheme.footer
        // ═══════════════════════════════════════════════════════════════
        PdfTheme.footer(note: 'شكراً لتعاملكم معنا'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════════════════════

  static PdfPageFormat _getPageFormat(String printSize) {
    switch (printSize) {
      case '58mm':
        return PdfPageFormat.roll57;
      case 'A4':
        return PdfPageFormat.a4;
      default:
        return PdfPageFormat.roll80;
    }
  }

  static String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    String formatted = price.toStringAsFixed(2);
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }
}
