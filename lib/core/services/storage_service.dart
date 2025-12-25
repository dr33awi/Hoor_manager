import 'package:hive_flutter/hive_flutter.dart';

/// خدمة التخزين المحلي باستخدام Hive
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';

  late Box _settings;
  late Box _cache;

  /// تهيئة الخدمة
  Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
    _cache = await Hive.openBox(_cacheBox);
  }

  // ==================== الإعدادات ====================

  /// حفظ إعداد
  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  /// قراءة إعداد
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue) as T?;
  }

  /// حذف إعداد
  Future<void> deleteSetting(String key) async {
    await _settings.delete(key);
  }

  // ==================== الكاش ====================

  /// حفظ في الكاش
  Future<void> saveToCache(String key, dynamic value, {Duration? expiry}) async {
    final data = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await _cache.put(key, data);
  }

  /// قراءة من الكاش
  T? getFromCache<T>(String key) {
    final data = _cache.get(key);
    if (data == null) return null;

    final timestamp = data['timestamp'] as int;
    final expiry = data['expiry'] as int?;

    // التحقق من انتهاء الصلاحية
    if (expiry != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp + expiry);
      if (DateTime.now().isAfter(expiryTime)) {
        _cache.delete(key);
        return null;
      }
    }

    return data['value'] as T?;
  }

  /// مسح الكاش
  Future<void> clearCache() async {
    await _cache.clear();
  }

  // ==================== إعدادات محددة ====================

  /// حفظ حد المخزون المنخفض
  Future<void> setLowStockThreshold(int value) async {
    await saveSetting('low_stock_threshold', value);
  }

  /// قراءة حد المخزون المنخفض
  int getLowStockThreshold() {
    return getSetting<int>('low_stock_threshold', defaultValue: 5) ?? 5;
  }

  /// حفظ معلومات المتجر
  Future<void> setStoreInfo({
    String? name,
    String? address,
    String? phone,
  }) async {
    if (name != null) await saveSetting('store_name', name);
    if (address != null) await saveSetting('store_address', address);
    if (phone != null) await saveSetting('store_phone', phone);
  }

  /// قراءة اسم المتجر
  String getStoreName() {
    return getSetting<String>('store_name', defaultValue: 'متجر حور') ?? 'متجر حور';
  }

  /// قراءة عنوان المتجر
  String? getStoreAddress() {
    return getSetting<String>('store_address');
  }

  /// قراءة هاتف المتجر
  String? getStorePhone() {
    return getSetting<String>('store_phone');
  }

  /// حفظ آخر رقم فاتورة
  Future<void> setLastInvoiceNumber(String date, int number) async {
    await saveSetting('last_invoice_$date', number);
  }

  /// قراءة آخر رقم فاتورة
  int getLastInvoiceNumber(String date) {
    return getSetting<int>('last_invoice_$date', defaultValue: 0) ?? 0;
  }

  /// حفظ حالة الإشعارات
  Future<void> setNotificationsEnabled(bool value) async {
    await saveSetting('notifications_enabled', value);
  }

  /// قراءة حالة الإشعارات
  bool getNotificationsEnabled() {
    return getSetting<bool>('notifications_enabled', defaultValue: true) ?? true;
  }

  /// حفظ وضع الثيم (true = داكن، false = فاتح)
  Future<void> setDarkMode(bool value) async {
    await saveSetting('dark_mode', value);
  }

  /// قراءة وضع الثيم
  bool getDarkMode() {
    return getSetting<bool>('dark_mode', defaultValue: false) ?? false;
  }
}
