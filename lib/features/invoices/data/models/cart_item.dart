/// نموذج عنصر السلة
class CartItem {
  final int productId;
  final String name;
  final String? barcode;
  final double unitPrice;
  final double costPrice;
  final double quantity;
  final double availableQty;
  final double discountAmount;
  final double discountPercent;

  const CartItem({
    required this.productId,
    required this.name,
    this.barcode,
    required this.unitPrice,
    this.costPrice = 0,
    required this.quantity,
    required this.availableQty,
    this.discountAmount = 0,
    this.discountPercent = 0,
  });

  /// حساب إجمالي السطر
  double get lineTotal {
    final subtotal = unitPrice * quantity;
    final discount = discountAmount + (subtotal * discountPercent / 100);
    return subtotal - discount;
  }

  /// نسخ مع تعديل
  CartItem copyWith({
    int? productId,
    String? name,
    String? barcode,
    double? unitPrice,
    double? costPrice,
    double? quantity,
    double? availableQty,
    double? discountAmount,
    double? discountPercent,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      availableQty: availableQty ?? this.availableQty,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}
