import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../services/print_settings_service.dart';
import '../services/printing/invoice_pdf_generator.dart';
import '../theme/redesign/design_tokens.dart';
import '../theme/redesign/typography.dart';

/// نتيجة ديالوج الطباعة
enum PrintDialogResult {
  print,
  preview,
  share,
  cancel,
}

/// ديالوج طباعة موحد
/// يمكن استخدامه للفواتير والسندات وأي مستند آخر
class PrintDialog {
  PrintDialog._();

  static final _printSettingsService = getIt<PrintSettingsService>();

  /// إظهار ديالوج الطباعة الموحد
  ///
  /// [context] - السياق
  /// [title] - عنوان الديالوج (مثل: "طباعة الفاتورة" أو "طباعة السند")
  /// [color] - لون الديالوج الرئيسي (اختياري، الافتراضي بنفسجي)
  ///
  /// يعيد [PrintDialogResult] مع [InvoicePrintSize] المختار
  static Future<({PrintDialogResult result, InvoicePrintSize size})?> show({
    required BuildContext context,
    required String title,
    Color? color,
  }) async {
    final themeColor = color ?? HoorColors.primary;
    final printOptions = await _printSettingsService.getPrintOptions();
    InvoicePrintSize selectedSize = printOptions.size;

    if (!context.mounted) return null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: HoorColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.xl.r),
          ),
          title: Row(
            children: [
              Icon(Icons.print, color: themeColor, size: 24.sp),
              Gap(8.w),
              Expanded(
                child: Text(
                  title,
                  style: HoorTypography.titleMedium,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان اختيار المقاس
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مقاس الورق',
                  style: HoorTypography.labelMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ),
              Gap(12.h),
              // خيارات المقاس
              PrintSizeOption(
                title: 'A4',
                subtitle: 'للطابعات العادية',
                icon: Icons.description,
                isSelected: selectedSize == InvoicePrintSize.a4,
                color: themeColor,
                onTap: () => setState(() => selectedSize = InvoicePrintSize.a4),
              ),
              Gap(8.h),
              PrintSizeOption(
                title: 'حراري 80mm',
                subtitle: 'للطابعات الحرارية الكبيرة',
                icon: Icons.receipt_long,
                isSelected: selectedSize == InvoicePrintSize.thermal80mm,
                color: themeColor,
                onTap: () =>
                    setState(() => selectedSize = InvoicePrintSize.thermal80mm),
              ),
              Gap(8.h),
              PrintSizeOption(
                title: 'حراري 58mm',
                subtitle: 'للطابعات الحرارية الصغيرة',
                icon: Icons.receipt,
                isSelected: selectedSize == InvoicePrintSize.thermal58mm,
                color: themeColor,
                onTap: () =>
                    setState(() => selectedSize = InvoicePrintSize.thermal58mm),
              ),
              Gap(16.h),
              // زر الذهاب للإعدادات المتقدمة
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/settings/print');
                },
                icon: Icon(Icons.settings, size: 18.sp),
                label: const Text('إعدادات متقدمة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HoorColors.textSecondary,
                  side: BorderSide(color: HoorColors.border),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  textStyle: HoorTypography.labelMedium,
                ),
              ),
            ],
          ),
          actionsPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (selectedSize != printOptions.size) {
                            await _printSettingsService.updateSetting(
                                defaultSize: selectedSize);
                          }
                          if (context.mounted) {
                            Navigator.pop(context, 'preview');
                          }
                        },
                        icon: const Icon(Icons.preview, size: 18),
                        label: const Text('معاينة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HoorColors.suppliers,
                          side: const BorderSide(color: HoorColors.suppliers),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          textStyle: HoorTypography.labelMedium,
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (selectedSize != printOptions.size) {
                            await _printSettingsService.updateSetting(
                                defaultSize: selectedSize);
                          }
                          if (context.mounted) Navigator.pop(context, 'print');
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('طباعة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          textStyle: HoorTypography.labelMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: HoorTypography.labelMedium.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (selectedSize != printOptions.size) {
                          await _printSettingsService.updateSetting(
                              defaultSize: selectedSize);
                        }
                        if (context.mounted) Navigator.pop(context, 'share');
                      },
                      icon: const Icon(Icons.share, size: 20),
                      tooltip: 'مشاركة PDF',
                      color: HoorColors.income,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return null;

    final dialogResult = switch (result) {
      'print' => PrintDialogResult.print,
      'preview' => PrintDialogResult.preview,
      'share' => PrintDialogResult.share,
      _ => PrintDialogResult.cancel,
    };

    // إعادة قراءة الإعدادات بعد التحديث
    final updatedOptions = await _printSettingsService.getPrintOptions();

    return (result: dialogResult, size: updatedOptions.size);
  }
}

/// خيار حجم الطباعة
class PrintSizeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const PrintSizeOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color = HoorColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HoorRadius.lg.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : HoorColors.surfaceMuted,
          borderRadius: BorderRadius.circular(HoorRadius.lg.r),
          border: Border.all(
            color: isSelected ? color : HoorColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : HoorColors.border,
                borderRadius: BorderRadius.circular(HoorRadius.md.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : HoorColors.textSecondary,
                size: 20.sp,
              ),
            ),
            Gap(10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HoorTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : HoorColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: HoorTypography.bodySmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }
}
