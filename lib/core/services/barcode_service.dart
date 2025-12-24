import 'dart:math';

/// خدمة الباركود
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  /// توليد باركود جديد (EAN-13)
  static String generateBarcode() {
    final random = Random();
    
    // بادئة الدولة (اليمن: 621)
    const countryCode = '621';
    
    // رمز الشركة (5 أرقام عشوائية)
    final companyCode = List.generate(5, (_) => random.nextInt(10)).join();
    
    // رمز المنتج (4 أرقام عشوائية)
    final productCode = List.generate(4, (_) => random.nextInt(10)).join();
    
    // الباركود بدون رقم التحقق
    final barcodeWithoutCheck = '$countryCode$companyCode$productCode';
    
    // حساب رقم التحقق
    final checkDigit = _calculateCheckDigit(barcodeWithoutCheck);
    
    return '$barcodeWithoutCheck$checkDigit';
  }

  /// توليد باركود بناءً على معرف المنتج
  static String generateFromProductId(String productId) {
    // استخدام hash للمعرف
    final hash = productId.hashCode.abs();
    final code = hash.toString().padLeft(12, '0').substring(0, 12);
    final checkDigit = _calculateCheckDigit(code);
    return '$code$checkDigit';
  }

  /// حساب رقم التحقق لـ EAN-13
  static int _calculateCheckDigit(String barcode) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(barcode[i]);
      sum += digit * (i.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit;
  }

  /// التحقق من صحة الباركود
  static bool isValidBarcode(String barcode) {
    // التحقق من الطول
    if (barcode.length != 13 && barcode.length != 8) {
      return false;
    }

    // التحقق من أن جميع الأحرف أرقام
    if (!RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }

    // التحقق من رقم التحقق
    if (barcode.length == 13) {
      final withoutCheck = barcode.substring(0, 12);
      final checkDigit = _calculateCheckDigit(withoutCheck);
      return barcode[12] == checkDigit.toString();
    }

    // للباركود EAN-8
    if (barcode.length == 8) {
      return _validateEAN8(barcode);
    }

    return false;
  }

  /// التحقق من صحة EAN-8
  static bool _validateEAN8(String barcode) {
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      final digit = int.parse(barcode[i]);
      sum += digit * (i.isEven ? 3 : 1);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return barcode[7] == checkDigit.toString();
  }

  /// تنسيق الباركود للعرض
  static String formatBarcode(String barcode) {
    if (barcode.length == 13) {
      return '${barcode.substring(0, 1)} ${barcode.substring(1, 7)} ${barcode.substring(7, 13)}';
    }
    if (barcode.length == 8) {
      return '${barcode.substring(0, 4)} ${barcode.substring(4, 8)}';
    }
    return barcode;
  }
}
