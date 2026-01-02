import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../di/injection.dart';
import 'pdf_theme.dart';
import '../currency_service.dart';
import '../export/export_templates.dart';
import 'print_settings_service.dart';

/// أحجام الطباعة المدعومة للسندات
enum VoucherPrintSize {
  a4, // سند A4 كامل
  thermal80mm, // طابعة حرارية 80mm
  thermal58mm, // طابعة حرارية 58mm
}

/// خيارات طباعة السند
class VoucherPrintOptions {
  final VoucherPrintSize size;
  final bool showLogo;
  final bool showExchangeRate;
  final Uint8List? logoBytes;
  final String? companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyTaxNumber;
  final String? footerMessage;

  const VoucherPrintOptions({
    this.size = VoucherPrintSize.a4,
    this.showLogo = true,
    this.showExchangeRate = true,
    this.logoBytes,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyTaxNumber,
    this.footerMessage,
  });

  VoucherPrintOptions copyWith({
    VoucherPrintSize? size,
    bool? showLogo,
    bool? showExchangeRate,
    Uint8List? logoBytes,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyTaxNumber,
    String? footerMessage,
  }) {
    return VoucherPrintOptions(
      size: size ?? this.size,
      showLogo: showLogo ?? this.showLogo,
      showExchangeRate: showExchangeRate ?? this.showExchangeRate,
      logoBytes: logoBytes ?? this.logoBytes,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyTaxNumber: companyTaxNumber ?? this.companyTaxNumber,
      footerMessage: footerMessage ?? this.footerMessage,
    );
  }
}

/// أنواع السندات
enum VoucherPrintType {
  receipt, // سند قبض
  payment, // سند دفع
  expense, // سند مصاريف
}

extension VoucherPrintTypeExtension on VoucherPrintType {
  String get arabicName {
    switch (this) {
      case VoucherPrintType.receipt:
        return 'سند قبض';
      case VoucherPrintType.payment:
        return 'سند دفع';
      case VoucherPrintType.expense:
        return 'سند مصاريف';
    }
  }

  String get englishName {
    switch (this) {
      case VoucherPrintType.receipt:
        return 'Receipt Voucher';
      case VoucherPrintType.payment:
        return 'Payment Voucher';
      case VoucherPrintType.expense:
        return 'Expense Voucher';
    }
  }

  PdfColor get color {
    switch (this) {
      case VoucherPrintType.receipt:
        return PdfColors.green;
      case VoucherPrintType.payment:
        return PdfColors.blue;
      case VoucherPrintType.expense:
        return PdfColors.orange;
    }
  }

  static VoucherPrintType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'receipt':
        return VoucherPrintType.receipt;
      case 'payment':
        return VoucherPrintType.payment;
      case 'expense':
        return VoucherPrintType.expense;
      default:
        return VoucherPrintType.expense;
    }
  }
}

/// بيانات السند للطباعة
class VoucherPrintData {
  final String voucherNumber;
  final String type; // receipt, payment, expense
  final DateTime date;
  final double amount;
  final double exchangeRate;
  final String? customerName;
  final String? supplierName;
  final String? description;
  final String? createdBy;

  const VoucherPrintData({
    required this.voucherNumber,
    required this.type,
    required this.date,
    required this.amount,
    required this.exchangeRate,
    this.customerName,
    this.supplierName,
    this.description,
    this.createdBy,
  });
}

/// مولد PDF للسندات
class VoucherPdfGenerator {
  /// تحميل الخطوط العربية
  static Future<void> _loadFonts() async {
    await PdfFonts.init();
  }

  /// إنشاء PDF للسند
  static Future<Uint8List> generateVoucherPdf(
    VoucherPrintData data, {
    VoucherPrintOptions options = const VoucherPrintOptions(),
  }) async {
    await _loadFonts();

    switch (options.size) {
      case VoucherPrintSize.a4:
        return _generateA4Voucher(data, options);
      case VoucherPrintSize.thermal80mm:
        return _generateThermalVoucher(data, options, 80);
      case VoucherPrintSize.thermal58mm:
        return _generateThermalVoucher(data, options, 58);
    }
  }

  /// إنشاء سند A4
  static Future<Uint8List> _generateA4Voucher(
    VoucherPrintData data,
    VoucherPrintOptions options,
  ) async {
    final pdf = pw.Document();
    final voucherType = VoucherPrintTypeExtension.fromString(data.type);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        theme: PdfTheme.create(),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ═══════════════ الرأس ═══════════════
                _buildSimpleHeader(data, options, voucherType),
                pw.SizedBox(height: 20),

                // ═══════════════ معلومات الشركة والطرف الآخر ═══════════════
                _buildCompanyAndPartyRow(data, options, voucherType),
                pw.SizedBox(height: 16),

                // ═══════════════ قسم المبلغ ═══════════════
                _buildSimpleAmountSection(data, options, voucherType),
                pw.SizedBox(height: 16),

                // ═══════════════ تفاصيل السند ═══════════════
                if (data.description != null && data.description!.isNotEmpty)
                  _buildSimpleDetailsBox(data, voucherType),

                pw.Spacer(),

                // ═══════════════ التذييل ═══════════════
                _buildSimpleFooter(options),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// رأس السند البسيط (مثل قالب الفاتورة)
  static pw.Widget _buildSimpleHeader(
    VoucherPrintData data,
    VoucherPrintOptions options,
    VoucherPrintType voucherType,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: voucherType.color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // نوع السند
          pw.Text(
            voucherType.arabicName,
            style: pw.TextStyle(
              font: PdfFonts.bold,
              fontSize: 22,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          // رقم السند والتاريخ
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(
                  'رقم: ${data.voucherNumber}',
                  style: pw.TextStyle(
                    font: PdfFonts.bold,
                    fontSize: 11,
                    color: voucherType.color,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(
                  ExportFormatters.formatDateTime(data.date),
                  style: pw.TextStyle(
                    font: PdfFonts.regular,
                    fontSize: 10,
                    color: voucherType.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// صف معلومات الشركة والطرف الآخر
  static pw.Widget _buildCompanyAndPartyRow(
    VoucherPrintData data,
    VoucherPrintOptions options,
    VoucherPrintType voucherType,
  ) {
    final hasCompanyInfo = options.companyName != null ||
        options.companyAddress != null ||
        options.companyPhone != null;

    final hasPartyInfo = data.customerName != null || data.supplierName != null;

    if (!hasCompanyInfo && !hasPartyInfo) {
      return pw.SizedBox.shrink();
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // صندوق معلومات الطرف الآخر (يمين)
        if (hasPartyInfo)
          pw.Expanded(
            child: _buildPartyInfoBox(data, voucherType),
          ),
        if (hasPartyInfo && hasCompanyInfo) pw.SizedBox(width: 12),
        // صندوق معلومات الشركة (يسار)
        if (hasCompanyInfo)
          pw.Expanded(
            child: _buildCompanyInfoBox(options),
          ),
      ],
    );
  }

  /// صندوق معلومات الشركة
  static pw.Widget _buildCompanyInfoBox(VoucherPrintOptions options) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 50,
            decoration: pw.BoxDecoration(
              color: ExportColors.primary,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (options.companyName != null)
                  pw.Text(
                    options.companyName!,
                    style: pw.TextStyle(font: PdfFonts.bold, fontSize: 12),
                  ),
                if (options.companyAddress != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    options.companyAddress!,
                    style: pw.TextStyle(
                        font: PdfFonts.regular,
                        fontSize: 9,
                        color: PdfColors.grey700),
                  ),
                ],
                if (options.companyPhone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'هاتف: ${options.companyPhone}',
                    style: pw.TextStyle(
                        font: PdfFonts.regular,
                        fontSize: 9,
                        color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// صندوق معلومات الطرف الآخر (العميل/المورد) - مثل نمط الفاتورة
  static pw.Widget _buildPartyInfoBox(
    VoucherPrintData data,
    VoucherPrintType voucherType,
  ) {
    String label;
    String? name;

    switch (voucherType) {
      case VoucherPrintType.receipt:
        label = 'العميل';
        name = data.customerName;
        break;
      case VoucherPrintType.payment:
        label = 'المورد';
        name = data.supplierName ?? data.customerName;
        break;
      case VoucherPrintType.expense:
        label = 'البيان';
        name = data.description ?? 'مصاريف عامة';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 50,
            decoration: pw.BoxDecoration(
              color: voucherType.color,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$label: ${name ?? "-"}',
                  style: pw.TextStyle(font: PdfFonts.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// قسم المبلغ البسيط
  static pw.Widget _buildSimpleAmountSection(
    VoucherPrintData data,
    VoucherPrintOptions options,
    VoucherPrintType voucherType,
  ) {
    final usdAmount =
        data.exchangeRate > 0 ? data.amount / data.exchangeRate : 0.0;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // إحصائيات
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('نوع السند', voucherType.arabicName),
                _buildStatColumn(
                    'التاريخ', ExportFormatters.formatDate(data.date)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // المبلغ
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                // المبلغ الإجمالي
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(
                          font: PdfFonts.bold,
                          fontSize: 14,
                          color: voucherType.color),
                    ),
                    pw.Text(
                      '${ExportFormatters.formatPrice(data.amount, showCurrency: false)} ${CurrencyService.currencySymbol}',
                      style: pw.TextStyle(
                          font: PdfFonts.bold,
                          fontSize: 18,
                          color: voucherType.color),
                    ),
                  ],
                ),
                // سعر الصرف والمبلغ بالدولار
                if (options.showExchangeRate && data.exchangeRate > 0) ...[
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'سعر الصرف',
                        style: pw.TextStyle(
                            font: PdfFonts.regular,
                            fontSize: 10,
                            color: PdfColors.grey700),
                      ),
                      pw.Text(
                        '${ExportFormatters.formatPrice(data.exchangeRate, showCurrency: false)} ${CurrencyService.currencySymbol}/\$',
                        style: pw.TextStyle(
                            font: PdfFonts.regular,
                            fontSize: 10,
                            color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'المبلغ بالدولار',
                        style: pw.TextStyle(
                            font: PdfFonts.bold,
                            fontSize: 11,
                            color: PdfColors.blue800),
                      ),
                      pw.Text(
                        '\$${usdAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            font: PdfFonts.bold,
                            fontSize: 12,
                            color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ],
                // المنشئ
                if (data.createdBy != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'بواسطة',
                        style: pw.TextStyle(
                            font: PdfFonts.regular,
                            fontSize: 10,
                            color: PdfColors.grey700),
                      ),
                      pw.Text(
                        data.createdBy!,
                        style: pw.TextStyle(
                            font: PdfFonts.bold,
                            fontSize: 10,
                            color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatColumn(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
              font: PdfFonts.regular, fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
              font: PdfFonts.bold, fontSize: 12, color: PdfColors.grey800),
        ),
      ],
    );
  }

  /// صندوق التفاصيل/البيان
  static pw.Widget _buildSimpleDetailsBox(
    VoucherPrintData data,
    VoucherPrintType voucherType,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // الشريط الجانبي الملون
        pw.Container(
          width: 3,
          height: 60,
          color: voucherType.color,
        ),
        // المحتوى
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.amber50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'البيان',
                  style: pw.TextStyle(
                      font: PdfFonts.bold,
                      fontSize: 10,
                      color: ExportColors.warning),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.description ?? '',
                  style: pw.TextStyle(
                      font: PdfFonts.regular,
                      fontSize: 11,
                      color: PdfColors.grey800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// تذييل السند
  static pw.Widget _buildSimpleFooter(VoucherPrintOptions options) {
    final footerText = options.footerMessage;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'تم الطباعة: ${ExportFormatters.formatDateTime(DateTime.now())}',
            style: pw.TextStyle(
                font: PdfFonts.regular, fontSize: 8, color: PdfColors.grey500),
          ),
          if (footerText != null && footerText.isNotEmpty)
            pw.Text(
              footerText,
              style: pw.TextStyle(
                  font: PdfFonts.bold, fontSize: 9, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  /// إنشاء سند للطابعة الحرارية
  static Future<Uint8List> _generateThermalVoucher(
    VoucherPrintData data,
    VoucherPrintOptions options,
    int widthMm,
  ) async {
    final pdf = pw.Document();
    final voucherType = VoucherPrintTypeExtension.fromString(data.type);
    final pageWidth = widthMm * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, double.infinity),
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        theme: PdfTheme.create(),
        build: (context) {
          return pw.Column(
            children: [
              // الرأس
              _buildThermalHeader(data, options, voucherType, widthMm),
              _thermalDivider(),

              // معلومات العميل/المورد
              if (data.customerName != null || data.supplierName != null) ...[
                _buildThermalPartyInfo(data, widthMm),
                _thermalDivider(),
              ],

              // المبلغ
              _buildThermalAmount(data, options, widthMm),
              _thermalDivider(),

              // الوصف
              if (data.description != null && data.description!.isNotEmpty) ...[
                _buildThermalDescription(data, widthMm),
                _thermalDivider(),
              ],

              // التذييل
              _buildThermalFooter(options, widthMm),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildThermalHeader(
    VoucherPrintData data,
    VoucherPrintOptions options,
    VoucherPrintType voucherType,
    int widthMm,
  ) {
    final titleSize = widthMm == 58 ? 12.0 : 14.0;
    final fontSize = widthMm == 58 ? 7.0 : 8.0;

    return pw.Column(
      children: [
        // اسم الشركة
        if (options.companyName != null)
          pw.Text(
            options.companyName!,
            style: pw.TextStyle(font: PdfFonts.bold, fontSize: titleSize),
            textAlign: pw.TextAlign.center,
          ),

        // العنوان
        if (options.companyAddress != null)
          pw.Text(
            options.companyAddress!,
            style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
            textAlign: pw.TextAlign.center,
          ),

        // رقم الهاتف
        if (options.companyPhone != null)
          pw.Text(
            options.companyPhone!,
            style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
            textAlign: pw.TextAlign.center,
          ),

        // الرقم الضريبي
        if (options.companyTaxNumber != null)
          pw.Text(
            'الرقم الضريبي: ${options.companyTaxNumber}',
            style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
            textAlign: pw.TextAlign.center,
          ),

        pw.SizedBox(height: 8),

        // نوع السند
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: voucherType.color,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            voucherType.arabicName,
            style: pw.TextStyle(
              font: PdfFonts.bold,
              fontSize: widthMm == 58 ? 10.0 : 12.0,
              color: PdfColors.white,
            ),
          ),
        ),

        pw.SizedBox(height: 6),

        // رقم السند والتاريخ
        pw.Text(
          data.voucherNumber,
          style: pw.TextStyle(
              font: PdfFonts.regular, fontSize: widthMm == 58 ? 9.0 : 10.0),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          ExportFormatters.formatDateTime(data.date),
          style: pw.TextStyle(
              font: PdfFonts.regular, fontSize: widthMm == 58 ? 8.0 : 9.0),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildThermalPartyInfo(VoucherPrintData data, int widthMm) {
    final fontSize = widthMm == 58 ? 8.0 : 9.0;
    final isReceipt = data.type == 'receipt';
    final label = isReceipt
        ? 'استلمنا من'
        : (data.type == 'payment' ? 'دفعنا إلى' : 'المصروف لـ');
    final name = data.customerName ?? data.supplierName ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: $name',
          style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
        ),
      ],
    );
  }

  static pw.Widget _buildThermalAmount(
    VoucherPrintData data,
    VoucherPrintOptions options,
    int widthMm,
  ) {
    final titleSize = widthMm == 58 ? 14.0 : 16.0;
    final fontSize = widthMm == 58 ? 8.0 : 9.0;

    return pw.Column(
      children: [
        pw.Text(
          'المبلغ',
          style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              '${_formatNumber(data.amount)} ${CurrencyService.currencySymbol}',
              style: pw.TextStyle(font: PdfFonts.bold, fontSize: titleSize),
            ),
          ),
        ),
        // سعر الصرف والإجمالي بالدولار
        if (options.showExchangeRate && data.exchangeRate > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'سعر الصرف',
                style: pw.TextStyle(
                    font: PdfFonts.regular, fontSize: fontSize - 1),
              ),
              pw.Text(
                '${data.exchangeRate.toStringAsFixed(0)} ${CurrencyService.currencySymbol}/\$',
                style: pw.TextStyle(
                    font: PdfFonts.regular, fontSize: fontSize - 1),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'بالدولار',
                style: pw.TextStyle(
                  font: PdfFonts.regular,
                  fontSize: fontSize,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                '\$${(data.amount / data.exchangeRate).toStringAsFixed(2)}',
                style: pw.TextStyle(
                  font: PdfFonts.bold,
                  fontSize: fontSize + 1,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildThermalDescription(
      VoucherPrintData data, int widthMm) {
    final fontSize = widthMm == 58 ? 7.0 : 8.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'البيان:',
          style: pw.TextStyle(font: PdfFonts.bold, fontSize: fontSize),
        ),
        pw.Text(
          data.description!,
          style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
          maxLines: 3,
        ),
      ],
    );
  }

  static pw.Widget _buildThermalFooter(
      VoucherPrintOptions options, int widthMm) {
    final fontSize = widthMm == 58 ? 7.0 : 8.0;

    return pw.Column(
      children: [
        if (options.footerMessage != null &&
            options.footerMessage!.isNotEmpty) ...[
          pw.Text(
            options.footerMessage!,
            style: pw.TextStyle(font: PdfFonts.regular, fontSize: fontSize),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
        ],
      ],
    );
  }

  static pw.Widget _thermalDivider() {
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

  static String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      final formatted = number.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        buffer.write(formatted[i]);
        count++;
        if (count == 3 && i != 0) {
          buffer.write(',');
          count = 0;
        }
      }
      return buffer.toString().split('').reversed.join();
    }
    return number.toStringAsFixed(0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // وظائف الطباعة والمشاركة والحفظ
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على خيارات الطباعة من إعدادات التطبيق
  static Future<VoucherPrintOptions> _getOptionsFromSettings({
    VoucherPrintOptions? options,
  }) async {
    // إذا تم توفير خيارات بمعلومات شركة، استخدمها
    if (options != null && options.companyName != null) {
      return options;
    }

    // جلب الإعدادات من خدمة الطباعة
    try {
      final printSettingsService = getIt<PrintSettingsService>();
      final settingsOptions = await printSettingsService.getVoucherPrintOptions(
        size: options?.size,
      );

      // دمج الإعدادات المُوفرة مع إعدادات التطبيق
      return VoucherPrintOptions(
        size: options?.size ?? settingsOptions.size,
        showLogo: options?.showLogo ?? settingsOptions.showLogo,
        showExchangeRate:
            options?.showExchangeRate ?? settingsOptions.showExchangeRate,
        logoBytes: options?.logoBytes ?? settingsOptions.logoBytes,
        companyName: options?.companyName ?? settingsOptions.companyName,
        companyAddress:
            options?.companyAddress ?? settingsOptions.companyAddress,
        companyPhone: options?.companyPhone ?? settingsOptions.companyPhone,
        footerMessage: options?.footerMessage ?? settingsOptions.footerMessage,
      );
    } catch (_) {
      // في حالة خطأ، أرجع الخيارات الأصلية أو الافتراضية
      return options ?? const VoucherPrintOptions();
    }
  }

  /// طباعة السند مباشرة
  static Future<void> printVoucher(
    VoucherPrintData data, {
    VoucherPrintOptions options = const VoucherPrintOptions(),
  }) async {
    final finalOptions = await _getOptionsFromSettings(options: options);
    final pdfBytes = await generateVoucherPdf(data, options: finalOptions);

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Voucher_${data.voucherNumber}',
    );
  }

  /// معاينة السند
  static Future<void> previewVoucher(
    VoucherPrintData data, {
    VoucherPrintOptions options = const VoucherPrintOptions(),
  }) async {
    final finalOptions = await _getOptionsFromSettings(options: options);
    final pdfBytes = await generateVoucherPdf(data, options: finalOptions);

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Voucher_${data.voucherNumber}',
    );
  }

  /// مشاركة السند كـ PDF
  static Future<void> shareVoucher(
    VoucherPrintData data, {
    VoucherPrintOptions options = const VoucherPrintOptions(),
  }) async {
    final finalOptions = await _getOptionsFromSettings(options: options);
    final pdfBytes = await generateVoucherPdf(data, options: finalOptions);
    final voucherType = VoucherPrintTypeExtension.fromString(data.type);

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/${voucherType.arabicName}_${data.voucherNumber}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '${voucherType.arabicName} رقم ${data.voucherNumber}',
    );
  }

  /// حفظ السند كـ PDF
  static Future<String> saveVoucher(
    VoucherPrintData data, {
    VoucherPrintOptions options = const VoucherPrintOptions(),
    String? customPath,
  }) async {
    final finalOptions = await _getOptionsFromSettings(options: options);
    final pdfBytes = await generateVoucherPdf(data, options: finalOptions);
    final voucherType = VoucherPrintTypeExtension.fromString(data.type);

    final directory =
        customPath ?? (await getApplicationDocumentsDirectory()).path;
    final fileName =
        '${voucherType.arabicName}_${data.voucherNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '$directory/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    return filePath;
  }
}
