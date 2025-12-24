import '../../../products/domain/entities/entities.dart';

/// عنصر في سلة المشتريات
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final String variantId;
  final String color;
  final String colorCode;
  final String size;
  final double unitPrice;
  final double unitCost;
  final int quantity;
  final String? barcode;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.variantId,
    required this.color,
    required this.colorCode,
    required this.size,
    required this.unitPrice,
    required this.unitCost,
    required this.quantity,
    this.barcode,
  });

  /// السعر الإجمالي
  double get totalPrice => unitPrice * quantity;

  /// التكلفة الإجمالية
  double get totalCost => unitCost * quantity;

  /// الربح
  double get profit => totalPrice - totalCost;

  /// إنشاء من منتج ومتغير
  factory CartItem.fromProduct({
    required ProductEntity product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    return CartItem(
      id: '${product.id}_${variant.id}',
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      variantId: variant.id,
      color: variant.color,
      colorCode: variant.colorCode,
      size: variant.size,
      unitPrice: product.price,
      unitCost: product.cost,
      quantity: quantity,
      barcode: variant.barcode ?? product.barcode,
    );
  }

  CartItem copyWith({
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
    return CartItem(
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

  /// تحديث الكمية
  CartItem updateQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity);
  }

  /// إضافة كمية
  CartItem addQuantity(int amount) {
    return copyWith(quantity: quantity + amount);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CartItem(product: $productName, color: $color, size: $size, qty: $quantity)';
}
