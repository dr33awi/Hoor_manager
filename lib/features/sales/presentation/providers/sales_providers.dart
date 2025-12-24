import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/entities/entities.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/sales_repository.dart';

// ==================== Repository Providers ====================

/// مزود مستودع المبيعات
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepositoryImpl(
    productRepository: ProductRepositoryImpl(),
  );
});

// ==================== Cart Providers ====================

/// حالة السلة
class CartState {
  final List<CartItem> items;
  final Discount discount;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  const CartState({
    this.items = const [],
    this.discount = Discount.none,
    this.customerName,
    this.customerPhone,
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
    String? customerName,
    String? customerPhone,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
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

  /// تعيين معلومات العميل
  void setCustomerInfo({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
    );
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

/// مزود فواتير اليوم
final todayInvoicesProvider = StreamProvider<List<InvoiceEntity>>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  return repository.watchTodayInvoices();
});

/// مزود الفواتير
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

/// مزود فاتورة واحدة
final invoiceProvider = FutureProvider.family<InvoiceEntity?, String>(
  (ref, invoiceId) async {
    final repository = ref.watch(salesRepositoryProvider);
    final result = await repository.getInvoiceById(invoiceId);
    return result.valueOrNull;
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

/// مزود إحصائيات اليوم الحالي
final todayStatsProvider = FutureProvider<DailySalesStats>((ref) async {
  return ref.watch(dailyStatsProvider(DateTime.now()).future);
});

// ==================== Sales Actions ====================

/// إدارة عمليات المبيعات
class SalesActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// إنشاء فاتورة
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
        customerName: cart.customerName,
        customerPhone: cart.customerPhone,
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
      ref.invalidate(invoiceProvider(invoiceId));
      ref.invalidate(todayInvoicesProvider);
      return true;
    } else {
      state = AsyncValue.error(result.errorOrNull!, StackTrace.current);
      return false;
    }
  }
}

/// مزود إدارة عمليات المبيعات
final salesActionsProvider =
    NotifierProvider<SalesActionsNotifier, AsyncValue<void>>(() {
  return SalesActionsNotifier();
});
