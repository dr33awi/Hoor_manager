import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import 'print_settings.dart';
import 'invoice_pdf_generator.dart';
import 'voucher_pdf_generator.dart';

/// خدمة إدارة إعدادات الطباعة الموحدة
/// تقوم بحفظ واسترجاع إعدادات الطباعة من قاعدة البيانات مع مزامنة Firestore
class PrintSettingsService extends ChangeNotifier {
  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  // Cache للإعدادات لتجنب القراءة المتكررة من قاعدة البيانات
  PrintSettings? _cachedSettings;

  // مفتاح حفظ الإعدادات في قاعدة البيانات
  static const String _settingsKey = 'print_settings';

  // Document ID في Firestore
  static const String _firestoreDocId = 'company_print_settings';

  // Firestore subscription
  StreamSubscription? _firestoreSubscription;

  // StreamController for reactive settings
  final _settingsController = StreamController<PrintSettings>.broadcast();

  /// Stream للاستماع لتغييرات الإعدادات
  Stream<PrintSettings> get settingsStream => _settingsController.stream;

  PrintSettingsService(this._database, this._firestore);

  /// Collection للإعدادات في Firestore
  CollectionReference get _collection =>
      _firestore.collection(AppConstants.printSettingsCollection);

  /// الحصول على إعدادات الطباعة
  Future<PrintSettings> getSettings() async {
    // إذا كانت الإعدادات مُخزنة مؤقتاً، أرجعها
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    // قراءة الإعدادات من قاعدة البيانات
    final jsonString = await _database.getSetting(_settingsKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _cachedSettings = PrintSettings.fromJson(json);
        return _cachedSettings!;
      } catch (_) {
        // في حالة خطأ، أرجع الإعدادات الافتراضية
      }
    }

    // إرجاع الإعدادات الافتراضية
    _cachedSettings = PrintSettings.defaultSettings;
    return _cachedSettings!;
  }

  /// حفظ إعدادات الطباعة
  Future<void> saveSettings(PrintSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _database.setSetting(_settingsKey, jsonString);
    _cachedSettings = settings;

    // إخطار المستمعين بالتغيير
    _settingsController.add(settings);
    notifyListeners();

    // مزامنة مع Firestore
    _syncToFirestore(settings);
  }

  /// مزامنة الإعدادات إلى Firestore
  Future<void> _syncToFirestore(PrintSettings settings) async {
    try {
      await _collection.doc(_firestoreDocId).set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Print settings synced to Firestore');
    } catch (e) {
      debugPrint('Error syncing print settings to Firestore: $e');
    }
  }

  /// سحب الإعدادات من Firestore
  Future<void> pullFromCloud() async {
    try {
      final doc = await _collection.doc(_firestoreDocId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // إزالة الحقول الخاصة بـ Firestore
        data.remove('updatedAt');

        final cloudSettings = PrintSettings.fromJson(data);
        await _database.setSetting(
            _settingsKey, jsonEncode(cloudSettings.toJson()));
        _cachedSettings = cloudSettings;
        debugPrint('Print settings pulled from Firestore');
      }
    } catch (e) {
      debugPrint('Error pulling print settings from Firestore: $e');
    }
  }

  /// بدء المزامنة في الوقت الفعلي
  void startRealtimeSync() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription =
        _collection.doc(_firestoreDocId).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        data.remove('updatedAt');

        try {
          final cloudSettings = PrintSettings.fromJson(data);
          // تحديث الـ cache والقاعدة المحلية
          _cachedSettings = cloudSettings;
          await _database.setSetting(
              _settingsKey, jsonEncode(cloudSettings.toJson()));

          // إخطار المستمعين بالتغيير
          _settingsController.add(cloudSettings);
          notifyListeners();

          debugPrint('Print settings updated from Firestore');
        } catch (e) {
          debugPrint('Error parsing print settings from Firestore: $e');
        }
      }
    });
  }

  /// إيقاف المزامنة في الوقت الفعلي
  void stopRealtimeSync() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  /// تحديث إعداد معين
  Future<void> updateSetting({
    InvoicePrintSize? defaultSize,
    bool? autoPrintAfterSave,
    bool? showBarcode,
    bool? showLogo,
    bool? showCustomerInfo,
    bool? showNotes,
    bool? showPaymentMethod,
    bool? showTaxDetails,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyTaxNumber,
    String? logoBase64,
    int? copies,
    String? footerMessage,
    bool? showProductDetails,
    bool? showInvoiceBarcode,
  }) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(
      defaultSize: defaultSize,
      autoPrintAfterSave: autoPrintAfterSave,
      showBarcode: showBarcode,
      showLogo: showLogo,
      showCustomerInfo: showCustomerInfo,
      showNotes: showNotes,
      showPaymentMethod: showPaymentMethod,
      showTaxDetails: showTaxDetails,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      companyTaxNumber: companyTaxNumber,
      logoBase64: logoBase64,
      copies: copies,
      footerMessage: footerMessage,
      showProductDetails: showProductDetails,
      showInvoiceBarcode: showInvoiceBarcode,
    );
    await saveSettings(updatedSettings);
  }

  /// الحصول على خيارات الطباعة (للاستخدام مع InvoicePdfGenerator)
  Future<InvoicePrintOptions> getPrintOptions() async {
    final settings = await getSettings();
    return settings.toInvoicePrintOptions();
  }

  /// الحصول على خيارات طباعة السندات (للاستخدام مع VoucherPdfGenerator)
  Future<VoucherPrintOptions> getVoucherPrintOptions({
    VoucherPrintSize? size,
  }) async {
    final settings = await getSettings();
    return settings.toVoucherPrintOptions(size: size);
  }

  /// مسح الإعدادات المُخزنة مؤقتاً (يُجبر إعادة القراءة)
  void clearCache() {
    _cachedSettings = null;
  }

  /// إعادة تعيين الإعدادات إلى القيم الافتراضية
  Future<void> resetToDefaults() async {
    await saveSettings(PrintSettings.defaultSettings);
  }

  /// التحقق من تفعيل الطباعة التلقائية
  Future<bool> isAutoPrintEnabled() async {
    final settings = await getSettings();
    return settings.autoPrintAfterSave;
  }

  /// الحصول على حجم الطباعة الافتراضي
  Future<InvoicePrintSize> getDefaultPrintSize() async {
    final settings = await getSettings();
    return settings.defaultSize;
  }

  /// حفظ معلومات الشركة
  Future<void> saveCompanyInfo({
    String? name,
    String? address,
    String? phone,
    String? taxNumber,
    String? logoBase64,
  }) async {
    await updateSetting(
      companyName: name,
      companyAddress: address,
      companyPhone: phone,
      companyTaxNumber: taxNumber,
      logoBase64: logoBase64,
    );
  }

  /// تنظيف الموارد
  @override
  void dispose() {
    stopRealtimeSync();
    _settingsController.close();
    super.dispose();
  }
}
