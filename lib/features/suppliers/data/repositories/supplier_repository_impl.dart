import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع الموردين
class SupplierRepositoryImpl implements SupplierRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

  SupplierRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// مرجع مجموعة الموردين
  CollectionReference<Map<String, dynamic>> get _suppliersCollection =>
      _firestore.collection('suppliers');

  @override
  Stream<List<SupplierEntity>> watchSuppliers() {
    return _suppliersCollection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SupplierModel.fromDocument(doc)).toList());
  }

  @override
  Future<Result<SupplierEntity>> getSupplierById(String id) async {
    try {
      final doc = await _suppliersCollection.doc(id).get();
      if (!doc.exists) {
        return Failure('المورد غير موجود');
      }
      return Success(SupplierModel.fromDocument(doc));
    } catch (e) {
      _logger.e('Error getting supplier: $e');
      return Failure('خطأ في جلب بيانات المورد');
    }
  }

  @override
  Future<Result<List<SupplierEntity>>> searchSuppliers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _suppliersCollection
          .where('searchTerms', arrayContains: queryLower)
          .limit(20)
          .get();

      final suppliers =
          snapshot.docs.map((doc) => SupplierModel.fromDocument(doc)).toList();
      return Success(suppliers);
    } catch (e) {
      _logger.e('Error searching suppliers: $e');
      return Failure('خطأ في البحث');
    }
  }

  @override
  Stream<List<SupplierEntity>> watchActiveSuppliers() {
    return _suppliersCollection
        .where('status', isEqualTo: SupplierStatus.active.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplierModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<SupplierEntity>> watchSuppliersWithDues() {
    return _suppliersCollection
        .where('balance', isGreaterThan: 0)
        .orderBy('balance', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplierModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<SupplierEntity>> addSupplier(SupplierEntity supplier) async {
    try {
      final model = SupplierModel.fromEntity(supplier);
      final docRef = await _suppliersCollection.add(model.toMap());

      final newSupplier = supplier.copyWith(id: docRef.id);
      _logger.i('Supplier added: ${docRef.id}');
      return Success(newSupplier);
    } catch (e) {
      _logger.e('Error adding supplier: $e');
      return Failure('خطأ في إضافة المورد');
    }
  }

  @override
  Future<Result<SupplierEntity>> updateSupplier(SupplierEntity supplier) async {
    try {
      final model = SupplierModel.fromEntity(supplier);
      await _suppliersCollection.doc(supplier.id).update(model.toUpdateMap());

      _logger.i('Supplier updated: ${supplier.id}');
      return Success(supplier);
    } catch (e) {
      _logger.e('Error updating supplier: $e');
      return Failure('خطأ في تحديث المورد');
    }
  }

  @override
  Future<Result<void>> deleteSupplier(String id) async {
    try {
      await _suppliersCollection.doc(id).delete();
      _logger.i('Supplier deleted: $id');
      return Success(null);
    } catch (e) {
      _logger.e('Error deleting supplier: $e');
      return Failure('خطأ في حذف المورد');
    }
  }

  @override
  Future<Result<void>> updateSupplierBalance({
    required String supplierId,
    required double amount,
    required bool isCredit,
  }) async {
    try {
      final adjustment = isCredit ? amount : -amount;
      await _suppliersCollection.doc(supplierId).update({
        'balance': FieldValue.increment(adjustment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Success(null);
    } catch (e) {
      _logger.e('Error updating balance: $e');
      return Failure('خطأ في تحديث الرصيد');
    }
  }

  @override
  Future<Result<void>> updateSupplierStats({
    required String supplierId,
    required double invoiceAmount,
    required double paidAmount,
  }) async {
    try {
      final balanceChange = invoiceAmount - paidAmount;
      await _suppliersCollection.doc(supplierId).update({
        'totalPurchases': FieldValue.increment(invoiceAmount),
        'totalPayments': FieldValue.increment(paidAmount),
        'balance': FieldValue.increment(balanceChange),
        'purchaseOrdersCount': FieldValue.increment(1),
        'lastPurchaseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Success(null);
    } catch (e) {
      _logger.e('Error updating stats: $e');
      return Failure('خطأ في تحديث الإحصائيات');
    }
  }

  @override
  Future<Result<List<SupplierEntity>>> getSuppliersByCategory(
      String categoryId) async {
    try {
      final snapshot = await _suppliersCollection
          .where('productCategories', arrayContains: categoryId)
          .where('status', isEqualTo: SupplierStatus.active.name)
          .get();

      final suppliers =
          snapshot.docs.map((doc) => SupplierModel.fromDocument(doc)).toList();
      return Success(suppliers);
    } catch (e) {
      _logger.e('Error getting suppliers by category: $e');
      return Failure('خطأ في جلب الموردين');
    }
  }

  @override
  Future<Result<String>> exportToExcel() async {
    try {
      final snapshot = await _suppliersCollection.orderBy('name').get();
      final suppliers =
          snapshot.docs.map((doc) => SupplierModel.fromDocument(doc)).toList();

      final excel = Excel.createExcel();
      final sheet = excel['الموردين'];

      // العناوين
      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('الشخص المسؤول'),
        TextCellValue('الهاتف'),
        TextCellValue('البريد'),
        TextCellValue('العنوان'),
        TextCellValue('الرقم الضريبي'),
        TextCellValue('التقييم'),
        TextCellValue('الرصيد'),
        TextCellValue('إجمالي المشتريات'),
      ]);

      // البيانات
      for (final supplier in suppliers) {
        sheet.appendRow([
          TextCellValue(supplier.name),
          TextCellValue(supplier.contactPerson ?? ''),
          TextCellValue(supplier.phone ?? ''),
          TextCellValue(supplier.email ?? ''),
          TextCellValue(supplier.address ?? ''),
          TextCellValue(supplier.taxNumber ?? ''),
          TextCellValue(_getRatingArabic(supplier.rating)),
          DoubleCellValue(supplier.balance),
          DoubleCellValue(supplier.totalPurchases),
        ]);
      }

      // حفظ الملف
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/suppliers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return Success(filePath);
    } catch (e) {
      _logger.e('Error exporting to Excel: $e');
      return Failure('خطأ في تصدير البيانات');
    }
  }

  @override
  Future<Result<int>> importFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      int imported = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        final supplier = SupplierEntity(
          id: '',
          name: row[0]?.value?.toString() ?? '',
          contactPerson: row[1]?.value?.toString(),
          phone: row[2]?.value?.toString(),
          email: row[3]?.value?.toString(),
          address: row[4]?.value?.toString(),
          taxNumber: row[5]?.value?.toString(),
          rating: _parseRating(row[6]?.value?.toString()),
          createdAt: DateTime.now(),
        );

        final result = await addSupplier(supplier);
        if (result.isSuccess) imported++;
      }

      return Success(imported);
    } catch (e) {
      _logger.e('Error importing from Excel: $e');
      return Failure('خطأ في استيراد البيانات');
    }
  }

  String _getRatingArabic(SupplierRating rating) {
    switch (rating) {
      case SupplierRating.excellent:
        return 'ممتاز';
      case SupplierRating.good:
        return 'جيد';
      case SupplierRating.average:
        return 'متوسط';
      case SupplierRating.poor:
        return 'ضعيف';
    }
  }

  SupplierRating _parseRating(String? rating) {
    switch (rating) {
      case 'ممتاز':
        return SupplierRating.excellent;
      case 'جيد':
        return SupplierRating.good;
      case 'متوسط':
        return SupplierRating.average;
      case 'ضعيف':
        return SupplierRating.poor;
      default:
        return SupplierRating.good;
    }
  }
}
