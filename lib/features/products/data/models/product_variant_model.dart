import '../../domain/entities/entities.dart';

/// نموذج متغير المنتج للتعامل مع Firestore
class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({
    required super.id,
    required super.color,
    super.colorCode,
    required super.size,
    required super.quantity,
    super.sku,
    super.barcode,
  });

  /// إنشاء من Map
  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: map['id'] ?? '',
      color: map['color'] ?? '',
      colorCode: map['colorCode'] ?? '#000000',
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 0,
      sku: map['sku'],
      barcode: map['barcode'],
    );
  }

  /// إنشاء من Entity
  factory ProductVariantModel.fromEntity(ProductVariant entity) {
    return ProductVariantModel(
      id: entity.id,
      color: entity.color,
      colorCode: entity.colorCode,
      size: entity.size,
      quantity: entity.quantity,
      sku: entity.sku,
      barcode: entity.barcode,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'colorCode': colorCode,
      'size': size,
      'quantity': quantity,
      'sku': sku,
      'barcode': barcode,
    };
  }

  @override
  ProductVariantModel copyWith({
    String? id,
    String? color,
    String? colorCode,
    String? size,
    int? quantity,
    String? sku,
    String? barcode,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      color: color ?? this.color,
      colorCode: colorCode ?? this.colorCode,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
    );
  }
}
