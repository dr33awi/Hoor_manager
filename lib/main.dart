import 'dart:ui' as ui;

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
import 'features/settings/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التطبيق
  await _initializeApp();

  runApp(
    const ProviderScope(
      child: HoorApp(),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // تحديث ألوان شريط النظام بناءً على الوضع
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.light,
        systemNavigationBarColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

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

          // الثيم
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // دعم اللغة العربية
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // إعداد الاتجاه RTL مع مؤشر الاتصال
          builder: (context, child) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Stack(
                children: [
                  child ?? const SizedBox(),
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
