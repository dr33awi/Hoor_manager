// lib/core/services/utilities/barcode_service.dart
// خدمة الباركود - المسح والإنشاء

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';

/// خدمة إدارة الباركود
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  /// توليد باركود فريد للمنتج
  /// يتكون من: كود المتجر (3) + السنة (2) + الشهر (2) + رقم تسلسلي (5)
  String generateProductBarcode({String? storeCode}) {
    final code = storeCode ?? BarcodeConstants.defaultStoreCode;
    final now = DateTime.now();
    final year = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final random = Random();
    final sequence = (random.nextInt(99999) + 1).toString().padLeft(5, '0');

    return '$code$year$month$sequence';
  }

  /// توليد باركود للمتغير (اللون والمقاس)
  /// الصيغة: باركود_المنتج-كود_اللون-المقاس
  String generateVariantBarcode(String productBarcode, String color, int size) {
    final colorCode = _getColorCode(color);
    return '$productBarcode-$colorCode-$size';
  }

  /// الحصول على كود اللون
  String _getColorCode(String color) {
    if (color.isEmpty) return 'XX';

    // استخدام أكواد الألوان من الثوابت
    final code = BarcodeConstants.colorCodes[color];
    if (code != null) return code;

    // إذا لم يوجد، استخدم أول حرفين
    return color.substring(0, min(2, color.length)).toUpperCase();
  }

  /// التحقق من صحة الباركود
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;

    // باركود المنتج الأساسي: 12 حرف
    if (barcode.length == 12) {
      return RegExp(r'^[A-Z]{3}\d{9}$').hasMatch(barcode);
    }

    // باركود المتغير: باركود_المنتج-كود_اللون-المقاس
    if (barcode.contains('-')) {
      final parts = barcode.split('-');
      if (parts.length == 3) {
        return parts[0].length == 12 &&
            parts[1].length == 2 &&
            int.tryParse(parts[2]) != null;
      }
    }

    // باركود خارجي (EAN-13 أو UPC-A)
    if (barcode.length == 13 || barcode.length == 12) {
      return RegExp(r'^\d+$').hasMatch(barcode);
    }

    return true; // قبول أي باركود آخر
  }

  /// تحليل باركود المتغير
  BarcodeInfo? parseVariantBarcode(String barcode) {
    if (!barcode.contains('-')) return null;

    final parts = barcode.split('-');
    if (parts.length != 3) return null;

    return BarcodeInfo(
      productBarcode: parts[0],
      colorCode: parts[1],
      size: int.tryParse(parts[2]),
    );
  }

  /// نسخ الباركود للحافظة
  Future<void> copyToClipboard(String barcode) async {
    await Clipboard.setData(ClipboardData(text: barcode));
  }
}

/// معلومات الباركود المحللة
class BarcodeInfo {
  final String productBarcode;
  final String colorCode;
  final int? size;

  BarcodeInfo({
    required this.productBarcode,
    required this.colorCode,
    this.size,
  });
}

/// مولد صورة الباركود
class BarcodeGenerator {
  /// إنشاء باركود Code128 كـ Widget
  static Widget buildBarcode(
    String data, {
    double width = 200,
    double height = 80,
    Color color = Colors.black,
    bool showText = true,
  }) {
    return CustomPaint(
      size: Size(width, height),
      painter: BarcodePainter(data: data, color: color, showText: showText),
    );
  }
}

/// رسام الباركود
class BarcodePainter extends CustomPainter {
  final String data;
  final Color color;
  final bool showText;

  BarcodePainter({
    required this.data,
    required this.color,
    required this.showText,
  });

  // جدول Code128B
  static const Map<String, String> code128B = {
    ' ': '11011001100',
    '!': '11001101100',
    '"': '11001100110',
    '#': '10010011000',
    '\$': '10010001100',
    '%': '10001001100',
    '&': '10011001000',
    "'": '10011000100',
    '(': '10001100100',
    ')': '11001001000',
    '*': '11001000100',
    '+': '11000100100',
    ',': '10110011100',
    '-': '10011011100',
    '.': '10011001110',
    '/': '10111001100',
    '0': '10011101100',
    '1': '10011100110',
    '2': '11001110010',
    '3': '11001011100',
    '4': '11001001110',
    '5': '11011100100',
    '6': '11001110100',
    '7': '11101101110',
    '8': '11101001100',
    '9': '11100101100',
    ':': '11100100110',
    ';': '11101100100',
    '<': '11100110100',
    '=': '11100110010',
    '>': '11011011000',
    '?': '11011000110',
    '@': '11000110110',
    'A': '10100011000',
    'B': '10001011000',
    'C': '10001000110',
    'D': '10110001000',
    'E': '10001101000',
    'F': '10001100010',
    'G': '11010001000',
    'H': '11000101000',
    'I': '11000100010',
    'J': '10110111000',
    'K': '10110001110',
    'L': '10001101110',
    'M': '10111011000',
    'N': '10111000110',
    'O': '10001110110',
    'P': '11101110110',
    'Q': '11010001110',
    'R': '11000101110',
    'S': '11011101000',
    'T': '11011100010',
    'U': '11011101110',
    'V': '11101011000',
    'W': '11101000110',
    'X': '11100010110',
    'Y': '11101101000',
    'Z': '11101100010',
  };

  static const String startB = '11010010000';
  static const String stop = '1100011101011';

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // بناء سلسلة الباركود
    String barcodePattern = startB;
    for (int i = 0; i < data.length; i++) {
      final char = data[i].toUpperCase();
      barcodePattern += code128B[char] ?? code128B['?']!;
    }
    barcodePattern += stop;

    // حساب عرض كل شريط
    final barcodeHeight = showText ? size.height * 0.75 : size.height;
    final barWidth = size.width / barcodePattern.length;

    // رسم الأشرطة
    double x = 0;
    for (int i = 0; i < barcodePattern.length; i++) {
      if (barcodePattern[i] == '1') {
        canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, barcodeHeight), paint);
      }
      x += barWidth;
    }

    // رسم النص
    if (showText) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: data,
          style: TextStyle(
            color: color,
            fontSize: size.height * 0.15,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, barcodeHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
