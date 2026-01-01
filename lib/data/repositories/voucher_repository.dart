import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/currency_service.dart';
import '../../core/di/injection.dart';
import '../database/app_database.dart';
import 'base_repository.dart';
import 'customer_repository.dart';
import 'supplier_repository.dart';

/// أنواع السندات
enum VoucherType {
  payment, // سند دفع (للموردين)
  receipt, // سند قبض (من العملاء)
  expense, // سند مصاريف
}

extension VoucherTypeExtension on VoucherType {
  String get value {
    switch (this) {
      case VoucherType.payment:
        return 'payment';
      case VoucherType.receipt:
        return 'receipt';
      case VoucherType.expense:
        return 'expense';
    }
  }

  String get arabicName {
    switch (this) {
      case VoucherType.payment:
        return 'سند دفع';
      case VoucherType.receipt:
        return 'سند قبض';
      case VoucherType.expense:
        return 'سند مصاريف';
    }
  }

  static VoucherType fromString(String value) {
    switch (value) {
      case 'payment':
        return VoucherType.payment;
      case 'receipt':
        return VoucherType.receipt;
      case 'expense':
        return VoucherType.expense;
      default:
        return VoucherType.expense;
    }
  }
}

class VoucherRepository extends BaseRepository<Voucher, VouchersCompanion> {
  final CurrencyService currencyService;
  final _uuid = const Uuid();
  StreamSubscription? _voucherFirestoreSubscription;
  StreamSubscription? _categoryFirestoreSubscription;

  // Repositories للتكامل
  CustomerRepository? _customerRepo;
  SupplierRepository? _supplierRepo;

  VoucherRepository({
    required super.database,
    required super.firestore,
    required this.currencyService,
  }) : super(
          collectionName: AppConstants.vouchersCollection,
        );

  /// تعيين الـ Repositories للتكامل
  void setIntegrationRepositories({
    CustomerRepository? customerRepo,
    SupplierRepository? supplierRepo,
  }) {
    _customerRepo = customerRepo;
    _supplierRepo = supplierRepo;
  }

  // Lazy getters للـ Repositories
  CustomerRepository get customerRepo =>
      _customerRepo ?? getIt<CustomerRepository>();
  SupplierRepository get supplierRepo =>
      _supplierRepo ?? getIt<SupplierRepository>();

  /// Collection للتصنيفات
  CollectionReference get categoryCollection =>
      firestore.collection(AppConstants.voucherCategoriesCollection);

  // ==================== Voucher Categories ====================

  Future<List<VoucherCategory>> getAllCategories() =>
      database.getAllVoucherCategories();

  Stream<List<VoucherCategory>> watchAllCategories() =>
      database.watchAllVoucherCategories();

  Stream<List<VoucherCategory>> watchActiveCategories() =>
      database.watchActiveVoucherCategories();

  Future<List<VoucherCategory>> getCategoriesByType(VoucherType type) =>
      database.getVoucherCategoriesByType(type.value);

  Future<VoucherCategory?> getCategoryById(String id) =>
      database.getVoucherCategoryById(id);

  Future<String> createCategory({
    required String name,
    required VoucherType type,
    bool isActive = true,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await database.insertVoucherCategory(VoucherCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type.value),
      isActive: Value(isActive),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
    ));

    // Sync to Firestore immediately
    _syncCategoryToFirestore(id);

    return id;
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    bool? isActive,
  }) async {
    final category = await getCategoryById(id);
    if (category == null) return;

    await database.updateVoucherCategory(VoucherCategoriesCompanion(
      id: Value(id),
      name: Value(name ?? category.name),
      type: Value(category.type),
      isActive: Value(isActive ?? category.isActive),
      syncStatus: const Value('pending'),
      createdAt: Value(category.createdAt),
    ));

    // Sync to Firestore immediately
    _syncCategoryToFirestore(id);
  }

  Future<void> deleteCategory(String id) async {
    await database.deleteVoucherCategory(id);
    // Delete from Firestore
    try {
      await categoryCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting category from Firestore: $e');
    }
  }

  // ==================== Vouchers ====================

  Future<List<Voucher>> getAllVouchers() => database.getAllVouchers();

  Stream<List<Voucher>> watchAllVouchers() => database.watchAllVouchers();

  Future<List<Voucher>> getVouchersByType(VoucherType type) =>
      database.getVouchersByType(type.value);

  Stream<List<Voucher>> watchVouchersByType(VoucherType type) =>
      database.watchVouchersByType(type.value);

  Future<List<Voucher>> getVouchersByDateRange(DateTime start, DateTime end) =>
      database.getVouchersByDateRange(start, end);

  Stream<List<Voucher>> watchVouchersByDateRange(
          DateTime start, DateTime end) =>
      database.watchVouchersByDateRange(start, end);

  Future<List<Voucher>> getVouchersByShift(String shiftId) =>
      database.getVouchersByShift(shiftId);

  Stream<List<Voucher>> watchVouchersByShift(String shiftId) =>
      database.watchVouchersByShift(shiftId);

  Future<Voucher?> getVoucherById(String id) => database.getVoucherById(id);

  /// إنشاء سند جديد
  Future<String> createVoucher({
    required VoucherType type,
    required double amount,
    String? categoryId,
    String? description,
    String? customerId,
    String? supplierId,
    String? shiftId,
    DateTime? voucherDate,
  }) async {
    final id = _uuid.v4();
    final voucherNumber = await _generateVoucherNumber(type);
    final exchangeRate = currencyService.exchangeRate;
    final now = DateTime.now();

    await database.insertVoucher(VouchersCompanion(
      id: Value(id),
      voucherNumber: Value(voucherNumber),
      type: Value(type.value),
      categoryId: Value(categoryId),
      amount: Value(amount),
      exchangeRate: Value(exchangeRate),
      description: Value(description),
      customerId: Value(customerId),
      supplierId: Value(supplierId),
      shiftId: Value(shiftId),
      syncStatus: const Value('pending'),
      voucherDate: Value(voucherDate ?? now),
      createdAt: Value(now),
    ));

    // إضافة حركة للصندوق إذا كان هناك شفت
    if (shiftId != null) {
      await _createCashMovement(
        type: type,
        amount: amount,
        shiftId: shiftId,
        voucherId: id,
        voucherNumber: voucherNumber,
        description: description,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // تحديث رصيد العميل/المورد تلقائياً
    // ═══════════════════════════════════════════════════════════════════════════
    await _updateCustomerSupplierBalance(
      type: type,
      amount: amount,
      customerId: customerId,
      supplierId: supplierId,
    );

    // Sync to Firestore immediately
    _syncVoucherToFirestore(id);

    return id;
  }

  /// تحديث رصيد العميل/المورد عند إنشاء سند
  Future<void> _updateCustomerSupplierBalance({
    required VoucherType type,
    required double amount,
    String? customerId,
    String? supplierId,
  }) async {
    try {
      switch (type) {
        case VoucherType.receipt:
          // سند قبض من عميل = خصم من رصيد العميل (العميل دفع)
          if (customerId != null) {
            await customerRepo.updateBalance(customerId, -amount);
            debugPrint(
                'Updated customer $customerId balance by -$amount (receipt voucher)');
          }
          break;
        case VoucherType.payment:
          // سند دفع للمورد = خصم من رصيد المورد (دفعنا للمورد)
          if (supplierId != null) {
            await supplierRepo.updateBalance(supplierId, -amount);
            debugPrint(
                'Updated supplier $supplierId balance by -$amount (payment voucher)');
          }
          break;
        case VoucherType.expense:
          // سند مصاريف لا يؤثر على العملاء/الموردين
          break;
      }
    } catch (e) {
      debugPrint('Error updating customer/supplier balance from voucher: $e');
    }
  }

  /// عكس تأثير السند على رصيد العميل/المورد
  Future<void> _reverseCustomerSupplierBalance({
    required String voucherType,
    required double amount,
    String? customerId,
    String? supplierId,
  }) async {
    try {
      switch (VoucherTypeExtension.fromString(voucherType)) {
        case VoucherType.receipt:
          // سند قبض كان خصم من العميل، العكس = زيادة
          if (customerId != null) {
            await customerRepo.updateBalance(customerId, amount);
            debugPrint(
                'عكس رصيد العميل $customerId بمقدار +$amount (حذف سند قبض)');
          }
          break;
        case VoucherType.payment:
          // سند دفع كان خصم من المورد، العكس = زيادة
          if (supplierId != null) {
            await supplierRepo.updateBalance(supplierId, amount);
            debugPrint(
                'عكس رصيد المورد $supplierId بمقدار +$amount (حذف سند دفع)');
          }
          break;
        case VoucherType.expense:
          // سند المصاريف لا يؤثر على العملاء/الموردين
          break;
      }
    } catch (e) {
      debugPrint('Error reversing voucher balance: $e');
    }
  }

  /// تحديث سند مع معالجة فرق الأرصدة
  Future<void> updateVoucher({
    required String id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? voucherDate,
  }) async {
    final voucher = await getVoucherById(id);
    if (voucher == null) return;

    // ═══════════════════════════════════════════════════════════════════════════
    // معالجة فرق الرصيد إذا تغير المبلغ
    // ═══════════════════════════════════════════════════════════════════════════
    if (amount != null && amount != voucher.amount) {
      final difference = amount - voucher.amount;

      // تحديث الفرق في الرصيد
      switch (VoucherTypeExtension.fromString(voucher.type)) {
        case VoucherType.receipt:
          // سند قبض: الزيادة = خصم إضافي من العميل
          if (voucher.customerId != null) {
            await customerRepo.updateBalance(voucher.customerId!, -difference);
            debugPrint(
                'تحديث رصيد العميل ${voucher.customerId} بمقدار ${-difference} (تعديل سند قبض)');
          }
          break;
        case VoucherType.payment:
          // سند دفع: الزيادة = خصم إضافي من المورد
          if (voucher.supplierId != null) {
            await supplierRepo.updateBalance(voucher.supplierId!, -difference);
            debugPrint(
                'تحديث رصيد المورد ${voucher.supplierId} بمقدار ${-difference} (تعديل سند دفع)');
          }
          break;
        case VoucherType.expense:
          // سند المصاريف لا يؤثر على الأرصدة
          break;
      }
    }

    await database.updateVoucher(VouchersCompanion(
      id: Value(id),
      voucherNumber: Value(voucher.voucherNumber),
      type: Value(voucher.type),
      categoryId: Value(categoryId ?? voucher.categoryId),
      amount: Value(amount ?? voucher.amount),
      exchangeRate: Value(voucher.exchangeRate),
      description: Value(description ?? voucher.description),
      customerId: Value(voucher.customerId),
      supplierId: Value(voucher.supplierId),
      shiftId: Value(voucher.shiftId),
      syncStatus: const Value('pending'),
      voucherDate: Value(voucherDate ?? voucher.voucherDate),
      createdAt: Value(voucher.createdAt),
    ));

    // Sync to Firestore immediately
    _syncVoucherToFirestore(id);
  }

  /// حذف سند مع عكس تأثيره على الأرصدة
  Future<void> deleteVoucher(String id) async {
    // جلب السند قبل الحذف
    final voucher = await getVoucherById(id);

    if (voucher != null) {
      // ═══════════════════════════════════════════════════════════════════════════
      // عكس تأثير الرصيد قبل الحذف
      // ═══════════════════════════════════════════════════════════════════════════
      await _reverseCustomerSupplierBalance(
        voucherType: voucher.type,
        amount: voucher.amount,
        customerId: voucher.customerId,
        supplierId: voucher.supplierId,
      );
    }

    await database.deleteVoucher(id);
    // Delete from Firestore
    try {
      await collection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting voucher from Firestore: $e');
    }
  }

  /// الحصول على ملخص السندات
  Future<Map<String, double>> getVoucherSummary(DateTime start, DateTime end) =>
      database.getVoucherSummaryByType(start, end);

  /// توليد رقم السند
  Future<String> _generateVoucherNumber(VoucherType type) async {
    final prefix = switch (type) {
      VoucherType.payment => 'PAY',
      VoucherType.receipt => 'REC',
      VoucherType.expense => 'EXP',
    };

    final today = DateTime.now();
    final dateStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // الحصول على عدد السندات اليوم
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final vouchers = await database.getVouchersByDateRange(start, end);
    final count = vouchers.where((v) => v.type == type.value).length + 1;

    return '$prefix-$dateStr-${count.toString().padLeft(4, '0')}';
  }

  /// إنشاء حركة صندوق للسند
  Future<void> _createCashMovement({
    required VoucherType type,
    required double amount,
    required String shiftId,
    required String voucherId,
    required String voucherNumber,
    String? description,
  }) async {
    final movementType = switch (type) {
      VoucherType.payment => 'voucher_payment', // دفع للمورد = خصم
      VoucherType.receipt => 'voucher_receipt', // قبض من عميل = إضافة
      VoucherType.expense => 'expense', // مصاريف = خصم
    };

    final noteText = description ?? type.arabicName;
    final exchangeRate = currencyService.exchangeRate;

    await database.insertCashMovement(CashMovementsCompanion(
      id: Value(_uuid.v4()),
      shiftId: Value(shiftId),
      type: Value(movementType),
      amount: Value(amount),
      exchangeRate: Value(exchangeRate),
      description: Value('$noteText - رقم السند: $voucherNumber'),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// إضافة تصنيفات افتراضية
  Future<void> createDefaultCategories() async {
    final existing = await getAllCategories();
    if (existing.isNotEmpty) return;

    // تصنيفات سند القبض
    await createCategory(name: 'تحصيل مبيعات', type: VoucherType.receipt);
    await createCategory(name: 'سداد دين', type: VoucherType.receipt);
    await createCategory(name: 'دفعة مقدمة', type: VoucherType.receipt);

    // تصنيفات سند الدفع
    await createCategory(name: 'دفعة للمورد', type: VoucherType.payment);
    await createCategory(name: 'سداد دين', type: VoucherType.payment);

    // تصنيفات سند المصاريف
    await createCategory(name: 'إيجار', type: VoucherType.expense);
    await createCategory(name: 'كهرباء', type: VoucherType.expense);
    await createCategory(name: 'ماء', type: VoucherType.expense);
    await createCategory(name: 'رواتب', type: VoucherType.expense);
    await createCategory(name: 'نقل', type: VoucherType.expense);
    await createCategory(name: 'صيانة', type: VoucherType.expense);
    await createCategory(name: 'مشتريات متنوعة', type: VoucherType.expense);
    await createCategory(name: 'أخرى', type: VoucherType.expense);
  }

  // ==================== Cloud Sync ====================

  /// Sync a specific voucher to Firestore immediately
  Future<void> _syncVoucherToFirestore(String voucherId) async {
    try {
      final voucher = await database.getVoucherById(voucherId);
      if (voucher == null) return;

      await collection.doc(voucherId).set(toFirestore(voucher));

      // Update sync status
      await database.updateVoucher(VouchersCompanion(
        id: Value(voucher.id),
        voucherNumber: Value(voucher.voucherNumber),
        type: Value(voucher.type),
        categoryId: Value(voucher.categoryId),
        amount: Value(voucher.amount),
        exchangeRate: Value(voucher.exchangeRate),
        description: Value(voucher.description),
        customerId: Value(voucher.customerId),
        supplierId: Value(voucher.supplierId),
        shiftId: Value(voucher.shiftId),
        syncStatus: const Value('synced'),
        voucherDate: Value(voucher.voucherDate),
        createdAt: Value(voucher.createdAt),
      ));
    } catch (e) {
      debugPrint('Error syncing voucher $voucherId: $e');
    }
  }

  /// Sync a specific category to Firestore immediately
  Future<void> _syncCategoryToFirestore(String categoryId) async {
    try {
      final category = await database.getVoucherCategoryById(categoryId);
      if (category == null) return;

      await categoryCollection
          .doc(categoryId)
          .set(_categoryToFirestore(category));

      // Update sync status
      await database.updateVoucherCategory(VoucherCategoriesCompanion(
        id: Value(category.id),
        name: Value(category.name),
        type: Value(category.type),
        isActive: Value(category.isActive),
        syncStatus: const Value('synced'),
        createdAt: Value(category.createdAt),
      ));
    } catch (e) {
      debugPrint('Error syncing category $categoryId: $e');
    }
  }

  @override
  Future<void> syncPendingChanges() async {
    // Sync pending vouchers
    final allVouchers = await database.getAllVouchers();
    final pendingVouchers =
        allVouchers.where((v) => v.syncStatus == 'pending').toList();

    for (final voucher in pendingVouchers) {
      try {
        await collection.doc(voucher.id).set(toFirestore(voucher));

        await database.updateVoucher(VouchersCompanion(
          id: Value(voucher.id),
          voucherNumber: Value(voucher.voucherNumber),
          type: Value(voucher.type),
          categoryId: Value(voucher.categoryId),
          amount: Value(voucher.amount),
          exchangeRate: Value(voucher.exchangeRate),
          description: Value(voucher.description),
          customerId: Value(voucher.customerId),
          supplierId: Value(voucher.supplierId),
          shiftId: Value(voucher.shiftId),
          syncStatus: const Value('synced'),
          voucherDate: Value(voucher.voucherDate),
          createdAt: Value(voucher.createdAt),
        ));
      } catch (e) {
        debugPrint('Error syncing voucher ${voucher.id}: $e');
      }
    }

    // Sync pending categories
    final allCategories = await database.getAllVoucherCategories();
    final pendingCategories =
        allCategories.where((c) => c.syncStatus == 'pending').toList();

    for (final category in pendingCategories) {
      try {
        await categoryCollection
            .doc(category.id)
            .set(_categoryToFirestore(category));

        await database.updateVoucherCategory(VoucherCategoriesCompanion(
          id: Value(category.id),
          name: Value(category.name),
          type: Value(category.type),
          isActive: Value(category.isActive),
          syncStatus: const Value('synced'),
          createdAt: Value(category.createdAt),
        ));
      } catch (e) {
        debugPrint('Error syncing category ${category.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      // Pull vouchers
      final voucherSnapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      for (final doc in voucherSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getVoucherById(doc.id);
        if (existing == null) {
          await database.insertVoucher(companion);
        } else if (existing.syncStatus == 'synced') {
          final cloudCreatedAt = (data['createdAt'] as Timestamp).toDate();
          if (cloudCreatedAt.isAfter(existing.createdAt)) {
            await database.updateVoucher(companion);
          }
        }
      }

      // Pull categories
      final categorySnapshot = await categoryCollection.get();

      for (final doc in categorySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = _categoryFromFirestore(data, doc.id);

        final existing = await database.getVoucherCategoryById(doc.id);
        if (existing == null) {
          await database.insertVoucherCategory(companion);
        } else if (existing.syncStatus == 'synced') {
          final cloudCreatedAt = (data['createdAt'] as Timestamp).toDate();
          if (cloudCreatedAt.isAfter(existing.createdAt)) {
            await database.updateVoucherCategory(companion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error pulling vouchers from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Voucher entity) {
    return {
      'voucherNumber': entity.voucherNumber,
      'type': entity.type,
      'categoryId': entity.categoryId,
      'amount': entity.amount,
      'exchangeRate': entity.exchangeRate,
      'description': entity.description,
      'customerId': entity.customerId,
      'supplierId': entity.supplierId,
      'shiftId': entity.shiftId,
      'voucherDate': Timestamp.fromDate(entity.voucherDate),
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }

  Map<String, dynamic> _categoryToFirestore(VoucherCategory entity) {
    return {
      'name': entity.name,
      'type': entity.type,
      'isActive': entity.isActive,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }

  @override
  VouchersCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return VouchersCompanion(
      id: Value(id),
      voucherNumber: Value(data['voucherNumber'] as String),
      type: Value(data['type'] as String),
      categoryId: Value(data['categoryId'] as String?),
      amount: Value((data['amount'] as num).toDouble()),
      exchangeRate: Value((data['exchangeRate'] as num?)?.toDouble() ?? 1.0),
      description: Value(data['description'] as String?),
      customerId: Value(data['customerId'] as String?),
      supplierId: Value(data['supplierId'] as String?),
      shiftId: Value(data['shiftId'] as String?),
      syncStatus: const Value('synced'),
      voucherDate: Value((data['voucherDate'] as Timestamp).toDate()),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
    );
  }

  VoucherCategoriesCompanion _categoryFromFirestore(
      Map<String, dynamic> data, String id) {
    return VoucherCategoriesCompanion(
      id: Value(id),
      name: Value(data['name'] as String),
      type: Value(data['type'] as String),
      isActive: Value(data['isActive'] as bool? ?? true),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    // Start voucher sync
    _voucherFirestoreSubscription?.cancel();
    _voucherFirestoreSubscription = collection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            _handleRemoteVoucherChange(data, change.doc.id);
            break;
          case DocumentChangeType.removed:
            _handleRemoteVoucherDelete(change.doc.id);
            break;
        }
      }
    });

    // Start category sync
    _categoryFirestoreSubscription?.cancel();
    _categoryFirestoreSubscription =
        categoryCollection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            _handleRemoteCategoryChange(data, change.doc.id);
            break;
          case DocumentChangeType.removed:
            _handleRemoteCategoryDelete(change.doc.id);
            break;
        }
      }
    });
  }

  @override
  void stopRealtimeSync() {
    _voucherFirestoreSubscription?.cancel();
    _voucherFirestoreSubscription = null;
    _categoryFirestoreSubscription?.cancel();
    _categoryFirestoreSubscription = null;
  }

  Future<void> _handleRemoteVoucherChange(
      Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getVoucherById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertVoucher(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudCreatedAt = (data['createdAt'] as Timestamp).toDate();
        if (cloudCreatedAt.isAfter(existing.createdAt)) {
          await database.updateVoucher(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote voucher change: $e');
    }
  }

  Future<void> _handleRemoteVoucherDelete(String id) async {
    try {
      final existing = await database.getVoucherById(id);
      if (existing != null) {
        await database.deleteVoucher(id);
        debugPrint('Deleted voucher from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote voucher delete: $e');
    }
  }

  Future<void> _handleRemoteCategoryChange(
      Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getVoucherCategoryById(id);
      final companion = _categoryFromFirestore(data, id);

      if (existing == null) {
        await database.insertVoucherCategory(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudCreatedAt = (data['createdAt'] as Timestamp).toDate();
        if (cloudCreatedAt.isAfter(existing.createdAt)) {
          await database.updateVoucherCategory(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote category change: $e');
    }
  }

  Future<void> _handleRemoteCategoryDelete(String id) async {
    try {
      final existing = await database.getVoucherCategoryById(id);
      if (existing != null) {
        await database.deleteVoucherCategory(id);
        debugPrint('Deleted category from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote category delete: $e');
    }
  }
}
