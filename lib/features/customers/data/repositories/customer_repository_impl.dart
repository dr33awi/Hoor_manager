import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../../core/utils/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/models.dart';

/// تنفيذ مستودع العملاء
class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

  CustomerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// مرجع مجموعة العملاء
  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      _firestore.collection('customers');

  /// مرجع مجموعة أسعار العملاء
  CollectionReference<Map<String, dynamic>> get _customerPricesCollection =>
      _firestore.collection('customer_prices');

  @override
  Stream<List<CustomerEntity>> watchCustomers() {
    return _customersCollection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CustomerModel.fromDocument(doc)).toList());
  }

  @override
  Future<Result<CustomerEntity>> getCustomerById(String id) async {
    try {
      final doc = await _customersCollection.doc(id).get();
      if (!doc.exists) {
        return Failure('العميل غير موجود');
      }
      return Success(CustomerModel.fromDocument(doc));
    } catch (e) {
      _logger.e('Error getting customer: $e');
      return Failure('خطأ في جلب بيانات العميل');
    }
  }

  @override
  Future<Result<List<CustomerEntity>>> searchCustomers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _customersCollection
          .where('searchTerms', arrayContains: queryLower)
          .limit(20)
          .get();

      final customers =
          snapshot.docs.map((doc) => CustomerModel.fromDocument(doc)).toList();
      return Success(customers);
    } catch (e) {
      _logger.e('Error searching customers: $e');
      return Failure('خطأ في البحث');
    }
  }

  @override
  Stream<List<CustomerEntity>> watchCustomersByType(CustomerType type) {
    return _customersCollection
        .where('type', isEqualTo: type.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromDocument(doc))
            .toList());
  }

  @override
  Stream<List<CustomerEntity>> watchCustomersWithDues() {
    return _customersCollection
        .where('balance', isLessThan: 0)
        .orderBy('balance')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromDocument(doc))
            .toList());
  }

  @override
  Future<Result<CustomerEntity>> addCustomer(CustomerEntity customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      final docRef = await _customersCollection.add(model.toMap());

      final newCustomer = customer.copyWith(id: docRef.id);
      _logger.i('Customer added: ${docRef.id}');
      return Success(newCustomer);
    } catch (e) {
      _logger.e('Error adding customer: $e');
      return Failure('خطأ في إضافة العميل');
    }
  }

  @override
  Future<Result<CustomerEntity>> updateCustomer(CustomerEntity customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await _customersCollection.doc(customer.id).update(model.toUpdateMap());

      _logger.i('Customer updated: ${customer.id}');
      return Success(customer);
    } catch (e) {
      _logger.e('Error updating customer: $e');
      return Failure('خطأ في تحديث العميل');
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      await _customersCollection.doc(id).delete();
      _logger.i('Customer deleted: $id');
      return Success(null);
    } catch (e) {
      _logger.e('Error deleting customer: $e');
      return Failure('خطأ في حذف العميل');
    }
  }

  @override
  Future<Result<void>> updateCustomerBalance({
    required String customerId,
    required double amount,
    required bool isCredit,
  }) async {
    try {
      final adjustment = isCredit ? amount : -amount;
      await _customersCollection.doc(customerId).update({
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
  Future<Result<void>> updateCustomerStats({
    required String customerId,
    required double invoiceAmount,
    required double paidAmount,
  }) async {
    try {
      final balanceChange = paidAmount - invoiceAmount;
      await _customersCollection.doc(customerId).update({
        'totalPurchases': FieldValue.increment(invoiceAmount),
        'totalPayments': FieldValue.increment(paidAmount),
        'balance': FieldValue.increment(balanceChange),
        'invoicesCount': FieldValue.increment(1),
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
  Future<Result<double?>> getLastPriceForCustomer({
    required String customerId,
    required String productId,
  }) async {
    try {
      final doc =
          await _customerPricesCollection.doc('${customerId}_$productId').get();

      if (!doc.exists) {
        return Success(null);
      }

      final data = doc.data()!;
      return Success((data['price'] as num?)?.toDouble());
    } catch (e) {
      _logger.e('Error getting last price: $e');
      return Success(null);
    }
  }

  /// حفظ آخر سعر للعميل
  Future<void> saveLastPriceForCustomer({
    required String customerId,
    required String productId,
    required double price,
  }) async {
    try {
      await _customerPricesCollection.doc('${customerId}_$productId').set({
        'customerId': customerId,
        'productId': productId,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error saving last price: $e');
    }
  }

  @override
  Future<Result<String>> exportToExcel() async {
    try {
      final snapshot = await _customersCollection.orderBy('name').get();
      final customers =
          snapshot.docs.map((doc) => CustomerModel.fromDocument(doc)).toList();

      final excel = Excel.createExcel();
      final sheet = excel['العملاء'];

      // العناوين
      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('الهاتف'),
        TextCellValue('البريد'),
        TextCellValue('العنوان'),
        TextCellValue('المدينة'),
        TextCellValue('الرقم الضريبي'),
        TextCellValue('النوع'),
        TextCellValue('حد الائتمان'),
        TextCellValue('الرصيد'),
        TextCellValue('إجمالي المشتريات'),
      ]);

      // البيانات
      for (final customer in customers) {
        sheet.appendRow([
          TextCellValue(customer.name),
          TextCellValue(customer.phone ?? ''),
          TextCellValue(customer.email ?? ''),
          TextCellValue(customer.address ?? ''),
          TextCellValue(customer.city ?? ''),
          TextCellValue(customer.taxNumber ?? ''),
          TextCellValue(_getTypeArabic(customer.type)),
          DoubleCellValue(customer.creditLimit),
          DoubleCellValue(customer.balance),
          DoubleCellValue(customer.totalPurchases),
        ]);
      }

      // حفظ الملف
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/customers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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

        final customer = CustomerEntity(
          id: '',
          name: row[0]?.value?.toString() ?? '',
          phone: row[1]?.value?.toString(),
          email: row[2]?.value?.toString(),
          address: row[3]?.value?.toString(),
          city: row[4]?.value?.toString(),
          taxNumber: row[5]?.value?.toString(),
          type: _parseType(row[6]?.value?.toString()),
          creditLimit: double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0,
          createdAt: DateTime.now(),
        );

        final result = await addCustomer(customer);
        if (result.isSuccess) imported++;
      }

      return Success(imported);
    } catch (e) {
      _logger.e('Error importing from Excel: $e');
      return Failure('خطأ في استيراد البيانات');
    }
  }

  String _getTypeArabic(CustomerType type) {
    switch (type) {
      case CustomerType.regular:
        return 'عادي';
      case CustomerType.vip:
        return 'VIP';
      case CustomerType.wholesale:
        return 'تاجر جملة';
    }
  }

  CustomerType _parseType(String? type) {
    switch (type) {
      case 'VIP':
        return CustomerType.vip;
      case 'تاجر جملة':
        return CustomerType.wholesale;
      default:
        return CustomerType.regular;
    }
  }
}
