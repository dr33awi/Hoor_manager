// lib/core/services/service_locator.dart
// 🎯 محدد الخدمات المركزي - إدارة موحدة لجميع الخدمات

import 'package:firebase_core/firebase_core.dart';

// الخدمات الأساسية
import 'base/logger_service.dart';

// خدمات البنية التحتية
import 'infrastructure/firebase_service.dart';
import 'infrastructure/local_storage_service.dart';
import 'infrastructure/connectivity_service.dart';

// خدمات الأعمال
import 'business/auth_service.dart';
import 'business/product_service.dart';
import 'business/sale_service.dart';

// الأدوات المساعدة
import 'business/barcode_service.dart';
import 'business/barcode_print_service.dart';
import 'business/print_service.dart';

/// 🎯 محدد الخدمات المركزي
/// يدير جميع الخدمات من مكان واحد ويمنع التكرار
class ServiceLocator {
  // ==================== Singleton ====================
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  /// الوصول السريع للـ instance
  static ServiceLocator get instance => _instance;
  static ServiceLocator get I => _instance;

  // ==================== حالة التهيئة ====================
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ==================== الخدمات ====================

  // خدمات البنية التحتية
  late final FirebaseService _firebaseService;
  late final LocalStorageService _localStorageService;
  late final ConnectivityService _connectivityService;

  // خدمات الأعمال
  late final AuthService _authService;
  late final ProductService _productService;
  late final SaleService _saleService;

  // خدمات الأدوات
  late final BarcodeService _barcodeService;
  late final BarcodePrintService _barcodePrintService;
  late final PrintService _printService;

  // ==================== Getters للخدمات ====================

  /// خدمة Firebase
  FirebaseService get firebase => _firebaseService;

  /// خدمة التخزين المحلي
  LocalStorageService get localStorage => _localStorageService;

  /// خدمة مراقبة الاتصال
  ConnectivityService get connectivity => _connectivityService;

  /// خدمة المصادقة
  AuthService get auth => _authService;

  /// خدمة المنتجات
  ProductService get products => _productService;

  /// خدمة المبيعات
  SaleService get sales => _saleService;

  /// خدمة الباركود
  BarcodeService get barcode => _barcodeService;

  /// خدمة طباعة الباركود
  BarcodePrintService get barcodePrint => _barcodePrintService;

  /// خدمة الطباعة
  PrintService get print => _printService;

  // ==================== التهيئة ====================

  /// تهيئة جميع الخدمات
  /// يجب استدعاؤها مرة واحدة عند بدء التطبيق
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.w('⚠️ ServiceLocator تم تهيئته مسبقاً');
      return;
    }

    AppLogger.startOperation('تهيئة ServiceLocator');

    try {
      // 1️⃣ تهيئة Firebase أولاً
      await _initializeFirebase();

      // 2️⃣ إنشاء الخدمات (Singletons)
      _createServices();

      // 3️⃣ تهيئة الخدمات التي تحتاج تهيئة
      await _initializeServices();

      // 4️⃣ بدء مراقبة الاتصال
      _connectivityService.startMonitoring();

      _isInitialized = true;
      AppLogger.endOperation('تهيئة ServiceLocator', success: true);
      AppLogger.s('✅ تم تهيئة جميع الخدمات بنجاح');
    } catch (e, stackTrace) {
      AppLogger.e(
        '❌ فشل تهيئة ServiceLocator',
        error: e,
        stackTrace: stackTrace,
      );
      AppLogger.endOperation('تهيئة ServiceLocator', success: false);
      rethrow;
    }
  }

  /// تهيئة Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      AppLogger.i('✅ Firebase initialized');
    } catch (e) {
      if (e.toString().contains('already been initialized')) {
        AppLogger.d('Firebase was already initialized');
      } else {
        rethrow;
      }
    }
  }

  /// إنشاء instances للخدمات
  void _createServices() {
    // خدمات البنية التحتية
    _firebaseService = FirebaseService();
    _localStorageService = LocalStorageService();
    _connectivityService = ConnectivityService();

    // خدمات الأعمال
    _authService = AuthService();
    _productService = ProductService();
    _saleService = SaleService();

    // خدمات الأدوات
    _barcodeService = BarcodeService();
    _barcodePrintService = BarcodePrintService();
    _printService = PrintService();
  }

  /// تهيئة الخدمات التي تحتاج تهيئة async
  Future<void> _initializeServices() async {
    // تهيئة Firebase Service
    final firebaseResult = await _firebaseService.initialize();
    if (!firebaseResult.success) {
      AppLogger.w(
        '⚠️ Firebase Service initialization warning: ${firebaseResult.error}',
      );
    }

    // تهيئة التخزين المحلي
    final storageResult = await _localStorageService.initialize();
    if (!storageResult.success) {
      AppLogger.w(
        '⚠️ Local Storage initialization warning: ${storageResult.error}',
      );
    }
  }

  // ==================== إعادة التعيين ====================

  /// إعادة تعيين جميع الخدمات (للاختبارات أو تسجيل الخروج)
  Future<void> reset() async {
    AppLogger.startOperation('إعادة تعيين ServiceLocator');

    try {
      // إيقاف مراقبة الاتصال
      _connectivityService.stopMonitoring();

      // مسح المستخدم من Auth Service
      _authService.setCurrentUser(null);

      AppLogger.endOperation('إعادة تعيين ServiceLocator', success: true);
    } catch (e) {
      AppLogger.e('خطأ في إعادة تعيين ServiceLocator', error: e);
      AppLogger.endOperation('إعادة تعيين ServiceLocator', success: false);
    }
  }

  /// تنظيف الموارد عند إغلاق التطبيق
  void dispose() {
    _connectivityService.dispose();
    AppLogger.i('🧹 تم تنظيف موارد ServiceLocator');
  }

  // ==================== طرق مساعدة ====================

  /// التحقق من حالة الاتصال
  bool get isOnline => _connectivityService.isConnected;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _authService.currentUserId;

  /// هل المستخدم مسجل الدخول؟
  bool get isAuthenticated => _authService.isAuthenticated;
}

// ==================== اختصارات سريعة ====================

/// اختصار للوصول السريع لـ ServiceLocator
ServiceLocator get sl => ServiceLocator.instance;

/// اختصار لخدمة Firebase
FirebaseService get firebaseService => sl.firebase;

/// اختصار لخدمة المصادقة
AuthService get authService => sl.auth;

/// اختصار لخدمة المنتجات
ProductService get productService => sl.products;

/// اختصار لخدمة المبيعات
SaleService get saleService => sl.sales;

/// اختصار لخدمة الباركود
BarcodeService get barcodeService => sl.barcode;

/// اختصار لخدمة طباعة الباركود
BarcodePrintService get barcodePrintService => sl.barcodePrint;

/// اختصار لخدمة الطباعة
PrintService get printService => sl.print;

/// اختصار لخدمة التخزين المحلي
LocalStorageService get localStorageService => sl.localStorage;

/// اختصار لخدمة مراقبة الاتصال
ConnectivityService get connectivityService => sl.connectivity;
