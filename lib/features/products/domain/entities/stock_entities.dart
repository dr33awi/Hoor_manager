import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع حركة المخزون
enum StockMovementType {
  /// وارد (شراء، استلام)
  incoming,

  /// صادر (بيع)
  outgoing,

  /// تعديل يدوي
  adjustment,

  /// مرتجع
  return_,

  /// تالف
  damaged,

  /// نقل بين المخازن
  transfer,
}

/// سبب حركة المخزون
enum StockMovementReason {
  sale,
  purchase,
  return_,
  damaged,
  adjustment,
  transfer,
  initialStock,
  inventoryCount,
}

/// حركة مخزون
class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String? variantId;
  final String? color;
  final String? size;
  final StockMovementType type;
  final StockMovementReason reason;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? referenceId; // رقم الفاتورة أو طلب الشراء
  final String? notes;
  final String performedBy;
  final String? performedByName;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantId,
    this.color,
    this.size,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.referenceId,
    this.notes,
    required this.performedBy,
    this.performedByName,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      variantId: json['variantId'],
      color: json['color'],
      size: json['size'],
      type: StockMovementType.values[json['type'] ?? 0],
      reason: StockMovementReason.values[json['reason'] ?? 0],
      quantity: json['quantity'] ?? 0,
      previousStock: json['previousStock'] ?? 0,
      newStock: json['newStock'] ?? 0,
      referenceId: json['referenceId'],
      notes: json['notes'],
      performedBy: json['performedBy'] ?? '',
      performedByName: json['performedByName'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'color': color,
        'size': size,
        'type': type.index,
        'reason': reason.index,
        'quantity': quantity,
        'previousStock': previousStock,
        'newStock': newStock,
        'referenceId': referenceId,
        'notes': notes,
        'performedBy': performedBy,
        'performedByName': performedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// هل الحركة واردة (زيادة)
  bool get isIncoming =>
      type == StockMovementType.incoming || type == StockMovementType.return_;

  /// هل الحركة صادرة (نقص)
  bool get isOutgoing =>
      type == StockMovementType.outgoing || type == StockMovementType.damaged;

  /// نص نوع الحركة
  String get typeText {
    switch (type) {
      case StockMovementType.incoming:
        return 'وارد';
      case StockMovementType.outgoing:
        return 'صادر';
      case StockMovementType.adjustment:
        return 'تعديل';
      case StockMovementType.return_:
        return 'مرتجع';
      case StockMovementType.damaged:
        return 'تالف';
      case StockMovementType.transfer:
        return 'نقل';
    }
  }

  /// نص سبب الحركة
  String get reasonText {
    switch (reason) {
      case StockMovementReason.sale:
        return 'بيع';
      case StockMovementReason.purchase:
        return 'شراء';
      case StockMovementReason.return_:
        return 'مرتجع';
      case StockMovementReason.damaged:
        return 'تالف';
      case StockMovementReason.adjustment:
        return 'تعديل يدوي';
      case StockMovementReason.transfer:
        return 'نقل';
      case StockMovementReason.initialStock:
        return 'رصيد افتتاحي';
      case StockMovementReason.inventoryCount:
        return 'جرد';
    }
  }
}

/// تنبيه مخزون
class StockAlert {
  final String id;
  final String productId;
  final String productName;
  final StockAlertType type;
  final int currentStock;
  final int threshold;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.currentStock,
    required this.threshold,
    this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      type: StockAlertType.values[json['type'] ?? 0],
      currentStock: json['currentStock'] ?? 0,
      threshold: json['threshold'] ?? 0,
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'type': type.index,
        'currentStock': currentStock,
        'threshold': threshold,
        'message': message,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// أنواع تنبيهات المخزون
enum StockAlertType {
  lowStock,
  outOfStock,
  overStock,
  reorderSuggestion,
}

/// اقتراح إعادة الطلب
class ReorderSuggestion {
  final String productId;
  final String productName;
  final int currentStock;
  final int minStock;
  final int avgMonthlySales;
  final int suggestedQuantity;
  final double estimatedCost;
  final int daysUntilOutOfStock;

  ReorderSuggestion({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStock,
    required this.avgMonthlySales,
    required this.suggestedQuantity,
    required this.estimatedCost,
    required this.daysUntilOutOfStock,
  });

  /// أولوية إعادة الطلب
  ReorderPriority get priority {
    if (currentStock == 0) return ReorderPriority.critical;
    if (daysUntilOutOfStock <= 7) return ReorderPriority.high;
    if (daysUntilOutOfStock <= 14) return ReorderPriority.medium;
    return ReorderPriority.low;
  }
}

/// أولوية إعادة الطلب
enum ReorderPriority {
  critical,
  high,
  medium,
  low,
}

/// نتيجة الجرد
class InventoryCountResult {
  final String id;
  final String productId;
  final String productName;
  final String? variantId;
  final String? color;
  final String? size;
  final int systemStock;
  final int actualStock;
  final int difference;
  final String? notes;
  final String countedBy;
  final DateTime countedAt;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  InventoryCountResult({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantId,
    this.color,
    this.size,
    required this.systemStock,
    required this.actualStock,
    required this.countedBy,
    required this.countedAt,
    this.notes,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  }) : difference = actualStock - systemStock;

  factory InventoryCountResult.fromJson(Map<String, dynamic> json) {
    return InventoryCountResult(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      variantId: json['variantId'],
      color: json['color'],
      size: json['size'],
      systemStock: json['systemStock'] ?? 0,
      actualStock: json['actualStock'] ?? 0,
      notes: json['notes'],
      countedBy: json['countedBy'] ?? '',
      countedAt: (json['countedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: json['isApproved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: (json['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'color': color,
        'size': size,
        'systemStock': systemStock,
        'actualStock': actualStock,
        'difference': difference,
        'notes': notes,
        'countedBy': countedBy,
        'countedAt': Timestamp.fromDate(countedAt),
        'isApproved': isApproved,
        'approvedBy': approvedBy,
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      };

  /// هل يوجد فرق
  bool get hasDifference => difference != 0;

  /// نوع الفرق
  String get differenceType {
    if (difference > 0) return 'زيادة';
    if (difference < 0) return 'نقص';
    return 'متطابق';
  }
}

/// جلسة جرد
class InventoryCountSession {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String startedBy;
  final String? completedBy;
  final List<InventoryCountResult> results;
  final InventoryCountStatus status;

  InventoryCountSession({
    required this.id,
    required this.name,
    required this.startedAt,
    this.completedAt,
    required this.startedBy,
    this.completedBy,
    this.results = const [],
    this.status = InventoryCountStatus.inProgress,
  });

  /// عدد المنتجات التي تم جردها
  int get countedProductsCount => results.length;

  /// عدد المنتجات بفروقات
  int get productsWithDifference =>
      results.where((r) => r.hasDifference).length;

  /// إجمالي فرق الزيادة
  int get totalPositiveDifference => results
      .where((r) => r.difference > 0)
      .fold(0, (sum, r) => sum + r.difference);

  /// إجمالي فرق النقص
  int get totalNegativeDifference => results
      .where((r) => r.difference < 0)
      .fold(0, (sum, r) => sum + r.difference.abs());
}

/// حالة جلسة الجرد
enum InventoryCountStatus {
  inProgress,
  completed,
  approved,
  cancelled,
}
