import 'dart:async';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'connectivity_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/cash_repository.dart';

/// Service to handle data synchronization between local and cloud storage
class SyncService extends ChangeNotifier {
  final ConnectivityService _connectivity;
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final InvoiceRepository _invoiceRepo;
  final InventoryRepository _inventoryRepo;
  final ShiftRepository _shiftRepo;
  final CashRepository _cashRepo;

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isOnline => _connectivity.isOnline;

  SyncService({
    required ConnectivityService connectivity,
    required ProductRepository productRepo,
    required CategoryRepository categoryRepo,
    required InvoiceRepository invoiceRepo,
    required InventoryRepository inventoryRepo,
    required ShiftRepository shiftRepo,
    required CashRepository cashRepo,
  })  : _connectivity = connectivity,
        _productRepo = productRepo,
        _categoryRepo = categoryRepo,
        _invoiceRepo = invoiceRepo,
        _inventoryRepo = inventoryRepo,
        _shiftRepo = shiftRepo,
        _cashRepo = cashRepo;

  /// Initialize sync service and start periodic sync
  Future<void> initialize() async {
    await _connectivity.initialize();

    // Listen for connectivity changes
    _connectivity.addListener(_onConnectivityChanged);

    // Start periodic sync
    _startPeriodicSync();

    // Initial sync if online
    if (_connectivity.isOnline) {
      await syncAll();
    }
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline) {
      // Sync pending changes when coming online
      syncAll();
    }
    notifyListeners();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Sync all data
  Future<void> syncAll() async {
    if (_isSyncing || !_connectivity.isOnline) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Sync in order of dependencies
      await _categoryRepo.syncPendingChanges();
      await _productRepo.syncPendingChanges();
      await _invoiceRepo.syncPendingChanges();
      await _inventoryRepo.syncPendingChanges();
      await _shiftRepo.syncPendingChanges();
      await _cashRepo.syncPendingChanges();

      // Pull latest from cloud
      await _categoryRepo.pullFromCloud();
      await _productRepo.pullFromCloud();
      await _invoiceRepo.pullFromCloud();
      await _inventoryRepo.pullFromCloud();
      await _shiftRepo.pullFromCloud();
      await _cashRepo.pullFromCloud();

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Force sync specific repository
  Future<void> syncRepository(String repoName) async {
    if (!_connectivity.isOnline) return;

    try {
      switch (repoName) {
        case 'products':
          await _productRepo.syncPendingChanges();
          await _productRepo.pullFromCloud();
          break;
        case 'categories':
          await _categoryRepo.syncPendingChanges();
          await _categoryRepo.pullFromCloud();
          break;
        case 'invoices':
          await _invoiceRepo.syncPendingChanges();
          await _invoiceRepo.pullFromCloud();
          break;
        case 'inventory':
          await _inventoryRepo.syncPendingChanges();
          await _inventoryRepo.pullFromCloud();
          break;
        case 'shifts':
          await _shiftRepo.syncPendingChanges();
          await _shiftRepo.pullFromCloud();
          break;
        case 'cash':
          await _cashRepo.syncPendingChanges();
          await _cashRepo.pullFromCloud();
          break;
      }
    } catch (e) {
      debugPrint('Sync error for $repoName: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
