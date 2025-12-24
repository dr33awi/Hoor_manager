import 'package:intl/intl.dart';

/// إضافات على num (int و double)
extension NumExtensions on num {
  // تنسيق كعملة
  String toCurrency({String symbol = 'ر.ي', int decimalDigits = 0}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      locale: 'ar',
    );
    return formatter.format(this);
  }

  // تنسيق كعملة مختصرة (ك، م)
  String toCompactCurrency({String symbol = ''}) {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}م$symbol';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}ك$symbol';
    }
    return '${toStringAsFixed(0)}$symbol';
  }

  // تنسيق كرقم مع فواصل
  String toFormattedNumber({int decimalDigits = 0}) {
    final formatter = NumberFormat('#,##0' + (decimalDigits > 0 ? '.${'0' * decimalDigits}' : ''), 'ar');
    return formatter.format(this);
  }

  // تنسيق كنسبة مئوية
  String toPercentage({int decimalDigits = 0}) {
    return '${toStringAsFixed(decimalDigits)}%';
  }

  // هل الرقم موجب
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;

  // تقريب لأقرب قيمة
  double roundToNearest(double nearest) {
    return (this / nearest).round() * nearest;
  }
}

/// إضافات على int
extension IntExtensions on int {
  // تحويل لمدة زمنية
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);
}

/// إضافات على double
extension DoubleExtensions on double {
  // تقريب لعدد معين من الخانات
  double roundTo(int places) {
    num mod = 1.0;
    for (int i = 0; i < places; i++) {
      mod *= 10;
    }
    return ((this * mod).round().toDouble() / mod);
  }
}
