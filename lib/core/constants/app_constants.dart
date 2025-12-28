/// Application constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Hoor Manager';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String invoicesCollection = 'invoices';
  static const String invoiceItemsCollection = 'invoice_items';
  static const String inventoryMovementsCollection = 'inventory_movements';
  static const String shiftsCollection = 'shifts';
  static const String cashMovementsCollection = 'cash_movements';
  static const String customersCollection = 'customers';
  static const String suppliersCollection = 'suppliers';
  static const String settingsCollection = 'settings';
  static const String backupsCollection = 'backups';
  static const String syncLogCollection = 'sync_log';

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String pendingSyncBox = 'pending_sync';

  // Tax Rate
  static const double defaultTaxRate = 0.15; // 15% VAT

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayTimeFormat = 'HH:mm';

  // Currency
  static const String currencySymbol = 'ل.س';
  static const String currencyCode = 'SYP';

  // USD Currency
  static const String usdSymbol = '\$';
  static const String usdCode = 'USD';

  // Default Exchange Rate (USD to SYP)
  static const double defaultExchangeRate = 14500.0;

  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
}

/// Invoice Types
enum InvoiceType {
  sale('sale', 'فاتورة مبيعات'),
  purchase('purchase', 'فاتورة مشتريات'),
  saleReturn('sale_return', 'مرتجع مبيعات'),
  purchaseReturn('purchase_return', 'مرتجع مشتريات'),
  openingBalance('opening_balance', 'فاتورة أول المدة');

  final String value;
  final String label;
  const InvoiceType(this.value, this.label);
}

/// Inventory Movement Types
enum MovementType {
  add('add', 'إضافة'),
  withdraw('withdraw', 'سحب'),
  return_('return', 'مرتجع'),
  adjustment('adjustment', 'تعديل جرد'),
  sale('sale', 'بيع'),
  purchase('purchase', 'شراء');

  final String value;
  final String label;
  const MovementType(this.value, this.label);
}

/// Cash Movement Types
enum CashMovementType {
  income('income', 'إيراد'),
  expense('expense', 'مصروف'),
  sale('sale', 'مبيعات'),
  purchase('purchase', 'مشتريات'),
  opening('opening', 'رصيد افتتاحي'),
  closing('closing', 'رصيد إغلاق');

  final String value;
  final String label;
  const CashMovementType(this.value, this.label);
}

/// Payment Methods
enum PaymentMethod {
  cash('cash', 'نقدي'),
  card('card', 'بطاقة'),
  transfer('transfer', 'تحويل'),
  credit('credit', 'آجل');

  final String value;
  final String label;
  const PaymentMethod(this.value, this.label);
}

/// Sync Status
enum SyncStatus {
  pending('pending'),
  synced('synced'),
  failed('failed'),
  conflict('conflict');

  final String value;
  const SyncStatus(this.value);
}
