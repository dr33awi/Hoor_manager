/// النصوص الثابتة في التطبيق
class AppStrings {
  AppStrings._();

  // اسم التطبيق
  static const String appName = 'Hoor';
  static const String appNameAr = 'حور';
  static const String appTagline = 'متجر الأحذية النسائية والولادية';

  // المصادقة
  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String resetPassword = 'استعادة كلمة المرور';
  static const String orLoginWith = 'أو سجل الدخول بواسطة';
  static const String loginWithGoogle = 'تسجيل الدخول بواسطة Google';
  static const String noAccount = 'ليس لديك حساب؟';
  static const String haveAccount = 'لديك حساب بالفعل؟';
  static const String fullName = 'الاسم الكامل';
  static const String phone = 'رقم الهاتف';

  // الصلاحيات
  static const String founder = 'مؤسس';
  static const String manager = 'مدير';
  static const String employee = 'موظف';
  static const String pendingApproval = 'في انتظار الموافقة';
  static const String accountApproved = 'تم تفعيل الحساب';
  static const String accountRejected = 'تم رفض الحساب';

  // التنقل
  static const String home = 'الرئيسية';
  static const String products = 'المنتجات';
  static const String sales = 'المبيعات';
  static const String reports = 'التقارير';
  static const String settings = 'الإعدادات';

  // المنتجات
  static const String addProduct = 'إضافة منتج';
  static const String editProduct = 'تعديل المنتج';
  static const String deleteProduct = 'حذف المنتج';
  static const String productName = 'اسم المنتج';
  static const String productPrice = 'السعر';
  static const String productCost = 'التكلفة';
  static const String productCategory = 'الفئة';
  static const String productColors = 'الألوان';
  static const String productSizes = 'المقاسات';
  static const String productStock = 'المخزون';
  static const String productBarcode = 'الباركود';
  static const String lowStock = 'مخزون منخفض';
  static const String outOfStock = 'نفد المخزون';

  // المبيعات
  static const String newSale = 'بيع جديد';
  static const String invoice = 'فاتورة';
  static const String invoices = 'الفواتير';
  static const String total = 'المجموع';
  static const String subtotal = 'المجموع الفرعي';
  static const String discount = 'الخصم';
  static const String discountPercent = 'خصم نسبة';
  static const String discountFixed = 'خصم ثابت';
  static const String paymentMethod = 'طريقة الدفع';
  static const String cash = 'نقدي';
  static const String cancelInvoice = 'إلغاء الفاتورة';
  static const String printInvoice = 'طباعة الفاتورة';
  static const String downloadPdf = 'تحميل PDF';

  // التقارير
  static const String dailyReport = 'تقرير يومي';
  static const String monthlyReport = 'تقرير شهري';
  static const String salesReport = 'تقرير المبيعات';
  static const String profitReport = 'تقرير الأرباح';
  static const String stockReport = 'تقرير المخزون';
  static const String topProducts = 'الأكثر مبيعاً';

  // الأزرار العامة
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String search = 'بحث';
  static const String filter = 'تصفية';
  static const String confirm = 'تأكيد';
  static const String back = 'رجوع';
  static const String next = 'التالي';
  static const String done = 'تم';
  static const String close = 'إغلاق';
  static const String retry = 'إعادة المحاولة';
  static const String refresh = 'تحديث';

  // الرسائل
  static const String loading = 'جاري التحميل...';
  static const String error = 'حدث خطأ';
  static const String success = 'تمت العملية بنجاح';
  static const String noData = 'لا توجد بيانات';
  static const String noProducts = 'لا توجد منتجات';
  static const String noSales = 'لا توجد مبيعات';
  static const String confirmDelete = 'هل أنت متأكد من الحذف؟';
  static const String deleteWarning = 'لا يمكن التراجع عن هذا الإجراء';
  static const String networkError = 'تحقق من اتصالك بالإنترنت';
  static const String sessionExpired = 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';

  // التحقق
  static const String required = 'هذا الحقل مطلوب';
  static const String invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String invalidPassword = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  static const String passwordMismatch = 'كلمات المرور غير متطابقة';
  static const String invalidPhone = 'رقم الهاتف غير صحيح';
}
