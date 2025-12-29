import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../data/database/app_database.dart';
import '../constants/invoice_types.dart';
import '../theme/app_colors.dart';

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
  'default': InvoiceTypeInfo(
    type: 'default',
    label: 'فاتورة',
    shortLabel: 'فاتورة',
    icon: Icons.receipt_outlined,
    color: AppColors.secondary,
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
  'bank_transfer': PaymentMethodInfo(
    method: 'bank_transfer',
    label: 'تحويل بنكي',
    icon: Icons.account_balance_outlined,
  ),
  'default': PaymentMethodInfo(
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
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: info.color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        useShortLabel ? info.shortLabel : info.label,
        style: TextStyle(
          fontSize: fontSize ?? 11.sp,
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
            color: AppColors.textHint,
          ),
          Gap(4.w),
        ],
        Text(
          info.label,
          style: TextStyle(
            fontSize: fontSize ?? 11.sp,
            color: AppColors.textSecondary,
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
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
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
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // أيقونة النوع
              InvoiceTypeIcon(type: invoice.type),
              Gap(12.w),

              // معلومات الفاتورة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصف الأول: رقم الفاتورة + شارة النوع
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InvoiceTypeBadge(
                          type: invoice.type,
                          useShortLabel: true,
                        ),
                      ],
                    ),
                    Gap(4.h),

                    // التاريخ
                    Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // اسم العميل/المورد
                    if (showCustomerName && customerName != null) ...[
                      Gap(2.h),
                      _buildPersonRow(Icons.person_outline, customerName!),
                    ],
                    if (showSupplierName && supplierName != null) ...[
                      Gap(2.h),
                      _buildPersonRow(
                          Icons.local_shipping_outlined, supplierName!),
                    ],

                    Gap(6.h),

                    // الصف الأخير: المبلغ + طريقة الدفع
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatAmount(invoice.total),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: typeInfo.color,
                          ),
                        ),
                        PaymentMethodBadge(method: invoice.paymentMethod),
                      ],
                    ),
                  ],
                ),
              ),

              Gap(8.w),
              Icon(
                Icons.chevron_left,
                color: AppColors.textHint,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(InvoiceTypeInfo typeInfo, DateFormat dateFormat) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // المبلغ
              Text(
                formatAmount(invoice.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: typeInfo.color,
                ),
              ),
              Gap(6.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: AppColors.textHint,
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
        Icon(icon, size: 14.sp, color: AppColors.textHint),
        Gap(4.w),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
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
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
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
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${formatAmount(value)}',
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? AppColors.error
                  : (isTotal ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}
