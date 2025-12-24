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
class HoorApp extends StatelessWidget {
  const HoorApp({super.key});

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

          // الثيم
          theme: AppTheme.lightTheme,

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

          // إعداد الاتجاه RTL
          builder: (context, child) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: child ?? const SizedBox(),
            );
          },

          // التوجيه
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
