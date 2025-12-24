import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

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

  // سيتم إضافة المزيد من الخدمات هنا لاحقاً:
  // - Firebase Services
  // - Repositories
  // - Use Cases
  // - etc.

  sl<Logger>().i('✅ Service Locator initialized successfully');
}
