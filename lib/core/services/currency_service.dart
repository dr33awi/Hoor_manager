import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة العملة وسعر الصرف
class CurrencyService extends ChangeNotifier {
  static const String _exchangeRateKey = 'usd_to_syp_rate';
  static const String _basePriceInUsdKey = 'base_price_in_usd';

  final SharedPreferences _prefs;

  // سعر الصرف الافتراضي (الدولار مقابل الليرة السورية)
  static const double defaultExchangeRate = 14500.0;

  double _exchangeRate = defaultExchangeRate;
  bool _basePriceInUsd = true; // هل الأسعار الأساسية بالدولار

  // Stream controller للتغييرات في سعر الصرف
  final _exchangeRateController = StreamController<double>.broadcast();

  CurrencyService(this._prefs) {
    _loadSettings();
  }

  /// سعر الصرف الحالي
  double get exchangeRate => _exchangeRate;

  /// هل الأسعار المدخلة بالدولار
  bool get basePriceInUsd => _basePriceInUsd;

  /// Stream للاستماع لتغييرات سعر الصرف
  Stream<double> get exchangeRateStream => _exchangeRateController.stream;

  /// رمز العملة الرئيسية (الليرة السورية)
  static const String currencySymbol = 'ل.س';
  static const String currencyCode = 'SYP';

  /// رمز عملة الدولار
  static const String usdSymbol = '\$';
  static const String usdCode = 'USD';

  void _loadSettings() {
    _exchangeRate = _prefs.getDouble(_exchangeRateKey) ?? defaultExchangeRate;
    _basePriceInUsd = _prefs.getBool(_basePriceInUsdKey) ?? true;
  }

  /// تحديث سعر الصرف
  Future<void> setExchangeRate(double rate) async {
    if (rate <= 0) return;

    _exchangeRate = rate;
    await _prefs.setDouble(_exchangeRateKey, rate);
    _exchangeRateController.add(rate);
    notifyListeners();
  }

  /// تحديث خيار العملة الأساسية للأسعار
  Future<void> setBasePriceInUsd(bool value) async {
    _basePriceInUsd = value;
    await _prefs.setBool(_basePriceInUsdKey, value);
    notifyListeners();
  }

  /// تحويل من دولار إلى ليرة سورية
  double usdToSyp(double usdAmount) {
    return usdAmount * _exchangeRate;
  }

  /// تحويل من ليرة سورية إلى دولار
  double sypToUsd(double sypAmount) {
    return sypAmount / _exchangeRate;
  }

  /// تنسيق السعر بالليرة السورية
  String formatSyp(double amount, {bool showSymbol = true}) {
    final formatted = _formatNumber(amount);
    return showSymbol ? '$formatted $currencySymbol' : formatted;
  }

  /// تنسيق السعر بالدولار
  String formatUsd(double amount, {bool showSymbol = true}) {
    final formatted = amount.toStringAsFixed(2);
    return showSymbol ? '$usdSymbol$formatted' : formatted;
  }

  /// تنسيق السعر مع تحويل من الدولار إذا لزم الأمر
  String formatPrice(double priceInUsd, {bool showSymbol = true}) {
    final sypAmount = usdToSyp(priceInUsd);
    return formatSyp(sypAmount, showSymbol: showSymbol);
  }

  /// تنسيق الرقم بفواصل الآلاف
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    }

    final parts = number.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;

    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(parts[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join();
  }

  /// الحصول على سعر البيع بالليرة السورية
  double getSalePriceInSyp(double salePriceInUsd) {
    return usdToSyp(salePriceInUsd);
  }

  /// الحصول على سعر الشراء بالليرة السورية
  double getPurchasePriceInSyp(double purchasePriceInUsd) {
    return usdToSyp(purchasePriceInUsd);
  }

  @override
  void dispose() {
    _exchangeRateController.close();
    super.dispose();
  }
}
