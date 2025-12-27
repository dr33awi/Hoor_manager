/// ثوابت التطبيق
class AppConstants {
  // اسم التطبيق
  static const String appName = 'تاجر';
  static const String appVersion = '1.0.0';
  
  // قاعدة البيانات
  static const String dbName = 'tajer_database.db';
  static const int dbVersion = 1;
  
  // الطباعة
  static const int defaultPrinterPort = 9100;
  static const int printerTimeout = 5; // ثواني
  
  // التنسيق
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  
  // الأرقام
  static const int decimalPlaces = 2;
  static const String currencySymbol = 'ر.س';
  static const String currencyCode = 'SAR';
  
  // الصفحات
  static const int defaultPageSize = 20;
  
  // الباركود
  static const int barcodeLength = 13;
  
  // SKU
  static const String skuPrefix = 'SKU';
  
  // أنواع الفواتير
  static const String invoiceTypeSale = 'SALE';
  static const String invoiceTypePurchase = 'PURCHASE';
  static const String invoiceTypeReturnSale = 'RETURN_SALE';
  static const String invoiceTypeReturnPurchase = 'RETURN_PURCHASE';
  
  // أنواع حركة المخزون
  static const String movementTypeOpening = 'OPENING';
  static const String movementTypeSale = 'SALE';
  static const String movementTypePurchase = 'PURCHASE';
  static const String movementTypeReturnSale = 'RETURN_SALE';
  static const String movementTypeReturnPurchase = 'RETURN_PURCHASE';
  static const String movementTypeAdjustment = 'ADJUSTMENT';
  static const String movementTypeTransfer = 'TRANSFER';
  
  // أنواع الأطراف (العملاء/الموردين)
  static const String partyTypeCustomer = 'CUSTOMER';
  static const String partyTypeSupplier = 'SUPPLIER';
  
  // أنواع السندات
  static const String voucherTypeReceipt = 'RECEIPT';
  static const String voucherTypePayment = 'PAYMENT';
  
  // طرق الدفع
  static const String paymentMethodCash = 'CASH';
  static const String paymentMethodCard = 'CARD';
  static const String paymentMethodTransfer = 'TRANSFER';
  
  // حالات الفاتورة
  static const String invoiceStatusDraft = 'DRAFT';
  static const String invoiceStatusPending = 'PENDING';
  static const String invoiceStatusCompleted = 'COMPLETED';
  static const String invoiceStatusCancelled = 'CANCELLED';
}

/// رسائل التطبيق
class AppMessages {
  // عام
  static const String loading = 'جاري التحميل...';
  static const String saving = 'جاري الحفظ...';
  static const String deleting = 'جاري الحذف...';
  static const String searching = 'جاري البحث...';
  
  // النجاح
  static const String savedSuccessfully = 'تم الحفظ بنجاح';
  static const String deletedSuccessfully = 'تم الحذف بنجاح';
  static const String updatedSuccessfully = 'تم التحديث بنجاح';
  static const String printedSuccessfully = 'تمت الطباعة بنجاح';
  
  // الأخطاء
  static const String errorOccurred = 'حدث خطأ';
  static const String networkError = 'خطأ في الاتصال';
  static const String notFound = 'غير موجود';
  static const String invalidData = 'بيانات غير صالحة';
  static const String insufficientStock = 'الكمية غير كافية';
  static const String printerNotConnected = 'الطابعة غير متصلة';
  
  // التأكيدات
  static const String confirmDelete = 'هل تريد الحذف؟';
  static const String confirmCancel = 'هل تريد الإلغاء؟';
  static const String confirmSave = 'هل تريد الحفظ؟';
  static const String unsavedChanges = 'يوجد تغييرات غير محفوظة';
  
  // الفواتير
  static const String invoiceSaved = 'تم حفظ الفاتورة';
  static const String invoicePrinted = 'تمت طباعة الفاتورة';
  static const String noItems = 'لا توجد أصناف';
  static const String selectCustomer = 'اختر العميل';
  static const String selectSupplier = 'اختر المورد';
  
  // المخزون
  static const String lowStock = 'كمية منخفضة';
  static const String outOfStock = 'نفد المخزون';
  static const String stockUpdated = 'تم تحديث المخزون';
  
  // البحث
  static const String noResults = 'لا توجد نتائج';
  static const String searchHint = 'ابحث هنا...';
  static const String scanBarcode = 'امسح الباركود';
}

/// أيقونات التطبيق (Phosphor Icons Names)
class AppIcons {
  static const String home = 'house';
  static const String sales = 'shopping-cart';
  static const String purchases = 'package';
  static const String returns = 'arrow-u-up-left';
  static const String products = 'cube';
  static const String categories = 'squares-four';
  static const String inventory = 'warehouse';
  static const String customers = 'users';
  static const String suppliers = 'truck';
  static const String vouchers = 'receipt';
  static const String reports = 'chart-bar';
  static const String settings = 'gear';
  static const String search = 'magnifying-glass';
  static const String add = 'plus';
  static const String edit = 'pencil';
  static const String delete = 'trash';
  static const String print = 'printer';
  static const String save = 'floppy-disk';
  static const String barcode = 'barcode';
  static const String camera = 'camera';
  static const String money = 'money';
  static const String calendar = 'calendar';
  static const String filter = 'funnel';
  static const String sort = 'sort-ascending';
  static const String menu = 'list';
  static const String close = 'x';
  static const String check = 'check';
  static const String warning = 'warning';
  static const String error = 'x-circle';
  static const String info = 'info';
  static const String question = 'question';
}
