// lib/features/sales/providers/sale_provider.dart
// مزود حالة المبيعات - مبسط

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/base_service.dart';
import '../models/sale_model.dart';
import '../../../core/services/sale_service.dart';

class SaleProvider with ChangeNotifier {
  final SaleService _saleService = SaleService();

  List<SaleModel> _sales = [];
  List<SaleItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterStatus;
  StreamSubscription? _salesSubscription;

  // بيانات الفاتورة الحالية
  String? _notes;
  double _discountPercent = 0;
  double _discountAmount = 0;

  // Getters
  List<SaleModel> get sales => _getFilteredSales();
  List<SaleModel> get allSales => _sales;
  List<SaleItem> get cartItems => List.unmodifiable(_cartItems);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get notes => _notes;
  double get discountPercent => _discountPercent;
  double get discountAmount => _discountAmount;

  /// المجموع الفرعي
  double get subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// قيمة الخصم
  double get discount {
    if (_discountAmount > 0) return _discountAmount.clamp(0, subtotal);
    return (subtotal * (_discountPercent / 100)).clamp(0, subtotal);
  }

  /// الإجمالي النهائي (بدون ضريبة)
  double get total => subtotal - discount;

  /// عدد العناصر
  int get cartItemsCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// هل السلة فارغة
  bool get isCartEmpty => _cartItems.isEmpty;

  /// المبيعات المفلترة
  List<SaleModel> _getFilteredSales() {
    var filtered = _sales;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.invoiceNumber.toLowerCase().contains(query) ||
            s.items.any(
              (item) => item.productName.toLowerCase().contains(query),
            );
      }).toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((s) => s.status == _filterStatus).toList();
    }

    return filtered;
  }

  /// مبيعات اليوم
  List<SaleModel> get todaySales {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _sales.where((s) {
      return s.saleDate.isAfter(startOfDay) && s.isCompleted;
    }).toList();
  }

  /// إجمالي مبيعات اليوم
  double get todayTotal => todaySales.fold(0, (sum, s) => sum + s.total);

  /// عدد فواتير اليوم
  int get todayOrdersCount => todaySales.length;

  /// ربح اليوم
  double get todayProfit => todaySales.fold(0, (sum, s) => sum + s.totalProfit);

  /// تحميل المبيعات
  Future<void> loadSales({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _saleService.getAllSales(
      startDate: startDate,
      endDate: endDate,
    );

    if (result.success) {
      _sales = result.data!;
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// إضافة عنصر للسلة مع التحقق من الكمية
  ServiceResult<void> addToCart(SaleItem item, {int? availableQuantity}) {
    // التحقق من الكمية المتوفرة
    if (availableQuantity != null) {
      final existingItem = _findCartItem(item.productId, item.color, item.size);
      final currentQty = existingItem?.quantity ?? 0;

      if (currentQty + item.quantity > availableQuantity) {
        return ServiceResult.failure(
          'الكمية المطلوبة أكبر من المتوفر ($availableQuantity)',
        );
      }
    }

    // التحقق من الحد الأقصى
    if (cartItemsCount + item.quantity > AppConstants.maxCartItems) {
      return ServiceResult.failure('تم الوصول للحد الأقصى لعناصر السلة');
    }

    final existingIndex = _findCartItemIndex(
      item.productId,
      item.color,
      item.size,
    );

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _cartItems.add(item);
    }

    notifyListeners();
    return ServiceResult.success();
  }

  /// البحث عن عنصر في السلة
  SaleItem? _findCartItem(String productId, String color, int size) {
    try {
      return _cartItems.firstWhere(
        (i) => i.productId == productId && i.color == color && i.size == size,
      );
    } catch (_) {
      return null;
    }
  }

  int _findCartItemIndex(String productId, String color, int size) {
    return _cartItems.indexWhere(
      (i) => i.productId == productId && i.color == color && i.size == size,
    );
  }

  /// تحديث كمية عنصر
  void updateCartItemQuantity(int index, int quantity) {
    if (index < 0 || index >= _cartItems.length) return;

    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else if (quantity <= AppConstants.maxQuantityPerItem) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
    }

    notifyListeners();
  }

  /// حذف عنصر من السلة
  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  /// مسح السلة
  void clearCart() {
    _cartItems.clear();
    _resetCheckoutData();
    notifyListeners();
  }

  void _resetCheckoutData() {
    _notes = null;
    _discountPercent = 0;
    _discountAmount = 0;
  }

  void setNotes(String? notes) {
    _notes = notes?.trim().isEmpty == true ? null : notes?.trim();
    notifyListeners();
  }

  void setDiscountPercent(double percent) {
    _discountPercent = percent.clamp(
      0,
      AppConstants.maxDiscountPercent.toDouble(),
    );
    _discountAmount = 0;
    notifyListeners();
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount.clamp(0, subtotal);
    _discountPercent = 0;
    notifyListeners();
  }

  /// إنشاء الفاتورة
  Future<SaleModel?> createSale() async {
    if (_cartItems.isEmpty) {
      _error = 'السلة فارغة';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final sale = SaleModel(
      id: '',
      invoiceNumber: '',
      items: List.from(_cartItems),
      subtotal: subtotal,
      discount: discount,
      discountPercent: _discountPercent,
      total: total,
      status: AppConstants.saleStatusCompleted,
      notes: _notes,
      userId: '',
      userName: '',
      saleDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final result = await _saleService.createSale(sale);

    _isLoading = false;

    if (result.success) {
      clearCart();
      await loadSales();
      notifyListeners();
      return result.data;
    } else {
      _error = result.error;
      notifyListeners();
      return null;
    }
  }

  /// إلغاء فاتورة
  Future<bool> cancelSale(String saleId, {String? reason}) async {
    _error = null;

    final result = await _saleService.cancelSale(saleId, reason: reason);

    if (result.success) {
      await loadSales();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// الحصول على فاتورة بالـ ID
  SaleModel? getSaleById(String id) {
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// بدء الاستماع للتحديثات
  void startListening() {
    _salesSubscription?.cancel();
    _salesSubscription = _saleService.streamSales().listen((sales) {
      _sales = sales;
      notifyListeners();
    });
  }

  /// إيقاف الاستماع
  void stopListening() {
    _salesSubscription?.cancel();
    _salesSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
