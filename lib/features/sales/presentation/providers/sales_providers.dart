import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_service.dart';
import '../../../products/domain/entities/entities.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/sales_repository.dart';

// ==================== Repository Providers ====================

/// مزود خدمة الأوفلاين
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

/// مزود مستودع المبيعات مع دعم الأوفلاين
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  return SalesRepositoryImpl(
    productRepository: productRepository,
    offlineService: offlineService,
  );
});

// ==================== Cart Providers ====================

/// حالة السلة
class CartState {
  final List<CartItem> items;
  final Discount discount;
  final String? notes;

  const CartState({
    this.items = const [],
    this.discount = Discount.none,
    this.notes,
  });

  /// المجموع الفرعي
  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  /// قيمة الخصم
  double get discountAmount => discount.calculate(subtotal);

  /// الإجمالي
  double get total => subtotal - discountAmount;

  /// إجمالي التكلفة
  double get totalCost => items.fold(0, (sum, item) => sum + item.totalCost);

  /// الربح
  double get profit => total - totalCost;

  /// عدد المنتجات
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// هل السلة فارغة
  bool get isEmpty => items.isEmpty;

  /// هل السلة غير فارغة
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    Discount? discount,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
    );
  }
}

/// مدير السلة
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  /// إضافة منتج للسلة
  void addItem({
    required ProductEntity product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id && item.variantId == variant.id,
    );

    if (existingIndex != -1) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = CartItem.fromProduct(
        product: product,
        variant: variant,
        quantity: quantity,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// تحديث كمية منتج
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// زيادة الكمية
  void incrementQuantity(String itemId) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    updateQuantity(itemId, item.quantity + 1);
  }

  /// تقليل الكمية
  void decrementQuantity(String itemId) {
    final item = state.items.firstWhere((i) => i.id == itemId);
    updateQuantity(itemId, item.quantity - 1);
  }

  /// إزالة منتج من السلة
  void removeItem(String itemId) {
    final updatedItems =
        state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// تطبيق خصم
  void applyDiscount(Discount discount) {
    state = state.copyWith(discount: discount);
  }

  /// إزالة الخصم
  void removeDiscount() {
    state = state.copyWith(discount: Discount.none);
  }

  /// تعيين ملاحظات
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  /// مسح السلة
  void clear() {
    state = const CartState();
  }
}

/// مزود السلة
final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

// ==================== Invoice Providers ====================

/// مزود فواتير اليوم (Stream للتحديث التلقائي)
final todayInvoicesProvider = StreamProvider<List<InvoiceEntity>>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  return repository.watchTodayInvoices();
});

/// مزود الفواتير (Future - للاستخدام مرة واحدة)
final invoicesProvider = FutureProvider.family<List<InvoiceEntity>,
    ({DateTime? start, DateTime? end})>(
  (ref, params) async {
    final repository = ref.watch(salesRepositoryProvider);
    final result = await repository.getInvoices(
      startDate: params.start,
      endDate: params.end,
    );
    return result.valueOrNull ?? [];
  },
);

/// مزود فاتورة واحدة (Future - للاستخدام مرة واحدة)
final invoiceProvider = FutureProvider.family<InvoiceEntity?, String>(
  (ref, invoiceId) async {
    final repository = ref.watch(salesRepositoryProvider);
    final result = await repository.getInvoiceById(invoiceId);
    return result.valueOrNull;
  },
);

/// مزود فاتورة واحدة (Stream - للتحديث التلقائي)
final invoiceStreamProvider = StreamProvider.family<InvoiceEntity?, String>(
  (ref, invoiceId) {
    final repository = ref.watch(salesRepositoryProvider);
    return repository.watchInvoice(invoiceId);
  },
);

/// مزود إحصائيات اليوم
final dailyStatsProvider = FutureProvider.family<DailySalesStats, DateTime>(
  (ref, date) async {
    final repository = ref.watch(salesRepositoryProvider);
    final result = await repository.getDailySalesStats(date);
    return result.valueOrNull ?? DailySalesStats.empty(date);
  },
);

/// مزود إحصائيات اليوم الحالي (يتحدث تلقائياً من فواتير اليوم)
final todayStatsProvider = Provider<AsyncValue<DailySalesStats>>((ref) {
  final invoicesAsync = ref.watch(todayInvoicesProvider);
  return invoicesAsync.when(
    data: (invoices) =>
        AsyncValue.data(DailySalesStats.fromInvoices(DateTime.now(), invoices)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// مزود عدد العمليات المعلقة
final pendingOperationsCountProvider = Provider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingOperationsCount;
});

/// مزود Stream لعدد العمليات المعلقة
final pendingOperationsStreamProvider = StreamProvider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingCountStream;
});

/// مزود حالة الاتصال
final connectivityProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectivityStream;
});

/// مزود حالة المزامنة
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.syncStatusStream;
});

// ==================== Sales Actions ====================

/// إدارة عمليات المبيعات مع دعم الأوفلاين
class SalesActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// التحقق من حالة الاتصال
  bool get isOnline => ref.read(offlineServiceProvider).isOnline;

  /// إنشاء فاتورة (يعمل أوفلاين)
  Future<InvoiceEntity?> createInvoice({
    required String soldBy,
    String? soldByName,
    double? amountPaid,
  }) async {
    final repository = ref.read(salesRepositoryProvider);
    final cart = ref.read(cartProvider);
    state = const AsyncValue.loading();

    try {
      if (cart.isEmpty) {
        state = AsyncValue.error('السلة فارغة', StackTrace.current);
        return null;
      }

      // توليد رقم الفاتورة
      final invoiceNumberResult = await repository.generateInvoiceNumber();
      if (!invoiceNumberResult.isSuccess) {
        state = AsyncValue.error(
            invoiceNumberResult.errorOrNull!, StackTrace.current);
        return null;
      }

      final invoiceNumber = invoiceNumberResult.valueOrNull!;
      final paid = amountPaid ?? cart.total;
      final change = paid - cart.total;

      // إنشاء الفاتورة
      final invoice = InvoiceEntity(
        id: '',
        invoiceNumber: invoiceNumber,
        items: cart.items,
        subtotal: cart.subtotal,
        discount: cart.discount,
        discountAmount: cart.discountAmount,
        total: cart.total,
        totalCost: cart.totalCost,
        profit: cart.profit,
        paymentMethod: PaymentMethod.cash,
        amountPaid: paid,
        change: change > 0 ? change : 0,
        status: InvoiceStatus.completed,
        notes: cart.notes,
        soldBy: soldBy,
        soldByName: soldByName,
        saleDate: DateTime.now(),
      );

      final result = await repository.createInvoice(invoice);

      if (result.isSuccess) {
        state = const AsyncValue.data(null);
        // مسح السلة بعد إنشاء الفاتورة بنجاح
        ref.read(cartProvider.notifier).clear();
        // تحديث البيانات
        _refreshData();
        return result.valueOrNull;
      } else {
        state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
        return null;
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  /// إلغاء فاتورة
  Future<bool> cancelInvoice({
    required String invoiceId,
    required String cancelledBy,
    String? reason,
  }) async {
    final repository = ref.read(salesRepositoryProvider);
    state = const AsyncValue.loading();

    final result = await repository.cancelInvoice(
      invoiceId: invoiceId,
      cancelledBy: cancelledBy,
      reason: reason,
    );

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
      // تحديث البيانات
      ref.invalidate(invoiceProvider(invoiceId));
      ref.invalidate(invoiceStreamProvider(invoiceId));
      _refreshData();
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }

  /// تحديث البيانات
  void _refreshData() {
    ref.invalidate(todayInvoicesProvider);
    ref.invalidate(dailyStatsProvider(DateTime.now()));
  }

  /// مزامنة البيانات يدوياً
  Future<SyncResult> syncData() async {
    final offlineService = ref.read(offlineServiceProvider);
    final result = await offlineService.syncPendingOperations();
    if (result.success) {
      _refreshData();
    }
    return result;
  }
}

/// مزود إدارة عمليات المبيعات
final salesActionsProvider =
    NotifierProvider<SalesActionsNotifier, AsyncValue<void>>(() {
  return SalesActionsNotifier();
});

// ==================== Direct Sale Provider ====================

/// إدارة البيع المباشر مع دعم الأوفلاين (بدون سلة)
class DirectSaleNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// التحقق من حالة الاتصال
  bool get isOnline => ref.read(offlineServiceProvider).isOnline;

  /// إنشاء فاتورة بيع مباشر (يعمل أوفلاين)
  Future<InvoiceEntity?> createDirectSale({
    required CartItem item,
    required Discount discount,
    required double amountPaid,
    required String soldBy,
    String? soldByName,
    String? notes,
  }) async {
    final repository = ref.read(salesRepositoryProvider);
    state = const AsyncValue.loading();

    try {
      // حساب القيم
      final subtotal = item.totalPrice;
      final discountAmount = discount.calculate(subtotal);
      final total = subtotal - discountAmount;
      final totalCost = item.totalCost;
      final profit = total - totalCost;
      final change = amountPaid - total;

      // توليد رقم الفاتورة
      final invoiceNumberResult = await repository.generateInvoiceNumber();
      if (!invoiceNumberResult.isSuccess) {
        state = AsyncValue.error(
            invoiceNumberResult.errorOrNull!, StackTrace.current);
        return null;
      }

      final invoiceNumber = invoiceNumberResult.valueOrNull!;

      // إنشاء الفاتورة
      final invoice = InvoiceEntity(
        id: '',
        invoiceNumber: invoiceNumber,
        items: [item],
        subtotal: subtotal,
        discount: discount,
        discountAmount: discountAmount,
        total: total,
        totalCost: totalCost,
        profit: profit,
        paymentMethod: PaymentMethod.cash,
        amountPaid: amountPaid,
        change: change > 0 ? change : 0,
        status: InvoiceStatus.completed,
        notes: notes,
        soldBy: soldBy,
        soldByName: soldByName,
        saleDate: DateTime.now(),
      );

      final result = await repository.createInvoice(invoice);

      if (result.isSuccess) {
        state = const AsyncValue.data(null);
        // تحديث البيانات
        _refreshData();
        return result.valueOrNull;
      } else {
        state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
        return null;
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  /// تحديث البيانات
  void _refreshData() {
    ref.invalidate(todayInvoicesProvider);
    ref.invalidate(dailyStatsProvider(DateTime.now()));
  }
}

/// مزود البيع المباشر
final directSaleProvider =
    NotifierProvider<DirectSaleNotifier, AsyncValue<void>>(() {
  return DirectSaleNotifier();
});

// ==================== Offline Invoice Providers ====================

/// مزود فاتورة أوفلاين بواسطة ID
final offlineInvoiceProvider = Provider.family<InvoiceEntity?, String>(
  (ref, invoiceId) {
    final offlineService = ref.watch(offlineServiceProvider);
    final invoiceMap = offlineService.getOfflineInvoiceById(invoiceId);
    if (invoiceMap == null) return null;
    return InvoiceModel.fromOfflineMap(invoiceMap, invoiceId);
  },
);

/// مزود ذكي للفاتورة - يدعم الأوفلاين والأونلاين
/// يستخدم هذا بدلاً من invoiceStreamProvider للشاشات التي تحتاج دعم أوفلاين
final smartInvoiceProvider = FutureProvider.family<InvoiceEntity?, String>(
  (ref, invoiceId) async {
    // إذا كان ID يبدأ بـ offline_ فهي فاتورة محلية
    if (invoiceId.startsWith('offline_')) {
      return ref.watch(offlineInvoiceProvider(invoiceId));
    }

    // خلاف ذلك، جلب من Firebase
    final repository = ref.watch(salesRepositoryProvider);
    final result = await repository.getInvoiceById(invoiceId);
    return result.valueOrNull;
  },
);

/// مزود كل الفواتير الأوفلاين
final allOfflineInvoicesProvider = Provider<List<InvoiceEntity>>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  final invoiceMaps = offlineService.getOfflineInvoices();
  return invoiceMaps.map((map) {
    final id = map['id'] as String? ?? '';
    return InvoiceModel.fromOfflineMap(map, id);
  }).toList();
});
