// lib/core/services/barcode_print_service.dart
// ✅ خدمة طباعة الباركود - بسيطة وفعالة

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

/// خدمة طباعة ملصقات الباركود
class BarcodePrintService {
  static final BarcodePrintService _instance = BarcodePrintService._internal();
  factory BarcodePrintService() => _instance;
  BarcodePrintService._internal();

  /// طباعة ملصق واحد مباشرة
  Future<bool> printLabel({
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    String? storeName,
  }) async {
    try {
      final pdf = await _generateLabelPDF(
        barcode: barcode,
        productName: productName,
        variant: variant,
        price: price,
        storeName: storeName,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'label_$barcode.pdf',
      );

      return true;
    } catch (e) {
      debugPrint('خطأ في الطباعة: $e');
      return false;
    }
  }

  /// طباعة عدة نسخ
  Future<bool> printMultipleCopies({
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    required int copies,
    String? storeName,
  }) async {
    try {
      final pdf = await _generateMultipleLabelsPDF(
        barcode: barcode,
        productName: productName,
        variant: variant,
        price: price,
        copies: copies,
        storeName: storeName,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'labels_${copies}x_$barcode.pdf',
      );

      return true;
    } catch (e) {
      debugPrint('خطأ في الطباعة: $e');
      return false;
    }
  }

  /// معاينة قبل الطباعة
  Future<void> previewAndPrint({
    required BuildContext context,
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    int copies = 1,
    String? storeName,
  }) async {
    final pdf = await _generateMultipleLabelsPDF(
      barcode: barcode,
      productName: productName,
      variant: variant,
      price: price,
      copies: copies,
      storeName: storeName,
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'preview_$barcode.pdf',
    );
  }

  /// توليد PDF لملصق واحد
  Future<pw.Document> _generateLabelPDF({
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    String? storeName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => _buildLabelContent(
          barcode: barcode,
          productName: productName,
          variant: variant,
          price: price,
          storeName: storeName,
        ),
      ),
    );

    return pdf;
  }

  /// توليد PDF لعدة نسخ
  Future<pw.Document> _generateMultipleLabelsPDF({
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    required int copies,
    String? storeName,
  }) async {
    final pdf = pw.Document();

    for (int i = 0; i < copies; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (context) => _buildLabelContent(
            barcode: barcode,
            productName: productName,
            variant: variant,
            price: price,
            storeName: storeName,
          ),
        ),
      );
    }

    return pdf;
  }

  /// بناء محتوى الملصق - باركود فقط
  pw.Widget _buildLabelContent({
    required String barcode,
    required String productName,
    required String variant,
    required double price,
    String? storeName,
  }) {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.BarcodeWidget(
          barcode: pw.Barcode.code128(),
          data: barcode,
          width: 200,
          height: 80,
          drawText: true,
          textStyle: const pw.TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
