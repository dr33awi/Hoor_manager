import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Types - توحيد أنواع الفواتير وطرق الدفع
/// ═══════════════════════════════════════════════════════════════════════════

/// نوع الفاتورة
enum InvoiceType {
  sale('sale'),
  purchase('purchase'),
  saleReturn('sale_return'),
  purchaseReturn('purchase_return'),
  openingBalance('opening_balance');

  final String code;
  const InvoiceType(this.code);

  static InvoiceType fromCode(String code) {
    return InvoiceType.values.firstWhere(
      (t) => t.code == code,
      orElse: () => InvoiceType.sale,
    );
  }
}

/// طريقة الدفع
enum PaymentMethod {
  cash('cash'),
  card('card'),
  transfer('transfer'),
  credit('credit');

  final String code;
  const PaymentMethod(this.code);

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Type Config - إعدادات نوع الفاتورة
/// ═══════════════════════════════════════════════════════════════════════════
class InvoiceTypeConfig {
  final InvoiceType type;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final PdfColor pdfColor;

  const InvoiceTypeConfig({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.pdfColor,
  });

  /// الحصول على الإعدادات من النوع
  static InvoiceTypeConfig fromType(InvoiceType type) {
    return _configs[type] ?? _defaultConfig;
  }

  /// الحصول على الإعدادات من الكود
  static InvoiceTypeConfig fromCode(String code) {
    return fromType(InvoiceType.fromCode(code));
  }

  static const _defaultConfig = InvoiceTypeConfig(
    type: InvoiceType.sale,
    label: 'فاتورة',
    shortLabel: 'فاتورة',
    icon: Icons.receipt_outlined,
    color: AppColors.secondary,
    pdfColor: PdfColors.grey700,
  );

  static final Map<InvoiceType, InvoiceTypeConfig> _configs = {
    InvoiceType.sale: const InvoiceTypeConfig(
      type: InvoiceType.sale,
      label: 'فاتورة مبيعات',
      shortLabel: 'مبيعات',
      icon: Icons.shopping_cart_outlined,
      color: AppColors.success,
      pdfColor: PdfColors.green700,
    ),
    InvoiceType.purchase: const InvoiceTypeConfig(
      type: InvoiceType.purchase,
      label: 'فاتورة مشتريات',
      shortLabel: 'مشتريات',
      icon: Icons.inventory_2_outlined,
      color: AppColors.info,
      pdfColor: PdfColors.blue700,
    ),
    InvoiceType.saleReturn: const InvoiceTypeConfig(
      type: InvoiceType.saleReturn,
      label: 'مرتجع مبيعات',
      shortLabel: 'مرتجع مبيعات',
      icon: Icons.assignment_return_outlined,
      color: AppColors.warning,
      pdfColor: PdfColors.orange700,
    ),
    InvoiceType.purchaseReturn: const InvoiceTypeConfig(
      type: InvoiceType.purchaseReturn,
      label: 'مرتجع مشتريات',
      shortLabel: 'مرتجع مشتريات',
      icon: Icons.assignment_returned_outlined,
      color: AppColors.lowStock,
      pdfColor: PdfColors.amber700,
    ),
    InvoiceType.openingBalance: const InvoiceTypeConfig(
      type: InvoiceType.openingBalance,
      label: 'رصيد افتتاحي',
      shortLabel: 'رصيد افتتاحي',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.primary,
      pdfColor: PdfColors.teal700,
    ),
  };

  /// جميع الأنواع
  static List<InvoiceTypeConfig> get all => _configs.values.toList();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Payment Method Config - إعدادات طريقة الدفع
/// ═══════════════════════════════════════════════════════════════════════════
class PaymentMethodConfig {
  final PaymentMethod method;
  final String label;
  final IconData icon;

  const PaymentMethodConfig({
    required this.method,
    required this.label,
    required this.icon,
  });

  /// الحصول على الإعدادات من الطريقة
  static PaymentMethodConfig fromMethod(PaymentMethod method) {
    return _configs[method] ?? _defaultConfig;
  }

  /// الحصول على الإعدادات من الكود
  static PaymentMethodConfig fromCode(String code) {
    return fromMethod(PaymentMethod.fromCode(code));
  }

  static const _defaultConfig = PaymentMethodConfig(
    method: PaymentMethod.cash,
    label: 'نقدي',
    icon: Icons.payments_outlined,
  );

  static final Map<PaymentMethod, PaymentMethodConfig> _configs = {
    PaymentMethod.cash: const PaymentMethodConfig(
      method: PaymentMethod.cash,
      label: 'نقدي',
      icon: Icons.payments_outlined,
    ),
    PaymentMethod.card: const PaymentMethodConfig(
      method: PaymentMethod.card,
      label: 'بطاقة',
      icon: Icons.credit_card_outlined,
    ),
    PaymentMethod.transfer: const PaymentMethodConfig(
      method: PaymentMethod.transfer,
      label: 'تحويل',
      icon: Icons.account_balance_outlined,
    ),
    PaymentMethod.credit: const PaymentMethodConfig(
      method: PaymentMethod.credit,
      label: 'آجل',
      icon: Icons.schedule_outlined,
    ),
  };

  /// جميع الطرق
  static List<PaymentMethodConfig> get all => _configs.values.toList();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Status - حالات الفاتورة
/// ═══════════════════════════════════════════════════════════════════════════
enum InvoiceStatus {
  pending('pending'),
  completed('completed'),
  cancelled('cancelled');

  final String code;
  const InvoiceStatus(this.code);

  static InvoiceStatus fromCode(String code) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => InvoiceStatus.completed,
    );
  }
}

class InvoiceStatusConfig {
  final InvoiceStatus status;
  final String label;
  final Color color;
  final IconData icon;

  const InvoiceStatusConfig({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
  });

  static InvoiceStatusConfig fromStatus(InvoiceStatus status) {
    return _configs[status] ?? _defaultConfig;
  }

  static InvoiceStatusConfig fromCode(String code) {
    return fromStatus(InvoiceStatus.fromCode(code));
  }

  static const _defaultConfig = InvoiceStatusConfig(
    status: InvoiceStatus.completed,
    label: 'مكتملة',
    color: AppColors.success,
    icon: Icons.check_circle_outlined,
  );

  static final Map<InvoiceStatus, InvoiceStatusConfig> _configs = {
    InvoiceStatus.pending: const InvoiceStatusConfig(
      status: InvoiceStatus.pending,
      label: 'معلقة',
      color: AppColors.warning,
      icon: Icons.pending_outlined,
    ),
    InvoiceStatus.completed: const InvoiceStatusConfig(
      status: InvoiceStatus.completed,
      label: 'مكتملة',
      color: AppColors.success,
      icon: Icons.check_circle_outlined,
    ),
    InvoiceStatus.cancelled: const InvoiceStatusConfig(
      status: InvoiceStatus.cancelled,
      label: 'ملغية',
      color: AppColors.error,
      icon: Icons.cancel_outlined,
    ),
  };

  static List<InvoiceStatusConfig> get all => _configs.values.toList();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Helper Functions - دوال مساعدة للتوافق مع الكود القديم
/// ═══════════════════════════════════════════════════════════════════════════

/// الحصول على تسمية نوع الفاتورة
String getInvoiceTypeLabelV2(String typeCode) {
  return InvoiceTypeConfig.fromCode(typeCode).label;
}

/// الحصول على لون نوع الفاتورة (Flutter)
Color getInvoiceTypeColorV2(String typeCode) {
  return InvoiceTypeConfig.fromCode(typeCode).color;
}

/// الحصول على لون نوع الفاتورة (PDF)
PdfColor getInvoiceTypePdfColorV2(String typeCode) {
  return InvoiceTypeConfig.fromCode(typeCode).pdfColor;
}

/// الحصول على أيقونة نوع الفاتورة
IconData getInvoiceTypeIconV2(String typeCode) {
  return InvoiceTypeConfig.fromCode(typeCode).icon;
}

/// الحصول على تسمية طريقة الدفع
String getPaymentMethodLabelV2(String methodCode) {
  return PaymentMethodConfig.fromCode(methodCode).label;
}

/// الحصول على أيقونة طريقة الدفع
IconData getPaymentMethodIconV2(String methodCode) {
  return PaymentMethodConfig.fromCode(methodCode).icon;
}

/// الحصول على تسمية الحالة
String getInvoiceStatusLabelV2(String statusCode) {
  return InvoiceStatusConfig.fromCode(statusCode).label;
}

/// الحصول على لون الحالة
Color getInvoiceStatusColorV2(String statusCode) {
  return InvoiceStatusConfig.fromCode(statusCode).color;
}
