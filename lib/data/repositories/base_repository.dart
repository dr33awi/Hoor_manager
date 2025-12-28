import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/app_database.dart';

/// Base repository with common sync functionality
abstract class BaseRepository<T, C> {
  final AppDatabase database;
  final FirebaseFirestore firestore;
  final String collectionName;

  BaseRepository({
    required this.database,
    required this.firestore,
    required this.collectionName,
  });

  CollectionReference get collection => firestore.collection(collectionName);

  /// Sync pending changes to cloud
  Future<void> syncPendingChanges();

  /// Pull latest data from cloud
  Future<void> pullFromCloud();

  /// Convert local entity to Firestore map
  Map<String, dynamic> toFirestore(T entity);

  /// Convert Firestore map to local companion
  C fromFirestore(Map<String, dynamic> data, String id);

  /// Generate unique ID
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(1000 + (DateTime.now().microsecond % 9000)).toString()}';
  }
}
