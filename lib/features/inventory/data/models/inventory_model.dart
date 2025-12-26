import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// موديل المستودع
class WarehouseModel extends WarehouseEntity {
  const WarehouseModel({
    required super.id,
    required super.name,
    super.code,
    super.description,
    super.address,
    super.phone,
    super.manager,
    super.status,
    super.isDefault,
    super.capacity,
    super.metadata,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory WarehouseModel.fromEntity(WarehouseEntity entity) {
    return WarehouseModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      description: entity.description,
      address: entity.address,
      phone: entity.phone,
      manager: entity.manager,
      status: entity.status,
      isDefault: entity.isDefault,
      capacity: entity.capacity,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory WarehouseModel.fromMap(Map<String, dynamic> map, String id) {
    return WarehouseModel(
      id: id,
      name: map['name'] ?? '',
      code: map['code'],
      description: map['description'],
      address: map['address'],
      phone: map['phone'],
      manager: map['manager'],
      status: WarehouseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WarehouseStatus.active,
      ),
      isDefault: map['isDefault'] ?? false,
      capacity: (map['capacity'] as num?)?.toDouble(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'address': address,
      'phone': phone,
      'manager': manager,
      'status': status.name,
      'isDefault': isDefault,
      'capacity': capacity,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// موديل حركة المخزون
class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.movementNumber,
    required super.type,
    super.status,
    super.sourceWarehouseId,
    super.sourceWarehouseName,
    super.destinationWarehouseId,
    super.destinationWarehouseName,
    super.referenceType,
    super.referenceId,
    super.referenceNumber,
    super.items,
    super.notes,
    required super.createdBy,
    super.approvedBy,
    super.approvedAt,
    required super.movementDate,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory StockMovementModel.fromEntity(StockMovementEntity entity) {
    return StockMovementModel(
      id: entity.id,
      movementNumber: entity.movementNumber,
      type: entity.type,
      status: entity.status,
      sourceWarehouseId: entity.sourceWarehouseId,
      sourceWarehouseName: entity.sourceWarehouseName,
      destinationWarehouseId: entity.destinationWarehouseId,
      destinationWarehouseName: entity.destinationWarehouseName,
      referenceType: entity.referenceType,
      referenceId: entity.referenceId,
      referenceNumber: entity.referenceNumber,
      items: entity.items
          .map((e) => StockMovementItemModel.fromEntity(e))
          .toList(),
      notes: entity.notes,
      createdBy: entity.createdBy,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      movementDate: entity.movementDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory StockMovementModel.fromMap(Map<String, dynamic> map, String id) {
    return StockMovementModel(
      id: id,
      movementNumber: map['movementNumber'] ?? '',
      type: StockMovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StockMovementType.adjustment,
      ),
      status: StockMovementStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StockMovementStatus.pending,
      ),
      sourceWarehouseId: map['sourceWarehouseId'],
      sourceWarehouseName: map['sourceWarehouseName'],
      destinationWarehouseId: map['destinationWarehouseId'],
      destinationWarehouseName: map['destinationWarehouseName'],
      referenceType: map['referenceType'],
      referenceId: map['referenceId'],
      referenceNumber: map['referenceNumber'],
      items: (map['items'] as List<dynamic>?)
              ?.map((e) =>
                  StockMovementItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      approvedBy: map['approvedBy'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      movementDate:
          (map['movementDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'movementNumber': movementNumber,
      'type': type.name,
      'status': status.name,
      'sourceWarehouseId': sourceWarehouseId,
      'sourceWarehouseName': sourceWarehouseName,
      'destinationWarehouseId': destinationWarehouseId,
      'destinationWarehouseName': destinationWarehouseName,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'items': items
          .map((e) => StockMovementItemModel.fromEntity(e).toMap())
          .toList(),
      'notes': notes,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'movementDate': Timestamp.fromDate(movementDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// موديل عنصر حركة المخزون
class StockMovementItemModel extends StockMovementItemEntity {
  const StockMovementItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.variantId,
    super.variantName,
    required super.quantity,
    super.batchNumber,
    super.expiryDate,
    super.notes,
  });

  /// تحويل من Entity
  factory StockMovementItemModel.fromEntity(StockMovementItemEntity entity) {
    return StockMovementItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      variantId: entity.variantId,
      variantName: entity.variantName,
      quantity: entity.quantity,
      batchNumber: entity.batchNumber,
      expiryDate: entity.expiryDate,
      notes: entity.notes,
    );
  }

  /// تحويل من Map
  factory StockMovementItemModel.fromMap(Map<String, dynamic> map) {
    return StockMovementItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'],
      variantId: map['variantId'],
      variantName: map['variantName'],
      quantity: map['quantity'] ?? 0,
      batchNumber: map['batchNumber'],
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      notes: map['notes'],
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'variantId': variantId,
      'variantName': variantName,
      'quantity': quantity,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'notes': notes,
    };
  }
}

/// موديل الجرد
class StockTakeModel extends StockTakeEntity {
  const StockTakeModel({
    required super.id,
    required super.stockTakeNumber,
    required super.warehouseId,
    required super.warehouseName,
    super.status,
    required super.stockTakeDate,
    super.items,
    super.notes,
    required super.createdBy,
    super.completedBy,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  /// تحويل من Entity
  factory StockTakeModel.fromEntity(StockTakeEntity entity) {
    return StockTakeModel(
      id: entity.id,
      stockTakeNumber: entity.stockTakeNumber,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      status: entity.status,
      stockTakeDate: entity.stockTakeDate,
      items: entity.items.map((e) => StockTakeItemModel.fromEntity(e)).toList(),
      notes: entity.notes,
      createdBy: entity.createdBy,
      completedBy: entity.completedBy,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// تحويل من Firestore
  factory StockTakeModel.fromMap(Map<String, dynamic> map, String id) {
    return StockTakeModel(
      id: id,
      stockTakeNumber: map['stockTakeNumber'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      warehouseName: map['warehouseName'] ?? '',
      status: StockTakeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StockTakeStatus.draft,
      ),
      stockTakeDate:
          (map['stockTakeDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List<dynamic>?)
              ?.map(
                  (e) => StockTakeItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      completedBy: map['completedBy'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'stockTakeNumber': stockTakeNumber,
      'warehouseId': warehouseId,
      'warehouseName': warehouseName,
      'status': status.name,
      'stockTakeDate': Timestamp.fromDate(stockTakeDate),
      'items':
          items.map((e) => StockTakeItemModel.fromEntity(e).toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
      'completedBy': completedBy,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// موديل عنصر الجرد
class StockTakeItemModel extends StockTakeItemEntity {
  const StockTakeItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.variantId,
    super.variantName,
    required super.systemQuantity,
    required super.actualQuantity,
    super.notes,
  });

  /// تحويل من Entity
  factory StockTakeItemModel.fromEntity(StockTakeItemEntity entity) {
    return StockTakeItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      variantId: entity.variantId,
      variantName: entity.variantName,
      systemQuantity: entity.systemQuantity,
      actualQuantity: entity.actualQuantity,
      notes: entity.notes,
    );
  }

  /// تحويل من Map
  factory StockTakeItemModel.fromMap(Map<String, dynamic> map) {
    return StockTakeItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'],
      variantId: map['variantId'],
      variantName: map['variantName'],
      systemQuantity: map['systemQuantity'] ?? 0,
      actualQuantity: map['actualQuantity'] ?? 0,
      notes: map['notes'],
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'variantId': variantId,
      'variantName': variantName,
      'systemQuantity': systemQuantity,
      'actualQuantity': actualQuantity,
      'notes': notes,
    };
  }
}

/// موديل رصيد المخزون
class StockBalanceModel extends StockBalanceEntity {
  const StockBalanceModel({
    required super.productId,
    required super.productName,
    super.productSku,
    super.variantId,
    super.variantName,
    required super.warehouseId,
    required super.warehouseName,
    required super.quantity,
    super.reservedQuantity,
    required super.availableQuantity,
    super.averageCost,
    required super.lastUpdated,
  });

  /// تحويل من Entity
  factory StockBalanceModel.fromEntity(StockBalanceEntity entity) {
    return StockBalanceModel(
      productId: entity.productId,
      productName: entity.productName,
      productSku: entity.productSku,
      variantId: entity.variantId,
      variantName: entity.variantName,
      warehouseId: entity.warehouseId,
      warehouseName: entity.warehouseName,
      quantity: entity.quantity,
      reservedQuantity: entity.reservedQuantity,
      availableQuantity: entity.availableQuantity,
      averageCost: entity.averageCost,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// تحويل من Firestore
  factory StockBalanceModel.fromMap(Map<String, dynamic> map, String id) {
    final quantity = map['quantity'] ?? 0;
    final reservedQuantity = map['reservedQuantity'] ?? 0;
    return StockBalanceModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'],
      variantId: map['variantId'],
      variantName: map['variantName'],
      warehouseId: map['warehouseId'] ?? '',
      warehouseName: map['warehouseName'] ?? '',
      quantity: quantity,
      reservedQuantity: reservedQuantity,
      availableQuantity: quantity - reservedQuantity,
      averageCost: (map['averageCost'] as num?)?.toDouble(),
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'variantId': variantId,
      'variantName': variantName,
      'warehouseId': warehouseId,
      'warehouseName': warehouseName,
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'averageCost': averageCost,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
