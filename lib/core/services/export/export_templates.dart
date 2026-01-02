import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../printing/pdf_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Export Templates - قوالب التصدير الموحدة
/// ═══════════════════════════════════════════════════════════════════════════

/// ألوان التصدير الموحدة
class ExportColors {
  ExportColors._();

  // ألوان PDF
  static const PdfColor primary = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor primaryLight = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor success = PdfColor.fromInt(0xFF43A047);
  static const PdfColor warning = PdfColor.fromInt(0xFFFFA000);
  static const PdfColor error = PdfColor.fromInt(0xFFE53935);
  static const PdfColor info = PdfColor.fromInt(0xFF1E88E5);

  // ألوان الجداول
  static const PdfColor tableHeader = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor tableRowEven = PdfColors.grey50;
  static const PdfColor tableRowOdd = PdfColors.white;
  static const PdfColor tableBorder = PdfColors.grey300;

  // ألوان أنواع الفواتير
  static const PdfColor sale = PdfColor.fromInt(0xFF43A047);
  static const PdfColor purchase = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor saleReturn = PdfColor.fromInt(0xFFFFA000);
  static const PdfColor purchaseReturn = PdfColor.fromInt(0xFFFF5722);

  /// الحصول على لون نوع الفاتورة
  static PdfColor getInvoiceTypeColor(String type) {
    switch (type) {
      case 'sale':
        return sale;
      case 'purchase':
        return purchase;
      case 'sale_return':
        return saleReturn;
      case 'purchase_return':
        return purchaseReturn;
      default:
        return primary;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PDF Report Template - قالب تقرير PDF الموحد
/// ═══════════════════════════════════════════════════════════════════════════
class PdfReportTemplate {
  final String title;
  final String? subtitle;
  final DateTime reportDate;
  final PdfColor headerColor;

  const PdfReportTemplate({
    required this.title,
    this.subtitle,
    required this.reportDate,
    this.headerColor = ExportColors.primary,
  });

  /// إنشاء رأس التقرير الموحد
  pw.Widget buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: PdfFonts.bold,
              fontSize: 24,
              color: PdfColors.white,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              subtitle!,
              style: pw.TextStyle(
                font: PdfFonts.regular,
                fontSize: 14,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'تاريخ التقرير: ${_formatDate(reportDate)}',
              style: pw.TextStyle(
                font: PdfFonts.regular,
                fontSize: 11,
                color: headerColor,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  /// إنشاء صندوق الإحصائيات الموحد
  pw.Widget buildStatsBox(List<StatItem> stats) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: ExportColors.tableBorder, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: stats.map((stat) => _buildStatItem(stat)).toList(),
      ),
    );
  }

  pw.Widget _buildStatItem(StatItem stat) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
        child: pw.Column(
          children: [
            pw.Text(
              stat.label,
              style: pw.TextStyle(
                font: PdfFonts.regular,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              stat.value,
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontSize: 14,
                color: stat.color ?? PdfColors.grey800,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// إنشاء جدول موحد
  pw.Widget buildTable({
    required List<String> headers,
    required List<List<String>> data,
    PdfColor? headerBgColor,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: ExportColors.tableBorder, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: headerBgColor ?? ExportColors.tableHeader,
          ),
          children: headers.map((header) {
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  font: PdfFonts.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven
                  ? ExportColors.tableRowEven
                  : ExportColors.tableRowOdd,
            ),
            children: row.map((cell) {
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(
                    font: PdfFonts.regular,
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// إنشاء فاصل بعنوان
  pw.Widget buildSectionDivider(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Divider(color: PdfColors.grey300)),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(child: pw.Divider(color: PdfColors.grey300)),
        ],
      ),
    );
  }

  /// إنشاء تذييل التقرير الموحد
  pw.Widget buildFooter({int pageNumber = 1, int totalPages = 1}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة $pageNumber من $totalPages',
            style: pw.TextStyle(
              font: PdfFonts.regular,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// عنصر إحصائي
/// ═══════════════════════════════════════════════════════════════════════════
class StatItem {
  final String label;
  final String value;
  final PdfColor? color;

  const StatItem({
    required this.label,
    required this.value,
    this.color,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Excel Export Styles - أنماط Excel الموحدة
/// ═══════════════════════════════════════════════════════════════════════════
class ExcelStyles {
  ExcelStyles._();

  // ألوان Excel (بصيغة Hex)
  static const String headerBgColor = 'FF1565C0';
  static const String headerTextColor = 'FFFFFFFF';
  static const String successColor = 'FF43A047';
  static const String warningColor = 'FFFFA000';
  static const String errorColor = 'FFE53935';
  static const String infoBgColor = 'FFE3F2FD';

  // ألوان أنواع الفواتير
  static const String saleColor = 'FF43A047';
  static const String purchaseColor = 'FF1E88E5';
  static const String saleReturnColor = 'FFFFA000';
  static const String purchaseReturnColor = 'FFFF5722';

  /// الحصول على لون نوع الفاتورة
  static String getInvoiceTypeColor(String type) {
    switch (type) {
      case 'sale':
        return saleColor;
      case 'purchase':
        return purchaseColor;
      case 'sale_return':
        return saleReturnColor;
      case 'purchase_return':
        return purchaseReturnColor;
      default:
        return headerBgColor;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Format Helpers - دوال التنسيق المساعدة
/// ═══════════════════════════════════════════════════════════════════════════
class ExportFormatters {
  ExportFormatters._();

  /// تنسيق السعر
  static String formatPrice(double price, {bool showCurrency = true}) {
    String formatted;

    if (price == price.roundToDouble()) {
      formatted = price.toStringAsFixed(0);
    } else {
      formatted = price.toStringAsFixed(2);
      // إزالة الأصفار الزائدة
      while (formatted.endsWith('0') && formatted.contains('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }

    // إضافة فواصل الآلاف
    final parts = formatted.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      if (intPart[i] == '-') {
        buffer.write(intPart[i]);
        continue;
      }
      buffer.write(intPart[i]);
      count++;
      if (count == 3 && i > 0 && intPart[i - 1] != '-') {
        buffer.write(',');
        count = 0;
      }
    }

    formatted = buffer.toString().split('').reversed.join();
    if (parts.length > 1) {
      formatted = '$formatted.${parts[1]}';
    }

    return showCurrency ? '$formatted ل.س' : formatted;
  }

  /// تنسيق التاريخ
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// تنسيق التاريخ والوقت (بنظام 12 ساعة)
  static String formatDateTime(DateTime date) {
    final hour = date.hour;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour < 12 ? 'ص' : 'م';
    return '${formatDate(date)} ${hour12.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  /// تنسيق الفترة الزمنية
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  /// الحصول على تسمية نوع الفاتورة
  static String getInvoiceTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'فاتورة مبيعات';
      case 'purchase':
        return 'فاتورة مشتريات';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      default:
        return 'فاتورة';
    }
  }

  /// الحصول على تسمية طريقة الدفع
  static String getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'card':
        return 'بطاقة';
      case 'transfer':
      case 'bank_transfer':
        return 'تحويل';
      case 'credit':
        return 'آجل';
      case 'partial':
        return 'دفع جزئي';
      default:
        return method;
    }
  }

  /// الحصول على تسمية حالة الفاتورة
  static String getInvoiceStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'معلقة';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  /// تنسيق الكمية
  static String formatQuantity(double qty) {
    if (qty == qty.truncate()) {
      return qty.truncate().toString();
    }
    return qty.toStringAsFixed(2);
  }

  /// تنسيق النسبة المئوية
  static String formatPercentage(double value) {
    if (value == value.truncate()) {
      return '${value.truncate()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}
