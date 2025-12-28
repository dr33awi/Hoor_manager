import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository<Customer, CustomersCompanion> {
  StreamSubscription? _customerFirestoreSubscription;

  CustomerRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.customersCollection);

  // ==================== Local Operations ====================

  Future<List<Customer>> getAllCustomers() => database.getAllCustomers();

  Stream<List<Customer>> watchAllCustomers() => database.watchAllCustomers();

  Future<Customer?> getCustomerById(String id) => database.getCustomerById(id);

  Future<String> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final id = generateId();
    final now = DateTime.now();

    await database.insertCustomer(CustomersCompanion(
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

  Future<void> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
    String? notes,
    bool? isActive,
  }) async {
    final existing = await database.getCustomerById(id);
    if (existing == null) return;

    await database.updateCustomer(CustomersCompanion(
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

  Future<void> updateBalance(String customerId, double amount) async {
    final customer = await database.getCustomerById(customerId);
    if (customer == null) return;

    await updateCustomer(
      id: customerId,
      balance: customer.balance + amount,
    );
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final allCustomers = await database.getAllCustomers();
    final pending =
        allCustomers.where((c) => c.syncStatus == 'pending').toList();

    for (final customer in pending) {
      try {
        await collection.doc(customer.id).set(toFirestore(customer));

        await database.updateCustomer(CustomersCompanion(
          id: Value(customer.id),
          name: Value(customer.name),
          phone: Value(customer.phone),
          email: Value(customer.email),
          address: Value(customer.address),
          balance: Value(customer.balance),
          notes: Value(customer.notes),
          isActive: Value(customer.isActive),
          syncStatus: const Value('synced'),
          createdAt: Value(customer.createdAt),
          updatedAt: Value(customer.updatedAt),
        ));
      } catch (e) {
        debugPrint('Error syncing customer ${customer.id}: $e');
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

        final existing = await database.getCustomerById(doc.id);
        if (existing == null) {
          await database.insertCustomer(companion);
        } else if (existing.syncStatus == 'synced') {
          final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
          if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
            await database.updateCustomer(companion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error pulling customers from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Customer entity) {
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
  CustomersCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return CustomersCompanion(
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
    _customerFirestoreSubscription?.cancel();
    _customerFirestoreSubscription = collection.snapshots().listen((snapshot) {
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
      final existing = await database.getCustomerById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertCustomer(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateCustomer(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote customer change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getCustomerById(id);
      if (existing != null) {
        await database.deleteCustomer(id);
        debugPrint('Deleted customer from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote customer delete: $e');
    }
  }
}
