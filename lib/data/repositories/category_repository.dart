import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'base_repository.dart';

class CategoryRepository extends BaseRepository<Category, CategoriesCompanion> {
  StreamSubscription? _categoryFirestoreSubscription;

  CategoryRepository({
    required super.database,
    required super.firestore,
  }) : super(collectionName: AppConstants.categoriesCollection);

  // ==================== Local Operations ====================

  Future<List<Category>> getAllCategories() => database.getAllCategories();

  Stream<List<Category>> watchAllCategories() => database.watchAllCategories();

  Future<Category?> getCategoryById(String id) => database.getCategoryById(id);

  Future<String> createCategory({
    required String name,
    String? description,
    String? parentId,
  }) async {
    final id = generateId();
    final now = DateTime.now();

    await database.insertCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      parentId: Value(parentId),
      syncStatus: const Value('pending'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return id;
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    String? parentId,
  }) async {
    final existing = await database.getCategoryById(id);
    if (existing == null) return;

    await database.updateCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      description: Value(description ?? existing.description),
      parentId: Value(parentId ?? existing.parentId),
      syncStatus: const Value('pending'),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteCategory(String id) async {
    // حذف من قاعدة البيانات المحلية
    await database.deleteCategory(id);

    // حذف من Firestore
    try {
      await collection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting category from Firestore: $e');
    }
  }

  // ==================== Cloud Sync ====================

  @override
  Future<void> syncPendingChanges() async {
    final pending = await database.getPendingCategories();

    for (final category in pending) {
      try {
        await collection.doc(category.id).set(toFirestore(category));

        await database.updateCategory(CategoriesCompanion(
          id: Value(category.id),
          name: Value(category.name),
          description: Value(category.description),
          parentId: Value(category.parentId),
          syncStatus: const Value('synced'),
          createdAt: Value(category.createdAt),
          updatedAt: Value(category.updatedAt),
        ));
      } catch (e) {
        debugPrint('Error syncing category ${category.id}: $e');
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

        final existing = await database.getCategoryById(doc.id);
        if (existing == null) {
          await database.insertCategory(companion);
        } else if (existing.syncStatus == 'synced') {
          final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
          if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
            await database.updateCategory(companion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error pulling categories from cloud: $e');
    }
  }

  @override
  Map<String, dynamic> toFirestore(Category entity) {
    return {
      'name': entity.name,
      'description': entity.description,
      'parentId': entity.parentId,
      'createdAt': Timestamp.fromDate(entity.createdAt),
      'updatedAt': Timestamp.fromDate(entity.updatedAt),
    };
  }

  @override
  CategoriesCompanion fromFirestore(Map<String, dynamic> data, String id) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(data['name'] as String),
      description: Value(data['description'] as String?),
      parentId: Value(data['parentId'] as String?),
      syncStatus: const Value('synced'),
      createdAt: Value((data['createdAt'] as Timestamp).toDate()),
      updatedAt: Value((data['updatedAt'] as Timestamp).toDate()),
    );
  }

  @override
  void startRealtimeSync() {
    _categoryFirestoreSubscription?.cancel();
    _categoryFirestoreSubscription = collection.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
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
      final existing = await database.getCategoryById(id);
      final companion = fromFirestore(data, id);

      if (existing == null) {
        await database.insertCategory(companion);
      } else if (existing.syncStatus == 'synced') {
        final cloudUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
          await database.updateCategory(companion);
        }
      }
    } catch (e) {
      debugPrint('Error handling remote category change: $e');
    }
  }

  Future<void> _handleRemoteDelete(String id) async {
    try {
      await database.deleteCategory(id);
    } catch (e) {
      debugPrint('Error handling remote category delete: $e');
    }
  }
}
