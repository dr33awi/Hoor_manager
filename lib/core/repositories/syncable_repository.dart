import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Syncable Repository Interface - توحيد منطق المزامنة
/// ═══════════════════════════════════════════════════════════════════════════

/// Interface لجميع الـ Repositories القابلة للمزامنة
abstract class SyncableRepository {
  /// اسم المستودع للـ logging
  String get repositoryName;

  /// مزامنة التغييرات المعلقة إلى السحابة
  Future<void> syncPendingChanges();

  /// سحب آخر البيانات من السحابة
  Future<void> pullFromCloud();

  /// بدء الاستماع للتغييرات في الوقت الفعلي
  void startRealtimeSync();

  /// إيقاف الاستماع للتغييرات
  void stopRealtimeSync();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Base Repository المحسّن
/// ═══════════════════════════════════════════════════════════════════════════
abstract class BaseSyncableRepository<T, C> implements SyncableRepository {
  final AppDatabase database;
  final FirebaseFirestore firestore;
  final String collectionName;

  StreamSubscription? _firestoreSubscription;
  bool _isRealtimeSyncActive = false;

  BaseSyncableRepository({
    required this.database,
    required this.firestore,
    required this.collectionName,
  });

  @override
  String get repositoryName => collectionName;

  CollectionReference get collection => firestore.collection(collectionName);

  /// تحويل Entity إلى Firestore map
  Map<String, dynamic> toFirestore(T entity);

  /// تحويل Firestore map إلى Companion
  C fromFirestore(Map<String, dynamic> data, String id);

  /// الحصول على العناصر المعلقة للمزامنة
  Future<List<T>> getPendingItems();

  /// تحديث حالة المزامنة
  Future<void> updateSyncStatus(String id, String status);

  /// إدراج أو تحديث عنصر من السحابة
  Future<void> upsertFromCloud(C companion);

  @override
  Future<void> syncPendingChanges() async {
    try {
      final pendingItems = await getPendingItems();

      for (final item in pendingItems) {
        try {
          final data = toFirestore(item);
          final id = data['id'] as String;

          await collection.doc(id).set(data, SetOptions(merge: true));
          await updateSyncStatus(id, 'synced');

          debugPrint('[$repositoryName] Synced item: $id');
        } catch (e) {
          debugPrint('[$repositoryName] Error syncing item: $e');
        }
      }

      if (pendingItems.isNotEmpty) {
        debugPrint(
            '[$repositoryName] Synced ${pendingItems.length} pending items');
      }
    } catch (e) {
      debugPrint('[$repositoryName] Error in syncPendingChanges: $e');
      rethrow;
    }
  }

  @override
  Future<void> pullFromCloud() async {
    try {
      final snapshot = await collection.get();

      for (final doc in snapshot.docs) {
        try {
          final companion =
              fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          await upsertFromCloud(companion);
        } catch (e) {
          debugPrint('[$repositoryName] Error processing doc ${doc.id}: $e');
        }
      }

      debugPrint(
          '[$repositoryName] Pulled ${snapshot.docs.length} items from cloud');
    } catch (e) {
      debugPrint('[$repositoryName] Error in pullFromCloud: $e');
      rethrow;
    }
  }

  @override
  void startRealtimeSync() {
    if (_isRealtimeSyncActive) return;

    _isRealtimeSyncActive = true;
    _firestoreSubscription = collection.snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          _handleDocumentChange(change);
        }
      },
      onError: (e) {
        debugPrint('[$repositoryName] Realtime sync error: $e');
      },
    );

    debugPrint('[$repositoryName] Started realtime sync');
  }

  @override
  void stopRealtimeSync() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _isRealtimeSyncActive = false;

    debugPrint('[$repositoryName] Stopped realtime sync');
  }

  void _handleDocumentChange(DocumentChange change) async {
    try {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          final companion = fromFirestore(data, change.doc.id);
          await upsertFromCloud(companion);
          break;
        case DocumentChangeType.removed:
          // يمكن تنفيذ الحذف هنا إذا لزم الأمر
          break;
      }
    } catch (e) {
      debugPrint('[$repositoryName] Error handling doc change: $e');
    }
  }

  /// توليد ID فريد
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(1000 + (DateTime.now().microsecond % 9000)).toString()}';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Sync Manager - إدارة مزامنة جميع الـ Repositories
/// ═══════════════════════════════════════════════════════════════════════════
class SyncManager {
  final List<SyncableRepository> _repositories;

  SyncManager(this._repositories);

  /// مزامنة جميع التغييرات المعلقة
  Future<void> syncAllPending() async {
    for (final repo in _repositories) {
      try {
        await repo.syncPendingChanges();
      } catch (e) {
        debugPrint('Error syncing ${repo.repositoryName}: $e');
      }
    }
  }

  /// سحب جميع البيانات من السحابة
  Future<void> pullAllFromCloud() async {
    for (final repo in _repositories) {
      try {
        await repo.pullFromCloud();
      } catch (e) {
        debugPrint('Error pulling ${repo.repositoryName}: $e');
      }
    }
  }

  /// بدء المزامنة في الوقت الفعلي لجميع الـ Repositories
  void startAllRealtimeSync() {
    for (final repo in _repositories) {
      repo.startRealtimeSync();
    }
  }

  /// إيقاف المزامنة في الوقت الفعلي
  void stopAllRealtimeSync() {
    for (final repo in _repositories) {
      repo.stopRealtimeSync();
    }
  }

  /// مزامنة كاملة (push ثم pull)
  Future<void> fullSync() async {
    await syncAllPending();
    await pullAllFromCloud();
  }

  /// مزامنة repository معين بالاسم
  Future<void> syncByName(String name) async {
    final repo = _repositories.firstWhere(
      (r) => r.repositoryName == name,
      orElse: () => throw Exception('Repository not found: $name'),
    );

    await repo.syncPendingChanges();
    await repo.pullFromCloud();
  }
}
