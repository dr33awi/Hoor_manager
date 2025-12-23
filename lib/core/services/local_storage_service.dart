// lib/core/services/local_storage_service.dart
// خدمة التخزين المحلي باستخدام SharedPreferences و Hive - محسنة مع التشفير

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/app_constants.dart';
import 'base_service.dart';
import 'logger_service.dart';

/// خدمة التخزين المحلي
class LocalStorageService extends BaseService {
  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ✅ مفتاح التشفير (في الإنتاج يجب تخزينه في مكان آمن)
  String? _encryptionKey;

  bool get isInitialized => _initialized;

  /// تهيئة الخدمة
  Future<ServiceResult<void>> initialize() async {
    if (_initialized) return ServiceResult.success();

    try {
      AppLogger.startOperation('تهيئة LocalStorage');

      // تهيئة SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // تهيئة Hive
      await Hive.initFlutter();

      // ✅ تهيئة مفتاح التشفير
      await _initEncryptionKey();

      // فتح الصناديق المطلوبة
      await _openBoxes();

      _initialized = true;
      AppLogger.endOperation('تهيئة LocalStorage', success: true);
      return ServiceResult.success();
    } catch (e, stackTrace) {
      AppLogger.e('فشل تهيئة LocalStorage', error: e, stackTrace: stackTrace);
      return ServiceResult.failure(handleError(e));
    }
  }

  /// ✅ تهيئة مفتاح التشفير
  Future<void> _initEncryptionKey() async {
    const keyName = 'encryption_key_v1';
    _encryptionKey = _prefs?.getString(keyName);

    if (_encryptionKey == null) {
      // إنشاء مفتاح جديد
      _encryptionKey = _generateSecureKey(32);
      await _prefs?.setString(keyName, _encryptionKey!);
      AppLogger.d('تم إنشاء مفتاح تشفير جديد');
    }
  }

  /// ✅ إنشاء مفتاح آمن عشوائي
  String _generateSecureKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// ✅ تشفير النص
  String _encrypt(String plainText) {
    if (_encryptionKey == null) return plainText;

    try {
      // تشفير بسيط باستخدام XOR (في الإنتاج استخدم مكتبة تشفير حقيقية)
      final keyBytes = utf8.encode(_encryptionKey!);
      final textBytes = utf8.encode(plainText);
      final encryptedBytes = <int>[];

      for (int i = 0; i < textBytes.length; i++) {
        encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64Encode(encryptedBytes);
    } catch (e) {
      AppLogger.e('خطأ في التشفير', error: e);
      return plainText;
    }
  }

  /// ✅ فك التشفير
  String _decrypt(String encryptedText) {
    if (_encryptionKey == null) return encryptedText;

    try {
      final keyBytes = utf8.encode(_encryptionKey!);
      final encryptedBytes = base64Decode(encryptedText);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      AppLogger.e('خطأ في فك التشفير', error: e);
      return encryptedText;
    }
  }

  /// فتح صناديق Hive
  Future<void> _openBoxes() async {
    await Hive.openBox<String>(AppConstants.productsBox);
    await Hive.openBox<String>(AppConstants.salesBox);
    await Hive.openBox<String>(AppConstants.categoriesBox);
    await Hive.openBox<String>(AppConstants.settingsBox);
    await Hive.openBox<String>(AppConstants.pendingSalesBox);
  }

  // ==================== SharedPreferences Operations ====================

  /// حفظ قيمة String
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// قراءة قيمة String
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// ✅ حفظ قيمة String مشفرة
  Future<bool> setSecureString(String key, String value) async {
    final encrypted = _encrypt(value);
    return await _prefs?.setString('secure_$key', encrypted) ?? false;
  }

  /// ✅ قراءة قيمة String مشفرة
  String? getSecureString(String key) {
    final encrypted = _prefs?.getString('secure_$key');
    if (encrypted == null) return null;
    return _decrypt(encrypted);
  }

  /// حفظ قيمة int
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// قراءة قيمة int
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// حفظ قيمة bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// قراءة قيمة bool
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// حفظ قيمة double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// قراءة قيمة double
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// حفظ قائمة String
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  /// قراءة قائمة String
  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// حفظ كائن JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }

  /// قراءة كائن JSON
  Map<String, dynamic>? getJson(String key) {
    final value = getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('خطأ في قراءة JSON', error: e);
      return null;
    }
  }

  /// ✅ حفظ كائن JSON مشفر
  Future<bool> setSecureJson(String key, Map<String, dynamic> value) async {
    return await setSecureString(key, jsonEncode(value));
  }

  /// ✅ قراءة كائن JSON مشفر
  Map<String, dynamic>? getSecureJson(String key) {
    final value = getSecureString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('خطأ في قراءة JSON المشفر', error: e);
      return null;
    }
  }

  /// حذف قيمة
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// مسح كل البيانات
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// التحقق من وجود مفتاح
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // ==================== Hive Operations ====================

  /// الحصول على صندوق
  Box<String>? _getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      AppLogger.w('الصندوق $boxName غير مفتوح');
      return null;
    }
    return Hive.box<String>(boxName);
  }

  /// حفظ في Hive
  Future<void> hiveSet(String boxName, String key, dynamic value) async {
    final box = _getBox(boxName);
    if (box != null) {
      await box.put(key, jsonEncode(value));
    }
  }

  /// قراءة من Hive
  T? hiveGet<T>(
    String boxName,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final box = _getBox(boxName);
    if (box == null) return null;

    final value = box.get(key);
    if (value == null) return null;

    try {
      return fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('خطأ في قراءة من Hive', error: e);
      return null;
    }
  }

  /// قراءة كل القيم من صندوق
  List<T> hiveGetAll<T>(
    String boxName,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final box = _getBox(boxName);
    if (box == null) return [];

    final results = <T>[];
    for (final value in box.values) {
      try {
        results.add(fromJson(jsonDecode(value) as Map<String, dynamic>));
      } catch (e) {
        AppLogger.e('خطأ في قراءة عنصر', error: e);
      }
    }
    return results;
  }

  /// حذف من Hive
  Future<void> hiveDelete(String boxName, String key) async {
    final box = _getBox(boxName);
    await box?.delete(key);
  }

  /// مسح صندوق
  Future<void> hiveClear(String boxName) async {
    final box = _getBox(boxName);
    await box?.clear();
  }

  /// عدد العناصر في صندوق
  int hiveCount(String boxName) {
    final box = _getBox(boxName);
    return box?.length ?? 0;
  }

  // ==================== Cache Operations ====================

  /// حفظ مع تاريخ انتهاء
  Future<void> setWithExpiry(String key, dynamic value, Duration expiry) async {
    final data = {
      'value': value,
      'expiry': DateTime.now().add(expiry).toIso8601String(),
    };
    await setJson(key, data);
  }

  /// قراءة مع التحقق من الانتهاء
  T? getWithExpiry<T>(String key) {
    final data = getJson(key);
    if (data == null) return null;

    final expiry = DateTime.tryParse(data['expiry'] as String? ?? '');
    if (expiry == null || expiry.isBefore(DateTime.now())) {
      remove(key);
      return null;
    }

    return data['value'] as T?;
  }

  // ==================== User Session ====================

  /// ✅ حفظ بيانات الجلسة (مشفرة)
  Future<void> saveSession({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    // ✅ تشفير بيانات الجلسة
    final sessionData = {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await setSecureJson('session_data', sessionData);

    // أيضاً حفظ بشكل عادي للوصول السريع (غير حساس)
    await setString(AppConstants.userIdKey, userId);
    await setString(AppConstants.userNameKey, userName);
    await setString(AppConstants.userRoleKey, userRole);
  }

  /// قراءة بيانات الجلسة
  Map<String, String?> getSession() {
    // محاولة قراءة الجلسة المشفرة أولاً
    final secureSession = getSecureJson('session_data');
    if (secureSession != null) {
      return {
        'userId': secureSession['userId'] as String?,
        'userName': secureSession['userName'] as String?,
        'userRole': secureSession['userRole'] as String?,
      };
    }

    // الرجوع للطريقة القديمة
    return {
      'userId': getString(AppConstants.userIdKey),
      'userName': getString(AppConstants.userNameKey),
      'userRole': getString(AppConstants.userRoleKey),
    };
  }

  /// ✅ مسح الجلسة بشكل آمن
  Future<void> clearSession() async {
    await remove('secure_session_data');
    await remove(AppConstants.userIdKey);
    await remove(AppConstants.userNameKey);
    await remove(AppConstants.userRoleKey);
  }

  /// التحقق من وجود جلسة
  bool hasSession() {
    return containsKey(AppConstants.userIdKey) ||
        containsKey('secure_session_data');
  }

  /// ✅ التحقق من صلاحية الجلسة
  bool isSessionValid() {
    final secureSession = getSecureJson('session_data');
    if (secureSession == null) return false;

    final timestamp = DateTime.tryParse(
      secureSession['timestamp'] as String? ?? '',
    );
    if (timestamp == null) return false;

    // الجلسة صالحة لمدة 30 يوم
    final maxAge = const Duration(days: 30);
    return DateTime.now().difference(timestamp) < maxAge;
  }

  // ==================== Cleanup ====================

  /// تنظيف الموارد
  Future<void> dispose() async {
    await Hive.close();
    AppLogger.d('تم تنظيف LocalStorageService');
  }
}
