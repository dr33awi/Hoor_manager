import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app/constants/app_constants.dart';

// الجداول
part 'database.g.dart';

/// جدول التصنيفات
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// جدول المنتجات
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable().unique()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  RealColumn get wholesalePrice => real().nullable()();
  RealColumn get qty => real().withDefault(const Constant(0.0))();
  RealColumn get minQty => real().withDefault(const Constant(0.0))();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get unit => text().withDefault(const Constant('قطعة'))();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// جدول حركات المخزون
class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get type =>
      text()(); // OPENING, SALE, PURCHASE, RETURN_SALE, RETURN_PURCHASE, ADJUSTMENT
  RealColumn get qty => real()();
  RealColumn get qtyBefore => real()();
  RealColumn get qtyAfter => real()();
  RealColumn get unitPrice => real().nullable()();
  TextColumn get refType => text().nullable()(); // INVOICE, VOUCHER, MANUAL
  IntColumn get refId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// جدول الأطراف (العملاء والموردين)
class Parties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // CUSTOMER, SUPPLIER
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().nullable()();
  TextColumn get phone2 => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit => real().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// جدول الفواتير
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().unique()();
  TextColumn get type =>
      text()(); // SALE, PURCHASE, RETURN_SALE, RETURN_PURCHASE
  IntColumn get partyId => integer().nullable().references(Parties, #id)();
  TextColumn get status => text().withDefault(
      const Constant('COMPLETED'))(); // DRAFT, PENDING, COMPLETED, CANCELLED
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();
  IntColumn get cashAccountId =>
      integer().nullable().references(CashAccounts, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get invoiceDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// جدول بنود الفاتورة
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get qty => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()();
  TextColumn get note => text().nullable()();
}

/// جدول السندات (قبض/صرف)
class Vouchers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().unique()();
  TextColumn get type => text()(); // RECEIPT, PAYMENT
  IntColumn get partyId => integer().nullable().references(Parties, #id)();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();
  IntColumn get cashAccountId =>
      integer().nullable().references(CashAccounts, #id)();
  IntColumn get invoiceId => integer().nullable().references(Invoices, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get voucherDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// جدول الصناديق والبنوك
class CashAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type =>
      text().withDefault(const Constant('CASH'))(); // CASH, BANK
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// جدول حركات الصندوق
class CashMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashAccountId => integer().references(CashAccounts, #id)();
  TextColumn get type => text()(); // IN, OUT
  RealColumn get amount => real()();
  RealColumn get balanceBefore => real()();
  RealColumn get balanceAfter => real()();
  TextColumn get refType => text().nullable()(); // INVOICE, VOUCHER, MANUAL
  IntColumn get refId => integer().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// جدول الجرد
class InventoryCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().unique()();
  TextColumn get status => text().withDefault(
      const Constant('PENDING'))(); // PENDING, COMPLETED, CANCELLED
  TextColumn get note => text().nullable()();
  DateTimeColumn get countDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// جدول بنود الجرد
class InventoryCountItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get countId =>
      integer().references(InventoryCounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get systemQty => real()();
  RealColumn get actualQty => real()();
  RealColumn get difference => real()();
  TextColumn get note => text().nullable()();
}

/// جدول الإعدادات
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  TextColumn get type => text().withDefault(
      const Constant('STRING'))(); // STRING, INT, DOUBLE, BOOL, JSON
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// جدول سجل العمليات
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableNameRef => text()();
  IntColumn get recordId => integer()();
  TextColumn get action => text()(); // INSERT, UPDATE, DELETE
  TextColumn get oldData => text().nullable()();
  TextColumn get newData => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// قاعدة البيانات الرئيسية
@DriftDatabase(tables: [
  Categories,
  Products,
  InventoryMovements,
  Parties,
  Invoices,
  InvoiceItems,
  Vouchers,
  CashAccounts,
  CashMovements,
  InventoryCounts,
  InventoryCountItems,
  Settings,
  AuditLog,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => AppConstants.dbVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // إضافة البيانات الأولية
        await _seedData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ترقية قاعدة البيانات
      },
    );
  }

  /// إضافة البيانات الأولية
  Future<void> _seedData() async {
    // إضافة صندوق افتراضي
    await into(cashAccounts).insert(
      CashAccountsCompanion.insert(
        name: 'الصندوق الرئيسي',
        type: const Value('CASH'),
        isDefault: const Value(true),
      ),
    );

    // إضافة تصنيف افتراضي
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'عام',
      ),
    );

    // إضافة الإعدادات الافتراضية
    final defaultSettings = [
      {'key': 'store_name', 'value': 'متجري', 'type': 'STRING'},
      {'key': 'store_phone', 'value': '', 'type': 'STRING'},
      {'key': 'store_address', 'value': '', 'type': 'STRING'},
      {'key': 'tax_rate', 'value': '15', 'type': 'DOUBLE'},
      {'key': 'currency', 'value': 'SAR', 'type': 'STRING'},
      {'key': 'printer_type', 'value': 'wifi', 'type': 'STRING'},
      {'key': 'printer_ip', 'value': '', 'type': 'STRING'},
      {'key': 'printer_port', 'value': '9100', 'type': 'INT'},
      {'key': 'auto_print', 'value': 'false', 'type': 'BOOL'},
      {'key': 'invoice_number_prefix', 'value': 'INV', 'type': 'STRING'},
      {'key': 'voucher_number_prefix', 'value': 'VCH', 'type': 'STRING'},
    ];

    for (final setting in defaultSettings) {
      await into(settings).insert(
        SettingsCompanion.insert(
          key: setting['key']!,
          value: setting['value']!,
          type: Value(setting['type']!),
        ),
      );
    }
  }
}

/// فتح اتصال قاعدة البيانات
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.dbName));
    return NativeDatabase.createInBackground(file);
  });
}
