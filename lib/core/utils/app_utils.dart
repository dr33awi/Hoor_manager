import 'dart:math';

/// أدوات مساعدة متنوعة
class AppUtils {
  AppUtils._();

  /// توليد معرف فريد
  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomStr = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return '$timestamp$randomStr';
  }

  /// توليد باركود عشوائي (13 رقم - EAN-13)
  static String generateBarcode() {
    final random = Random();
    // أول رقمين: كود الدولة (نستخدم 62 لليمن)
    String barcode = '62';
    // 10 أرقام عشوائية
    for (int i = 0; i < 10; i++) {
      barcode += random.nextInt(10).toString();
    }
    // حساب رقم التحقق (check digit)
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return barcode + checkDigit.toString();
  }

  /// تنسيق رقم الهاتف
  static String formatPhoneNumber(String phone) {
    // إزالة المسافات والشرطات
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    // إضافة كود الدولة إذا لم يكن موجوداً
    if (cleaned.startsWith('7') && cleaned.length == 9) {
      cleaned = '+967$cleaned';
    } else if (cleaned.startsWith('967')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  /// اختصار النص
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// تحويل حجم الملف للقراءة
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// حساب نسبة الخصم
  static double calculateDiscountPercentage(double original, double discounted) {
    if (original <= 0) return 0;
    return ((original - discounted) / original) * 100;
  }

  /// حساب السعر بعد الخصم
  static double applyDiscount(double price, double discount, {bool isPercentage = true}) {
    if (isPercentage) {
      return price * (1 - discount / 100);
    }
    return price - discount;
  }

  /// حساب الربح
  static double calculateProfit(double sellingPrice, double cost) {
    return sellingPrice - cost;
  }

  /// حساب نسبة الربح
  static double calculateProfitMargin(double sellingPrice, double cost) {
    if (cost <= 0) return 0;
    return ((sellingPrice - cost) / cost) * 100;
  }
}
