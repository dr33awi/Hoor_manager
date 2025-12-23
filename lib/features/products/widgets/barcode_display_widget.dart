// lib/core/widgets/barcode_display_widget.dart
// ✅ ويدجت عرض الباركود الحقيقي

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

/// ويدجت عرض الباركود بأنواع مختلفة
class BarcodeDisplayWidget extends StatelessWidget {
  final String data;
  final BarcodeType type;
  final double width;
  final double height;
  final bool showText;
  final Color color;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const BarcodeDisplayWidget({
    super.key,
    required this.data,
    this.type = BarcodeType.Code128,
    this.width = 200,
    this.height = 80,
    this.showText = true,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarcodeWidget(
        barcode: _getBarcodeType(),
        data: data,
        width: width - 16,
        height: showText ? height - 32 : height - 16,
        drawText: showText,
        style:
            textStyle ??
            const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
        color: color,
        backgroundColor: backgroundColor,
        errorBuilder: (context, error) => Center(
          child: Text(
            'باركود غير صالح',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Barcode _getBarcodeType() {
    switch (type) {
      case BarcodeType.Code128:
        return Barcode.code128();
      case BarcodeType.Code39:
        return Barcode.code39();
      case BarcodeType.Code93:
        return Barcode.code93();
      case BarcodeType.EAN13:
        return Barcode.ean13();
      case BarcodeType.EAN8:
        return Barcode.ean8();
      case BarcodeType.UPCA:
        return Barcode.upcA();
      case BarcodeType.UPCE:
        return Barcode.upcE();
      case BarcodeType.QRCode:
        return Barcode.qrCode();
      case BarcodeType.DataMatrix:
        return Barcode.dataMatrix();
      case BarcodeType.PDF417:
        return Barcode.pdf417();
      case BarcodeType.Codabar:
        return Barcode.codabar();
      default:
        return Barcode.code128();
    }
  }
}

/// أنواع الباركود المدعومة
enum BarcodeType {
  Code128,
  Code39,
  Code93,
  EAN13,
  EAN8,
  UPCA,
  UPCE,
  QRCode,
  DataMatrix,
  PDF417,
  Codabar,
}

/// معاينة الباركود بحجم كبير
class BarcodePreviewDialog extends StatelessWidget {
  final String barcode;
  final String productName;
  final String? variant;
  final double? price;

  const BarcodePreviewDialog({
    super.key,
    required this.barcode,
    required this.productName,
    this.variant,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'معاينة الباركود',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // معلومات المنتج
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (variant != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      variant!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${price!.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // الباركود
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  BarcodeDisplayWidget(
                    data: barcode,
                    width: 280,
                    height: 100,
                    showText: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    barcode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // نسخ الباركود
                      // Clipboard.setData(ClipboardData(text: barcode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الباركود')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // طباعة الباركود
                      Navigator.pop(context);
                      // افتح نافذة الطباعة
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('طباعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت ملصق الباركود الصغير (للمنتجات)
class CompactBarcodeLabel extends StatelessWidget {
  final String barcode;
  final String productName;
  final double price;
  final VoidCallback? onTap;

  const CompactBarcodeLabel({
    super.key,
    required this.barcode,
    required this.productName,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الباركود
            BarcodeDisplayWidget(
              data: barcode,
              width: 160,
              height: 60,
              showText: false,
            ),

            const SizedBox(height: 8),

            // اسم المنتج
            Text(
              productName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // السعر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${price.toStringAsFixed(0)} ر.س',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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
