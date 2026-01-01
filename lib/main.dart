/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Manager - Main Entry Point
/// Modern Accounting & Sales Management System
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: HoorManagerApp(),
    ),
  );
}

class HoorManagerApp extends ConsumerWidget {
  const HoorManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Hoor Manager',
          debugShowCheckedModeBanner: false,

          // Theme Configuration
          theme: HoorTheme.light,
          darkTheme: HoorTheme.dark,
          themeMode: ThemeMode.light,

          // RTL Support for Arabic
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Router Configuration
          routerConfig: router,
        );
      },
    );
  }
}
