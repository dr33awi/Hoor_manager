import '../../domain/entities/entities.dart';

/// نموذج عنصر السلة للتعامل مع Firestore
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.productImage,
    required super.variantId,
    required super.color,
    required super.colorCode,
    required super.size,
    required super.unitPrice,
    required super.unitCost,
    required super.quantity,
    super.barcode,
  });

  /// إنشاء من Map
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      variantId: map['variantId'] ?? '',
      color: map['color'] ?? '',
      colorCode: map['colorCode'] ?? '#000000',
      size: map['size'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      barcode: map['barcode'],
    );
  }

  /// إنشاء من Entity
  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      productImage: entity.productImage,
      variantId: entity.variantId,
      color: entity.color,
      colorCode: entity.colorCode,
      size: entity.size,
      unitPrice: entity.unitPrice,
      unitCost: entity.unitCost,
      quantity: entity.quantity,
      barcode: entity.barcode,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'variantId': variantId,
      'color': color,
      'colorCode': colorCode,
      'size': size,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'quantity': quantity,
      'barcode': barcode,
      'totalPrice': totalPrice,
      'totalCost': totalCost,
    };
  }

  @override
  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    String? variantId,
    String? color,
    String? colorCode,
    String? size,
    double? unitPrice,
    double? unitCost,
    int? quantity,
    String? barcode,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      variantId: variantId ?? this.variantId,
      color: color ?? this.color,
      colorCode: colorCode ?? this.colorCode,
      size: size ?? this.size,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
    );
  }
}
