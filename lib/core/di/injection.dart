import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/backup_service.dart';
import '../services/currency_service.dart';
import '../services/print_settings_service.dart';
import '../services/accounting_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/cash_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/voucher_repository.dart';
import '../../data/repositories/warehouse_repository.dart';
import '../../data/repositories/inventory_count_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Firebase
  await Firebase.initializeApp();

  // External Services
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<Connectivity>(Connectivity());

  // Database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Core Services
  getIt.registerSingleton<ConnectivityService>(
    ConnectivityService(getIt<Connectivity>()),
  );

  // Repositories
  getIt.registerSingleton<ProductRepository>(
    ProductRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<CategoryRepository>(
    CategoryRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<InvoiceRepository>(
    InvoiceRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<InventoryRepository>(
    InventoryRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<ShiftRepository>(
    ShiftRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<CashRepository>(
    CashRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<CustomerRepository>(
    CustomerRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<SupplierRepository>(
    SupplierRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // Currency Service
  getIt.registerSingleton<CurrencyService>(
    CurrencyService(getIt<SharedPreferences>()),
  );

  // Voucher Repository (after CurrencyService)
  getIt.registerSingleton<VoucherRepository>(
    VoucherRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
      currencyService: getIt<CurrencyService>(),
    ),
  );

  // Print Settings Service (before SyncService)
  getIt.registerSingleton<PrintSettingsService>(
    PrintSettingsService(
      getIt<AppDatabase>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  // Sync Service
  getIt.registerSingleton<SyncService>(
    SyncService(
      connectivity: getIt<ConnectivityService>(),
      productRepo: getIt<ProductRepository>(),
      categoryRepo: getIt<CategoryRepository>(),
      invoiceRepo: getIt<InvoiceRepository>(),
      inventoryRepo: getIt<InventoryRepository>(),
      shiftRepo: getIt<ShiftRepository>(),
      cashRepo: getIt<CashRepository>(),
      customerRepo: getIt<CustomerRepository>(),
      supplierRepo: getIt<SupplierRepository>(),
      voucherRepo: getIt<VoucherRepository>(),
      printSettingsService: getIt<PrintSettingsService>(),
    ),
  );

  // Backup Service
  getIt.registerSingleton<BackupService>(
    BackupService(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // Warehouse Repository
  getIt.registerSingleton<WarehouseRepository>(
    WarehouseRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // Inventory Count Repository
  getIt.registerSingleton<InventoryCountRepository>(
    InventoryCountRepository(
      database: getIt<AppDatabase>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Accounting Service - خدمة المحاسبة الموحدة
  // ═══════════════════════════════════════════════════════════════════════════
  getIt.registerSingleton<AccountingService>(
    AccountingService(
      database: getIt<AppDatabase>(),
      currencyService: getIt<CurrencyService>(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // تكامل الخدمات - ربط الـ Repositories ببعضها البعض
  // ═══════════════════════════════════════════════════════════════════════════

  // تكامل InvoiceRepository مع Cash, Customer, Supplier, Inventory
  getIt<InvoiceRepository>().setIntegrationRepositories(
    cashRepo: getIt<CashRepository>(),
    customerRepo: getIt<CustomerRepository>(),
    supplierRepo: getIt<SupplierRepository>(),
    inventoryRepo: getIt<InventoryRepository>(),
  );

  // تكامل VoucherRepository مع Customer, Supplier
  getIt<VoucherRepository>().setIntegrationRepositories(
    customerRepo: getIt<CustomerRepository>(),
    supplierRepo: getIt<SupplierRepository>(),
  );
}
