import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أنواع التصدير المتاحة
enum ExportType {
  excel,
  pdf,
  sharePdf,
  shareExcel,
}

/// زر التصدير الموحد
/// يعرض قائمة بخيارات التصدير المختلفة (Excel, PDF, مشاركة)
class ExportMenuButton extends StatelessWidget {
  const ExportMenuButton({
    super.key,
    required this.onExport,
    this.enabledOptions = const {
      ExportType.excel,
      ExportType.pdf,
      ExportType.sharePdf,
    },
    this.isLoading = false,
    this.icon,
    this.iconSize,
    this.tooltip,
  });

  /// Callback عند اختيار نوع التصدير
  final void Function(ExportType type) onExport;

  /// الخيارات المفعلة (بشكل افتراضي: Excel, PDF, مشاركة PDF)
  final Set<ExportType> enabledOptions;

  /// حالة التحميل
  final bool isLoading;

  /// أيقونة مخصصة (افتراضي: more_vert)
  final IconData? icon;

  /// حجم الأيقونة
  final double? iconSize;

  /// نص التلميح
  final String? tooltip;

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

    return PopupMenuButton<ExportType>(
      icon: Icon(icon ?? Icons.more_vert, size: iconSize ?? 24.sp),
      tooltip: tooltip ?? 'خيارات التصدير',
      onSelected: onExport,
      itemBuilder: (context) => [
        if (enabledOptions.contains(ExportType.excel))
          PopupMenuItem(
            value: ExportType.excel,
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('تصدير Excel'),
              ],
            ),
          ),
        if (enabledOptions.contains(ExportType.pdf))
          PopupMenuItem(
            value: ExportType.pdf,
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('تصدير PDF'),
              ],
            ),
          ),
        if (enabledOptions.contains(ExportType.sharePdf))
          PopupMenuItem(
            value: ExportType.sharePdf,
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.blue, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('مشاركة PDF'),
              ],
            ),
          ),
        if (enabledOptions.contains(ExportType.shareExcel))
          PopupMenuItem(
            value: ExportType.shareExcel,
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.green.shade700, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('مشاركة Excel'),
              ],
            ),
          ),
      ],
    );
  }
}

/// امتداد لتحويل ExportType إلى نص
extension ExportTypeExtension on ExportType {
  String get label {
    switch (this) {
      case ExportType.excel:
        return 'Excel';
      case ExportType.pdf:
        return 'PDF';
      case ExportType.sharePdf:
        return 'مشاركة PDF';
      case ExportType.shareExcel:
        return 'مشاركة Excel';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportType.excel:
        return Icons.table_chart;
      case ExportType.pdf:
        return Icons.picture_as_pdf;
      case ExportType.sharePdf:
      case ExportType.shareExcel:
        return Icons.share;
    }
  }

  Color get color {
    switch (this) {
      case ExportType.excel:
      case ExportType.shareExcel:
        return Colors.green;
      case ExportType.pdf:
        return Colors.red;
      case ExportType.sharePdf:
        return Colors.blue;
    }
  }
}
