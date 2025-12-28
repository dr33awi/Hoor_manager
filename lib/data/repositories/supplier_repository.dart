import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class SupplierRepository extends BaseRepository<Supplier, SuppliersCompanion> {
  StreamSubscription? _supplierFirestoreSubscription;

  SupplierRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.suppliersCollection);

  // ==================== Local Operations ====================

  Future<List<Supplier>> getAllSuppliers() => database.getAllSuppliers();

  Stream<List<Supplier>> watchAllSuppliers() => database.watchAllSuppliers();

  Future<Supplier?> getSupplierById(String id) => database.getSupplierById(id);

  Future<String> createSupplier({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final id = generateId();
    final now = DateTime.now();

    await database.insertSupplier(SuppliersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      balance: const Value(0),
      notes: Value(notes),
      isActive: const Value(true),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return id;
  }

  Future<void> updateSupplier({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
    String? notes,
    bool? isActive,
  }) async {
    final existing = await database.getSupplierById(id);
    if (existing == null) return;

    await database.updateSupplier(SuppliersCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      phone: Value(phone ?? existing.phone),
      email: Value(email ?? existing.email),
      address: Value(address ?? existing.address),
      balance: Value(balance ?? existing.balance),
      notes: Value(notes ?? existing.notes),
      isActive: Value(isActive ?? existing.isActive),
      syncStatus: const Value('pending'),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateBalance(String supplierId, double amount) async {
    final supplier = await database.getSupplierById(supplierId);
    if (supplier == null) return;

    await updateSupplier(
      id: supplierId,
      balance: supplier.balance + amount,
    );
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final allSuppliers = await database.getAllSuppliers();
    final pending =
        allSuppliers.where((s) => s.syncStatus == 'pending').toList();

    for (final supplier in pending) {
      try {
        await collection.doc(supplier.id).set(toFirestore(supplier));

        await database.updateSupplier(SuppliersCompanion(
          id: Value(supplier.id),
          name: Value(supplier.name),
          phone: Value(supplier.phone),
          email: Value(supplier.email),
          address: Value(supplier.address),
          balance: Value(supplier.balance),
          notes: Value(supplier.notes),
          isActive: Value(supplier.isActive),
          syncStatus: const Value('synced'),
          createdAt: Value(supplier.createdAt),
          updatedAt: Value(supplier.updatedAt),
        ));
      } catch (e) {
        debugPrint('Error syncing supplier ${supplier.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection.get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getSupplierById(doc.id);
        if (existing == null) {
          await database.insertSupplier(companion);
        } else if (existing.syncStatus == 'synced') {
          final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
          if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
            await database.updateSupplier(companion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error pulling suppliers from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Supplier entity) {
    return {
      'name': entity.name,
      'phone': entity.phone,
      'email': entity.email,
      'address': entity.address,
      'balance': entity.balance,
      'notes': entity.notes,
      'isActive': entity.isActive,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  @override
  SuppliersCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return SuppliersCompanion(
      id: Value(id),
      name: Value(data['name'] as String),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      balance: Value((data['balance'] as num?)?.toDouble() ?? 0),
      notes: Value(data['notes'] as String?),
      isActive: Value(data['isActive'] as bool? ?? true),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _supplierFirestoreSubscription?.cancel();
    _supplierFirestoreSubscription = collection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            _handleRemoteChange(data, change.doc.id);
            break;
          case DocumentChangeType.removed:
            _handleRemoteDelete(change.doc.id);
            break;
        }
      }
    });
  }

  Future<void> _handleRemoteChange(Map<String, dynamic> data, String id) async {
    try {
      final existing = await database.getSupplierById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertSupplier(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateSupplier(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote supplier change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getSupplierById(id);
      if (existing != null) {
        await database.deleteSupplier(id);
        debugPrint('Deleted supplier from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote supplier delete: $e');
    }
  }
}
