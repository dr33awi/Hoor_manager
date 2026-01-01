import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../data/database/app_database.dart';
import '../constants/invoice_types.dart';
import '../theme/redesign/design_tokens.dart';
import '../theme/redesign/typography.dart';
import '../di/injection.dart';
import '../services/currency_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ثوابت وبيانات الفواتير الموحدة
/// Unified Invoice Constants & Data
/// ═══════════════════════════════════════════════════════════════════════════

/// معلومات نوع الفاتورة - يستخدم InvoiceTypeConfig من invoice_types.dart
class InvoiceTypeInfo {
  final String type;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const InvoiceTypeInfo({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });

  /// الحصول على معلومات النوع من الكود
  static InvoiceTypeInfo fromType(String type) {
    final config = InvoiceTypeConfig.fromCode(type);
    return InvoiceTypeInfo(
      type: config.type.code,
      label: config.label,
      shortLabel: config.shortLabel,
      icon: config.icon,
      color: config.color,
    );
  }
}

/// معلومات طريقة الدفع - يستخدم PaymentMethodConfig من invoice_types.dart
class PaymentMethodInfo {
  final String method;
  final String label;
  final IconData icon;

  const PaymentMethodInfo({
    required this.method,
    required this.label,
    required this.icon,
  });

  /// الحصول على معلومات طريقة الدفع من الكود
  static PaymentMethodInfo fromMethod(String method) {
    final config = PaymentMethodConfig.fromCode(method);
    return PaymentMethodInfo(
      method: config.method.code,
      label: config.label,
      icon: config.icon,
    );
  }
}

/// جميع أنواع الفواتير - للتوافق مع الكود القديم
/// يُفضل استخدام InvoiceTypeConfig.all بدلاً منها
final Map<String, InvoiceTypeInfo> invoiceTypes = {
  for (final config in InvoiceTypeConfig.all)
    config.type.code: InvoiceTypeInfo(
      type: config.type.code,
      label: config.label,
      shortLabel: config.shortLabel,
      icon: config.icon,
      color: config.color,
    ),
  'default': const InvoiceTypeInfo(
    type: 'default',
    label: 'فاتورة',
    shortLabel: 'فاتورة',
    icon: Icons.receipt_outlined,
    color: HoorColors.textSecondary,
  ),
};

/// جميع طرق الدفع - للتوافق مع الكود القديم
/// يُفضل استخدام PaymentMethodConfig.all بدلاً منها
final Map<String, PaymentMethodInfo> paymentMethods = {
  for (final config in PaymentMethodConfig.all)
    config.method.code: PaymentMethodInfo(
      method: config.method.code,
      label: config.label,
      icon: config.icon,
    ),
  // إضافة bank_transfer للتوافق
  'bank_transfer': const PaymentMethodInfo(
    method: 'bank_transfer',
    label: 'تحويل بنكي',
    icon: Icons.account_balance_outlined,
  ),
  'default': const PaymentMethodInfo(
    method: 'default',
    label: 'غير محدد',
    icon: Icons.payment_outlined,
  ),
};

/// ═══════════════════════════════════════════════════════════════════════════
/// دوال مساعدة - تستخدم invoice_types.dart
/// Helper Functions
/// ═══════════════════════════════════════════════════════════════════════════

/// الحصول على لون نوع الفاتورة
Color getInvoiceTypeColor(String type) =>
    InvoiceTypeConfig.fromCode(type).color;

/// الحصول على تسمية نوع الفاتورة
String getInvoiceTypeLabel(String type) =>
    InvoiceTypeConfig.fromCode(type).label;

/// الحصول على التسمية المختصرة لنوع الفاتورة
String getInvoiceTypeShortLabel(String type) =>
    InvoiceTypeConfig.fromCode(type).shortLabel;

/// الحصول على أيقونة نوع الفاتورة
IconData getInvoiceTypeIcon(String type) =>
    InvoiceTypeConfig.fromCode(type).icon;

/// الحصول على تسمية طريقة الدفع
String getPaymentMethodLabel(String method) =>
    PaymentMethodConfig.fromCode(method).label;

/// الحصول على أيقونة طريقة الدفع
IconData getPaymentMethodIcon(String method) =>
    PaymentMethodConfig.fromCode(method).icon;

/// تنسيق السعر بالليرة السورية (بدون أصفار زائدة)
/// يعرض الرقم كامل مع فواصل الآلاف وبدون كسور إذا كان عدد صحيح
String formatPrice(double price, {bool showCurrency = true}) {
  String formatted;

  // إزالة الأصفار الزائدة بعد الفاصلة
  if (price == price.roundToDouble()) {
    formatted = price.toStringAsFixed(0);
  } else {
    formatted = price.toStringAsFixed(2);
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
  }

  // إضافة فواصل الآلاف للجزء الصحيح
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

/// تنسيق المبلغ (للتقارير - يختصر الأرقام الكبيرة)
String formatAmount(double amount, {bool showCurrency = true}) {
  String formatted;
  if (amount >= 1000000) {
    formatted = '${(amount / 1000000).toStringAsFixed(1)}M';
  } else {
    final intAmount = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intAmount.length - 1; i >= 0; i--) {
      buffer.write(intAmount[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    formatted = buffer.toString().split('').reversed.join();
  }
  return showCurrency ? '$formatted ل.س' : formatted;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Widgets موحدة
/// Unified Widgets
/// ═══════════════════════════════════════════════════════════════════════════

/// شارة نوع الفاتورة
class InvoiceTypeBadge extends StatelessWidget {
  final String type;
  final bool useShortLabel;
  final double? fontSize;

  const InvoiceTypeBadge({
    super.key,
    required this.type,
    this.useShortLabel = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final info = InvoiceTypeInfo.fromType(type);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.sm.r),
        border: Border.all(
          color: info.color.withValues(alpha: 0.3),
          width: 0.5.w,
        ),
      ),
      child: Text(
        useShortLabel ? info.shortLabel : info.label,
        style: HoorTypography.labelSmall.copyWith(
          fontSize: fontSize,
          color: info.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// شارة طريقة الدفع
class PaymentMethodBadge extends StatelessWidget {
  final String method;
  final bool showIcon;
  final double? fontSize;

  const PaymentMethodBadge({
    super.key,
    required this.method,
    this.showIcon = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final info = PaymentMethodInfo.fromMethod(method);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            info.icon,
            size: 14.sp,
            color: HoorColors.textTertiary,
          ),
          Gap(4.w),
        ],
        Text(
          info.label,
          style: HoorTypography.labelSmall.copyWith(
            fontSize: fontSize,
            color: HoorColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// أيقونة نوع الفاتورة مع خلفية
class InvoiceTypeIcon extends StatelessWidget {
  final String type;
  final double? size;

  const InvoiceTypeIcon({
    super.key,
    required this.type,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final info = InvoiceTypeInfo.fromType(type);
    final iconSize = size ?? 24.sp;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md.r),
      ),
      child: Icon(
        info.icon,
        color: info.color,
        size: iconSize,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// بطاقة الفاتورة الموحدة
/// Unified Invoice Card
/// ═══════════════════════════════════════════════════════════════════════════

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;
  final bool showCustomerName;
  final bool showSupplierName;
  final String? customerName;
  final String? supplierName;
  final bool compact;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.showCustomerName = false,
    this.showSupplierName = false,
    this.customerName,
    this.supplierName,
    this.compact = false,
  });

  /// تحويل المبلغ باستخدام سعر الصرف المحفوظ في الفاتورة
  String _invoiceToUsd(Invoice inv, double amount) {
    final currencyService = getIt<CurrencyService>();
    final rate = inv.exchangeRate ?? currencyService.exchangeRate;
    if (rate <= 0) return '\$0.00';
    return '\$${(amount / rate).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = InvoiceTypeInfo.fromType(invoice.type);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (compact) {
      return _buildCompactCard(typeInfo, dateFormat);
    }

    return _buildFullCard(typeInfo, dateFormat);
  }

  Widget _buildFullCard(InvoiceTypeInfo typeInfo, DateFormat dateFormat) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: HoorColors.surface,
          borderRadius: HoorRadius.cardRadius,
          border: Border.all(color: HoorColors.border),
          boxShadow: HoorShadows.sm,
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // أيقونة النوع
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: 24.sp,
                ),
              ),
              Gap(16.w),

              // معلومات الفاتورة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصف الأول: رقم الفاتورة + التاريخ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: HoorTypography.titleMedium.copyWith(
                            color: HoorColors.primary,
                          ),
                        ),
                        Text(
                          dateFormat.format(invoice.invoiceDate),
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    Gap(8.h),

                    // اسم العميل/المورد
                    if (showCustomerName && customerName != null) ...[
                      _buildPersonRow(Icons.person_outline, customerName!),
                      Gap(4.h),
                    ],
                    if (showSupplierName && supplierName != null) ...[
                      _buildPersonRow(
                          Icons.local_shipping_outlined, supplierName!),
                      Gap(4.h),
                    ],

                    // الصف الأخير: المبلغ + طريقة الدفع
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatAmount(invoice.total),
                              style: HoorTypography.titleLarge.copyWith(
                                color: HoorColors.primary,
                              ),
                            ),
                            // USD Display
                            Row(
                              children: [
                                Text(
                                  _invoiceToUsd(invoice, invoice.total),
                                  style: HoorTypography.bodySmall.copyWith(
                                    color: HoorColors.textSecondary,
                                  ),
                                ),
                                if (invoice.exchangeRate != null) ...[
                                  Gap(4.w),
                                  Text(
                                    '(${NumberFormat('#,###').format(invoice.exchangeRate)})',
                                    style: HoorTypography.caption,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        PaymentMethodBadge(
                          method: invoice.paymentMethod,
                          fontSize: 12.sp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(InvoiceTypeInfo typeInfo, DateFormat dateFormat) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: 8.h),
        elevation: 0,
        color: HoorColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md.r),
          side: const BorderSide(color: HoorColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              // شارة النوع
              InvoiceTypeBadge(
                type: invoice.type,
                useShortLabel: true,
                fontSize: 10.sp,
              ),
              Gap(10.w),

              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: HoorTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: HoorTypography.caption,
                    ),
                  ],
                ),
              ),

              // المبلغ
              Text(
                formatAmount(invoice.total),
                style: HoorTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: typeInfo.color,
                ),
              ),
              Gap(6.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: HoorColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonRow(IconData icon, String name) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: HoorColors.textTertiary),
        Gap(4.w),
        Expanded(
          child: Text(
            name,
            style: HoorTypography.bodySmall.copyWith(
              color: HoorColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// صف معلومات (للتفاصيل)
/// Info Row Widget
/// ═══════════════════════════════════════════════════════════════════════════

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double? labelWidth;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth ?? 100.w,
            child: Text(
              '$label:',
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: HoorTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// صف الملخص المالي
/// Summary Row Widget
/// ═══════════════════════════════════════════════════════════════════════════

class SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;
  final bool isTotal;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? HoorTypography.titleMedium
                : HoorTypography.bodyMedium,
          ),
          Text(
            '${isNegative ? '-' : ''}${formatAmount(value)}',
            style: (isTotal
                    ? HoorTypography.titleMedium
                    : HoorTypography.bodyMedium)
                .copyWith(
              color: isNegative
                  ? HoorColors.error
                  : (isTotal ? HoorColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}
