import '../../../../core/utils/result.dart';
import '../entities/entities.dart';

/// واجهة مستودع الموردين
abstract class SupplierRepository {
  /// الحصول على جميع الموردين
  Stream<List<SupplierEntity>> watchSuppliers();

  /// الحصول على مورد بالمعرف
  Future<Result<SupplierEntity>> getSupplierById(String id);

  /// البحث عن الموردين
  Future<Result<List<SupplierEntity>>> searchSuppliers(String query);

  /// الحصول على الموردين النشطين
  Stream<List<SupplierEntity>> watchActiveSuppliers();

  /// الحصول على الموردين الذين لهم مستحقات
  Stream<List<SupplierEntity>> watchSuppliersWithDues();

  /// إضافة مورد جديد
  Future<Result<SupplierEntity>> addSupplier(SupplierEntity supplier);

  /// تحديث مورد
  Future<Result<SupplierEntity>> updateSupplier(SupplierEntity supplier);

  /// حذف مورد
  Future<Result<void>> deleteSupplier(String id);

  /// تحديث رصيد المورد
  Future<Result<void>> updateSupplierBalance({
    required String supplierId,
    required double amount,
    required bool isCredit, // true = إضافة للرصيد (نحن ندين له)، false = خصم
  });

  /// تحديث إحصائيات المورد بعد فاتورة شراء
  Future<Result<void>> updateSupplierStats({
    required String supplierId,
    required double invoiceAmount,
    required double paidAmount,
  });

  /// الحصول على الموردين حسب فئة المنتجات
  Future<Result<List<SupplierEntity>>> getSuppliersByCategory(
      String categoryId);

  /// تصدير الموردين إلى Excel
  Future<Result<String>> exportToExcel();

  /// استيراد الموردين من Excel
  Future<Result<int>> importFromExcel(String filePath);
}
