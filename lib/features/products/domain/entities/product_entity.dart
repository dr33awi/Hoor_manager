import 'product_variant.dart';

/// كيان المنتج
class ProductEntity {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> images; // صور إضافية
  final String categoryId;
  final String? categoryName;
  final double price; // سعر البيع
  final double cost; // سعر التكلفة
  final String? barcode; // باركود رئيسي
  final List<ProductVariant> variants; // المتغيرات (لون + مقاس)
  final bool isActive;
  final int lowStockThreshold; // حد التنبيه للمخزون المنخفض
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.images = const [],
    required this.categoryId,
    this.categoryName,
    required this.price,
    required this.cost,
    this.barcode,
    this.variants = const [],
    this.isActive = true,
    this.lowStockThreshold = 5,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// إجمالي المخزون
  int get totalStock {
    return variants.fold(0, (sum, v) => sum + v.quantity);
  }

  /// هل المنتج نفد
  bool get isOutOfStock => totalStock <= 0;

  /// هل المخزون منخفض
  bool get isLowStock => totalStock > 0 && totalStock <= lowStockThreshold;

  /// هل متوفر
  bool get isAvailable => totalStock > 0 && isActive;

  /// الربح لكل قطعة
  double get profit => price - cost;

  /// نسبة الربح
  double get profitMargin {
    if (cost <= 0) return 0;
    return ((price - cost) / cost) * 100;
  }

  /// الألوان المتوفرة
  List<String> get availableColors {
    return variants
        .where((v) => v.quantity > 0)
        .map((v) => v.color)
        .toSet()
        .toList();
  }

  /// جميع الألوان
  List<String> get allColors {
    return variants.map((v) => v.color).toSet().toList();
  }

  /// المقاسات المتوفرة
  List<String> get availableSizes {
    return variants
        .where((v) => v.quantity > 0)
        .map((v) => v.size)
        .toSet()
        .toList();
  }

  /// جميع المقاسات
  List<String> get allSizes {
    return variants.map((v) => v.size).toSet().toList();
  }

  /// المقاسات المتوفرة للون معين
  List<String> availableSizesForColor(String color) {
    return variants
        .where((v) => v.color == color && v.quantity > 0)
        .map((v) => v.size)
        .toList();
  }

  /// الحصول على متغير بلون ومقاس معين
  ProductVariant? getVariant(String color, String size) {
    try {
      return variants.firstWhere(
        (v) => v.color == color && v.size == size,
      );
    } catch (_) {
      return null;
    }
  }

  /// الحصول على الكمية المتوفرة للون ومقاس
  int getQuantity(String color, String size) {
    return getVariant(color, size)?.quantity ?? 0;
  }

  /// المتغيرات ذات المخزون المنخفض
  List<ProductVariant> get lowStockVariants {
    return variants.where((v) => v.isLowStock).toList();
  }

  /// المتغيرات النافدة
  List<ProductVariant> get outOfStockVariants {
    return variants.where((v) => v.isOutOfStock).toList();
  }

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? images,
    String? categoryId,
    String? categoryName,
    double? price,
    double? cost,
    String? barcode,
    List<ProductVariant>? variants,
    bool? isActive,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      barcode: barcode ?? this.barcode,
      variants: variants ?? this.variants,
      isActive: isActive ?? this.isActive,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProductEntity(id: $id, name: $name, price: $price, stock: $totalStock)';
}
