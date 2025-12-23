// lib/core/services/utilities/print_service.dart
// خدمة الطباعة - للباركود والفواتير

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../theme/app_theme.dart';

/// خدمة الطباعة
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// تحويل Widget إلى صورة
  Future<Uint8List?> widgetToImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error converting widget to image: $e');
      return null;
    }
  }
}

/// ويدجت ملصق الباركود للطباعة
class BarcodeLabelWidget extends StatelessWidget {
  final String barcode;
  final String productName;
  final String variant; // اللون والمقاس
  final double price;
  final GlobalKey repaintKey;

  const BarcodeLabelWidget({
    super.key,
    required this.barcode,
    required this.productName,
    required this.variant,
    required this.price,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اسم المنتج
            Text(
              productName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // اللون والمقاس
            Text(
              variant,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),

            // الباركود
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: CustomPaint(
                painter: SimpleBarcodePatinterForLabel(barcode),
              ),
            ),
            const SizedBox(height: 4),

            // رقم الباركود
            Text(
              barcode,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),

            // السعر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${price.toStringAsFixed(0)} ر.س',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسام باركود بسيط للملصقات
class SimpleBarcodePatinterForLabel extends CustomPainter {
  final String data;

  SimpleBarcodePatinterForLabel(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // رسم أشرطة بسيطة بناءً على البيانات
    final barWidth = size.width / (data.length * 3 + 10);
    double x = barWidth * 2;

    // شريط البداية
    canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
    x += barWidth * 2;
    canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
    x += barWidth * 2;

    // رسم الأشرطة بناءً على الأحرف
    for (int i = 0; i < data.length; i++) {
      final charCode = data.codeUnitAt(i);

      // رسم نمط بناءً على كود الحرف
      for (int j = 0; j < 3; j++) {
        if ((charCode >> j) & 1 == 1) {
          canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
        }
        x += barWidth;
      }
      x += barWidth * 0.5;
    }

    // شريط النهاية
    x = size.width - barWidth * 4;
    canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
    x += barWidth * 2;
    canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ويدجت الفاتورة للطباعة
class InvoicePrintWidget extends StatelessWidget {
  final String invoiceNumber;
  final DateTime date;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? notes;
  final GlobalKey repaintKey;

  const InvoicePrintWidget({
    super.key,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.notes,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الشعار والعنوان
            const Text(
              '🥾 متجر الأحذية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'فاتورة مبيعات',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // خط فاصل
            Divider(color: Colors.grey.shade300, thickness: 1),

            // معلومات الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'رقم الفاتورة:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  invoiceNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التاريخ:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(_formatDate(date), style: const TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, thickness: 1),

            // عناوين الجدول
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'المنتج',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'الكمية',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'السعر',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade200),

            // المنتجات
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.variant,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.total.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, thickness: 1),

            // المجموع
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المجموع الفرعي:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '${subtotal.toStringAsFixed(0)} ر.س',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الخصم:',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
                  Text(
                    '- ${discount.toStringAsFixed(0)} ر.س',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} ر.س',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ملاحظات: $notes',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),

            // رسالة الشكر
            const Text(
              'شكراً لتسوقكم معنا',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'البضاعة المباعة لا ترد ولا تستبدل',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// عنصر في الفاتورة
class InvoiceItem {
  final String name;
  final String variant;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.name,
    required this.variant,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}
