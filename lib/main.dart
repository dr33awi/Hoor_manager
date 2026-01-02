// ═══════════════════════════════════════════════════════════════════════════
// Hoor Manager Pro - Main Entry Point
// Professional Accounting & Sales Management System
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router_pro.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies (Firebase, Database, Services)
  await configureDependencies();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Preload fonts
  await _preloadFonts();

  runApp(
    const ProviderScope(
      child: HoorManagerPro(),
    ),
  );
}

/// Preload Google Fonts for smoother experience
Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.cairo(),
      GoogleFonts.jetBrainsMono(),
    ]);
  } catch (e) {
    debugPrint('Font preloading failed: $e');
  }
}

class HoorManagerPro extends ConsumerWidget {
  const HoorManagerPro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProProvider);

    return ScreenUtilInit(
      // iPhone 13 design size
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Hoor Manager Pro',
          debugShowCheckedModeBanner: false,

          // ═══════════════════════════════════════════════════════════════════
          // Localization
          // ═══════════════════════════════════════════════════════════════════
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ═══════════════════════════════════════════════════════════════════
          // Theme
          // ═══════════════════════════════════════════════════════════════════
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light, // TODO: Make this configurable

          // ═══════════════════════════════════════════════════════════════════
          // Router
          // ═══════════════════════════════════════════════════════════════════
          routerConfig: router,

          // ═══════════════════════════════════════════════════════════════════
          // Builder for global configurations
          // ═══════════════════════════════════════════════════════════════════
          builder: (context, child) {
            // Ensure RTL text direction
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                // Prevent system font scaling from breaking layouts
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
