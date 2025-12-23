// lib/main.dart
// نقطة البداية للتطبيق - محسن ومصحح

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/products/providers/product_provider.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعدادات النظام
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  AppLogger.i('🚀 بدء تشغيل التطبيق...');

  // تهيئة الخدمات
  await _initializeServices();

  AppLogger.i('✅ التطبيق جاهز للتشغيل');

  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  // تهيئة التخزين المحلي
  AppLogger.startOperation('تهيئة التخزين المحلي');
  final localStorage = LocalStorageService();
  await localStorage.initialize();
  AppLogger.endOperation('تهيئة التخزين المحلي', success: true);

  // تهيئة Firebase
  AppLogger.startOperation('تهيئة Firebase');
  final firebaseService = FirebaseService();
  final result = await firebaseService.initialize();
  AppLogger.endOperation('تهيئة Firebase', success: result.success);

  // بدء مراقبة الاتصال
  ConnectivityService().startMonitoring();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // إعدادات اللغة العربية
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // الثيم
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // الشاشة الرئيسية
        home: const AuthWrapper(),
      ),
    );
  }
}

/// غلاف المصادقة
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() {
    ConnectivityService().checkConnectivity().then((isConnected) {
      if (!isConnected && mounted) {
        _showOfflineSnackbar();
      }
    });
  }

  void _showOfflineSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Text('أنت غير متصل بالإنترنت'),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _checkConnectivity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // جاري التحميل
        if (authProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'جاري التحميل...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // مسجل الدخول
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // غير مسجل الدخول
        return const LoginScreen();
      },
    );
  }
}
