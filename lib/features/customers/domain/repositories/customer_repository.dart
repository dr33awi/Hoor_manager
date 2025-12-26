import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع العملاء
abstract class CustomerRepository {
  /// الحصول على جميع العملاء
  Stream<List<CustomerEntity>> watchCustomers();

  /// الحصول على عميل بالمعرف
  Future<Result<CustomerEntity>> getCustomerById(String id);

  /// البحث عن العملاء
  Future<Result<List<CustomerEntity>>> searchCustomers(String query);

  /// الحصول على العملاء حسب النوع
  Stream<List<CustomerEntity>> watchCustomersByType(CustomerType type);

  /// الحصول على العملاء الذين عليهم مستحقات
  Stream<List<CustomerEntity>> watchCustomersWithDues();

  /// إضافة عميل جديد
  Future<Result<CustomerEntity>> addCustomer(CustomerEntity customer);

  /// تحديث عميل
  Future<Result<CustomerEntity>> updateCustomer(CustomerEntity customer);

  /// حذف عميل
  Future<Result<void>> deleteCustomer(String id);

  /// تحديث رصيد العميل
  Future<Result<void>> updateCustomerBalance({
    required String customerId,
    required double amount,
    required bool isCredit, // true = إضافة للرصيد، false = خصم
  });

  /// تحديث إحصائيات العميل بعد فاتورة
  Future<Result<void>> updateCustomerStats({
    required String customerId,
    required double invoiceAmount,
    required double paidAmount,
  });

  /// الحصول على آخر سعر للعميل لمنتج معين
  Future<Result<double?>> getLastPriceForCustomer({
    required String customerId,
    required String productId,
  });

  /// تصدير العملاء إلى Excel
  Future<Result<String>> exportToExcel();

  /// استيراد العملاء من Excel
  Future<Result<int>> importFromExcel(String filePath);
}
