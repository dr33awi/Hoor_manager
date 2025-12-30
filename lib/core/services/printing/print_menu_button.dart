import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'invoice_pdf_generator.dart';

/// أنواع الطباعة المتاحة
enum PrintType {
  /// طباعة مباشرة
  print,

  /// مشاركة PDF
  share,

  /// حفظ PDF
  save,

  /// معاينة PDF
  preview,
}

/// أحجام الطباعة المتاحة
enum PrintSize {
  /// A4 كامل
  a4,

  /// طابعة حرارية 80mm
  thermal80mm,

  /// طابعة حرارية 58mm
  thermal58mm,
}

/// تحويل PrintSize إلى InvoicePrintSize
extension PrintSizeExtension on PrintSize {
  InvoicePrintSize toInvoicePrintSize() {
    switch (this) {
      case PrintSize.a4:
        return InvoicePrintSize.a4;
      case PrintSize.thermal80mm:
        return InvoicePrintSize.thermal80mm;
      case PrintSize.thermal58mm:
        return InvoicePrintSize.thermal58mm;
    }
  }

  String get label {
    switch (this) {
      case PrintSize.a4:
        return 'A4';
      case PrintSize.thermal80mm:
        return '80mm حراري';
      case PrintSize.thermal58mm:
        return '58mm حراري';
    }
  }

  IconData get icon {
    switch (this) {
      case PrintSize.a4:
        return Icons.description;
      case PrintSize.thermal80mm:
      case PrintSize.thermal58mm:
        return Icons.receipt_long;
    }
  }
}

/// زر الطباعة الموحد
/// يعرض قائمة بخيارات الطباعة المختلفة
class PrintMenuButton extends StatelessWidget {
  const PrintMenuButton({
    super.key,
    required this.onPrint,
    this.enabledOptions = const {
      PrintType.print,
      PrintType.share,
      PrintType.save,
    },
    this.showSizeSelector = false,
    this.currentSize = PrintSize.a4,
    this.onSizeChanged,
    this.isLoading = false,
    this.icon,
    this.iconSize,
    this.tooltip,
    this.color,
  });

  /// Callback عند اختيار نوع الطباعة
  final void Function(PrintType type) onPrint;

  /// الخيارات المفعلة
  final Set<PrintType> enabledOptions;

  /// إظهار خيارات حجم الطباعة
  final bool showSizeSelector;

  /// الحجم الحالي
  final PrintSize currentSize;

  /// Callback عند تغيير الحجم
  final void Function(PrintSize size)? onSizeChanged;

  /// حالة التحميل
  final bool isLoading;

  /// أيقونة مخصصة
  final IconData? icon;

  /// حجم الأيقونة
  final double? iconSize;

  /// نص التلميح
  final String? tooltip;

  /// لون الأيقونة
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<dynamic>(
      icon: Icon(
        icon ?? Icons.print,
        size: iconSize ?? 24.sp,
        color: color,
      ),
      tooltip: tooltip ?? 'خيارات الطباعة',
      onSelected: (value) {
        if (value is PrintType) {
          onPrint(value);
        } else if (value is PrintSize && onSizeChanged != null) {
          onSizeChanged!(value);
        }
      },
      itemBuilder: (context) => [
        // خيارات الطباعة
        if (enabledOptions.contains(PrintType.print))
          PopupMenuItem<PrintType>(
            value: PrintType.print,
            child: Row(
              children: [
                Icon(Icons.print, color: Colors.blue, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('طباعة'),
              ],
            ),
          ),
        if (enabledOptions.contains(PrintType.preview))
          PopupMenuItem<PrintType>(
            value: PrintType.preview,
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.purple, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('معاينة'),
              ],
            ),
          ),
        if (enabledOptions.contains(PrintType.share))
          PopupMenuItem<PrintType>(
            value: PrintType.share,
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('مشاركة PDF'),
              ],
            ),
          ),
        if (enabledOptions.contains(PrintType.save))
          PopupMenuItem<PrintType>(
            value: PrintType.save,
            child: Row(
              children: [
                Icon(Icons.save_alt, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('حفظ PDF'),
              ],
            ),
          ),

        // فاصل إذا كان هناك خيارات حجم
        if (showSizeSelector && enabledOptions.isNotEmpty)
          const PopupMenuDivider(),

        // خيارات الحجم
        if (showSizeSelector) ...[
          PopupMenuItem<PrintSize>(
            enabled: false,
            child: Text(
              'حجم الطباعة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ),
          for (final size in PrintSize.values)
            PopupMenuItem<PrintSize>(
              value: size,
              child: Row(
                children: [
                  Icon(
                    size == currentSize ? Icons.check_circle : size.icon,
                    color: size == currentSize ? Colors.blue : Colors.grey,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    size.label,
                    style: TextStyle(
                      fontWeight: size == currentSize
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// زر طباعة بسيط (أيقونة فقط)
class SimplePrintButton extends StatelessWidget {
  const SimplePrintButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconSize,
    this.tooltip,
    this.color,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? iconSize;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        icon ?? Icons.print,
        size: iconSize ?? 24.sp,
        color: color,
      ),
      tooltip: tooltip ?? 'طباعة',
      onPressed: onPressed,
    );
  }
}

/// امتداد لتحويل PrintType إلى نص
extension PrintTypeExtension on PrintType {
  String get label {
    switch (this) {
      case PrintType.print:
        return 'طباعة';
      case PrintType.share:
        return 'مشاركة PDF';
      case PrintType.save:
        return 'حفظ PDF';
      case PrintType.preview:
        return 'معاينة';
    }
  }

  IconData get icon {
    switch (this) {
      case PrintType.print:
        return Icons.print;
      case PrintType.share:
        return Icons.share;
      case PrintType.save:
        return Icons.save_alt;
      case PrintType.preview:
        return Icons.preview;
    }
  }

  Color get color {
    switch (this) {
      case PrintType.print:
        return Colors.blue;
      case PrintType.share:
        return Colors.green;
      case PrintType.save:
        return Colors.orange;
      case PrintType.preview:
        return Colors.purple;
    }
  }
}
