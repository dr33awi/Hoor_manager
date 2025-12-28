import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// خدمة طباعة الباركود
class BarcodePrintService {
  static final BarcodePrintService _instance = BarcodePrintService._internal();
  factory BarcodePrintService() => _instance;
  BarcodePrintService._internal();

  /// طباعة باركود واحد
  static Future<void> printBarcode({
    required String barcode,
    double? price,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          50 * PdfPageFormat.mm,
          30 * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (context) => _buildBarcodeLabel(
          barcode: barcode,
          price: price,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'باركود_$barcode',
    );
  }

  /// طباعة عدة باركودات في صفحة واحدة
  static Future<void> printMultipleBarcodes({
    required List<BarcodeItem> items,
    BarcodeLayout layout = BarcodeLayout.threeColumns,
  }) async {
    final pdf = pw.Document();

    final labelsPerPage = layout.columns * layout.rows;
    final pages = (items.length / labelsPerPage).ceil();

    for (int page = 0; page < pages; page++) {
      final startIndex = page * labelsPerPage;
      final endIndex = (startIndex + labelsPerPage).clamp(0, items.length);
      final pageItems = items.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) => _buildMultiBarcodePage(
            items: pageItems,
            layout: layout,
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'باركودات_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// معاينة الباركود قبل الطباعة
  static Future<void> previewBarcode({
    required BuildContext context,
    required String barcode,
    double? price,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => BarcodePrintPreviewDialog(
        barcode: barcode,
        price: price,
      ),
    );
  }

  /// بناء ملصق باركود واحد
  static pw.Widget _buildBarcodeLabel({
    required String barcode,
    double? price,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // الباركود
          pw.BarcodeWidget(
            barcode: _getBarcodeType(barcode),
            data: barcode,
            width: 40 * PdfPageFormat.mm,
            height: 15 * PdfPageFormat.mm,
            drawText: true,
            textStyle: const pw.TextStyle(fontSize: 9),
          ),

          // السعر (إن وجد)
          if (price != null) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              '${price.toStringAsFixed(2)} ر.س',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء صفحة متعددة الباركودات
  static pw.Widget _buildMultiBarcodePage({
    required List<BarcodeItem> items,
    required BarcodeLayout layout,
  }) {
    final rows = <pw.TableRow>[];

    for (int row = 0; row < layout.rows; row++) {
      final cells = <pw.Widget>[];

      for (int col = 0; col < layout.columns; col++) {
        final index = row * layout.columns + col;

        if (index < items.length) {
          final item = items[index];
          cells.add(
            pw.Container(
              width: layout.labelWidth * PdfPageFormat.mm,
              height: layout.labelHeight * PdfPageFormat.mm,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: _getBarcodeType(item.barcode),
                    data: item.barcode,
                    width: (layout.labelWidth - 10) * PdfPageFormat.mm,
                    height: (layout.labelHeight - 12) * PdfPageFormat.mm,
                    drawText: true,
                    textStyle: pw.TextStyle(fontSize: layout.fontSize - 1),
                  ),
                  if (item.price != null) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '${item.price!.toStringAsFixed(2)} ر.س',
                      style: pw.TextStyle(
                        fontSize: layout.fontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        } else {
          cells.add(pw.Container(
            width: layout.labelWidth * PdfPageFormat.mm,
            height: layout.labelHeight * PdfPageFormat.mm,
          ));
        }
      }

      rows.add(pw.TableRow(children: cells));
    }

    return pw.Table(children: rows);
  }

  /// تحديد نوع الباركود
  static pw.Barcode _getBarcodeType(String barcode) {
    if (barcode.length == 13 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return pw.Barcode.ean13();
    } else if (barcode.length == 8 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return pw.Barcode.ean8();
    } else if (barcode.length == 12 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return pw.Barcode.upcA();
    } else {
      return pw.Barcode.code128();
    }
  }
}

/// عنصر باركود للطباعة
class BarcodeItem {
  final String barcode;
  final String productName;
  final double? price;
  final String? color;
  final String? size;
  final int quantity;

  const BarcodeItem({
    required this.barcode,
    required this.productName,
    this.price,
    this.color,
    this.size,
    this.quantity = 1,
  });
}

/// تخطيطات طباعة الباركود
enum BarcodeLayout {
  /// 3 أعمدة × 10 صفوف (30 ملصق)
  threeColumns(3, 10, 65, 27, 7),

  /// 2 عمود × 7 صفوف (14 ملصق)
  twoColumns(2, 7, 95, 38, 9),

  /// 4 أعمدة × 12 صف (48 ملصق صغير)
  fourColumns(4, 12, 48, 22, 6),

  /// ملصق واحد كبير
  single(1, 1, 190, 80, 12);

  final int columns;
  final int rows;
  final double labelWidth;
  final double labelHeight;
  final double fontSize;

  const BarcodeLayout(
    this.columns,
    this.rows,
    this.labelWidth,
    this.labelHeight,
    this.fontSize,
  );

  String get displayName {
    switch (this) {
      case BarcodeLayout.threeColumns:
        return '3 أعمدة (30 ملصق)';
      case BarcodeLayout.twoColumns:
        return '2 عمود (14 ملصق)';
      case BarcodeLayout.fourColumns:
        return '4 أعمدة (48 ملصق)';
      case BarcodeLayout.single:
        return 'ملصق واحد كبير';
    }
  }
}

/// نافذة معاينة الباركود قبل الطباعة
class BarcodePrintPreviewDialog extends StatefulWidget {
  final String barcode;
  final double? price;

  const BarcodePrintPreviewDialog({
    super.key,
    required this.barcode,
    this.price,
  });

  @override
  State<BarcodePrintPreviewDialog> createState() =>
      _BarcodePrintPreviewDialogState();
}

class _BarcodePrintPreviewDialogState extends State<BarcodePrintPreviewDialog> {
  bool _showPrice = true;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print, color: Colors.blue),
          SizedBox(width: 8),
          Text('طباعة الباركود'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // معاينة الباركود
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // محاكاة شكل الباركود
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            20,
                            (i) => Container(
                              width: i % 3 == 0 ? 3 : 2,
                              height: 50,
                              color: i % 2 == 0 ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.barcode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showPrice && widget.price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${widget.price!.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // خيار عرض السعر
            if (widget.price != null)
              SwitchListTile(
                title: const Text('إظهار السعر'),
                value: _showPrice,
                onChanged: (v) => setState(() => _showPrice = v),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : _print,
          icon: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print),
          label: Text(_isPrinting ? 'جاري...' : 'طباعة'),
        ),
      ],
    );
  }

  Future<void> _print() async {
    setState(() => _isPrinting = true);

    try {
      await BarcodePrintService.printBarcode(
        barcode: widget.barcode,
        price: _showPrice ? widget.price : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الطباعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}

/// نافذة طباعة متعددة للباركودات
class MultiBarcodesPrintDialog extends StatefulWidget {
  final List<BarcodeItem> items;

  const MultiBarcodesPrintDialog({
    super.key,
    required this.items,
  });

  @override
  State<MultiBarcodesPrintDialog> createState() =>
      _MultiBarcodesPrintDialogState();
}

class _MultiBarcodesPrintDialogState extends State<MultiBarcodesPrintDialog> {
  BarcodeLayout _selectedLayout = BarcodeLayout.threeColumns;
  bool _isPrinting = false;

  int get _totalLabels {
    return widget.items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print, color: Colors.blue),
          SizedBox(width: 8),
          Text('طباعة الباركودات'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ملخص
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم طباعة $_totalLabels ملصق لـ ${widget.items.length} منتج',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // اختيار التخطيط
            const Text(
              'تخطيط الصفحة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...BarcodeLayout.values.map((layout) {
              return RadioListTile<BarcodeLayout>(
                title: Text(layout.displayName),
                subtitle: Text(
                  '${layout.labelWidth.toInt()}×${layout.labelHeight.toInt()} مم',
                ),
                value: layout,
                groupValue: _selectedLayout,
                onChanged: (v) => setState(() => _selectedLayout = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            const SizedBox(height: 8),

            // عدد الصفحات المتوقع
            Text(
              'عدد الصفحات: ${(_totalLabels / (_selectedLayout.columns * _selectedLayout.rows)).ceil()}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : _print,
          icon: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print),
          label: Text(_isPrinting ? 'جاري...' : 'طباعة'),
        ),
      ],
    );
  }

  Future<void> _print() async {
    setState(() => _isPrinting = true);

    try {
      // توسيع العناصر حسب الكمية
      final expandedItems = <BarcodeItem>[];
      for (final item in widget.items) {
        for (int i = 0; i < item.quantity; i++) {
          expandedItems.add(item);
        }
      }

      await BarcodePrintService.printMultipleBarcodes(
        items: expandedItems,
        layout: _selectedLayout,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الطباعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}
