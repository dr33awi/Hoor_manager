import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'connectivity_service.dart';
import 'network_utils.dart';
import '../mappers/entity_mappers.dart';
import '../../data/database/app_database.dart' as db;
import '../constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Backup Info - معلومات النسخة الاحتياطية
/// ═══════════════════════════════════════════════════════════════════════════
class BackupInfo {
  final String id;
  final DateTime createdAt;
  final String? version;
  final bool isLocal;
  final String? path;
  final int? size;

  BackupInfo({
    required this.id,
    required this.createdAt,
    this.version,
    this.isLocal = true,
    this.path,
    this.size,
  });

  String get formattedDate => DateFormat('yyyy/MM/dd HH:mm').format(createdAt);

  String get sizeFormatted {
    if (size == null) return '';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Backup Service - خدمة النسخ الاحتياطي المحسّنة
/// ═══════════════════════════════════════════════════════════════════════════
class BackupService {
  final db.AppDatabase _database;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;

  BackupService({
    required db.AppDatabase database,
    required FirebaseFirestore firestore,
    required ConnectivityService connectivity,
  })  : _database = database,
        _firestore = firestore,
        _connectivity = connectivity;

  // ═══════════════════════════════════════════════════════════════════════════
  // النسخ الاحتياطي المحلي
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create local backup
  Future<String> createLocalBackup({String? customName}) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupName = customName ?? 'backup_$timestamp';

      // Get all data from database using entity mappers
      final data = await _exportAllData();

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Save backup file
      final file = File('${backupDir.path}/$backupName.json');
      await file.writeAsString(jsonEncode(data));

      // Save last backup time
      await saveLastBackupTime();

      debugPrint('Local backup created: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error creating local backup: $e');
      rethrow;
    }
  }

  /// الحصول على معلومات النسخ الاحتياطية المحلية
  Future<List<BackupInfo>> getLocalBackupsInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final backups = <BackupInfo>[];
      for (final file in files) {
        final stat = await file.stat();
        final name = file.path.split(Platform.pathSeparator).last;
        final id = name.replaceAll('.json', '');

        backups.add(BackupInfo(
          id: id,
          createdAt: stat.modified,
          isLocal: true,
          path: file.path,
          size: stat.size,
        ));
      }

      // Sort by date descending
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      debugPrint('Error listing local backups: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // النسخ الاحتياطي السحابي
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create cloud backup
  Future<void> createCloudBackup({String? description}) async {
    if (!_connectivity.isOnline) {
      throw NoConnectionException();
    }

    try {
      final timestamp = DateTime.now();
      final backupId = DateFormat('yyyyMMdd_HHmmss').format(timestamp);

      // Get all data using entity mappers
      final data = await _exportAllData();

      // Save to Firestore
      await _firestore
          .collection(AppConstants.backupsCollection)
          .doc(backupId)
          .set({
        'createdAt': Timestamp.fromDate(timestamp),
        'data': data,
        'version': AppConstants.appVersion,
        'description': description,
      });

      // Save last backup time
      await saveLastBackupTime();

      debugPrint('Cloud backup created: $backupId');
    } catch (e) {
      debugPrint('Error creating cloud backup: $e');
      rethrow;
    }
  }

  /// الحصول على معلومات النسخ الاحتياطية السحابية
  Future<List<BackupInfo>> getCloudBackupsInfo() async {
    if (!_connectivity.isOnline) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.backupsCollection)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BackupInfo(
          id: doc.id,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          version: data['version'] as String?,
          isLocal: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error listing cloud backups: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الاستعادة
  // ═══════════════════════════════════════════════════════════════════════════

  /// Restore from local backup
  Future<void> restoreFromLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('ملف النسخة الاحتياطية غير موجود');
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      await _importAllData(data);

      debugPrint('Restored from local backup: $filePath');
    } catch (e) {
      debugPrint('Error restoring from local backup: $e');
      rethrow;
    }
  }

  /// Restore from cloud backup by ID
  Future<void> restoreFromCloudBackup(String backupId) async {
    if (!_connectivity.isOnline) {
      throw NoConnectionException();
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.backupsCollection)
          .doc(backupId)
          .get();

      if (!doc.exists) {
        throw Exception('النسخة الاحتياطية غير موجودة');
      }

      final data = doc.data()!['data'] as Map<String, dynamic>;
      await _importAllData(data);

      debugPrint('Restored from cloud backup: $backupId');
    } catch (e) {
      debugPrint('Error restoring from cloud backup: $e');
      rethrow;
    }
  }

  /// Restore from cloud (latest backup)
  Future<void> restoreFromCloud() async {
    if (!_connectivity.isOnline) {
      throw NoConnectionException();
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.backupsCollection)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('لا توجد نسخ احتياطية متاحة');
      }

      final doc = snapshot.docs.first;
      final data = doc.data()['data'] as Map<String, dynamic>;
      await _importAllData(data);

      debugPrint('Restored from latest cloud backup');
    } catch (e) {
      debugPrint('Error restoring from cloud: $e');
      rethrow;
    }
  }

  /// استعادة من BackupInfo
  Future<void> restoreFromBackupInfo(BackupInfo backup) async {
    if (backup.isLocal) {
      if (backup.path != null) {
        await restoreFromLocalBackup(backup.path!);
      }
    } else {
      await restoreFromCloudBackup(backup.id);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحذف
  // ═══════════════════════════════════════════════════════════════════════════

  /// حذف نسخة احتياطية محلية
  Future<void> deleteLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted local backup: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting local backup: $e');
      rethrow;
    }
  }

  /// حذف نسخة احتياطية سحابية
  Future<void> deleteCloudBackup(String backupId) async {
    if (!_connectivity.isOnline) {
      throw NoConnectionException();
    }

    try {
      await _firestore
          .collection(AppConstants.backupsCollection)
          .doc(backupId)
          .delete();
      debugPrint('Deleted cloud backup: $backupId');
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال التوافق مع الكود القديم
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get list of local backups (للتوافق مع الكود القديم)
  Future<List<FileSystemEntity>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      return files;
    } catch (e) {
      debugPrint('Error listing local backups: $e');
      return [];
    }
  }

  /// Get list of cloud backups (للتوافق مع الكود القديم)
  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    if (!_connectivity.isOnline) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.backupsCollection)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'createdAt': (doc.data()['createdAt'] as Timestamp).toDate(),
                'version': doc.data()['version'],
              })
          .toList();
    } catch (e) {
      debugPrint('Error listing cloud backups: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // التصدير والاستيراد - باستخدام Entity Mappers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Export all data from database using Entity Mappers
  Future<Map<String, dynamic>> _exportAllData() async {
    final products = await _database.getAllProducts();
    final categories = await _database.getAllCategories();
    final invoices = await _database.getAllInvoices();
    final customers = await _database.getAllCustomers();
    final suppliers = await _database.getAllSuppliers();

    return {
      'products': products.map((p) => Mappers.product.toMap(p)).toList(),
      'categories': categories.map((c) => Mappers.category.toMap(c)).toList(),
      'invoices': invoices.map((i) => Mappers.invoice.toMap(i)).toList(),
      'customers': customers.map((c) => Mappers.customer.toMap(c)).toList(),
      'suppliers': suppliers.map((s) => Mappers.supplier.toMap(s)).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الاستيراد
  // ═══════════════════════════════════════════════════════════════════════════

  /// Import all data into database
  Future<void> _importAllData(Map<String, dynamic> data) async {
    debugPrint('Starting data import with ${data.keys.length} tables');

    try {
      // 1. Clear all existing data in reverse order (to handle foreign keys)
      await _database.customStatement('DELETE FROM invoice_items');
      await _database.customStatement('DELETE FROM invoices');
      await _database.customStatement('DELETE FROM inventory_movements');
      await _database.customStatement('DELETE FROM cash_movements');
      await _database.customStatement('DELETE FROM shifts');
      await _database.customStatement('DELETE FROM products');
      await _database.customStatement('DELETE FROM categories');
      await _database.customStatement('DELETE FROM customers');
      await _database.customStatement('DELETE FROM suppliers');

      // 2. Import categories first (products depend on them)
      if (data['categories'] != null) {
        for (final cat in data['categories'] as List) {
          await _database.insertCategory(_categoryFromMap(cat));
        }
        debugPrint(
            'Imported ${(data['categories'] as List).length} categories');
      }

      // 3. Import customers
      if (data['customers'] != null) {
        for (final cust in data['customers'] as List) {
          await _database.insertCustomer(_customerFromMap(cust));
        }
        debugPrint('Imported ${(data['customers'] as List).length} customers');
      }

      // 4. Import suppliers
      if (data['suppliers'] != null) {
        for (final sup in data['suppliers'] as List) {
          await _database.insertSupplier(_supplierFromMap(sup));
        }
        debugPrint('Imported ${(data['suppliers'] as List).length} suppliers');
      }

      // 5. Import products
      if (data['products'] != null) {
        for (final prod in data['products'] as List) {
          await _database.insertProduct(_productFromMap(prod));
        }
        debugPrint('Imported ${(data['products'] as List).length} products');
      }

      // 6. Import invoices and their items
      if (data['invoices'] != null) {
        for (final inv in data['invoices'] as List) {
          await _database.insertInvoice(_invoiceFromMap(inv));
          // Note: Invoice items would need to be exported/imported separately
        }
        debugPrint('Imported ${(data['invoices'] as List).length} invoices');
      }

      // Save last restore time
      await _database.setSetting(
        'last_restore_time',
        DateTime.now().toIso8601String(),
      );

      debugPrint('Data import completed successfully');
    } catch (e) {
      debugPrint('Error during data import: $e');
      rethrow;
    }
  }

  // Helper methods to convert maps back to database companions
  db.CategoriesCompanion _categoryFromMap(Map<String, dynamic> data) {
    return db.CategoriesCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      description: Value(data['description'] as String?),
      parentId: Value(data['parentId'] as String?),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  db.ProductsCompanion _productFromMap(Map<String, dynamic> data) {
    return db.ProductsCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      sku: Value(data['sku'] as String?),
      barcode: Value(data['barcode'] as String?),
      categoryId: Value(data['categoryId'] as String?),
      purchasePrice: Value((data['purchasePrice'] as num).toDouble()),
      salePrice: Value((data['salePrice'] as num).toDouble()),
      quantity: Value(data['quantity'] as int),
      minQuantity: Value(data['minQuantity'] as int),
      taxRate: Value(
          data['taxRate'] != null ? (data['taxRate'] as num).toDouble() : null),
      description: Value(data['description'] as String?),
      imageUrl: Value(data['imageUrl'] as String?),
      isActive: Value(data['isActive'] as bool? ?? true),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  db.CustomersCompanion _customerFromMap(Map<String, dynamic> data) {
    return db.CustomersCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      balance: Value((data['balance'] as num?)?.toDouble() ?? 0),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  db.SuppliersCompanion _supplierFromMap(Map<String, dynamic> data) {
    return db.SuppliersCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      balance: Value((data['balance'] as num?)?.toDouble() ?? 0),
      notes: Value(data['notes'] as String?),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  db.InvoicesCompanion _invoiceFromMap(Map<String, dynamic> data) {
    return db.InvoicesCompanion(
      id: Value(data['id'] as String),
      invoiceNumber: Value(data['invoiceNumber'] as String),
      type: Value(data['type'] as String),
      customerId: Value(data['customerId'] as String?),
      supplierId: Value(data['supplierId'] as String?),
      subtotal: Value((data['subtotal'] as num).toDouble()),
      taxAmount: Value((data['taxAmount'] as num?)?.toDouble() ?? 0),
      discountAmount: Value((data['discountAmount'] as num?)?.toDouble() ?? 0),
      total: Value((data['total'] as num).toDouble()),
      paidAmount: Value((data['paidAmount'] as num?)?.toDouble() ?? 0),
      paymentMethod: Value(data['paymentMethod'] as String? ?? 'cash'),
      notes: Value(data['notes'] as String?),
      shiftId: Value(data['shiftId'] as String?),
      syncStatus: const Value('synced'),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  /// Save last backup time
  Future<void> saveLastBackupTime() async {
    await _database.setSetting(
      'last_backup_time',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    final value = await _database.getSetting('last_backup_time');
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
