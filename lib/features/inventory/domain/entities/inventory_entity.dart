import 'package:flutter/material.dart';

/// حالة المستودع
enum WarehouseStatus {
  active,
  inactive,
  maintenance;

  String get arabicName {
    switch (this) {
      case WarehouseStatus.active:
        return 'نشط';
      case WarehouseStatus.inactive:
        return 'غير نشط';
      case WarehouseStatus.maintenance:
        return 'صيانة';
    }
  }

  Color get color {
    switch (this) {
      case WarehouseStatus.active:
        return Colors.green;
      case WarehouseStatus.inactive:
        return Colors.grey;
      case WarehouseStatus.maintenance:
        return Colors.orange;
    }
  }
}

/// نوع حركة المخزون
enum StockMovementType {
  inbound, // وارد
  outbound, // صادر
  transfer, // تحويل
  adjustment, // تعديل
  return_; // مرتجع

  String get arabicName {
    switch (this) {
      case StockMovementType.inbound:
        return 'وارد';
      case StockMovementType.outbound:
        return 'صادر';
      case StockMovementType.transfer:
        return 'تحويل';
      case StockMovementType.adjustment:
        return 'تعديل';
      case StockMovementType.return_:
        return 'مرتجع';
    }
  }

  Color get color {
    switch (this) {
      case StockMovementType.inbound:
        return Colors.green;
      case StockMovementType.outbound:
        return Colors.red;
      case StockMovementType.transfer:
        return Colors.blue;
      case StockMovementType.adjustment:
        return Colors.orange;
      case StockMovementType.return_:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case StockMovementType.inbound:
        return Icons.arrow_downward;
      case StockMovementType.outbound:
        return Icons.arrow_upward;
      case StockMovementType.transfer:
        return Icons.swap_horiz;
      case StockMovementType.adjustment:
        return Icons.tune;
      case StockMovementType.return_:
        return Icons.undo;
    }
  }
}

/// حالة حركة المخزون
enum StockMovementStatus {
  pending,
  approved,
  cancelled;

  String get arabicName {
    switch (this) {
      case StockMovementStatus.pending:
        return 'معلق';
      case StockMovementStatus.approved:
        return 'معتمد';
      case StockMovementStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case StockMovementStatus.pending:
        return Colors.orange;
      case StockMovementStatus.approved:
        return Colors.green;
      case StockMovementStatus.cancelled:
        return Colors.red;
    }
  }
}

/// حالة الجرد
enum StockTakeStatus {
  draft,
  inProgress,
  completed,
  cancelled;

  String get arabicName {
    switch (this) {
      case StockTakeStatus.draft:
        return 'مسودة';
      case StockTakeStatus.inProgress:
        return 'جاري';
      case StockTakeStatus.completed:
        return 'مكتمل';
      case StockTakeStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case StockTakeStatus.draft:
        return Colors.grey;
      case StockTakeStatus.inProgress:
        return Colors.blue;
      case StockTakeStatus.completed:
        return Colors.green;
      case StockTakeStatus.cancelled:
        return Colors.red;
    }
  }
}

/// كيان المستودع
class WarehouseEntity {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? address;
  final String? phone;
  final String? manager;
  final WarehouseStatus status;
  final bool isDefault;
  final double? capacity;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WarehouseEntity({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.address,
    this.phone,
    this.manager,
    this.status = WarehouseStatus.active,
    this.isDefault = false,
    this.capacity,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  WarehouseEntity copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? address,
    String? phone,
    String? manager,
    WarehouseStatus? status,
    bool? isDefault,
    double? capacity,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarehouseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      manager: manager ?? this.manager,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      capacity: capacity ?? this.capacity,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان حركة المخزون
class StockMovementEntity {
  final String id;
  final String movementNumber;
  final StockMovementType type;
  final StockMovementStatus status;
  final String? sourceWarehouseId;
  final String? sourceWarehouseName;
  final String? destinationWarehouseId;
  final String? destinationWarehouseName;
  final String? referenceType; // invoice, purchase, return, etc.
  final String? referenceId;
  final String? referenceNumber;
  final List<StockMovementItemEntity> items;
  final String? notes;
  final String createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime movementDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockMovementEntity({
    required this.id,
    required this.movementNumber,
    required this.type,
    this.status = StockMovementStatus.pending,
    this.sourceWarehouseId,
    this.sourceWarehouseName,
    this.destinationWarehouseId,
    this.destinationWarehouseName,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.items = const [],
    this.notes,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    required this.movementDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// إجمالي الكمية
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// عدد الأصناف
  int get itemCount => items.length;

  StockMovementEntity copyWith({
    String? id,
    String? movementNumber,
    StockMovementType? type,
    StockMovementStatus? status,
    String? sourceWarehouseId,
    String? sourceWarehouseName,
    String? destinationWarehouseId,
    String? destinationWarehouseName,
    String? referenceType,
    String? referenceId,
    String? referenceNumber,
    List<StockMovementItemEntity>? items,
    String? notes,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? movementDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockMovementEntity(
      id: id ?? this.id,
      movementNumber: movementNumber ?? this.movementNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      sourceWarehouseId: sourceWarehouseId ?? this.sourceWarehouseId,
      sourceWarehouseName: sourceWarehouseName ?? this.sourceWarehouseName,
      destinationWarehouseId:
          destinationWarehouseId ?? this.destinationWarehouseId,
      destinationWarehouseName:
          destinationWarehouseName ?? this.destinationWarehouseName,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      movementDate: movementDate ?? this.movementDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان عنصر حركة المخزون
class StockMovementItemEntity {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? variantId;
  final String? variantName;
  final int quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;

  const StockMovementItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.variantId,
    this.variantName,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    this.notes,
  });

  StockMovementItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? variantId,
    String? variantName,
    int? quantity,
    String? batchNumber,
    DateTime? expiryDate,
    String? notes,
  }) {
    return StockMovementItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
    );
  }
}

/// كيان الجرد
class StockTakeEntity {
  final String id;
  final String stockTakeNumber;
  final String warehouseId;
  final String warehouseName;
  final StockTakeStatus status;
  final DateTime stockTakeDate;
  final List<StockTakeItemEntity> items;
  final String? notes;
  final String createdBy;
  final String? completedBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockTakeEntity({
    required this.id,
    required this.stockTakeNumber,
    required this.warehouseId,
    required this.warehouseName,
    this.status = StockTakeStatus.draft,
    required this.stockTakeDate,
    this.items = const [],
    this.notes,
    required this.createdBy,
    this.completedBy,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// عدد الأصناف
  int get itemCount => items.length;

  /// عدد الأصناف المتطابقة
  int get matchedCount => items.where((item) => item.difference == 0).length;

  /// عدد الأصناف بفروقات موجبة
  int get surplusCount => items.where((item) => item.difference > 0).length;

  /// عدد الأصناف بفروقات سالبة
  int get shortageCount => items.where((item) => item.difference < 0).length;

  StockTakeEntity copyWith({
    String? id,
    String? stockTakeNumber,
    String? warehouseId,
    String? warehouseName,
    StockTakeStatus? status,
    DateTime? stockTakeDate,
    List<StockTakeItemEntity>? items,
    String? notes,
    String? createdBy,
    String? completedBy,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockTakeEntity(
      id: id ?? this.id,
      stockTakeNumber: stockTakeNumber ?? this.stockTakeNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      status: status ?? this.status,
      stockTakeDate: stockTakeDate ?? this.stockTakeDate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// كيان عنصر الجرد
class StockTakeItemEntity {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? variantId;
  final String? variantName;
  final int systemQuantity; // الكمية في النظام
  final int actualQuantity; // الكمية الفعلية
  final String? notes;

  const StockTakeItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.variantId,
    this.variantName,
    required this.systemQuantity,
    required this.actualQuantity,
    this.notes,
  });

  /// الفرق بين الكمية الفعلية والنظامية
  int get difference => actualQuantity - systemQuantity;

  /// هل هناك فرق
  bool get hasDifference => difference != 0;

  StockTakeItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? variantId,
    String? variantName,
    int? systemQuantity,
    int? actualQuantity,
    String? notes,
  }) {
    return StockTakeItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      notes: notes ?? this.notes,
    );
  }
}

/// كيان رصيد المخزون
class StockBalanceEntity {
  final String productId;
  final String productName;
  final String? productSku;
  final String? variantId;
  final String? variantName;
  final String warehouseId;
  final String warehouseName;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final double? averageCost;
  final DateTime lastUpdated;

  const StockBalanceEntity({
    required this.productId,
    required this.productName,
    this.productSku,
    this.variantId,
    this.variantName,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    this.reservedQuantity = 0,
    required this.availableQuantity,
    this.averageCost,
    required this.lastUpdated,
  });
}
