import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

/// خدمة النسخ الاحتياطي
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _logger = Logger();
  final _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// المجموعات التي يتم نسخها احتياطياً
  final List<String> _collectionsToBackup = [
    'products',
    'categories',
    'invoices',
    'users',
    'settings',
  ];

  /// إنشاء نسخة احتياطية
  Future<BackupResult> createBackup({
    List<String>? collections,
    bool includeAuditLogs = false,
  }) async {
    try {
      final timestamp = DateTime.now();
      final backupCollections = collections ?? _collectionsToBackup;
      final backupData = <String, dynamic>{
        'version': '1.0',
        'createdAt': timestamp.toIso8601String(),
        'collections': <String, dynamic>{},
      };

      // نسخ كل مجموعة
      for (final collection in backupCollections) {
        _logger.d('Backing up collection: $collection');

        final snapshot = await _firestore.collection(collection).get();
        final documents = <String, dynamic>{};

        for (final doc in snapshot.docs) {
          documents[doc.id] = _convertTimestamps(doc.data());
        }

        backupData['collections'][collection] = documents;
      }

      // نسخ سجل النشاطات إذا طلب
      if (includeAuditLogs) {
        final auditSnapshot = await _firestore
            .collection('audit_logs')
            .orderBy('timestamp', descending: true)
            .limit(1000)
            .get();

        final auditDocs = <String, dynamic>{};
        for (final doc in auditSnapshot.docs) {
          auditDocs[doc.id] = _convertTimestamps(doc.data());
        }
        backupData['collections']['audit_logs'] = auditDocs;
      }

      // حفظ الملف
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'backup_${_dateFormat.format(timestamp)}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(jsonEncode(backupData));

      // حفظ سجل النسخة الاحتياطية
      await _saveBackupRecord(fileName, timestamp, backupCollections);

      _logger.i('Backup created: $fileName');

      return BackupResult(
        success: true,
        filePath: filePath,
        fileName: fileName,
        timestamp: timestamp,
        collectionsCount: backupCollections.length,
        totalDocuments: _countDocuments(backupData['collections']),
      );
    } catch (e) {
      _logger.e('Error creating backup: $e');
      return BackupResult(
        success: false,
        error: 'فشل في إنشاء النسخة الاحتياطية: $e',
      );
    }
  }

  /// استعادة من نسخة احتياطية
  Future<RestoreResult> restoreBackup({
    required String filePath,
    List<String>? collectionsToRestore,
    bool mergeData = false,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير موجود',
        );
      }

      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      // التحقق من صحة الملف
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('collections')) {
        return RestoreResult(
          success: false,
          error: 'ملف النسخة الاحتياطية غير صالح',
        );
      }

      final collections = backupData['collections'] as Map<String, dynamic>;
      final restoredCollections = <String>[];
      int totalDocuments = 0;

      for (final entry in collections.entries) {
        final collectionName = entry.key;

        // تخطي المجموعات غير المطلوبة
        if (collectionsToRestore != null &&
            !collectionsToRestore.contains(collectionName)) {
          continue;
        }

        final documents = entry.value as Map<String, dynamic>;

        // حذف البيانات الحالية إذا لم يكن الدمج مطلوباً
        if (!mergeData) {
          final existingDocs =
              await _firestore.collection(collectionName).get();
          final batch = _firestore.batch();
          for (final doc in existingDocs.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        // استعادة البيانات
        for (final docEntry in documents.entries) {
          final docId = docEntry.key;
          final docData =
              _restoreTimestamps(docEntry.value as Map<String, dynamic>);

          await _firestore
              .collection(collectionName)
              .doc(docId)
              .set(docData, SetOptions(merge: mergeData));

          totalDocuments++;
        }

        restoredCollections.add(collectionName);
        _logger.d('Restored collection: $collectionName');
      }

      _logger.i('Backup restored successfully');

      return RestoreResult(
        success: true,
        restoredCollections: restoredCollections,
        totalDocuments: totalDocuments,
      );
    } catch (e) {
      _logger.e('Error restoring backup: $e');
      return RestoreResult(
        success: false,
        error: 'فشل في استعادة النسخة الاحتياطية: $e',
      );
    }
  }

  /// مشاركة ملف النسخة الاحتياطية
  Future<void> shareBackup(String filePath) async {
    await Share.shareXFiles([XFile(filePath)],
        text: 'نسخة احتياطية - مدير هور');
  }

  /// الحصول على قائمة النسخ الاحتياطية المحلية
  Future<List<BackupInfo>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = await dir.list().toList();

      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File &&
            file.path.endsWith('.json') &&
            file.path.contains('backup_')) {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;

          backups.add(BackupInfo(
            fileName: fileName,
            filePath: file.path,
            createdAt: stat.modified,
            size: stat.size,
          ));
        }
      }

      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      _logger.e('Error getting local backups: $e');
      return [];
    }
  }

  /// حذف نسخة احتياطية محلية
  Future<bool> deleteLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error deleting backup: $e');
      return false;
    }
  }

  /// إنشاء نسخة احتياطية تلقائية
  Future<void> scheduleAutoBackup({
    required String userId,
    int intervalDays = 7,
  }) async {
    // التحقق من آخر نسخة احتياطية
    final lastBackup = await _getLastBackupDate();

    if (lastBackup == null ||
        DateTime.now().difference(lastBackup).inDays >= intervalDays) {
      _logger.i('Creating auto backup...');
      await createBackup();
    }
  }

  Future<DateTime?> _getLastBackupDate() async {
    try {
      final snapshot = await _firestore
          .collection('backup_records')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return (data['createdAt'] as Timestamp?)?.toDate();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveBackupRecord(
    String fileName,
    DateTime timestamp,
    List<String> collections,
  ) async {
    await _firestore.collection('backup_records').add({
      'fileName': fileName,
      'createdAt': Timestamp.fromDate(timestamp),
      'collections': collections,
    });
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        result[entry.key] = {
          '_type': 'Timestamp',
          'value': (entry.value as Timestamp).toDate().toIso8601String(),
        };
      } else if (entry.value is Map) {
        result[entry.key] =
            _convertTimestamps(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((item) {
          if (item is Map) {
            return _convertTimestamps(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        if (map['_type'] == 'Timestamp') {
          result[entry.key] = Timestamp.fromDate(DateTime.parse(map['value']));
        } else {
          result[entry.key] = _restoreTimestamps(map);
        }
      } else if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((item) {
          if (item is Map) {
            return _restoreTimestamps(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  int _countDocuments(Map<String, dynamic> collections) {
    int count = 0;
    for (final docs in collections.values) {
      if (docs is Map) {
        count += docs.length;
      }
    }
    return count;
  }
}

/// نتيجة النسخ الاحتياطي
class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final DateTime? timestamp;
  final int? collectionsCount;
  final int? totalDocuments;
  final String? error;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.timestamp,
    this.collectionsCount,
    this.totalDocuments,
    this.error,
  });
}

/// نتيجة الاستعادة
class RestoreResult {
  final bool success;
  final List<String>? restoredCollections;
  final int? totalDocuments;
  final String? error;

  RestoreResult({
    required this.success,
    this.restoredCollections,
    this.totalDocuments,
    this.error,
  });
}

/// معلومات نسخة احتياطية
class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int size;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.size,
  });

  /// حجم الملف بصيغة مقروءة
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
