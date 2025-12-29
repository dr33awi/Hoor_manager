import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/repositories/syncable_repository.dart';
import '../database/app_database.dart';

/// Base repository with common sync functionality
/// يرث من SyncableRepository الموحد
abstract class BaseRepository<T, C> implements SyncableRepository {
  final AppDatabase database;
  final FirebaseFirestore firestore;
  final String collectionName;

  StreamSubscription? _firestoreSubscription;

  BaseRepository({
    required this.database,
    required this.firestore,
    required this.collectionName,
  });

  @override
  String get repositoryName => collectionName;

  CollectionReference get collection => firestore.collection(collectionName);

  /// Sync pending changes to cloud
  @override
  Future<void> syncPendingChanges();

  /// Pull latest data from cloud
  @override
  Future<void> pullFromCloud();

  /// Convert local entity to Firestore map
  Map<String, dynamic> toFirestore(T entity);

  /// Convert Firestore map to local companion
  C fromFirestore(Map<String, dynamic> data, String id);

  /// Start listening to Firestore changes
  @override
  void startRealtimeSync();

  /// Stop listening to Firestore changes
  @override
  void stopRealtimeSync() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  /// Generate unique ID
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(1000 + (DateTime.now().microsecond % 9000)).toString()}';
  }
}
