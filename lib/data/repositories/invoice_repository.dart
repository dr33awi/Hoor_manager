import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class InvoiceRepository extends BaseRepository<Invoice, InvoicesCompanion> {
  StreamSubscription? _invoiceFirestoreSubscription;

  InvoiceRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.invoicesCollection);

  // ==================== Local Operations ====================

  Future<List<Invoice>> getAllInvoices() => database.getAllInvoices();

  Stream<List<Invoice>> watchAllInvoices() => database.watchAllInvoices();

  Future<List<Invoice>> getInvoicesByType(String type) =>
      database.getInvoicesByType(type);

  Future<List<Invoice>> getInvoicesByDateRange(DateTime start, DateTime end) =>
      database.getInvoicesByDateRange(start, end);

  Future<List<Invoice>> getInvoicesByShift(String shiftId) =>
      database.getInvoicesByShift(shiftId);

  Future<Invoice?> getInvoiceById(String id) => database.getInvoiceById(id);

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) =>
      database.getInvoiceItems(invoiceId);

  /// Create a complete invoice with items
  Future<String> createInvoice({
    required String type,
    String? customerId,
    String? supplierId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0,
    required String paymentMethod,
    double paidAmount = 0,
    String? notes,
    String? shiftId,
    DateTime? invoiceDate,
  }) async {
    final id = generateId();
    final now = DateTime.now();
    final invoiceNumber = await _generateInvoiceNumber(type);

    // Calculate totals
    double subtotal = 0;

    final invoiceItems = <InvoiceItemsCompanion>[];

    for (final item in items) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      final purchasePrice = item['purchasePrice'] as double? ?? 0;
      final itemDiscount = item['discount'] as double? ?? 0;

      final itemSubtotal = quantity * unitPrice;
      final itemTotal = itemSubtotal - itemDiscount;

      subtotal += itemSubtotal;

      invoiceItems.add(InvoiceItemsCompanion(
        id: Value(generateId()),
        invoiceId: Value(id),
        productId: Value(item['productId'] as String),
        productName: Value(item['productName'] as String),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
        purchasePrice: Value(purchasePrice),
        discountAmount: Value(itemDiscount),
        taxAmount: const Value(0),
        total: Value(itemTotal),
        syncStatus: const Value('pending'),
        createdAt: Value(now),
      ));
    }

    final total = subtotal - discountAmount;

    // Insert invoice
    await database.insertInvoice(InvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      type: Value(type),
      customerId: Value(customerId),
      supplierId: Value(supplierId),
      subtotal: Value(subtotal),
      taxAmount: const Value(0),
      discountAmount: Value(discountAmount),
      total: Value(total),
      paidAmount: Value(paidAmount),
      paymentMethod: Value(paymentMethod),
      status: const Value('completed'),
      notes: Value(notes),
      shiftId: Value(shiftId),
      syncStatus: const Value('pending'),
      invoiceDate: Value(invoiceDate ?? now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // Insert invoice items
    await database.insertInvoiceItems(invoiceItems);

    // Update inventory based on invoice type
    await _updateInventory(type, items);

    return id;
  }

  Future<String> _generateInvoiceNumber(String type) async {
    final prefix = switch (type) {
      'sale' => 'INV',
      'purchase' => 'PUR',
      'sale_return' => 'SRT',
      'purchase_return' => 'PRT',
      'opening_balance' => 'OPN',
      _ => 'DOC',
    };

    final today = DateTime.now();
    final dateStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // Get count for today
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final invoices = await database.getInvoicesByDateRange(start, end);
    final count = invoices.where((i) => i.type == type).length + 1;

    return '$prefix-$dateStr-${count.toString().padLeft(4, '0')}';
  }

  Future<void> _updateInventory(
      String type, List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      final product = await database.getProductById(productId);

      if (product == null) continue;

      int adjustment;
      String movementType;

      switch (type) {
        case 'sale':
          adjustment = -quantity;
          movementType = 'sale';
          break;
        case 'purchase':
        case 'opening_balance':
          adjustment = quantity;
          movementType = 'purchase';
          break;
        case 'sale_return':
          adjustment = quantity;
          movementType = 'return';
          break;
        case 'purchase_return':
          adjustment = -quantity;
          movementType = 'return';
          break;
        default:
          continue;
      }

      final newQuantity = product.quantity + adjustment;
      await database.updateProductQuantity(productId, newQuantity);

      await database.insertInventoryMovement(InventoryMovementsCompanion(
        id: Value(generateId()),
        productId: Value(productId),
        type: Value(movementType),
        quantity: Value(quantity),
        previousQuantity: Value(product.quantity),
        newQuantity: Value(newQuantity),
        reason: Value('Invoice: $type'),
        syncStatus: const Value('pending'),
        createdAt: Value(DateTime.now()),
      ));
    }
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingInvoices();

    for (final invoice in pending) {
      try {
        // Sync invoice
        await collection.doc(invoice.id).set(toFirestore(invoice));

        // Sync invoice items
        final items = await database.getInvoiceItems(invoice.id);
        for (final item in items) {
          await firestore
              .collection(AppConstants.invoiceItemsCollection)
              .doc(item.id)
              .set(_invoiceItemToFirestore(item));
        }

        // Update sync status
        await database.updateInvoice(InvoicesCompanion(
          id: Value(invoice.id),
          syncStatus: const Value('synced'),
        ));
      } catch (e) {
        debugPrint('Error syncing invoice ${invoice.id}: $e');
      }
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final companion = fromFirestore(data, doc.id);

        final existing = await database.getInvoiceById(doc.id);
        if (existing == null) {
          await database.insertInvoice(companion);
        }
      }
    } catch (e) {
      debugPrint('Error pulling invoices from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Invoice entity) {
    return {
      'invoiceNumber': entity.invoiceNumber,
      'type': entity.type,
      'customerId': entity.customerId,
      'supplierId': entity.supplierId,
      'subtotal': entity.subtotal,
      'taxAmount': entity.taxAmount,
      'discountAmount': entity.discountAmount,
      'total': entity.total,
      'paidAmount': entity.paidAmount,
      'paymentMethod': entity.paymentMethod,
      'status': entity.status,
      'notes': entity.notes,
      'shiftId': entity.shiftId,
      'invoiceDate': Timestamp.fromDate(entity.invoiceDate),
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  Map<String, dynamic> _invoiceItemToFirestore(InvoiceItem item) {
    return {
      'invoiceId': item.invoiceId,
      'productId': item.productId,
      'productName': item.productName,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'purchasePrice': item.purchasePrice,
      'discountAmount': item.discountAmount,
      'taxAmount': item.taxAmount,
      'total': item.total,
      'createdAt': Timestamp.fromDate(item.createdAt),
    };
  }

  @override
  InvoicesCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return InvoicesCompanion(
      id: Value(id),
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
      status: Value(data['status'] as String? ?? 'completed'),
      notes: Value(data['notes'] as String?),
      shiftId: Value(data['shiftId'] as String?),
      syncStatus: const Value('synced'),
      invoiceDate: Value((data['invoiceDate'] as Timestamp).toDate()),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _invoiceFirestoreSubscription?.cancel();
    _invoiceFirestoreSubscription = collection.snapshots().listen((snapshot) {
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
      final existing = await database.getInvoiceById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertInvoice(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateInvoice(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote invoice change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      final existing = await database.getInvoiceById(id);
      if (existing != null) {
        // Delete invoice items first
        await database.deleteInvoiceItems(id);
        // Then delete the invoice
        await database.deleteInvoice(id);
        debugPrint('Deleted invoice from remote: $id');
      }
    } catch (e) {
      debugPrint('Error handling remote invoice delete: $e');
    }
  }
}
