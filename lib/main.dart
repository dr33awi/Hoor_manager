import 'dart:ui' as ui;

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/injection/injection.dart';
import 'config/routes/app_router.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/offline_service.dart';
import 'features/products/presentation/providers/product_providers.dart';
import 'features/sales/presentation/providers/sales_providers.dart';
import 'features/customers/presentation/providers/customer_providers.dart';
import 'features/suppliers/presentation/providers/supplier_providers.dart';
import 'features/purchases/presentation/providers/purchase_providers.dart';
import 'features/payments/presentation/providers/payment_providers.dart';
import 'features/inventory/presentation/providers/inventory_providers.dart';
import 'features/accounts/presentation/providers/account_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التطبيق
  await _initializeApp();

  runApp(
    DevicePreview(
      // تفعيل في وضع Debug فقط
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(
        child: HoorApp(),
      ),
    ),
  );
}

/// تهيئة التطبيق
Future<void> _initializeApp() async {
  // تهيئة Firebase
  await Firebase.initializeApp();

  // تهيئة اللغة العربية للتواريخ والأرقام
  await initializeDateFormatting('ar', null);
  Intl.defaultLocale = 'ar';

  // تهيئة Service Locator
  await setupServiceLocator();

  // تهيئة خدمة التخزين المحلي
  await StorageService().init();

  // تهيئة خدمة العمل بدون إنترنت
  await OfflineService().initialize();

  // إعداد اتجاه الشاشة (Portrait فقط)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // إعداد لون شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// التطبيق الرئيسي
class HoorApp extends ConsumerStatefulWidget {
  const HoorApp({super.key});

  @override
  ConsumerState<HoorApp> createState() => _HoorAppState();
}

class _HoorAppState extends ConsumerState<HoorApp> {
  @override
  void initState() {
    super.initState();
    // تهيئة الـ repositories لتسجيل callbacks المزامنة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRepositories();
    });
  }

  /// تهيئة الـ repositories لتسجيل callbacks المزامنة
  void _initializeRepositories() {
    // قراءة الـ repositories لتفعيل callbacks
    ref.read(productRepositoryProvider);
    ref.read(salesRepositoryProvider);
    ref.read(customerRepositoryProvider);
    ref.read(supplierRepositoryProvider);
    ref.read(purchaseRepositoryProvider);
    ref.read(paymentRepositoryProvider);
    ref.read(inventoryRepositoryProvider);
    ref.read(accountRepositoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // أبعاد التصميم الأساسية (iPhone 14)
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          // إعدادات أساسية
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,

          // دعم DevicePreview
          useInheritedMediaQuery: true,

          // الثيم
          theme: AppTheme.lightTheme,

          // دعم اللغة العربية
          locale: DevicePreview.locale(context) ?? const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // إعداد الاتجاه RTL مع مؤشر الاتصال ودعم DevicePreview
          builder: (context, child) {
            // دمج DevicePreview.appBuilder مع الـ builder المخصص
            final devicePreviewChild = DevicePreview.appBuilder(context, child);
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Stack(
                children: [
                  devicePreviewChild,
                  // مؤشر حالة الاتصال
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: ConnectivityBanner(),
                    ),
                  ),
                ],
              ),
            );
          },

          // التوجيه
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
