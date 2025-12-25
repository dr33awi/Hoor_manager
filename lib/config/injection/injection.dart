import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../core/services/offline_service.dart';
import '../../core/services/backup_service.dart';
import '../../features/products/data/services/stock_management_service.dart';

/// Service Locator الرئيسي للتطبيق
final GetIt sl = GetIt.instance;

/// تهيئة جميع الخدمات
Future<void> setupServiceLocator() async {
  // Logger
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    ),
  );

  // خدمة العمل بدون إنترنت
  sl.registerLazySingleton<OfflineService>(() => OfflineService());

  // خدمة النسخ الاحتياطي
  sl.registerLazySingleton<BackupService>(() => BackupService());

  // خدمة إدارة المخزون
  sl.registerLazySingleton<StockManagementService>(
      () => StockManagementService());

  sl<Logger>().i('✅ Service Locator initialized successfully');
}
